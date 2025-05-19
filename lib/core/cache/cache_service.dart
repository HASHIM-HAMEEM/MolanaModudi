import 'dart:async'; 
import 'dart:convert';
import 'dart:io'; 
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/network/network_info.dart';
import 'package:modudi/core/cache/utils/cache_utils.dart';

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
import 'models/download_progress.dart';
import 'utils/cache_logger.dart';
import 'utils/concurrency_utils.dart';

/// Central service for managing all types of caches in the app
class CacheService {
  static final Logger _log = Logger('CacheService');
  
  // Cache managers
  final HiveCacheManager _hiveManager;
  final PreferencesCacheManager _prefsManager;
  final NetworkInfo _networkInfo;
  final CacheConfig _config;

  // Initialize with a default value to prevent LateInitializationError
  late final VideoCacheManager _videoCacheManager;
  late final ImageCacheManager _imageManager;
  
  // Define local formatSize method to fix references
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  // Background operation flags
  bool _backgroundCleanupScheduled = false;
  bool _initialized = false;
  
  // Active downloads tracking
  final Map<String, Completer<bool>> _activeDownloads = {};
  
  // Book priorities for cache retention
  final Map<String, CachePriority> _bookPriorities = {};
  
  // Cache eviction lock to prevent concurrent evictions
  final Lock _evictionLock = Lock();
  
  // Stream controller for download progress updates
  final StreamController<DownloadProgress> _downloadProgressController = 
      StreamController<DownloadProgress>.broadcast();
  
  // Memory cache for ultra-fast access during an active session
  // This prevents data reloading when navigating between screens
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, int> _memoryCacheTimestamps = {};
  final Map<String, dynamic> _memoryCacheMetadata = {};
  final int _maxMemoryCacheSize = 100 * 1024 * 1024;
  int _currentMemoryCacheSize = 0;
  
  // Memory cache TTL 
  static const Duration _memoryCacheTtl = Duration(hours: 8);
  
  // Keep track of which screen each cached item belongs to
  // This allows for efficient release of screen-specific cache when navigating away
  final Map<String, Map<String, dynamic>> _screenMemoryCaches = {};
      
  /// Close all resources used by the cache service
  Future<void> dispose() async {
    _downloadProgressController.close();
    _networkInfo.dispose(); 
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();
    _memoryCacheMetadata.clear();
    _currentMemoryCacheSize = 0;
  }
      
  // Work queue for managing concurrent downloads
  final WorkQueue _downloadQueue = WorkQueue(3);

  /// Create a new cache service with the specified configuration
  CacheService({
    HiveCacheManager? hiveManager,
    PreferencesCacheManager? prefsManager,
    NetworkInfo? networkInfo,
    CacheConfig? config,
  }) : 
    _hiveManager = hiveManager ?? HiveCacheManager(),
    _prefsManager = prefsManager ?? PreferencesCacheManager(),
    _networkInfo = networkInfo ?? NetworkInfo(),
    _config = config ?? CacheConfig.defaultConfig {
  }

  static CacheService? _instance;
  bool _isDisposed = false;

  CacheService._internal(this._config, this._hiveManager, this._prefsManager, this._networkInfo) {
    // Initialize managers that depend on 'this' CacheService instance here
    _videoCacheManager = VideoCacheManager(cacheService: this);
    _imageManager = ImageCacheManager(this);
  }

