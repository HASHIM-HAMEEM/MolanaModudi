import 'dart:collection';
import 'dart:async'; 
import 'dart:convert';
import 'dart:io'; 
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/network/network_info.dart';
import 'package:modudi/core/cache/utils/cache_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'config/cache_config.dart' hide CachePolicy;
import 'config/cache_config.dart' as config;
import 'config/cache_constants.dart';
import 'managers/hive_cache_manager.dart';
import 'managers/image_cache_manager.dart';
import 'managers/preferences_cache_manager.dart';
import 'managers/video_cache_manager.dart';
import 'models/cache_result.dart';
import 'models/cache_metadata.dart';
import 'models/cache_priority.dart';
import 'utils/cache_logger.dart';
import 'utils/concurrency_utils.dart';
import 'utils/cache_metrics_service.dart'; 
import 'models/pending_pin_operation.dart'; // Added for offline pin queue

/// Central service for managing all types of caches in the app
class CacheService {

  String? _getScreenIdForKey(String key) {
    // Example implementation: adjust based on your key format.
    if (key.contains('@')) {
      return key.split('@').first;
    }
    return null;
  }
  static final Logger _log = Logger('CacheService');
  
  // Cache managers
  final HiveCacheManager _hiveManager;
  final PreferencesCacheManager _prefsManager;
  final NetworkInfo _networkInfo;
  final CacheConfig _config;
  CacheMetricsService? _metricsService; 

  // Initialize with a default value to prevent LateInitializationError
  late final VideoCacheManager _videoCacheManager;
  late final ImageCacheManager _imageManager;
  
  // Background operation flags
  bool _backgroundCleanupScheduled = false;
  bool _initialized = false;
  
  // Active downloads tracking
  final Map<String, Completer<bool>> _activeDownloads = {};
  
  // Book priorities for cache retention
  final Map<String, CachePriority> _bookPriorities = {};
  
  // Removed download progress functionality - no longer needed
  
  // Memory cache for ultra-fast access during an active session
  // This prevents data reloading when navigating between screens
  // Use an insertion-ordered map to implement simple LRU eviction. The value
  // is the cached object; metadata & timestamps are tracked in separate maps.
  final LinkedHashMap<String, dynamic> _memoryCache = LinkedHashMap();
  final Map<String, int> _memoryCacheTimestamps = {};
  final Map<String, CacheMetadata> _memoryCacheMetadata = {};
  
  // 100 MB in-memory cap. When exceeded the oldest (least recently used)
  // entries are removed.
  final int _maxMemoryCacheSize = 100 * 1024 * 1024;
  int _currentMemoryCacheSize = 0;

  // Concurrency guard: Track in-flight network fetches per cache key
  // Ensures only one network request is made for the same key at a time
  final Map<String, Future<CacheResult<dynamic>>> _inFlightFetches = {};

  // Memory cache TTL 
  static const Duration _memoryCacheTtl = Duration(hours: 8);
  Timer? _memoryCachePruneTimer; // Timer for periodic pruning
      
  // Keep track of which screen each cached item belongs to
  // This allows for efficient release of screen-specific cache when navigating away
  final Map<String, Map<String, dynamic>> _screenMemoryCaches = {};
      
  /// Close all resources used by the cache service
  Future<void> dispose() async {
    // Removed download progress controller - no longer needed
    _networkInfo.dispose(); 
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();
    _memoryCacheMetadata.clear();
    _currentMemoryCacheSize = 0;
    _memoryCachePruneTimer?.cancel(); // Cancel the timer on dispose
  }

  // Added for PrefetchNotifier
  Future<void> prefetchUrls(List<String> urls, {Duration? ttl}) async {
    if (!_initialized) await initialize();
    _log.info('CacheService: Prefetching ${urls.length} URLs.');
    for (final url in urls) {
      try {
        // Using preloadImage from _imageManager as it includes retry logic.
        // _imageManager should be initialized by CacheService.initialize()
        await _imageManager.preloadImage(url, ttl: ttl);
        _log.finer('CacheService: Successfully prefetched URL: $url');
      } catch (e, stackTrace) {
        _log.warning('CacheService: Failed to prefetch URL: $url', e, stackTrace);
        // Decide if one failure should stop all, or continue. For prefetching, continuing is often preferred.
      }
    }
    _log.info('CacheService: Finished prefetching ${urls.length} URLs.');
  }

  // Added for PrefetchNotifier
  Future<void> putRaw({required String key, required String boxName, required dynamic data, Duration? ttl, String? source}) async {
    if (!_initialized) await initialize();
    _log.info('CacheService: Putting raw data with key "$key" into box "$boxName".');
    try {
      // Calculate data size. Assuming 'data' is String as per PrefetchNotifier's current usage.
      // If 'data' can be other types, this might need adjustment or type checking.
      final dataSizeBytes = data is String ? utf8.encode(data).length : 0;

      final metadata = CacheMetadata(
        originalKey: key,
        boxName: boxName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttlMillis: ttl?.inMilliseconds, // Use provided ttl or let CacheMetadata use default
        source: source ?? 'prefetch_notifier', // Default source if not provided
        dataSizeBytes: dataSizeBytes,
      );

      // _hiveManager should be initialized by CacheService.initialize()
      await _hiveManager.put<dynamic>(
        key: key,
        data: data, // Pass the original data
        boxName: boxName,
        metadata: metadata, // Pass the constructed metadata
      );
      _log.finer('CacheService: Successfully put raw data with key "$key" into box "$boxName".');
    } catch (e, stackTrace) {
      _log.severe('CacheService: Error putting raw data with key "$key" into box "$boxName"', e, stackTrace);
      rethrow; // Rethrow to allow the caller (PrefetchNotifier) to handle it.
    }
  }
      
  // Work queue for managing concurrent downloads
  final WorkQueue _downloadQueue = WorkQueue(3);

  /// Create a new cache service with the specified configuration
  /// This constructor is now private to enforce singleton pattern via init().


  static CacheService? _instance;
  bool _isDisposed = false;

  CacheService._internal(this._config, this._hiveManager, this._prefsManager, this._networkInfo) {
    // Initialize managers that depend on 'this' CacheService instance here
    _videoCacheManager = VideoCacheManager(cacheService: this);
    _imageManager = ImageCacheManager(this);

    // Initialize CacheMetricsService based on the configuration
    if (_config.enableAnalytics && _config.trackCacheMetrics) {
      _metricsService = CacheMetricsService();
      _log.info('CacheMetricsService initialized in _internal constructor.');
    } else {
      _log.info('CacheMetricsService not initialized (analytics or tracking disabled in _internal constructor).');
    }
  }

  static Future<CacheService> init({
    CacheConfig config = const CacheConfig(),
    List<String> customBoxNames = const [],
  }) async {
    if (_instance != null && !_instance!._isDisposed && _instance!._initialized) {
      _log.info('CacheService already initialized and ready.');
      return _instance!;
    }
    _log.info('Initializing CacheService...');

    await Hive.initFlutter();

    // Register adapters for offline pin queue
    if (!Hive.isAdapterRegistered(PendingPinOperationAdapter().typeId)) {
      Hive.registerAdapter(PendingPinOperationAdapter());
    }
    if (!Hive.isAdapterRegistered(PinOperationTypeAdapter().typeId)) {
      Hive.registerAdapter(PinOperationTypeAdapter());
    }

    final List<String> generalBoxNames = [
      CacheConstants.booksBoxName,
      CacheConstants.volumesBoxName,
      CacheConstants.chaptersBoxName,
      CacheConstants.headingsBoxName,
      CacheConstants.contentBoxName,
      CacheConstants.bookStructuresBoxName,
      CacheConstants.thumbnailMetadataBoxName,
      CacheConstants.imageMetadataBoxName,
    ];
    generalBoxNames.addAll(customBoxNames);

    final List<Future<void>> boxOpeningFutures = [];
    for (final boxName in generalBoxNames) {
      if (!Hive.isBoxOpen(boxName)) {
        _log.info('Queueing opening of general Hive box: $boxName');
        boxOpeningFutures.add(
          Hive.openBox<String>(boxName).then((_) { // Explicitly open as Box<String>
            _log.info('Successfully opened general Hive box<String>: $boxName');
          }).catchError((e, stackTrace) {
            _log.severe('Error opening general Hive box<String>: $boxName', e, stackTrace);
            throw e;
          })
        );
      } else {
        _log.info('General Hive box already open: $boxName');
      }
    }
    
    try {
      await Future.wait(boxOpeningFutures);
      _log.info('All queued general Hive boxes have been processed for opening.');
    } catch (e, stackTrace) {
      _log.severe('Error during concurrent opening of general Hive boxes', e, stackTrace);
      rethrow;
    }
    
    final hiveManager = HiveCacheManager();
    // await hiveManager.initialize(); // This will be called on the instance later

    final prefsManager = PreferencesCacheManager();
    // await prefsManager.initialize(); // This will be called on the instance later

    final networkInfo = NetworkInfo();
    // await networkInfo.initialize(); // This will be called on the instance later

    // Create the instance if it doesn't exist or was disposed
    if (_instance == null || _instance!._isDisposed) {
    _instance = CacheService._internal(
      config,
        hiveManager, // Pass managers that don't depend on CacheService instance itself
      prefsManager,
      networkInfo,
    );
      _instance!._isDisposed = false;
      _log.info('CacheService instance created.');
    } else {
      // If instance exists, update its config if necessary (though config is usually static)
      // For now, assume config passed to init is for initial setup only.
      _log.info('CacheService instance already exists. Re-using.');
    }

    // Now, perform instance-specific initializations that were in the old initialize() method
    if (!_instance!._initialized) { // Check if already initialized by a concurrent call
      CacheLogger.setLoggingEnabled(_instance!._config.enableLogging);

      await _instance!._networkInfo.initialize(); // Initialize network info for the instance
      await _instance!._hiveManager.initialize();
      await _instance!._prefsManager.initialize();
      
      // _videoCacheManager and _imageManager are already initialized in _internal constructor
      // but their own .initialize() methods should be called.
      await _instance!._videoCacheManager.initialize(); 
      await _instance!._imageManager.initialize();

      await _instance!._loadBookPriorities();
      
      if (_instance!._config.autoClearStaleOnStart) {
        _instance!._scheduleBackgroundCleanup();
      }
      
      // Start periodic pruning of memory cache
      _instance!.startMemoryCachePruning();

      _instance!._initialized = true;
      _log.info('CacheService instance fully initialized and ready.');
    } else {
      _log.info('CacheService instance was already initialized by another call.');
    }
    
    return _instance!;
  }

