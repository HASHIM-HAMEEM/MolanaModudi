import 'dart:io';
import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' hide CacheManager;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

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

  // Expose the DefaultCacheManager instance
  DefaultCacheManager get defaultCacheManager => _cacheManager;

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
      final CacheResult<Map<String, dynamic>> cacheResult = 
          await _cacheService.getCachedData<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.imageMetadataBoxName,
      );
      final Map<String, dynamic>? metadata = cacheResult.data;

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

  /// Preload an image into both disk and memory cache with retry mechanism
  Future<bool> preloadImage(String url, {Duration? ttl, int maxRetries = 2}) async {
    if (!_initialized) await initialize();
    
    int retryCount = 0;
    bool success = false;
    
    while (retryCount <= maxRetries && !success) {
      try {
        final file = await downloadAndCacheImage(url, ttl: ttl);
        success = file != null;
        if (success) {
          app_logger.CacheLogger.info('Successfully preloaded image after ${retryCount > 0 ? "$retryCount retries" : "first attempt"}: $url');
          return true;
        } else {
          retryCount++;
          if (retryCount <= maxRetries) {
            app_logger.CacheLogger.warning('Image preload attempt $retryCount/$maxRetries failed for $url, retrying...');
            await Future.delayed(Duration(milliseconds: 500 * retryCount)); // Exponential backoff
          }
        }
      } catch (e) {
        _log.warning('Error preloading image: $url (attempt ${retryCount + 1}/$maxRetries)', e);
        retryCount++;
        if (retryCount <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount)); // Exponential backoff
        }
      }
    }
    
    if (!success) {
      _log.warning('Failed to preload image after $maxRetries retries: $url');
    }
    return success;
  }
  
  /// Preload multiple images in parallel with progress tracking
  Future<Map<String, bool>> batchPreloadImages(List<String> urls, {Duration? ttl, int maxConcurrent = 3}) async {
    if (!_initialized) await initialize();
    if (urls.isEmpty) return {};
    
    final Map<String, bool> results = {};
    int completed = 0;
    final totalImages = urls.length;
    
    try {
      _log.info('Starting batch preload of ${urls.length} images');
      
      // Process images in batches to limit concurrent operations
      for (int i = 0; i < urls.length; i += maxConcurrent) {
        final batch = urls.skip(i).take(maxConcurrent).toList();
        final futures = <Future<void>>[];
        
        for (final url in batch) {
          futures.add((() async {
            results[url] = await preloadImage(url, ttl: ttl);
            completed++;
            // Update progress
            final progress = completed / totalImages;
            _preloadProgressController.add(progress);
            app_logger.CacheLogger.info('Image preload progress: ${(progress * 100).toStringAsFixed(0)}% ($completed/$totalImages)');
          })());
        }
        
        // Wait for batch to complete before starting next batch
        await Future.wait(futures);
      }
      
      _log.info('Completed batch preload: ${results.values.where((v) => v).length}/${urls.length} images successfully cached');
      _preloadProgressController.add(1.0); // Mark as complete
      
      return results;
    } catch (e) {
      _log.severe('Error in batch preload of images', e);
      // Still return partial results
      return results;
    }
  }
  
  /// Validate a cached image exists and is not corrupt
  Future<bool> validateCachedImage(String url) async {
    if (!_initialized) await initialize();
    final String cacheKey = _generateCacheKey(url);
    
    try {
      // Check metadata first
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.imageMetadataBoxName,
      );
      
      final Map<String, dynamic>? metadata = cacheResult.data;
      if (metadata != null && metadata['filePath'] != null) {
        final filePath = metadata['filePath'] as String;
        final file = File(filePath);
        
        if (await file.exists()) {
          // Check if file is a valid image by checking file size
          final fileSize = await file.length();
          if (fileSize > 0) {
            return true;
          } else {
            // Empty file, invalid
            app_logger.CacheLogger.warning('Cached image is invalid (zero size): $url');
            // Clean up invalid file
            await file.delete();
            await _cacheService.remove(cacheKey, CacheConstants.imageMetadataBoxName);
            return false;
          }
        } else {
          // File doesn't exist but metadata does - clean up metadata
          app_logger.CacheLogger.warning('Cached image file not found but metadata exists: $url');
          await _cacheService.remove(cacheKey, CacheConstants.imageMetadataBoxName);
          return false;
        }
      }
      
      // Try using flutter_cache_manager's internal cache
      final fileInfo = await _cacheManager.getFileFromCache(cacheKey);
      return fileInfo != null && await fileInfo.file.exists() && await fileInfo.file.length() > 0;
    } catch (e) {
      _log.warning('Error validating cached image: $url', e);
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

      // Get the app directory for storing images
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/$directoryName');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Extract file extension from URL or use .jpg as default
      final extension = _getImageExtension(url);
      final filename = '$id$extension';
      final filePath = '${targetDir.path}/$filename';
      
      // Copy the cached file to the app directory
      final newFile = await cachedFile.copy(filePath);
      
      // Store metadata about the saved image
      final metadata = {
        'filePath': filePath,
        'url': url,
        'savedAt': DateTime.now().toIso8601String(),
        'offline': true,
      };
      
      await _cacheService.cacheData(
        key: '${CacheConstants.imageKeyPrefix}${id}_offline',
        data: metadata,
        boxName: CacheConstants.imageMetadataBoxName,
        ttl: const Duration(days: 365), // Long TTL for offline images
      );
      
      app_logger.CacheLogger.info('Image $url saved to app directory: $filePath');
      return newFile;
    } catch (e, stackTrace) {
      _log.severe('Error saving image $url to app directory', e, stackTrace);
      return null;
    }
  }
  
  /// Get file extension from URL
  String _getImageExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final lastDotIndex = path.lastIndexOf('.');
    
    if (lastDotIndex != -1 && lastDotIndex < path.length - 1) {
      return path.substring(lastDotIndex); // Includes the dot
    }
    
    // Default extension if none found
    return '.jpg';
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