  static Future<CacheService> init({
    CacheConfig config = const CacheConfig(),
    List<String> customBoxNames = const [],
  }) async {
    if (_instance != null && !_instance!._isDisposed) {
      _log.info('CacheService already initialized.');
      return _instance!;
    }
    _log.info('Initializing CacheService...');

    // Initialize Hive prerequisite
    await Hive.initFlutter();

    // Define all Hive boxes that need to be opened.
    // Managers will open their specific boxes during their own initialization.
    // CacheService will open general-purpose boxes here.
    final List<String> generalBoxNames = [
      CacheConstants.booksBoxName,        // For book data not managed by a specific book manager's Hive setup
      CacheConstants.volumesBoxName,
      CacheConstants.chaptersBoxName,
      CacheConstants.headingsBoxName,
      CacheConstants.contentBoxName,
      CacheConstants.bookStructuresBoxName,
      CacheConstants.thumbnailMetadataBoxName,
      CacheConstants.imageMetadataBoxName, // Until ImageCacheManager handles its Hive metadata box
      // Add other general boxes if any
    ];
    generalBoxNames.addAll(customBoxNames);

    // Open general-purpose Hive boxes
    for (final boxName in generalBoxNames) {
      if (!Hive.isBoxOpen(boxName)) {
          // TODO: Determine if any of these boxes need specific type adapters like <CacheMetadata>.
          // For now, opening them without a type. If issues arise, this will need refinement.
          // Example: Hive.openBox<TypeName>(boxName)
          // Based on previous code, CacheMetadata was specific to CacheConstants.metadataBoxName (handled by HiveCacheManager)
        await Hive.openBox(boxName);
        _log.info('Opened general Hive box: $boxName');
      }
    }
    
    // Initialize core managers first (those that might open their own Hive boxes)
    final hiveManager = HiveCacheManager();
    await hiveManager.initialize(); // Opens metadataBoxName and settingsBoxName

    final prefsManager = PreferencesCacheManager();
    await prefsManager.initialize();

    final networkInfo = NetworkInfo();

    // Create the CacheService instance
    _instance = CacheService._internal(
      config,
      hiveManager,
      prefsManager,
      networkInfo,
    );

    // Initialize other managers that depend on the CacheService instance
    // and might perform async operations or open their own resources (like VideoCacheManager opening its Hive boxes).
    await _instance!._videoCacheManager.initialize(); // Opens videoMetadataBoxName and playlistBoxName
    await _instance!._imageManager.initialize(); // Currently doesn't open Hive boxes, uses flutter_cache_manager

    _log.info('CacheService initialized successfully.');
    _instance!._isDisposed = false;
    return _instance!;
  }

  static CacheService get instance {
    if (_instance == null || _instance!._isDisposed) {
      throw Exception("CacheService not initialized. Call CacheService.init() first.");
    }
    return _instance!;
  }

  /// Initialize the cache service and load data
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize network connectivity monitor
    await _networkInfo.initialize();
    
    try {
      CacheLogger.setLoggingEnabled(_config.enableLogging);
      
      // Initialize all managers
      await _hiveManager.initialize();
      await _prefsManager.initialize();
      
      // Ensure managers that depend on the CacheService are initialized
      // This reinforces initialization of these late variables in case the constructor
      // didn't run correctly or the instance was reset
      _videoCacheManager = VideoCacheManager(cacheService: this);
      _imageManager = ImageCacheManager(this);
      
      await _videoCacheManager.initialize();
      await _imageManager.initialize();
      
      // Load book priorities for cache management
      await _loadBookPriorities();
      
      // Schedule background tasks if enabled
      if (_config.autoClearStaleOnStart) {
        _scheduleBackgroundCleanup();
      }
      
      _initialized = true;
      CacheLogger.info('CacheService initialized successfully');
    } catch (e, stackTrace) {
      _log.severe('Error initializing CacheService', e, stackTrace);
      rethrow;
    }
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