  static CacheService get instance {
    if (_instance == null || _instance!._isDisposed) {
      throw Exception("CacheService not initialized. Call CacheService.init() first.");
    }
    return _instance!;
  }

  /// DEPRECATED: Initialize the cache service and load data. Use CacheService.init() instead.
  /// This method is now mostly a no-op if init() has been called.
  Future<void> initialize() async {
    if (_initialized) {
      _log.info('CacheService.initialize() called, but already initialized. No-op.');
      return;
    }
    // If somehow init() was not called, this would be a fallback, 
    // but the pattern should be to ensure init() is called first.
    _log.warning('CacheService.initialize() called without prior static CacheService.init(). This is not recommended.');
    // For safety, try to run the core init logic if not initialized.
    // This might indicate an issue in the app's startup sequence.
    // Re-direct to the static init method, which is idempotent.
    await CacheService.init(config: _config); // Use its own config if available
  }
  
  /// Load book priorities from persistent storage
  Future<void> _loadBookPriorities() async {
    try {
      // Ensure the cache service is initialized
      await _hiveManager.initialize();
      // Use Hive.box directly since _hiveManager.initialize() should have opened it
      final box = Hive.box<String>(CacheConstants.metadataBoxName);
      final priorityKeys = box.keys.where((key) => key.startsWith('priority:'));
      
      for (final key in priorityKeys) {
        final data = box.get(key);
        if (data != null) {
          try {
            final Map<String, dynamic> json = jsonDecode(data);
            final priority = CachePriority.fromJson(json);
            _bookPriorities[priority.bookId] = priority;
          } catch (e) {
            _log.warning('Error parsing priority data for key $key: $e');
          }
        }
      }
      
      _log.info('Loaded ${_bookPriorities.length} book priorities');
    } catch (e) {
      _log.warning('Error loading book priorities: $e');
    }
  }
  
