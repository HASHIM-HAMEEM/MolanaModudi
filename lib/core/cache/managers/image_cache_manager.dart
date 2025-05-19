import 'dart:io';
import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' hide CacheManager;
import 'package:logging/logging.dart';

import '../cache_service.dart';
import '../config/cache_constants.dart';
import '../models/cache_result.dart';
import '../utils/cache_logger.dart' as app_logger;

/// Manages caching for images, leveraging CacheService for metadata and flutter_cache_manager for file operations.
class ImageCacheManager {
  static final Logger _log = Logger('ImageCacheManager');
  
  // Use the flutter_cache_manager package for disk caching
  late final DefaultCacheManager _cacheManager;
  bool _initialized = false;

  final CacheService _cacheService;

  // Constructor to inject CacheService
  ImageCacheManager(this._cacheService);
  
  // Stream controller for preloading progress
  final StreamController<double> _preloadProgressController = 
      StreamController<double>.broadcast();
  
  // Getter for preload progress stream
  Stream<double> get preloadProgressStream => _preloadProgressController.stream;

  /// Initialize the image cache manager
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _cacheManager = DefaultCacheManager();
      // Note: ImageCacheManager does not directly open its own Hive box here.
      // CacheService.init() is responsible for opening CacheConstants.imageMetadataBoxName.
      // ImageCacheManager will use _cacheService to access this box.
      _initialized = true;
      app_logger.CacheLogger.info('ImageCacheManager initialized successfully');
    } catch (e, stackTrace) {
      _log.severe('Error initializing ImageCacheManager', e, stackTrace);
      rethrow;
    }
  }

  /// Download and cache an image in both disk and memory
  Future<File?> downloadAndCacheImage(String url, {Duration? ttl}) async {
    if (!_initialized) await initialize();
    
    final String cacheKey = _generateCacheKey(url);
    try {
      // downloadFile returns NonNull FileInfo, or throws an exception.
      final fileInfo = await _cacheManager.downloadFile(
        url,
        key: cacheKey,
      );
      
      // The if (fileInfo != null) check was redundant here as downloadFile guarantees non-null on success.
      final metadata = {
        'filePath': fileInfo.file.path,
        'url': url,
        'validTill': fileInfo.validTill.toIso8601String(),
        'downloadedAt': DateTime.now().toIso8601String(),
      };
      await _cacheService.cacheData(
        key: cacheKey,
        data: metadata,
        boxName: CacheConstants.imageMetadataBoxName,
        ttl: ttl ?? CacheConstants.imageCacheTtl, // Use default image TTL if not provided
      );
      app_logger.CacheLogger.info('Downloaded and cached image via flutter_cache_manager & metadata stored: $url');
      return fileInfo.file;
    } catch (e, stackTrace) {
      _log.severe('Error downloading and caching image: $url', e, stackTrace);
      return null;
    }
  }

  /// Get a cached image with three-tier approach: metadata (CacheService) -> disk (flutter_cache_manager) -> network
  Future<File?> getImage(String url, {Duration? ttl}) async {
    if (!_initialized) await initialize();
    final String cacheKey = _generateCacheKey(url);

    try {
      // STEP 1: Try CacheService metadata cache
      final CacheResult<Map<String, dynamic>>? cacheResult = 
          await _cacheService.getCachedData<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.imageMetadataBoxName,
      );
      final Map<String, dynamic>? metadata = cacheResult?.data;

      if (metadata != null && metadata['filePath'] != null) {
        final filePath = metadata['filePath'] as String;
        final file = File(filePath);
        if (await file.exists()) {
          // TODO: Check TTL from metadata if necessary, though getCachedData might handle it.
          // For now, if metadata exists and file exists, consider it a hit.
          // Optionally update last access time in metadata via _cacheService if needed.
          app_logger.CacheLogger.logCacheHit(url, 'image-metadata (CacheService)');
          return file;
        } else {
          // Stale metadata: file doesn't exist at the path
          app_logger.CacheLogger.warning('Stale image metadata for $url: File not found at $filePath. Removing metadata.');
          await _cacheService.remove(cacheKey, CacheConstants.imageMetadataBoxName);
        }
      }

      // STEP 2: Try flutter_cache_manager's internal cache (disk/memory)
      final fileInfo = await _cacheManager.getFileFromCache(cacheKey);
      if (fileInfo != null) {
        app_logger.CacheLogger.logCacheHit(url, 'image-disk (flutter_cache_manager)');
        // Store metadata in CacheService for future faster lookups
        final newMetadata = {
          'filePath': fileInfo.file.path,
          'url': url,
          'validTill': fileInfo.validTill.toIso8601String(),
          'downloadedAt': DateTime.now().toIso8601String(), // Or use fileInfo.downloadedAt if available and preferred
        };
        await _cacheService.cacheData(
          key: cacheKey,
          data: newMetadata,
          boxName: CacheConstants.imageMetadataBoxName,
          ttl: ttl ?? CacheConstants.imageCacheTtl,
        );
        return fileInfo.file;
      }
      
      // STEP 3: If not in any cache, download and cache it
      app_logger.CacheLogger.logCacheMiss(url, 'image-metadata & image-disk');
      return await downloadAndCacheImage(url, ttl: ttl); // This will also store metadata
    } catch (e, stackTrace) {
      _log.severe('Error getting image: $url', e, stackTrace);
      return null;
    }
  }

  /// Preload an image into both disk and memory cache
  Future<bool> preloadImage(String url, {Duration? ttl}) async {
    if (!_initialized) await initialize();
    
    try {
      final file = await downloadAndCacheImage(url, ttl: ttl);
      return file != null;
    } catch (e) {
      _log.warning('Error preloading image: $url', e);
      return false;
    }
  }
  
  /// Preload multiple images and report progress
  Future<int> preloadImages(List<String> urls, {Duration? ttl}) async {
    if (!_initialized) await initialize();
    
    int successCount = 0;
    int totalCount = urls.length;
    
    for (int i = 0; i < urls.length; i++) {
      try {
        final success = await preloadImage(urls[i], ttl: ttl);
        if (success) successCount++;
        
        // Report progress
        _preloadProgressController.add((i + 1) / totalCount);
      } catch (e) {
        // Continue with next image
        _log.warning('Error preloading image batch: ${urls[i]}', e);
      }
    }
    
    return successCount;
  }

  /// Save an image to local storage for offline use
  Future<File?> saveImageToAppDirectory(String url, String id, String directoryName) async {
    if (!_initialized) await initialize();

    try {
      // First, ensure the image is cached by flutter_cache_manager
      File? cachedFile = await getImage(url);
      if (cachedFile == null) {
        _log.warning('Image $url not found in cache, cannot save to app directory.');
        return null;
      }

      // TODO: This section needs path_provider and proper directory setup if functionality is kept.
      // For now, commenting out to resolve baseDir issues and remove path_provider dependency.
      /*
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(path.join(appDir.path, directoryName));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final extension = _getImageExtension(url);
      final filename = '$id$extension';
      final filePath = path.join(targetDir.path, filename);
      
      final newFile = await cachedFile.copy(filePath);
      app_logger.CacheLogger.info('Image $url saved to app directory: $filePath');
      return newFile;
      */
      _log.info('saveImageToAppDirectory: Functionality to copy to app directory is currently disabled pending path_provider re-integration.');
      return cachedFile; // Returning the cached file directly for now
    } catch (e, stackTrace) {
      _log.severe('Error saving image $url to app directory', e, stackTrace);
      return null;
    }
  }

  /// Get an image file path by its ID, if previously saved by saveImageToAppDirectory
  /// This method relies on the custom saving logic of saveImageToAppDirectory.
  Future<String?> getSavedImageFilePath(String id, String directoryName, String extension) async {
    if (!_initialized) await initialize();
    // TODO: This section needs path_provider and proper directory setup if functionality is kept.
    /*
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(path.join(appDir.path, directoryName));
      final filename = '$id$extension';
      final filePath = path.join(targetDir.path, filename);
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
    } catch (e, stackTrace) {
      _log.severe('Error getting saved image file path for ID $id', e, stackTrace);
    }
    */
    _log.info('getSavedImageFilePath: Functionality to get from app directory is currently disabled pending path_provider re-integration.');
    return null;
  }

  /// Clear all cached images (delegates to flutter_cache_manager and clears metadata from CacheService).
  Future<void> clearCache() async {
    if (!_initialized) await initialize();
    
    try {
      // Clear disk cache via flutter_cache_manager
      await _cacheManager.emptyCache();
      
      // Clear metadata from CacheService
      await _cacheService.clearBox(CacheConstants.imageMetadataBoxName);
      
      app_logger.CacheLogger.info('Cleared image cache (disk cache and metadata cleared)');
    } catch (e, stackTrace) {
      _log.severe('Error clearing image cache', e, stackTrace);
    }
  }
  
  /// Clean up resources
  void dispose() {
    _preloadProgressController.close();
  }

  /// Get the size of the image cache in bytes.
  /// Note: This is an estimation. flutter_cache_manager does not provide a direct way to get its cache size.
  Future<int> getCacheSize() async {
    if (!_initialized) await initialize();
    int totalSize = 0;
    // The ability to get precise cache size from flutter_cache_manager is limited.
    // This method is unlikely to be accurate or useful with flutter_cache_manager.
    // Consider removing or relying on flutter_cache_manager's internal mechanisms.
    _log.warning('getCacheSize: Accurate cache size from flutter_cache_manager is not directly available.');
    return totalSize;
  }

  /// Enforce cache size limits. (Primarily delegates to flutter_cache_manager's mechanisms)
  Future<void> enforceSizeLimit() async {
    if (!_initialized) await initialize();
    // flutter_cache_manager handles its own size limits (maxNrOfCacheObjects, stalePeriod).
    // Explicitly calling emptyCache() here might be too aggressive unless specific conditions are met.
    // For now, this method can be a no-op or rely on flutter_cache_manager's config.
    /*
    try {
      final cacheSize = await getCacheSize(); // This is already problematic
      
      if (cacheSize > CacheConstants.maxImageCacheSizeBytes) {
        // Let flutter_cache_manager handle its own cleanup
        await _cacheManager.emptyCache(); 
        app_logger.CacheLogger.info('Enforced image cache size limit by clearing flutter_cache_manager');
      }
    } catch (e) {
      _log.warning('Error enforcing image cache size limit', e);
    }
    */
    _log.info('enforceSizeLimit: Relying on flutter_cache_manager internal size management.');
  }

  /// Generate a cache key for an URL
  String _generateCacheKey(String url) {
    // Remove URL parameters to avoid duplicate caching
    final uri = Uri.parse(url);
    final baseUrl = '${uri.scheme}://${uri.host}${uri.path}';
    return baseUrl;
  }

  /// Remove an image from the cache
  Future<void> removeImage(String url) async {
    if (!_initialized) await initialize();
    
    try {
      await _cacheManager.removeFile(_generateCacheKey(url));
      app_logger.CacheLogger.info('Removed image from cache: $url');
    } catch (e) {
      _log.warning('Error removing image from cache: $url', e);
    }
  }
}