    // Apply policy, defaulting to config if not provided
    final effectivePolicy = policy ?? config.CachePolicy.cacheFirst;
    final effectiveTtl = ttl ?? _config.defaultTtl;
    
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
        final metadata = _memoryCacheMetadata[key] as CacheMetadata?;
        if (metadata != null) {
          final updatedMetadata = metadata.incrementAccessCount();
          await _saveCacheMetadata(key, updatedMetadata); // Save to persistent store
          _memoryCacheMetadata[key] = updatedMetadata; // Update in-memory metadata cache
          return CacheResult<T>(
            data: memoryCached,
            source: CacheResultSource.cache,
            isCacheHit: true,
            metadata: updatedMetadata // Use updated metadata
          );
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
          return CacheResult<T>(
            data: memoryCached,
            source: CacheResultSource.cache,
            isCacheHit: true,
            metadata: newMetadata
          );
        }
      }
      
      // STEP 2: Check persistent storage if policy allows it
      if (effectivePolicy != config.CachePolicy.networkOnly) {
        final cachedResult = await getCachedData<T>(key: key, boxName: boxName);
        
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
            return CacheResult<T>(
              data: cachedResult.data,
              source: cachedResult.source,
              isCacheHit: cachedResult.isCacheHit,
              metadata: finalMetadata, // Use updated metadata
              error: cachedResult.error
            );
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
            return CacheResult<T>(
              data: cachedResult.data,
              source: cachedResult.source,
              isCacheHit: cachedResult.isCacheHit,
              metadata: finalMetadata, // Use updated metadata
              error: cachedResult.error
            );
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
            return CacheResult<T>(
              data: cachedResult.data,
              source: cachedResult.source,
              isCacheHit: cachedResult.isCacheHit,
              metadata: finalMetadata, // Use updated metadata
              error: cachedResult.error
            );
          }
        }
      }
            
      // STEP 3: Network fetch (either cache miss or networkFirst/networkOnly policy)
      if (effectivePolicy != config.CachePolicy.cacheOnly) {
        try {
          // Check connectivity before attempting network fetch
          final isOnline = await isConnected();
          if (!isOnline) {
            throw Exception('Device is offline');
          }
          
          final networkResult = await networkFetch();
          
          // Cache the network result (both in persistent storage and memory)
          await cacheData(
            key: key, 
            data: networkResult, 
            boxName: boxName, 
            ttl: effectiveTtl,
            screenId: screenId,
          );
          
          return CacheResult<T>(
            data: networkResult,
            source: CacheResultSource.network,
            isCacheHit: false
          );
        } catch (networkError) {
          _log.warning('Network fetch failed for key $key: $networkError');
          
          // For networkFirst or cacheFirst, fall back to cache even if stale
          if (effectivePolicy == config.CachePolicy.networkFirst ||
              effectivePolicy == config.CachePolicy.cacheFirst) {
            final fallbackResult = await getCachedData<T>(key: key, boxName: boxName);
            if (fallbackResult.hasData) {
              // Mark as stale since network fetch failed
              return CacheResult<T>(
                data: fallbackResult.data,
                source: CacheResultSource.cache,
                isCacheHit: true
              );
            }
          }
          
          // Re-throw if we can't recover
          rethrow;
        }
      }
      
      // If we reach here with cacheOnly policy, it means cache was empty
      throw Exception('Data not found in cache and network fetch not allowed');
    } catch (e) {
      _log.severe('Error fetching data for key $key: $e');
      rethrow;
    }
  }

  /// Cache data directly in both persistent storage and memory cache
  Future<void> cacheData<T>({
    required String key,
    required T data,
    required String boxName,
    Duration? ttl,
    String? screenId, 
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
        // eTag and version can be set later if available from network responses
      );
      
      // STEP 1: Add to memory cache for ultra-fast access
      _addToMemoryCache(key, data, metadata, screenId: screenId);
      
      // STEP 2: Store data in persistent cache
      await _hiveManager.put(
        key: key,
        data: data,
        boxName: boxName,
        ttl: ttl ?? _config.defaultTtl,
        language: metadata.language, // Pass language from CacheService's metadata
        properties: metadata.properties // Pass properties from CacheService's metadata
      );

      // STEP 3: Store the authoritative CacheMetadata object using CacheService's mechanism
      await _saveCacheMetadata(key, metadata);
      
      CacheLogger.logCacheWrite(key, boxName, metadata.dataSizeBytes); // Use dataSizeBytes from CacheService's metadata
      _log.fine('Cached data for key: $key with TTL: ${metadata.ttl.inHours} hours');
    } catch (e) {
      _log.warning('Error caching data for key $key: $e');
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
  void _addToMemoryCache<T>(String key, T data, CacheMetadata? metadata, {String? screenId}) {
    if (screenId != null) {
      _screenMemoryCaches.putIfAbsent(screenId, () => {})[key] = data;
      // _log.finer('Added $key to screen-specific memory cache for $screenId');
    } else {
      // Add to general memory cache if not screen-specific or if general is also desired
      int sizeOfNewData = 0;
      if (metadata != null) {
        // The metadata is not null here, and the lint suggests dataSizeBytes is also non-nullable
        sizeOfNewData = metadata.dataSizeBytes; // Direct assignment as compiler confirms it's non-null
      }

      if (_currentMemoryCacheSize + sizeOfNewData > _maxMemoryCacheSize) {
        _evictFromMemoryCache(sizeOfNewData);
      }
      _memoryCache[key] = data;
      _memoryCacheTimestamps[key] = DateTime.now().millisecondsSinceEpoch;
      if (metadata != null) { // Check for null metadata before accessing its properties or storing it
        _memoryCacheMetadata[key] = metadata; // Store full metadata if available
        final int? dataSize = metadata.dataSizeBytes; // dataSize is int?
        _currentMemoryCacheSize += (dataSize ?? 0); // Apply ?? 0 to dataSize
      }
      // If metadata or metadata.dataSizeBytes is null, sizeOfNewData is 0.
      // If metadata is null, _currentMemoryCacheSize is not increased here, 
      // which means items with null metadata (and thus unknown size) don't contribute to memory pressure based on this logic.
      // This might need review if items with null metadata should still consume a nominal size or be estimated.
    }
  }

  /// Remove data from memory cache
  void _removeFromMemoryCache(String key) {
    if (_memoryCache.containsKey(key)) {
      final data = _memoryCache[key];
      final estimatedSize = CacheUtils.calculateObjectSize(data);
      
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
      _memoryCacheMetadata.remove(key);
      _currentMemoryCacheSize -= estimatedSize;
      
      if (_currentMemoryCacheSize < 0) _currentMemoryCacheSize = 0;
    }
  }
  
  /// Evict items from memory cache to free up space
  void _evictFromMemoryCache(int requiredBytes) {
    // Sort by access time (oldest first)
    final entries = _memoryCacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    int freedBytes = 0;
    int entriesRemoved = 0;
    
    for (final entry in entries) {
      if (freedBytes >= requiredBytes) break;
      
      final key = entry.key;
      if (_memoryCache.containsKey(key)) {
        final data = _memoryCache[key];
        final estimatedSize = CacheUtils.calculateObjectSize(data);
        
        _memoryCache.remove(key);
        _memoryCacheTimestamps.remove(key);
        
        freedBytes += estimatedSize;
        entriesRemoved++;
      }
    }
    
    _currentMemoryCacheSize -= freedBytes;
    if (_currentMemoryCacheSize < 0) _currentMemoryCacheSize = 0;
    
    _log.fine('Evicted $entriesRemoved items from memory cache, freed ${_formatSize(freedBytes)}');
  }
  
  /// Pre-load a screen's data into memory cache
  /// This is useful for navigation performance optimization
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
  
  /// Release memory cache for a specific screen
  /// Call this when navigating away from a screen and its data won't be needed soon
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
        final metadata = _memoryCacheMetadata[key] as CacheMetadata?;
        if (metadata != null) {
          return CacheResult<T>(
            data: memoryCached,
            source: CacheResultSource.cache,
            isCacheHit: true,
            metadata: metadata
          );
        } else {
          // Create basic metadata if none exists
          final newMetadata = CacheMetadata(
            originalKey: key,
            boxName: boxName,
            timestamp: _memoryCacheTimestamps[key] ?? DateTime.now().millisecondsSinceEpoch
          );
          return CacheResult<T>(
            data: memoryCached,
            source: CacheResultSource.cache,
            isCacheHit: true,
            metadata: newMetadata
          );
        }
      }
      
      // Check persistent storage using the HiveCacheManager
      try {
        // Get the Hive box through the manager
        final box = await Hive.openBox(boxName);
        final dynamic rawData = await box.get(key);
        
        if (rawData == null) {
          _log.fine('Cache miss for key: $key');
          return CacheResult<T>(
            data: null,
            source: CacheResultSource.notFound,
            isCacheHit: false
          );
        }
        
        // Try to convert the raw data to the expected type
        T? typedData;
        try {
          typedData = rawData as T;
        } catch (e) {
          _log.warning('Type conversion error for cached data: $e');
          return CacheResult<T>(
            data: null,
            source: CacheResultSource.error,
            isCacheHit: false,
            error: Exception('Type conversion error')
          );
        }
        
        // Get metadata
        final metadata = await _getCacheMetadata(key);
        
        // Add to memory cache for faster subsequent access
        _addToMemoryCache(key, typedData, metadata);
        
        return CacheResult<T>(
          data: typedData,
          source: CacheResultSource.cache,
          isCacheHit: true,
          metadata: metadata
        );
      } catch (e) {
        _log.warning('Error retrieving data from persistent cache: $e');
        return CacheResult<T>(
          data: null,
          source: CacheResultSource.error,
          isCacheHit: false,
          error: e
        );
      }
    } catch (e) {
      _log.warning('Error getting cached data for key $key: $e');
      return CacheResult<T>(
        data: null,
        source: CacheResultSource.error,
        isCacheHit: false,
        error: e
      );
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
    
    _log.info('Cleaning memory cache, current size: ${_formatSize(_currentMemoryCacheSize)}');
    
    // Sort by timestamp (oldest first)
    final entries = _memoryCacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove oldest items until we're below 70% capacity
    int removedCount = 0;
    for (final entry in entries) {
      if (_currentMemoryCacheSize <= _maxMemoryCacheSize * 0.7) break;
      
      final key = entry.key;
      _removeFromMemoryCache(key);
      removedCount++;
    }
    
    _log.info('Memory cache cleanup complete. Removed $removedCount items, new size: ${_formatSize(_currentMemoryCacheSize)}');
  }
  
  /// Clear expired items from cache
  Future<void> _clearExpiredCaches() async {
    try {
      // Clear expired items from all managed boxes manually
      // Delete any metadata with isExpired == true
      final metadataBox = Hive.box<CacheMetadata>(CacheConstants.metadataBoxName);
      final expiredKeys = <String>[];
      
      for (final metaKey in metadataBox.keys) {
        if (metaKey.startsWith('metadata:')) {
          final metadata = metadataBox.get(metaKey);
          if (metadata != null && metadata.isExpired) {
            // Extract the original cache key and box name from metadata key
            final originalKey = metaKey.substring('metadata:'.length);
            expiredKeys.add(originalKey);
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
            
            final box = await Hive.openBox(boxName);
            await box.delete(key);
            await metadataBox.delete('metadata:$expiredKey');
            
            _log.fine('Deleted expired cache for key: $key in box: $boxName');
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
  Stream<DownloadProgress> get downloadProgressStream => 
      _downloadProgressController.stream;
  
  /// Download a complete book, including all headings and content
  /// Returns a Future that completes when the download is started (not finished)
  Future<void> downloadBook({required String bookId, required Future<Map<String, dynamic>> Function() fetchBookData, required Future<List<dynamic>> Function() fetchHeadings, required Future<Map<String, dynamic>> Function(String headingId) fetchHeadingContent}) async {
    if (!_initialized) await initialize();
    
    // Check if a download is already in progress for this book
    if (_activeDownloads.containsKey(bookId)) {
      _log.info('Download already in progress for book $bookId');
      return;
    }
    
    // Create a new completer to track this download
    final completer = Completer<bool>();
    _activeDownloads[bookId] = completer;
    
    // Queue the download job
    _downloadQueue.add(() async {
      final progress = DownloadProgress.start(bookId, 0);
      _downloadProgressController.add(progress);
      
      try {
        // Step 1: Fetch and cache book data
        final bookData = await fetchBookData();
        await cacheData(
          key: '${CacheConstants.bookKeyPrefix}$bookId',
          data: bookData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(days: 30), 
        );
        
        // Update progress
        var currentProgress = progress.copyWith(
          completedItems: 1,
          totalItems: 1, 
        );
        _downloadProgressController.add(currentProgress);
        
        // Step 2: Fetch and cache headings
        final headings = await fetchHeadings();
        await cacheData(
          key: '${CacheConstants.bookKeyPrefix}${bookId}_headings',
          data: headings,
          boxName: CacheConstants.headingsBoxName,
          ttl: const Duration(days: 30),
        );
        
        // Update total items count now that we know how many headings
        final totalItems = headings.length + 1; 
        currentProgress = currentProgress.copyWith(
          totalItems: totalItems,
        );
        _downloadProgressController.add(currentProgress);
        
        // Step 3: Fetch and cache each heading's content
        int completedHeadings = 0;
        
        for (final heading in headings) {
          // Ensure headingId is treated as a string and is not null.
          final String? headingId = heading is Map ? heading['id']?.toString() : null;

          if (headingId == null) {
            _log.warning('Skipping a heading due to missing or invalid ID in book $bookId');
            // Potentially decrement totalItems for progress accuracy if a heading is skipped
            // currentProgress = currentProgress.copyWith(totalItems: currentProgress.totalItems -1);
            continue; // Skip this iteration
          }

          try {
            final headingContent = await fetchHeadingContent(headingId);
            
            // Cache the fetched heading content
            if (headingContent.isNotEmpty) { // Ensure there's something to cache
              await cacheData(
                key: '${CacheConstants.headingContentKeyPrefix}$headingId',
                data: headingContent, // This is the Map<String, dynamic>
                boxName: CacheConstants.contentBoxName,
                ttl: CacheConstants.bookCacheTtl, // Consistent TTL
              );
              _log.finer('Cached content for heading $headingId during bulk download of book $bookId');
            } else {
              _log.warning('Skipping cache for empty/invalid content for heading $headingId in book $bookId');
            }
            
            completedHeadings++;
            currentProgress = currentProgress.copyWith(
              completedItems: completedHeadings + 1, 
            );
            _downloadProgressController.add(currentProgress);
          } catch (e) {
            _log.warning('Error downloading content for heading $headingId: $e');
            // Continue with other headings even if one fails
          }
        }
        
        // Set book as high priority for retention
        await updateBookPriority(bookId, CachePriorityLevel.high);
        
        // Notify completion
        _downloadProgressController.add(DownloadProgress.complete(bookId, totalItems));
        completer.complete(true);
      } catch (e) {
        _log.severe('Error downloading book $bookId: $e');
        _downloadProgressController.add(DownloadProgress.failed(bookId, e.toString()));
        completer.complete(false);
      } finally {
        _activeDownloads.remove(bookId);
      }
      
      return completer.future;
    });
  }
  
  /// Check if a book is fully downloaded and available offline
  Future<bool> isBookDownloaded(String bookId) async {
    if (!_initialized) await initialize();
    
    try {
      // Check if book data is cached
      final bookResult = await getCachedData(
        key: '${CacheConstants.bookKeyPrefix}$bookId',
        boxName: CacheConstants.booksBoxName,
      );
      
      if (!bookResult.hasData) return false;
      
      // Check if headings are cached
      final headingsResult = await getCachedData(
        key: '${CacheConstants.bookKeyPrefix}${bookId}_headings',
        boxName: CacheConstants.headingsBoxName,
      );
      
      if (!headingsResult.hasData) return false;
      
      // Check if this book has high priority (fully downloaded)
      final priority = _bookPriorities[bookId];
      return priority?.level == CachePriorityLevel.high;
    } catch (e) {
      _log.warning('Error checking if book $bookId is downloaded: $e');
      return false;
    }
  }
  
  /// Get a list of all downloaded books
  Future<List<String>> getDownloadedBooks() async {
    if (!_initialized) await initialize();
    
    try {
      return _bookPriorities.entries
          .where((entry) => entry.value.level == CachePriorityLevel.high)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      _log.warning('Error getting downloaded books: $e');
      return [];
    }
  }

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
    } catch (e) {
      _log.warning('Background refresh failed for key $key: $e');
    }
  }
  
  /// Get cache metadata for a specific key
  Future<CacheMetadata?> _getCacheMetadata(String key) async {
    try {
      final box = Hive.box<CacheMetadata>(CacheConstants.metadataBoxName);
      final metadata = box.get('metadata:$key');
      
      return metadata;
    } catch (e) {
      _log.warning('Error getting metadata for key $key: $e');
      return null;
    }
  }
  
  /// Save metadata for a cached item
  Future<void> _saveCacheMetadata(String key, CacheMetadata metadata) async {
    try {
      final box = Hive.box<CacheMetadata>(CacheConstants.metadataBoxName);
      await box.put('metadata:$key', metadata);
    } catch (e) {
      _log.warning('Error saving metadata for key $key: $e');
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
      // This assumes _saveCacheMetadata (and by extension _getCacheMetadata) uses a specific box for metadata
      // which is CacheConstants.metadataBoxName
      await _hiveManager.delete(key, CacheConstants.metadataBoxName); 

      _log.info('Successfully removed item and its metadata for key: $key from box: $boxName');
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
    } catch (e, stackTrace) {
      _log.severe('Error clearing Hive box: $boxName', e, stackTrace);
      rethrow;
    }
  }
}