  /// Update the priority of a book
  Future<void> updateBookPriority(String bookId, CachePriorityLevel level) async {
    if (!_initialized) await initialize();
    
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final currentPriority = _bookPriorities[bookId];
      
      final updatedPriority = currentPriority != null
          ? currentPriority.copyWith(
              level: level,
              lastAccessTimestamp: now,
              accessCount: currentPriority.accessCount + 1,
            )
          : CachePriority(
              bookId: bookId,
              level: level,
              lastAccessTimestamp: now,
            );
      
      // Update in-memory cache
      _bookPriorities[bookId] = updatedPriority;
      
      // Save to persistent storage
      // Ensure the cache service is initialized
      await _hiveManager.initialize();
      // Use Hive.box directly
      final box = Hive.box<String>(CacheConstants.metadataBoxName);
      await box.put('priority:$bookId', jsonEncode(updatedPriority.toJson()));
      
      CacheLogger.info('Updated priority for book $bookId to ${level.toString().split('.').last}');
    } catch (e) {
      _log.warning('Error updating book priority for $bookId: $e');
    }
  }

  /// Check if the device is currently connected to the internet
  /// Using NetworkInfo for more reliable connectivity detection
  Future<bool> isConnected() async {
    try {
      return await _networkInfo.checkConnectivity();
    } catch (e) {
      _log.warning('Error checking connectivity: $e');
      return false;
    }
  }
  
  /// Get real-time connectivity status without async wait
  bool get isConnectedSync => _networkInfo.isConnected;
  
  /// Fetch data from cache or network with improved connectivity awareness
  Future<CacheResult<T>> fetch<T>({
    required String key,
    required String boxName,
    required Future<T> Function() networkFetch,
    Duration? ttl,
    config.CachePolicy? policy,
    String? screenId, 
  }) async {
    if (!_initialized) await initialize();

    final effectivePolicy = policy ?? config.CachePolicy.cacheFirst;
    final effectiveTtl = ttl ?? _config.defaultTtl;

    CacheResult<T>? cachedResult;
    
    try {
      // STEP 1: Check memory cache first (ultra-fast)
      final memoryCached = _getFromMemoryCache<T>(key);
      if (memoryCached != null) {
        _log.fine('Memory cache hit for key: $key');
        
        // Associate with screen if provided
        if (screenId != null) {
          _screenMemoryCaches.putIfAbsent(screenId, () => {})[key] = memoryCached;
        }
        
        // Update access stats for memory hit
        final metadata = _memoryCacheMetadata[key];
        if (metadata != null) {
          final updatedMetadata = metadata.incrementAccessCount();
          await _saveCacheMetadata(key, updatedMetadata); // Save to persistent store
          _memoryCacheMetadata[key] = updatedMetadata; // Update in-memory metadata cache
          _metricsService?.recordHit(key); // ADDED: Record hit
          return CacheResult.fresh(memoryCached, metadata: updatedMetadata);
        } else {
          // Create a new metadata object if none exists in memory, with initial access
          final newMetadata = CacheMetadata(
            originalKey: key,
            boxName: boxName,
            timestamp: _memoryCacheTimestamps[key] ?? DateTime.now().millisecondsSinceEpoch,
            accessCount: 1, // Initial access
            lastAccessTimestamp: DateTime.now().millisecondsSinceEpoch // Initial access
          );
          await _saveCacheMetadata(key, newMetadata); // Save to persistent store
          _memoryCacheMetadata[key] = newMetadata; // Add to in-memory metadata cache
          _metricsService?.recordHit(key); // ADDED: Record hit
          return CacheResult.fresh(memoryCached, metadata: newMetadata);
        }
      }
      
      // STEP 2: Check persistent storage if policy allows it
      if (effectivePolicy != config.CachePolicy.networkOnly) {
        cachedResult = await getCachedData<T>(key: key, boxName: boxName);
        
        if (cachedResult.hasData) {
          // Associate with screen if provided
          if (screenId != null) {
            _screenMemoryCaches.putIfAbsent(screenId, () => {})[key] = cachedResult.data;
          }
          
          // Get cache metadata for checking staleness
          // final metadata = await _getCacheMetadata(key); // Already in cachedResult.metadata
          final CacheMetadata? existingMetadata = cachedResult.metadata;
          final isStale = existingMetadata?.isStale(effectiveTtl) ?? true;
          
          // Update access stats for persistent hit
          CacheMetadata? finalMetadata = existingMetadata;
          if (existingMetadata != null) {
            finalMetadata = existingMetadata.incrementAccessCount();
            await _saveCacheMetadata(key, finalMetadata);
          }

          // Return cache immediately if policy is cacheOnly or it's not stale
          if (effectivePolicy == config.CachePolicy.cacheOnly ||
              !isStale) {
            // Ensure the result uses the potentially updated metadata
            _metricsService?.recordHit(key); // ADDED: Record hit
            if (!isStale) {
              return CacheResult.fresh(cachedResult.data as T, metadata: finalMetadata);
            } else { // This implies policy is cacheOnly and data is stale
              return CacheResult.stale(cachedResult.data as T, metadata: finalMetadata);
            }
          }
          
          // For staleWhileRevalidate, trigger network fetch in background then return cache
          if (effectivePolicy == config.CachePolicy.staleWhileRevalidate) {
            // No await - don't block returning the cached data
            _refreshCacheInBackground(
              key: key,
              boxName: boxName,
              fetch: networkFetch,
              ttl: effectiveTtl
            );
            // Ensure the result uses the potentially updated metadata
            _metricsService?.recordHit(key); // ADDED: Record hit
            return CacheResult.stale(cachedResult.data as T, metadata: finalMetadata);
          }
          
          // For cacheFirst, return cache when found even if stale
          if (effectivePolicy == config.CachePolicy.cacheFirst) {
            // Optionally refresh stale data in background for better user experience
            if (isStale && await isConnected()) {
              _refreshCacheInBackground(
                key: key,
                boxName: boxName,
                fetch: networkFetch,
                ttl: effectiveTtl
              );
            }
            // Ensure the result uses the potentially updated metadata
            _metricsService?.recordHit(key); // ADDED: Record hit
            if (!isStale) {
              return CacheResult.fresh(cachedResult.data as T, metadata: finalMetadata);
            } else {
              return CacheResult.stale(cachedResult.data as T, metadata: finalMetadata);
            }
          }
        }
      }
            
      // STEP 4: Fetch from network if allowed by policy and connectivity
      final isOnline = await isConnected();
      if (isOnline &&
          (effectivePolicy == config.CachePolicy.networkFirst ||
              effectivePolicy == config.CachePolicy.cacheFirst ||
              effectivePolicy == config.CachePolicy.networkOnly)) {
        try {
          // Check for an in-flight fetch for this key
          if (_inFlightFetches.containsKey(key)) {
            _log.fine('Request for key $key is already in flight. Awaiting existing Future<CacheResult<T>>.');
            // Cast to the correct type. If the future fails, the await will rethrow the error.
            return await (_inFlightFetches[key]! as Future<CacheResult<T>>);
          }

          // No in-flight fetch, proceed with new network request and caching logic.
          // Create a Completer to produce the Future<CacheResult<T>>.
          final completer = Completer<CacheResult<T>>();
          _inFlightFetches[key] = completer.future;
          _log.fine('Added new Future<CacheResult<T>> to _inFlightFetches for key: $key.');

          try {
            final T fetchedData = await networkFetch(); // Actual network call
            _log.fine('Network fetch successful for key: $key');
            
            // Cache the newly fetched data (disk and memory)
            // This is done ONLY by the first caller that initiated the fetch.
            final newMetadata = await cacheData<T>(
              key: key, 
              data: fetchedData, 
              boxName: boxName, 
              ttl: effectiveTtl,
              isPinned: cachedResult?.metadata?.isPinned ?? false 
            );
            
            // _putInMemoryCache is called within cacheData, so no need to call it separately here for the primary caching.
            // However, ensure it's associated with screenId if provided.
            if (screenId != null) {
               // _putInMemoryCache if not already done by cacheData, or ensure association
               // cacheData calls _putInMemoryCache which handles the main L1 update.
               // We just need to ensure the screen association if screenId is present.
               _screenMemoryCaches.putIfAbsent(screenId, () => {})[key] = fetchedData;
            }
            
            final result = CacheResult.fresh(fetchedData, metadata: newMetadata);
            completer.complete(result); // Complete with the successful CacheResult
            return result;
          } catch (e, stackTrace) {
            _log.warning('Network fetch or caching failed for key $key: $e');
            final errorResult = CacheResult.fromError<T>(CacheError('Network fetch/caching failed: $e', stackTrace));
            // If network fetch fails and we had a stale cache, return it rather than erroring out
            // This logic needs to be outside the completer error handling if we want to return stale cache.
            // For now, the in-flight future will complete with an error.
            final err = errorResult.error;
            if (err is CacheError) {
              completer.completeError(err, err.stackTrace);
            } else {
              completer.completeError(err ?? Exception("Unknown fetch error"));
            } // Complete the future with an error
            
            // Check if we should return stale data based on original cachedResult
            if (cachedResult != null && cachedResult.hasData) {
              return CacheResult.stale(cachedResult.data as T, metadata: cachedResult.metadata, error: CacheError('Network fetch or caching failed for key $key, returning stale data.', stackTrace));
            }
            return errorResult; // Return the error result
          } finally {
            // Remove the future from the map once it's completed (either successfully or with an error).
            _inFlightFetches.remove(key);
            _log.fine('Removed Future<CacheResult<T>> from _inFlightFetches for key: $key.');
          }
        } catch (e) {
          // This catch is for errors not handled by the inner try-finally related to the completer.
          // For example, if _inFlightFetches.containsKey itself throws, or an issue before completer is set.
          _inFlightFetches.remove(key); // Ensure removal if error occurs before/during completer setup
          _log.warning('Outer error in network fetch logic for key $key: $e');
          if (cachedResult != null && cachedResult.hasData) {
            return CacheResult.stale(cachedResult.data as T, metadata: cachedResult.metadata, error: CacheError('Outer error in network fetch logic for key $key, returning stale data.', e is Error ? e.stackTrace : StackTrace.current));
          }
          return CacheResult.fromError<T>(CacheError('Outer error in network fetch logic for key $key: $e', e is Error ? e.stackTrace : StackTrace.current));
        }
      }
      
      // If we reach here with cacheOnly policy, it means cache was empty
      // or if network was unavailable and no cache hit.
      _log.fine('No data found for key $key. Policy: $effectivePolicy, Online: $isOnline, Cached: ${cachedResult?.hasData}');
      if (cachedResult != null && cachedResult.hasData) {
        // This implies network was not attempted or failed, but we have some cache.
        return cachedResult; 
      }
      // At this point, no data from cache and network fetch was not performed or failed without stale fallback.
      return CacheResult.missing<T>(error: CacheError('Data not found for key: $key. Network fetch not allowed or failed, and no cache available.', StackTrace.current));

    } catch (e, stackTrace) { // This is the main catch block for the entire fetch operation
      _log.severe('Overall error fetching data for key $key: $e', e, stackTrace);
      // Fallback to cachedResult if any error occurs and data is available
      if (cachedResult != null && cachedResult.hasData) {
        return CacheResult.stale(
          cachedResult.data as T,
          metadata: cachedResult.metadata,
          error: CacheError('Overall fetch failed, returning stale for key $key: $e', stackTrace)
        );
      }
      // Otherwise, return a generic error result
      return CacheResult.fromError<T>(
        CacheError('Overall fetch failed for key $key: $e', stackTrace)
      );
    }
  } // Closing brace for the fetch method

  /// Cache data directly in both persistent storage and memory cache
  Future<CacheMetadata> cacheData<T>({
    required String key,
    required T data,
    required String boxName,
    Duration? ttl,
    String? screenId, 
    bool isPinned = false, // Added isPinned parameter back
  }) async {
    if (!_initialized) await initialize();

    try {
      // Create metadata
      final metadata = CacheMetadata(
        originalKey: key,
        boxName: boxName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        lastAccessTimestamp: DateTime.now().millisecondsSinceEpoch,
        accessCount: 1,
        ttlMillis: (ttl ?? _config.defaultTtl).inMilliseconds,
        dataSizeBytes: CacheUtils.calculateObjectSize(data),
        isPinned: isPinned, // Use isPinned parameter here
        // eTag and version can be set later if available from network responses
      );
      
      // STEP 1: Add to memory cache for ultra-fast access
      _putInMemoryCache(key, data, metadata, screenId: screenId);
      
      // STEP 2: Store data in persistent cache
      await _hiveManager.put(
        key: key,
        data: data,
        boxName: boxName,
        metadata: metadata, // Pass the created CacheMetadata object
        // ttl, language, properties are removed as they are now in the metadata object
      );

      // STEP 3: Store the authoritative CacheMetadata object using CacheService's mechanism
      await _saveCacheMetadata(key, metadata);
      
      _metricsService?.recordWrite(key); // ADDED: Record write
      CacheLogger.logCacheWrite(key, boxName, metadata.dataSizeBytes); // Use dataSizeBytes from CacheService's metadata
      _log.fine('Cached data for key: $key with TTL: ${metadata.ttl.inHours} hours');
      return metadata; // Return the created metadata
    } catch (e) {
      _log.warning('Error caching data for key $key: $e');
      rethrow;
    }
  }

  /// Retrieves an item from the L1 memory cache.
  /// Returns null if the item is not found or an error occurs.
  T? getFromMemoryCache<T>(String key) {
    try {
      return _getFromMemoryCache<T>(key);
    } catch (e, stackTrace) {
      _log.warning('Error getting item from memory cache: $key', e, stackTrace);
      return null;
    }
  }

  /// Stores an item in the L1 memory cache.
  ///
  /// [key]: The cache key.
  /// [data]: The data to store.
  /// [dataSizeBytes]: The size of the data in bytes. Used if [metadata] is null or does not contain size.
  /// [metadata]: Optional metadata for the cached item. If provided and contains `dataSizeBytes`,
  ///            that will be preferred over the [dataSizeBytes] parameter.
  /// [screenId]: Optional screen ID to associate this cache entry with for screen-specific eviction.
  void storeInMemoryCache<T>(
    String key, 
    T data, 
    int dataSizeBytes, // Explicit size from caller
    {CacheMetadata? metadata, 
    String? screenId}
  ) {
    try {
      // Use metadata's size if available, otherwise use the provided dataSizeBytes
      final int sizeToUse = metadata?.dataSizeBytes ?? dataSizeBytes;
      
      // If metadata is null, create a basic one for _putInMemoryCache if needed, or let _putInMemoryCache handle it.
      // For now, _putInMemoryCache can create its own if metadata is null.
      // We need to ensure _putInMemoryCache can accept an explicit size if metadata is not passed or incomplete.
      // Let's adjust _putInMemoryCache or ensure it works with this.
      // For simplicity, we'll pass the calculated/provided size directly to _putInMemoryCache.
      // _putInMemoryCache will need to be adjusted to accept this explicit size.

      CacheMetadata effectiveMetadata = metadata ?? CacheMetadata(
        originalKey: key,
        boxName: CacheConstants.MEMORY_CACHE_BOX, // Special box name for memory items. Assumes MEMORY_CACHE_BOX is defined.
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttlMillis: _memoryCacheTtl.inMilliseconds, // Default TTL for memory cache
        dataSizeBytes: sizeToUse, // Use the determined size
        source: 'memory', // Indicate it's an in-memory item
      );

      // Ensure metadata has the correct size
      if (effectiveMetadata.dataSizeBytes != sizeToUse) {
        effectiveMetadata = effectiveMetadata.copyWith(dataSizeBytes: sizeToUse);
      }
      
      _putInMemoryCache<T>(key, data, effectiveMetadata, screenId: screenId);
    } catch (e, stackTrace) {
      _log.warning('Error storing item in memory cache: $key', e, stackTrace);
    }
  }

  /// Get data from memory cache
  T? _getFromMemoryCache<T>(String key) {
    if (_memoryCache.containsKey(key)) {
      final timestamp = _memoryCacheTimestamps[key] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if memory cache entry is still valid
      if (now - timestamp < _memoryCacheTtl.inMilliseconds) {
        // Update timestamp to mark as recently accessed
        _memoryCacheTimestamps[key] = now;
        return _memoryCache[key] as T?;
      } else {
        // Remove expired memory cache entry
        _removeFromMemoryCache(key);
      }
    }
    
    return null;
  }
  
  /// Add data to memory cache
  void _putInMemoryCache<T>(
    String key,
    T data,
    CacheMetadata? metadata, {
    String? screenId,
    int? explicitSizeBytes, // Added to accept size directly
  }) {
    if (key.isEmpty) {
      _log.warning('Attempted to put item with empty key in memory cache.');
      return;
    }
    // If this key already exists, remove it first to update its position in the LRU map.
    if (_memoryCache.containsKey(key)) {
      _removeFromMemoryCache(key, isEviction: false, screenId: _getScreenIdForKey(key));
    }

    int itemSizeBytes;
    if (explicitSizeBytes != null) {
      itemSizeBytes = explicitSizeBytes;
    } else if (metadata?.dataSizeBytes != null && metadata!.dataSizeBytes > 0) {
      itemSizeBytes = metadata.dataSizeBytes;
    } else if (data != null) {
      // Fallback to calculating size if not provided
      if (data is String) {
        itemSizeBytes = utf8.encode(data).length;
      } else if (data is Uint8List) {
        itemSizeBytes = data.lengthInBytes;
      } else {
        // For other types, estimate using JSON encoding (can be inaccurate)
        try {
          itemSizeBytes = jsonEncode(data).length;
        } catch (_) {
          itemSizeBytes = 1024; // Default small size if encoding fails
          _log.info('Could not accurately determine size for memory cache item type: ${data.runtimeType}. Using default size: $itemSizeBytes bytes for key: $key');
        }
      }
    } else {
      itemSizeBytes = 0; // No data, no size
    }
    
    _currentMemoryCacheSize += itemSizeBytes;
      _memoryCache[key] = data;
      _memoryCacheTimestamps[key] = DateTime.now().millisecondsSinceEpoch;
    
    // Store minimal metadata if provided, otherwise a basic one is fine for L1.
    // L1 primarily cares about existence and LRU, not full metadata like L2.
    _memoryCacheMetadata[key] = metadata ?? CacheMetadata(
      originalKey: key,
      boxName: 'memory', // Special type for memory cache
      timestamp: DateTime.now().millisecondsSinceEpoch,
      ttlMillis: _memoryCacheTtl.inMilliseconds,
      dataSizeBytes: itemSizeBytes,
      source: 'memory',
    );

    if (screenId != null) {
      _screenMemoryCaches.putIfAbsent(screenId, () => {})[key] = data;
      _log.finer('Associated memory cache key "$key" with screen "$screenId"');
    }

    _log.finer('Put item into L1 memory cache: $key, Size: ${CacheUtils.formatSize(itemSizeBytes)}, Total L1 Size: ${CacheUtils.formatSize(_currentMemoryCacheSize)}');
    _evictLeastRecentlyUsed(); // Check if eviction is needed
   }

  /// Remove data from memory cache
  void _removeFromMemoryCache(String key, {bool isEviction = true, String? screenId}) {
    if (_memoryCache.containsKey(key)) {
      final data = _memoryCache[key];
      final estimatedSize = CacheUtils.calculateObjectSize(data);
      
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
      _memoryCacheMetadata.remove(key);
      _currentMemoryCacheSize -= estimatedSize;
      
      if (_currentMemoryCacheSize < 0) _currentMemoryCacheSize = 0;
      
      if (screenId != null && _screenMemoryCaches.containsKey(screenId)) {
        _screenMemoryCaches[screenId]?.remove(key);
        _log.finer('Removed $key from screen-specific memory cache for $screenId');
      }
      
      if (isEviction) {
        _metricsService?.recordEviction(key, reason: 'LRU-mem');
      }
    }
  }
  
  /// Optimized: More intelligent LRU eviction with batch operations
  void _evictLeastRecentlyUsed() {
    if (_currentMemoryCacheSize <= _maxMemoryCacheSize) return;
    
    final targetSize = (_maxMemoryCacheSize * 0.7).round(); // Target 70% capacity
    final sizeToFree = _currentMemoryCacheSize - targetSize;
    
    // Create list of entries sorted by last access time (oldest first)
    final entriesByAge = _memoryCacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    int freedSize = 0;
    final keysToRemove = <String>[];
    
    // Collect keys to remove until we free enough space
    for (final entry in entriesByAge) {
      if (freedSize >= sizeToFree) break;
      
      final key = entry.key;
      final metadata = _memoryCacheMetadata[key];
      final itemSize = metadata?.dataSizeBytes ?? CacheUtils.calculateObjectSize(_memoryCache[key]);
      
      keysToRemove.add(key);
      freedSize += itemSize;
    }
    
    if (keysToRemove.isNotEmpty) {
      _log.info('LRU evicting ${keysToRemove.length} items (${CacheUtils.formatSize(freedSize)}) from memory cache');
      
      // Batch remove for better performance
      for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
      _memoryCacheMetadata.remove(key);
        
        // Clean up screen associations
        final screenId = _getScreenIdForKey(key);
        if (screenId != null && _screenMemoryCaches.containsKey(screenId)) {
          _screenMemoryCaches[screenId]?.remove(key);
        }
        
      _metricsService?.recordEviction(key, reason: 'LRU-mem');
      }
      
      // Update size in one operation
      _currentMemoryCacheSize = max(0, _currentMemoryCacheSize - freedSize);
      
      _log.fine('Memory cache after LRU eviction: ${CacheUtils.formatSize(_currentMemoryCacheSize)}');
    }
  }

  /// **DEPRECATED**: This feature is not currently used in the app.
  /// If implemented, ensure `releaseScreenMemoryCache` is called appropriately.
  /// 
  /// Preloads data for a specific screen and stores it in the memory cache.
  /// This is useful for improving perceived performance by fetching data before a screen is displayed.
  @Deprecated('Not currently used. If used, ensure releaseScreenMemoryCache is called.')
  Future<void> preloadScreenData(String screenId, List<String> keys, List<String> boxNames) async {
    if (!_initialized) await initialize();
    
    assert(keys.length == boxNames.length, 'Keys and box names must have the same length');
    
    _log.fine('Preloading ${keys.length} items for screen: $screenId');
    
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final boxName = boxNames[i];
      
      // Load into memory cache if not already there
      if (!_memoryCache.containsKey(key)) {
        final cacheResult = await getCachedData<dynamic>(key: key, boxName: boxName);
        if (cacheResult.hasData) {
          _log.fine('Preloaded cache item for key: $key');
        }
      }
    }
  }
  
  /// **DEPRECATED**: This feature is tied to `preloadScreenData` or manual L1 screen caching.
  /// If `storeInMemoryCache` is used with `screenId`, this must be called on screen disposal.
  ///
  /// Releases all memory cache entries associated with a specific screen ID.
  /// This should be called when a screen is disposed to free up memory.
  @Deprecated('Not currently used with screen-specific L1 caching. Call if screenId is used in storeInMemoryCache.')
  void releaseScreenMemoryCache(String screenId) {
    if (_screenMemoryCaches.containsKey(screenId)) {
      final screenCache = _screenMemoryCaches.remove(screenId);
      if (screenCache != null) {
        CacheLogger.info('Released memory cache for screen: $screenId, removed ${screenCache.length} items.');
      }
    } else {
      CacheLogger.info('No memory cache found to release for screen: $screenId');
    }
  }

  /// Get cached data with type conversion, following the cache-first approach
  /// First checks the ultra-fast memory cache, then persistent storage
  Future<CacheResult<T>> getCachedData<T>({required String key, required String boxName}) async {
    if (!_initialized) await initialize();
    
    try {
      // Check memory cache first
      final memoryCached = _getFromMemoryCache<T>(key);
      if (memoryCached != null) {
        _log.fine('Memory cache hit for key: $key');
        final metadata = _memoryCacheMetadata[key];
        if (metadata != null) {
          _metricsService?.recordHit(key); // ADDED: Record hit
          if (metadata.isExpired) { // metadata is non-null here
            return CacheResult.stale<T>(memoryCached, metadata: metadata);
          } else {
            return CacheResult.fresh<T>(memoryCached, metadata: metadata);
          }
        } else {
          // Create basic metadata if none exists
          final newMetadata = CacheMetadata(
            originalKey: key,
            boxName: boxName,
            timestamp: _memoryCacheTimestamps[key] ?? DateTime.now().millisecondsSinceEpoch
          );
          return CacheResult.fresh<T>(memoryCached, metadata: newMetadata);
        }
      }
      
      // Check persistent storage using the HiveCacheManager
      try {
        // Get the Hive box through the manager
        final List<String> keysInBox = await _hiveManager.getAllKeys(boxName); // NEW - Corrected
        if (!keysInBox.contains(key)) { // NEW - Corrected
          _log.fine('Cache miss for key: $key');
          _metricsService?.recordMiss(key); // ADDED: Record miss
          return CacheResult.missing<T>();
        }
        
        // Try to convert the raw data to the expected type
        T? typedData;
        try {
          typedData = await _hiveManager.get(key: key, boxName: boxName) as T; // NEW - Corrected with named arguments
        } catch (e) {
          _log.warning('Type conversion error for cached data: $e');
          return CacheResult.fromError<T>(CacheError('Type conversion error for cached data for key $key: $e', e is Error ? e.stackTrace : StackTrace.current));
        }
        
        // Get metadata
        final metadata = await _getCacheMetadata(key);
        
        // Add to memory cache for faster subsequent access
        _putInMemoryCache(key, typedData, metadata);
        
        _metricsService?.recordHit(key); // ADDED: Record hit
        if (metadata == null) {
          _log.warning('Metadata unexpectedly null for key: $key in persistent cache hit scenario. Treating as error.');
          return CacheResult.fromError<T>(CacheError('Metadata not found for key $key after persistent cache retrieval', StackTrace.current));
        }
        if (metadata.isExpired) {
          return CacheResult.stale<T>(typedData as T, metadata: metadata);
        } else {
          return CacheResult.fresh<T>(typedData as T, metadata: metadata);
        }
      } catch (e) {
        _log.warning('Error retrieving data from persistent cache: $e');
        return CacheResult.fromError<T>(CacheError('Error retrieving data from persistent cache for key $key: $e', e is Error ? e.stackTrace : StackTrace.current));
      }
    } catch (e) {
      _log.warning('Error getting cached data for key $key: $e');
      return CacheResult.fromError<T>(CacheError('Error getting cached data for key $key: $e', e is Error ? e.stackTrace : StackTrace.current));
    }
  }

  /// Get a cached image if available, otherwise download it
  Future<String?> getImage(String url, {Duration? ttl}) async {
    if (!_initialized) await initialize();
    
    try {
      final file = await _imageManager.getImage(url, ttl: ttl);
      return file?.path;
    } catch (e) {
      _log.warning('Error getting image: $url', e);
      return null;
    }
  }

  /// Save an image for offline use
  Future<File?> saveImageForOffline(String url, String id, String directoryName) async {
    if (!_initialized) await initialize();
    
    try {
      return await _imageManager.saveImageToAppDirectory(url, id, directoryName);
    } catch (e) {
      _log.severe('Error saving image for offline via CacheService: $url', e);
      return null;
    }
  }

  /// Cache video metadata
  Future<void> cacheVideoMetadata(String videoId, Map<String, dynamic> metadata) async {
    if (!_initialized) await initialize();
    
    try {
      await _videoCacheManager.cacheVideoMetadata(videoId, metadata);
    } catch (e) {
      _log.warning('Error caching video metadata: $videoId', e);
      rethrow;
    }
  }

  /// Get cached video metadata
  Future<Map<String, dynamic>?> getVideoMetadata(String videoId) async {
    if (!_initialized) await initialize();
    
    try {
      return await _videoCacheManager.getVideoMetadata(videoId);
    } catch (e) {
      _log.warning('Error getting video metadata: $videoId', e);
      return null;
    }
  }

  /// Cache playlist data
  Future<void> cachePlaylist(String playlistId, Map<String, dynamic> playlistData) async {
    if (!_initialized) await initialize();
    
    try {
      await _videoCacheManager.cachePlaylist(playlistId, playlistData);
    } catch (e) {
      _log.warning('Error caching playlist: $playlistId', e);
      rethrow;
    }
  }

  /// Get cached playlist
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    if (!_initialized) await initialize();
    
    try {
      return await _videoCacheManager.getPlaylist(playlistId);
    } catch (e) {
      _log.warning('Error getting playlist: $playlistId', e);
      return null;
    }
  }

  /// Save bookmarks for a book
  Future<bool> saveBookmarks(String bookId, List<dynamic> bookmarks) async {
    if (!_initialized) await initialize();
    
    try {
      return await _prefsManager.saveBookmarks(bookId, bookmarks);
    } catch (e) {
      _log.warning('Error saving bookmarks: $bookId', e);
      return false;
    }
  }

  /// Get bookmarks for a book
  Future<List<dynamic>?> getBookmarks(String bookId) async {
    if (!_initialized) await initialize();
    
    try {
      return await _prefsManager.getBookmarks(bookId);
    } catch (e) {
      _log.warning('Error getting bookmarks: $bookId', e);
      return null;
    }
  }

  /// Save reading progress for a book
  Future<bool> saveReadingProgress(String bookId, Map<String, dynamic> progress) async {
    if (!_initialized) await initialize();
    
    try {
      return await _prefsManager.saveReadingProgress(bookId, progress);
    } catch (e) {
      _log.warning('Error saving reading progress: $bookId', e);
      return false;
    }
  }

  /// Get reading progress for a book
  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    if (!_initialized) await initialize();
    
    try {
      return await _prefsManager.getReadingProgress(bookId);
    } catch (e) {
      _log.warning('Error getting reading progress: $bookId', e);
      return null;
    }
  }

  /// Get cache size statistics
  Future<Map<String, int>> getCacheSizeStats() async {
    if (!_initialized) await initialize();
    
    try {
      final booksCacheSize = await _hiveManager.getBoxSize(CacheConstants.booksBoxName);
      final volumesCacheSize = await _hiveManager.getBoxSize(CacheConstants.volumesBoxName);
      final chaptersCacheSize = await _hiveManager.getBoxSize(CacheConstants.chaptersBoxName);
      final headingsCacheSize = await _hiveManager.getBoxSize(CacheConstants.headingsBoxName);
      final contentCacheSize = await _hiveManager.getBoxSize(CacheConstants.contentBoxName);
      
      final imageCacheSize = await _imageManager.getCacheSize();
      final videoCacheSize = await _videoCacheManager.getCacheSize();
      final prefsCacheSize = await _prefsManager.getTotalSize();
      
      final totalSize = booksCacheSize + volumesCacheSize + chaptersCacheSize + 
          headingsCacheSize + contentCacheSize + imageCacheSize + 
          videoCacheSize + prefsCacheSize;
      
      return {
        'books': booksCacheSize,
        'volumes': volumesCacheSize,
        'chapters': chaptersCacheSize,
        'headings': headingsCacheSize,
        'content': contentCacheSize,
        'images': imageCacheSize,
        'videos': videoCacheSize,
        'preferences': prefsCacheSize,
        'total': totalSize,
      };
    } catch (e) {
      _log.warning('Error getting cache size stats', e);
      return {'total': 0};
    }
  }

  /// For implementing cache cleanup during background operations, called occasionally
  Future<void> _scheduleBackgroundCleanup() async {
    if (_backgroundCleanupScheduled) return;
    _backgroundCleanupScheduled = true;
    
    try {
      // Allow 1-2 minutes from app launch before starting cleanup to not impact startup performance
      await Future.delayed(Duration(minutes: 1 + Random().nextInt(2)));
      
      // First, clear memory cache if needed
      _cleanupMemoryCache();
      
      // Next, clear expired items from persistent storage
      if (await isConnected()) {
        await _clearExpiredCaches();
      }
      
      // Schedule the next cleanup
      await Future.delayed(Duration(hours: 12)); 
      _backgroundCleanupScheduled = false;
      _scheduleBackgroundCleanup();
    } catch (e) {
      _log.warning('Error in background cleanup: $e');
      // Reset the flag to allow retry
      _backgroundCleanupScheduled = false;
      await Future.delayed(Duration(minutes: 15));
      _scheduleBackgroundCleanup();
    }
  }
  
  /// Clean up memory cache by removing oldest entries when exceeding size limit
  void _cleanupMemoryCache() {
    if (_currentMemoryCacheSize <= _maxMemoryCacheSize * 0.8) {
      // Memory cache is still below 80% of maximum capacity, no need to clean
      return;
    }
    
    _log.info('Cleaning memory cache, current size: ${CacheUtils.formatSize(_currentMemoryCacheSize)}');
    
    // Sort by access time (oldest first)
    final entries = _memoryCacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Sort by oldest

    int removedCount = 0;
    for (final entry in entries) {
      if (_currentMemoryCacheSize <= _maxMemoryCacheSize * 0.7) break;
      
      final key = entry.key;
      _removeFromMemoryCache(key);
      _metricsService?.recordEviction(key, reason: 'memory_pressure_cleanup'); // CORRECTED: Use key
      removedCount++;
    }
    
    _log.info('Memory cache cleanup complete. Removed $removedCount items, new size: ${CacheUtils.formatSize(_currentMemoryCacheSize)}');
  }
  
  /// Clear expired items from cache
  Future<void> _clearExpiredCaches() async {
    try {
      // Clear expired items from all managed boxes manually
      // Delete any metadata with isExpired == true
      final metadataBox = Hive.box<String>(CacheConstants.metadataBoxName);
      final expiredKeys = <String>[];
      
      for (final metaKey in metadataBox.keys) {
        if (metaKey.toString().startsWith('metadata:')) {
          final metadataJson = metadataBox.get(metaKey);
          if (metadataJson != null) {
            try {
              final metadata = CacheMetadata.fromMap(jsonDecode(metadataJson));
              if (metadata.isExpired && !metadata.isPinned) {
            // Extract the original cache key and box name from metadata key
                final originalKey = metaKey.toString().substring('metadata:'.length);
            expiredKeys.add(originalKey);
              }
            } catch (e) {
              _log.warning('Error parsing metadata for key $metaKey: $e');
            }
          }
        }
      }
      
      // Delete expired data from respective boxes
      for (final expiredKey in expiredKeys) {
        try {
          // Extract box name and key from the combined key
          final parts = expiredKey.split(':');
          if (parts.length >= 2) {
            final boxName = parts[0];
            final key = parts.sublist(1).join(':'); 
            
            final bool itemExists = await _hiveManager.exists(key: key, boxName: boxName); // NEW - Corrected
            if (!itemExists) {
              _log.warning('Expired cache item $key in box $boxName does not exist, skipping deletion');
              continue;
            }
            
            await _hiveManager.delete(key, boxName);
            await metadataBox.delete('metadata:$expiredKey');
            
            _log.fine('Deleted expired cache for key: $key in box: $boxName');
            _metricsService?.recordEviction(expiredKey, reason: 'expired'); // ADDED: Record eviction
          }
        } catch (e) {
          _log.warning('Error deleting expired cache for key $expiredKey: $e');
        }
      }
      
      _log.info('Cleared ${expiredKeys.length} expired cache entries');
    } catch (e) {
      _log.warning('Error clearing expired caches: $e');
    }
  }

  /// Stream of download progress updates
  // Stream<DownloadProgress> get downloadProgressStream => 
  //     _downloadProgressController.stream;
  // Removed download functionality - no longer needed

  /// Refresh cache data in the background
  Future<void> _refreshCacheInBackground<T>({
    required String key,
    required String boxName,
    required Future<T> Function() fetch,
    required Duration ttl,
  }) async {
    try {
      // Check connectivity before attempting background refresh
      final isOnline = await isConnected();
      if (!isOnline) {
        _log.info('Skipping background refresh for key $key: device is offline');
        return;
      }
      
      final result = await fetch();
      await cacheData(key: key, data: result, boxName: boxName, ttl: ttl);
      _log.fine('Background refresh completed for key: $key');
      _metricsService?.recordWrite(key); // ADDED: Record write
    } catch (e) {
      _log.warning('Background refresh failed for key $key: $e');
    }
  }
  
  /// Get cache metadata for a specific key
  Future<CacheMetadata?> _getCacheMetadata(String key) async {
    try {
      final box = Hive.box<String>(CacheConstants.metadataBoxName);
      final String? metadataJson = box.get('metadata:$key');
      
      if (metadataJson == null) return null;
      
      return CacheMetadata.fromMap(jsonDecode(metadataJson));
    } catch (e) {
      _log.warning('Error getting metadata for key $key: $e');
      return null;
    }
  }
  
  /// Save metadata for a cached item
  Future<void> _saveCacheMetadata(String key, CacheMetadata metadata) async {
    try {
      final box = Hive.box<String>(CacheConstants.metadataBoxName);
      await box.put('metadata:$key', jsonEncode(metadata.toMap()));
      await _ensurePersistentSize(); // NEW: Enforce global limit after write
    } catch (e) {
      _log.warning('Error saving metadata for key $key: $e');
    }
  }

  // Helper to queue a pin/unpin operation when offline
  Future<void> _queuePinOperation(PendingPinOperation operation) async {
    try {
      // Ensure the box is open. It should have been opened during CacheService.init -> HiveCacheManager.initialize
      if (!Hive.isBoxOpen(CacheConstants.offlinePinQueueBoxName)) {
        _log.warning('Offline pin queue box (${CacheConstants.offlinePinQueueBoxName}) is not open. Attempting to open directly...');
        await Hive.openBox<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName); 
      }
      final queueBox = Hive.box<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName);
      // Use itemKey_timestamp as the key for the queue entry to ensure uniqueness and order if multiple ops for same item (though latest should win)
      await queueBox.put(operation.id, operation); 
      _log.info('Queued pin operation: ${operation.operationType} for ${operation.itemKey} (ID: ${operation.id})');
    } catch (e, stackTrace) {
      _log.severe('Error queuing pin operation for ${operation.itemKey}: $e', e, stackTrace);
    }
  }

  // Helper to get the latest pending pin operation for an item
  Future<PendingPinOperation?> _getPendingPinOperation(String itemKey) async {
    try {
      if (!Hive.isBoxOpen(CacheConstants.offlinePinQueueBoxName)) {
        _log.warning('Offline pin queue box (${CacheConstants.offlinePinQueueBoxName}) is not open. Attempting to open directly...');
        await Hive.openBox<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName); 
      }
      final queueBox = Hive.box<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName);
      if (queueBox.isEmpty) {
        return null;
      }

      PendingPinOperation? latestOperation;
      // Iterate over values, as keys are itemKey_timestamp and not directly itemKey
      for (final operationInQueue in queueBox.values) {
        if (operationInQueue.itemKey == itemKey) {
          if (latestOperation == null || operationInQueue.timestamp > latestOperation.timestamp) {
            latestOperation = operationInQueue;
          }
        }
      }
      if (latestOperation != null) {
        _log.finer('Found pending operation for $itemKey: ${latestOperation.operationType} (ID: ${latestOperation.id})');
      }
      return latestOperation;
    } catch (e, stackTrace) {
      _log.severe('Error getting pending pin operation for $itemKey: $e', e, stackTrace);
      return null; 
    }
  }

  /// Remove a cached item and its metadata
  Future<void> remove(String key, String boxName, {String? screenId}) async {
    _log.info('Attempting to remove item with key: $key from box: $boxName');
    try {
      // Remove from persistent storage via HiveCacheManager
      await _hiveManager.delete(key, boxName);

      // Remove from primary memory cache
      _removeFromMemoryCache(key);

      // Remove from screen-specific memory cache if screenId is provided
      if (screenId != null && _screenMemoryCaches.containsKey(screenId)) {
        _screenMemoryCaches[screenId]?.remove(key);
        _log.finer('Removed $key from screen-specific memory cache for $screenId');
      }

      // Remove associated metadata from CacheService's metadata tracking
      _memoryCacheMetadata.remove(key);
      // Also attempt to remove from Hive-based metadata store, if it was persisted by _saveCacheMetadata
      await _hiveManager.delete(key, CacheConstants.metadataBoxName); 

      _log.info('Successfully removed item and its metadata for key: $key from box: $boxName');
      _metricsService?.recordEviction(key, reason: 'manual_remove'); // ADDED: Record eviction
    } catch (e, stackTrace) {
      _log.severe('Error removing item for key: $key from box: $boxName', e, stackTrace);
      rethrow; // Or handle more gracefully depending on desired error propagation
    }
  }

  /// Clear all entries from a specific Hive box.
  Future<void> clearBox(String boxName) async {
    if (!_initialized) await initialize();
    try {
      await _hiveManager.clearBox(boxName);
      // Also clear any memory cache entries that might be related, though typically box clearing is for persistent only.
      // For simplicity, we are not clearing specific memory cache items here, as they are managed by TTL / screen.
      _log.info('Cleared all entries from Hive box: $boxName');
      _metricsService?.recordBoxPurge(boxName); // CORRECTED: Use recordBoxPurge
    } catch (e, stackTrace) {
      _log.severe('Error clearing Hive box: $boxName', e, stackTrace);
      rethrow;
    }
  }
  
  /// Get all keys from a specific Hive box.
  /// Useful for browsing all cached items or scanning for specific patterns
  Future<List<String>> getCachedKeys(String boxName) async {
    if (!_initialized) await initialize();
    try {
      final List<String> keysInBox = await _hiveManager.getAllKeys(boxName); // NEW - Corrected
      return keysInBox;
    } catch (e, stackTrace) {
      _log.severe('Error getting keys from box: $boxName', e, stackTrace);
      return []; // Return empty list on error
    }
  }
  /// Pins an item in the cache, preventing it from being automatically evicted.
  /// Handles offline queuing and optimistic updates.
  Future<void> pinItem(String key, String boxName) async {
    if (!_initialized) await initialize();
    _log.info('Attempting to pin item: $key in box: $boxName');

    final bool online = await isConnected();

    final CacheMetadata? existingMetadata = await _getCacheMetadata(key);
    if (existingMetadata == null) {
      _log.warning('Cannot pin item $key: Metadata not found. Item might not be cached or metadata is missing.');
      return;
    }

    // Check if item is already pinned in metadata
    if (existingMetadata.isPinned) {
      _log.info('Item $key in $boxName is already marked as pinned in metadata.');
      if (online) {
        // If online and item is already pinned, check if there's a conflicting pending UNPIN.
        // If so, this PIN operation should resolve/remove that pending UNPIN.
        PendingPinOperation? pendingUnpinOp = await _getPendingPinOperation(key);
        if (pendingUnpinOp != null && pendingUnpinOp.operationType == PinOperationType.unpin) {
          // Ensure the queue box is open before attempting to delete
          if (!Hive.isBoxOpen(CacheConstants.offlinePinQueueBoxName)) {
            await Hive.openBox<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName);
          }
          final queueBox = Hive.box<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName);
          await queueBox.delete(pendingUnpinOp.id);
          _log.info('Item $key is already pinned. Removed conflicting pending UNPIN operation (ID: ${pendingUnpinOp.id}) due to current online PIN action.');
        }
      }
      return;
    }

    // Verify the data exists in the specified persistent cache box
    final bool itemExistsInPersistentCache = await _hiveManager.exists(key: key, boxName: boxName);
    if (!itemExistsInPersistentCache) {
      _log.warning('Cannot pin item $key in $boxName: Data not found in persistent cache box. Please ensure item is cached first.');
      return;
    }

    if (!online) {
      _log.info('Device is offline. Queuing pin operation for $key and performing optimistic update.');
      final operation = PendingPinOperation(
        itemKey: key, // Corrected: Only itemKey and operationType are needed
        operationType: PinOperationType.pin
        // id and timestamp are auto-generated by PendingPinOperation constructor
        // boxName is not part of PendingPinOperation model
      );
      await _queuePinOperation(operation);

      // Optimistic update: Reflect the pinned state locally immediately
    final updatedMetadata = existingMetadata.copyWith(isPinned: true);
      if (_memoryCacheMetadata.containsKey(key)) {
        _memoryCacheMetadata[key] = updatedMetadata;
        _log.finer('Optimistically updated in-memory metadata for pinned item $key.');
      }
      await _saveCacheMetadata(key, updatedMetadata); // Persist optimistic update
      _log.info('Item $key in box $boxName has been optimistically pinned (offline). Queued for sync.');
      return; // Offline operation complete for now
    } else { // Online
      _log.info('Device is online. Proceeding with online pin operation for $key.');
      
      PendingPinOperation? pendingOp = await _getPendingPinOperation(key);
      if (pendingOp != null) {
        if (!Hive.isBoxOpen(CacheConstants.offlinePinQueueBoxName)) {
          await Hive.openBox<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName);
        }
        final queueBox = Hive.box<PendingPinOperation>(CacheConstants.offlinePinQueueBoxName);
        await queueBox.delete(pendingOp.id);
        _log.info('Removed pending ${pendingOp.operationType} operation for $key (ID: ${pendingOp.id}) as it will be handled by current online pin.');
      }

      final updatedMetadata = existingMetadata.copyWith(isPinned: true);
    if (_memoryCacheMetadata.containsKey(key)) {
      _memoryCacheMetadata[key] = updatedMetadata;
       _log.finer('Updated in-memory metadata for pinned item $key.');
    }
    await _saveCacheMetadata(key, updatedMetadata);
      _log.info('Item $key in box $boxName has been successfully pinned (online).');
    }
  }

  /// Unpins an item in the cache, making it subject to normal eviction policies.
  Future<void> unpinItem(String key, String boxName) async {
    if (!_initialized) await initialize();
    _log.info('Attempting to unpin item: $key in box: $boxName');

    final CacheMetadata? existingMetadata = await _getCacheMetadata(key);
    if (existingMetadata == null) {
      _log.warning('Cannot unpin item $key: Metadata not found.');
      return;
    }

    if (!existingMetadata.isPinned) {
      _log.info('Item $key in $boxName is not currently pinned.');
      return;
    }

    final updatedMetadata = existingMetadata.copyWith(isPinned: false);
    
    // Update in memory metadata store if present
    if (_memoryCacheMetadata.containsKey(key)) {
      _memoryCacheMetadata[key] = updatedMetadata;
      _log.finer('Updated in-memory metadata for unpinned item $key.');
    }
    // Update in persistent metadata store
    await _saveCacheMetadata(key, updatedMetadata);
    _log.info('Item $key in box $boxName has been unpinned.');
  }

  /// Removes an item that was potentially saved for offline use. 
  /// This is effectively the same as the general remove method.
  Future<void> removeOfflineItem(String key, String boxName, {String? screenId}) async {
    _log.info('Removing offline (potentially pinned) item: $key from box: $boxName.');
    // The standard remove method will delete the item regardless of its pinned status
    // and also handle metadata cleanup and metric recording.
    await remove(key, boxName, screenId: screenId);
    _log.info('Offline item $key from $boxName removed.');
  }

  /// Checks if a cached item is currently pinned.
  Future<bool> isItemPinned(String key) async {
    if (!_initialized) await initialize();
    final CacheMetadata? metadata = await _getCacheMetadata(key);
    return metadata?.isPinned ?? false;
  }

  /// Return cached data synchronously if it is present in L1 memory cache.
  T? getSync<T>(String key) {
    final data = _getFromMemoryCache<T>(key);
    if (data != null) {
      _metricsService?.recordHit(key);
    }
    return data;
  }

  /// Ensure total disk usage stays under [CacheConstants.maxPersistentBytes].
  Future<void> _ensurePersistentSize() async {
    final totalBytes = await _hiveManager.getTotalSizeBytes();
    if (totalBytes <= CacheConstants.maxPersistentBytes) return;

    // Evict low priority books until under limit.
    final over = totalBytes - CacheConstants.maxPersistentBytes;
    _log.info('Persistent cache exceeds limit by ${CacheUtils.formatSize(over)} – starting eviction');
    await _hiveManager.evictLowPriorityItems(bytesToFree: over, bookPriorities: _bookPriorities);
  }

  /// Expose Hive manager for advanced operations (e.g., background workers)
  HiveCacheManager get hiveManager => _hiveManager;

  /// Expose DefaultCacheManager for image caching operations
  fcm.DefaultCacheManager get defaultCacheManager => _imageManager.defaultCacheManager;

  // Cache Statistics and Management Methods

  /// Returns the formatted size of the persistent (Hive) cache.
  Future<String> getFormattedPersistentCacheSize() async {
    try {
      final sizeBytes = await _hiveManager.getTotalSizeBytes();
      return CacheUtils.formatSize(sizeBytes);
    } catch (e, stackTrace) {
      _log.severe('Error getting persistent cache size', e, stackTrace);
      return 'Error';
    }
  }

  /// Returns the formatted size of the memory cache.
  String getFormattedMemoryCacheSize() {
    return CacheUtils.formatSize(_currentMemoryCacheSize);
  }

  /// Returns the formatted total size of both memory and persistent caches.
  Future<String> getFormattedTotalCacheSize() async {
    try {
      final persistentSizeBytes = await _hiveManager.getTotalSizeBytes();
      final totalBytes = persistentSizeBytes + _currentMemoryCacheSize;
      return CacheUtils.formatSize(totalBytes);
    } catch (e, stackTrace) {
      _log.severe('Error getting total cache size', e, stackTrace);
      return 'Error';
    }
  }

  /// Clears all data from the persistent (Hive) cache.
  Future<void> clearPersistentCache() async {
    _log.info('Clearing persistent cache...');
    try {
      const boxesToClear = [
        CacheConstants.booksBoxName,
        CacheConstants.volumesBoxName,
        CacheConstants.chaptersBoxName,
        CacheConstants.headingsBoxName,
        CacheConstants.contentBoxName,
        CacheConstants.videoMetadataBoxName,
        CacheConstants.videosBoxName,
        CacheConstants.categoriesBoxName,
        CacheConstants.playlistBoxName,
        CacheConstants.offlineQueueBoxName,
        // CacheConstants.settingsBoxName, // Usually settings should persist
        CacheConstants.bookStructuresBoxName,
        CacheConstants.thumbnailMetadataBoxName,
        CacheConstants.imageMetadataBoxName,
        CacheConstants.bookmarksBoxName,
        CacheConstants.notesBoxName,
        CacheConstants.userBoxName,
      ];

      for (final boxName in boxesToClear) {
        await _hiveManager.clearBox(boxName);
        _log.fine('Cleared Hive box: $boxName');
      }
      // Metadata box is crucial, clear it last or separately
      await _hiveManager.clearBox(CacheConstants.metadataBoxName);
      _log.info('Cleared Hive box: ${CacheConstants.metadataBoxName}');
      
      _log.info('Persistent cache cleared successfully.');
    } catch (e, stackTrace) {
      _log.severe('Error clearing persistent cache', e, stackTrace);
    }
  }

  /// Clears all data from the memory cache.
  void clearMemoryCache() {
    _log.info('Clearing memory cache...');
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();
    _memoryCacheMetadata.clear();
    _currentMemoryCacheSize = 0;
    _screenMemoryCaches.clear(); // Clear screen-specific memory caches as well
    _log.info('Memory cache cleared. Current size: ${CacheUtils.formatSize(_currentMemoryCacheSize)}');
  }

  /// Clears all caches (memory and persistent).
  Future<void> clearAllCaches() async {
    _log.info('Clearing all caches...');
    clearMemoryCache();
    await clearPersistentCache();
    _log.info('All caches cleared successfully.');
  }

  /// Coalesce refreshBookIfStale calls
  final Map<String, Future<void>> _inFlightRefreshes = {};  

  /// If the cached book is older than [CacheConstants.bookCacheTtl] trigger a refresh.
  Future<void> refreshBookIfStale(String bookId) async {
    // Avoid duplicate work
    if (_inFlightRefreshes.containsKey(bookId)) return _inFlightRefreshes[bookId]!;

    final completer = Completer<void>();
    _inFlightRefreshes[bookId] = completer.future;

    () async {
      try {
        final cacheEntry = await getCachedData<Map<String, dynamic>>(
          key: '${CacheConstants.bookKeyPrefix}$bookId',
          boxName: CacheConstants.booksBoxName,
        );

        bool needsRefresh = true;
        if (cacheEntry.hasData && cacheEntry.metadata != null) {
          final age = DateTime.now().millisecondsSinceEpoch - cacheEntry.metadata!.timestamp;
          needsRefresh = age > CacheConstants.bookCacheTtl.inMilliseconds;
        }

        if (!needsRefresh) {
          _log.fine('Book $bookId cache fresh – skip refresh');
          completer.complete();
          return;
        }

        // Fetch fresh data via repository (avoiding circular dep by direct Firestore)
        try {
          final doc = await FirebaseFirestore.instance.collection('books').doc(bookId).get();
          if (!doc.exists) {
            completer.complete();
            return;
          }
          final bookData = doc.data() as Map<String, dynamic>;
          await cacheData(
            key: '${CacheConstants.bookKeyPrefix}$bookId',
            data: bookData,
            boxName: CacheConstants.booksBoxName,
            ttl: CacheConstants.bookCacheTtl,
          );
          _log.info('Refreshed stale book $bookId in background');
        } catch (e) {
          _log.warning('Failed to refresh book $bookId: $e');
        }
        completer.complete();
      } finally {
        _inFlightRefreshes.remove(bookId);
      }
    }();

    return completer.future;
  }

  /// Optimized: Periodically prunes expired items from the memory cache with adaptive timing
  void startMemoryCachePruning() {
    _memoryCachePruneTimer?.cancel(); // Cancel any existing timer
    
    // Adaptive pruning: More frequent when cache is fuller
    final cacheUsageRatio = _currentMemoryCacheSize / _maxMemoryCacheSize;
    Duration interval;
    
    if (cacheUsageRatio > 0.8) {
      interval = const Duration(minutes: 5); // Aggressive pruning when near capacity
    } else if (cacheUsageRatio > 0.5) {
      interval = const Duration(minutes: 15); // Moderate pruning
    } else {
      interval = const Duration(minutes: 30); // Standard pruning
    }
    
    _memoryCachePruneTimer = Timer.periodic(interval, (timer) {
      pruneExpiredMemoryCacheItems();
      
      // Restart with new adaptive timing after pruning
      if (_isDisposed) {
        timer.cancel();
      } else {
        startMemoryCachePruning(); // Restart with new interval
      }
    });
    _log.info('Started adaptive memory cache pruning (${interval.inMinutes} min intervals).');
  }

  /// Optimized: Batch pruning with more efficient memory recalculation
  void pruneExpiredMemoryCacheItems() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<String> keysToRemove = [];
    int sizeToReclaim = 0;
    
    // Batch collect expired keys and calculate size to reclaim
    _memoryCacheTimestamps.forEach((key, timestamp) {
      final metadata = _memoryCacheMetadata[key];
      final ttl = metadata?.ttlMillis ?? _memoryCacheTtl.inMilliseconds;
      if (now - timestamp > ttl) {
        keysToRemove.add(key);
        sizeToReclaim += metadata?.dataSizeBytes ?? CacheUtils.calculateObjectSize(_memoryCache[key]);
      }
    });

    if (keysToRemove.isNotEmpty) {
      _log.info('Pruning ${keysToRemove.length} expired items (${CacheUtils.formatSize(sizeToReclaim)}) from memory cache.');
      
      // Batch remove for better performance
      for (final key in keysToRemove) {
        final data = _memoryCache[key];
        _memoryCache.remove(key);
        _memoryCacheTimestamps.remove(key);
        _memoryCacheMetadata.remove(key);
        
        // Clean up screen associations
        final screenId = _getScreenIdForKey(key);
        if (screenId != null && _screenMemoryCaches.containsKey(screenId)) {
          _screenMemoryCaches[screenId]?.remove(key);
        }
        
        _metricsService?.recordEviction(key, reason: 'TTL-expired-mem');
      }
      
      // Update size in one operation
      _currentMemoryCacheSize = max(0, _currentMemoryCacheSize - sizeToReclaim);
      
      _log.fine('Memory cache after pruning: ${CacheUtils.formatSize(_currentMemoryCacheSize)}');
    }
  }
}
