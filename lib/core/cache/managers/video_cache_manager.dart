import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import '../config/cache_constants.dart';
import '../utils/cache_logger.dart';
import '../utils/cache_utils.dart';
import '../cache_service.dart';

/// Manages caching for video metadata and content
class VideoCacheManager {
  static final Logger _log = Logger('VideoCacheManager');
  static const String _videoMetadataBoxName = CacheConstants.videoMetadataBoxName;
  static const String _playlistBoxName = CacheConstants.playlistBoxName;
  static const Duration _defaultTtl = CacheConstants.videoCacheTtl; // This can be passed to CacheService
  static const int _maxCacheSize = CacheConstants.maxVideoCacheSizeBytes; // For file cache management
  
  late final String _videoCacheDir;
  bool _initialized = false;

  // Add CacheService instance
  final CacheService _cacheService;

  // Update constructor to accept CacheService
  VideoCacheManager({required CacheService cacheService}) : _cacheService = cacheService;

  /// Initialize the video cache manager
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Set up local cache directory for downloaded videos
      final appDir = await getApplicationDocumentsDirectory();
      _videoCacheDir = path.join(appDir.path, 'video_cache');
      
      // Create directory if it doesn't exist
      final directory = Directory(_videoCacheDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Initialize Hive boxes
      if (!Hive.isBoxOpen(_videoMetadataBoxName)) {
        await Hive.openBox<String>(_videoMetadataBoxName);
      }
      
      if (!Hive.isBoxOpen(_playlistBoxName)) {
        await Hive.openBox<String>(_playlistBoxName);
      }
      
      _initialized = true;
      CacheLogger.info('VideoCacheManager initialized successfully');
    } catch (e, stackTrace) {
      _log.severe('Error initializing VideoCacheManager', e, stackTrace);
      rethrow;
    }
  }

  /// Cache video metadata using CacheService
  Future<void> cacheVideoMetadata(String videoId, Map<String, dynamic> metadata) async {
    if (!_initialized) await initialize(); // Keep its own initialization for file system parts
    
    try {
      // Use CacheService to cache the metadata
      await _cacheService.cacheData<Map<String, dynamic>>(
        key: videoId, // Using videoId directly as key for this specific metadata
        data: metadata,
        boxName: _videoMetadataBoxName, // Use the dedicated box name
        ttl: _defaultTtl, // Pass the default TTL for video metadata
      );
      CacheLogger.logCacheWrite(videoId, 'video_metadata (via CacheService)', CacheUtils.calculateObjectSize(metadata));
    } catch (e, stackTrace) {
      _log.severe('Error caching video metadata via CacheService: $videoId', e, stackTrace);
      rethrow;
    }
  }

  /// Get cached video metadata using CacheService
  Future<Map<String, dynamic>?> getVideoMetadata(String videoId) async {
    if (!_initialized) await initialize(); // Keep its own initialization
    
    try {
      // Use CacheService to get cached data
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: videoId,
        boxName: _videoMetadataBoxName,
      );
      
      if (cacheResult.hasData) {
        // Optional: Log cache hit via CacheLogger if CacheService doesn't do it verbosely enough for this context
        // CacheLogger.logCacheHit(videoId, 'video_metadata (via CacheService)');
        // The CacheResult.metadata will have accessCount, timestamps, etc.
        return cacheResult.data; 
      } else {
        // Optional: Log cache miss
        // CacheLogger.logCacheMiss(videoId, 'video_metadata (via CacheService)');
        return null;
      }
    } catch (e) {
      _log.warning('Error getting video metadata via CacheService: $videoId', e);
      return null;
    }
  }

  /// Cache playlist metadata using CacheService
  Future<void> cachePlaylist(String playlistId, Map<String, dynamic> playlistData) async {
    if (!_initialized) await initialize();
    
    try {
      // Use CacheService to cache the playlist data
      await _cacheService.cacheData<Map<String, dynamic>>(
        key: playlistId, // Using playlistId directly as key
        data: playlistData,
        boxName: _playlistBoxName, // Use the dedicated box name for playlists
        ttl: _defaultTtl, // Pass the default TTL (can be adjusted for playlists specifically if needed)
      );
      CacheLogger.logCacheWrite(playlistId, 'playlist (via CacheService)', CacheUtils.calculateObjectSize(playlistData));
    } catch (e, stackTrace) {
      _log.severe('Error caching playlist via CacheService: $playlistId', e, stackTrace);
      rethrow;
    }
  }

  /// Get cached playlist using CacheService
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    if (!_initialized) await initialize();
    
    try {
      // Use CacheService to get cached playlist data
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: playlistId,
        boxName: _playlistBoxName,
      );
      
      if (cacheResult.hasData) {
        // The CacheResult.metadata will have accessCount, timestamps, etc.
        return cacheResult.data;
      } else {
        return null;
      }
    } catch (e) {
      _log.warning('Error getting playlist via CacheService: $playlistId', e);
      return null;
    }
  }

  /// Cache video thumbnail
  Future<String?> cacheVideoThumbnail(String videoId, String thumbnailUrl) async {
    if (!_initialized) await initialize();
    
    try {
      // Create a unique filename
      final extension = _getImageExtension(thumbnailUrl);
      final filename = 'thumbnail_$videoId$extension';
      final filePath = path.join(_videoCacheDir, filename);
      
      final file = File(filePath);
      // Check if already downloaded AND metadata exists in CacheService
      final metadataKey = '${CacheConstants.thumbnailMetadataPrefix}$videoId'; // Use defined constant
      final existingMetadataResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: metadataKey,
        boxName: CacheConstants.thumbnailMetadataBoxName, // Use defined constant
      );

      if (await file.exists() && existingMetadataResult.hasData) {
        _log.info('Thumbnail already exists and metadata found for $videoId at $filePath');
        // Optionally update access stats for the metadata if needed via CacheService, though getCachedData might do it.
        return filePath;
      }
      
      // Download and save file
      _log.info('Downloading thumbnail for $videoId from $thumbnailUrl');
      final response = await http.get(Uri.parse(thumbnailUrl));
      if (response.statusCode != 200) {
        _log.warning('Error downloading thumbnail $thumbnailUrl: HTTP ${response.statusCode}');
        return null;
      }
      
      await file.writeAsBytes(response.bodyBytes);
      CacheLogger.info('Cached video thumbnail file: $videoId -> $filePath');

      // Store metadata in CacheService
      final thumbnailMetadata = {
        'originalUrl': thumbnailUrl,
        'localPath': filePath,
        'videoId': videoId,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'extension': extension,
      };

      await _cacheService.cacheData<Map<String, dynamic>>(
        key: metadataKey,
        data: thumbnailMetadata,
        boxName: CacheConstants.thumbnailMetadataBoxName, // Use defined constant
        ttl: _defaultTtl, // Or a specific TTL for thumbnails
      );
      _log.info('Stored thumbnail metadata in CacheService for $videoId');
      
      return filePath;
    } catch (e) {
      _log.warning('Error caching video thumbnail for $videoId: $e');
      return null;
    }
  }

  /// Get path to cached video thumbnail
  Future<String?> getVideoThumbnailPath(String videoId) async { // Made async to await CacheService
    if (!_initialized) {
      _log.warning('VideoCacheManager not initialized');
      return null;
    }

    final metadataKey = '${CacheConstants.thumbnailMetadataPrefix}$videoId'; // Use defined constant
    try {
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: metadataKey,
        boxName: CacheConstants.thumbnailMetadataBoxName, // Use defined constant
      );

      if (cacheResult.hasData && cacheResult.data != null) {
        final metadata = cacheResult.data!;
        final localPath = metadata['localPath'] as String?;

        if (localPath != null) {
          if (File(localPath).existsSync()) {
            return localPath;
          } else {
            _log.warning('Thumbnail metadata found for $videoId, but file $localPath does not exist. Clearing stale metadata.');
            await _cacheService.remove(metadataKey, CacheConstants.thumbnailMetadataBoxName);
            return null; 
          }
        }
      }
    } catch (e) {
      _log.warning('Error getting thumbnail metadata from CacheService for $videoId: $e');
      // Fall through to direct file system check as a fallback
    }
    
    // Fallback: Direct file system check (can be removed if CacheService is fully reliable)
    _log.info('No/invalid metadata in CacheService for $videoId, attempting direct file check.');
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
      final filename = 'thumbnail_$videoId$ext';
      final filePath = path.join(_videoCacheDir, filename);
      
      if (File(filePath).existsSync()) {
        _log.info('Found thumbnail via direct file check: $filePath. Consider caching its metadata.');
        // Optionally, if found here but not in metadata, one could call cacheVideoThumbnail's metadata storing part.
        return filePath;
      }
    }
    
    return null;
  }

  /// Preload multiple video thumbnails
  Future<void> preloadVideoThumbnails(Map<String, String> videoThumbnails) async {
    if (!_initialized) await initialize();
    
    final futures = <Future>[];
    
    for (final entry in videoThumbnails.entries) {
      futures.add(cacheVideoThumbnail(entry.key, entry.value));
    }
    
    await Future.wait(futures);
  }

  /// Clear expired cache entries
  Future<int> clearExpiredEntries() async {
    if (!_initialized) await initialize();
    
    try {
      int removedCount = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check video metadata
      final metadataBox = Hive.box<String>(_videoMetadataBoxName);
      final metadataKeys = metadataBox.keys.toList();
      
      for (final key in metadataKeys) {
        try {
          final json = metadataBox.get(key);
          if (json == null) continue;
          
          final metadata = jsonDecode(json) as Map<String, dynamic>;
          final timestamp = metadata['cache_timestamp'] as int;
          final ttlMillis = metadata['ttl_millis'] as int;
          
          if (now > timestamp + ttlMillis) {
            await metadataBox.delete(key);
            removedCount++;
          }
        } catch (e) {
          // Log but continue with other entries
          _log.warning('Error processing metadata entry: $key', e);
        }
      }
      
      // Check playlists
      final playlistBox = Hive.box<String>(_playlistBoxName);
      final playlistKeys = playlistBox.keys.toList();
      
      for (final key in playlistKeys) {
        try {
          final json = playlistBox.get(key);
          if (json == null) continue;
          
          final playlist = jsonDecode(json) as Map<String, dynamic>;
          final timestamp = playlist['cache_timestamp'] as int;
          final ttlMillis = playlist['ttl_millis'] as int;
          
          if (now > timestamp + ttlMillis) {
            await playlistBox.delete(key);
            removedCount++;
          }
        } catch (e) {
          // Log but continue with other entries
          _log.warning('Error processing playlist entry: $key', e);
        }
      }
      
      // Check thumbnails and other files in cache directory
      final cacheDir = Directory(_videoCacheDir);
      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            final fileAge = now - stat.modified.millisecondsSinceEpoch;
            
            // Remove files older than default TTL
            if (fileAge > _defaultTtl.inMilliseconds) {
              await file.delete();
              removedCount++;
            }
          }
        }
      }
      
      CacheLogger.info('Cleared $removedCount expired video cache entries');
      return removedCount;
    } catch (e, stackTrace) {
      _log.severe('Error clearing expired video cache entries', e, stackTrace);
      return 0;
    }
  }

  /// Enforce size limit on video cache
  Future<void> enforceSizeLimit() async {
    if (!_initialized) await initialize();
    
    try {
      // Get cache directory size
      final cacheDir = Directory(_videoCacheDir);
      if (!await cacheDir.exists()) return;
      
      int totalSize = 0;
      final files = <File>[];
      
      // Collect files and calculate total size
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final size = await entity.length();
          totalSize += size;
          files.add(entity);
        }
      }
      
      // If under limit, no action needed
      if (totalSize <= _maxCacheSize) return;
      
      // Sort files by last access time (oldest first)
      // Get stats for all files first, then sort
      final fileStat = <File, FileStat>{};
      for (final file in files) {
        fileStat[file] = await file.stat();
      }
      
      files.sort((a, b) {
        return fileStat[a]!.accessed.compareTo(fileStat[b]!.accessed);
      });
      
      // Delete oldest files until under limit
      for (final file in files) {
        if (totalSize <= _maxCacheSize) break;
        
        final size = await file.length();
        await file.delete();
        totalSize -= size;
        
        CacheLogger.logCacheEviction(file.path, 'video_cache', 'Size limit');
      }
      
      CacheLogger.info('Enforced video cache size limit, now at ${totalSize ~/ (1024 * 1024)} MB');
    } catch (e, stackTrace) {
      _log.severe('Error enforcing video cache size limit', e, stackTrace);
    }
  }

  /// Clear all cached videos and metadata
  Future<void> clearCache() async {
    if (!_initialized) await initialize();
    
    try {
      // Clear metadata boxes
      final metadataBox = Hive.box<String>(_videoMetadataBoxName);
      final playlistBox = Hive.box<String>(_playlistBoxName);
      
      await metadataBox.clear();
      await playlistBox.clear();
      
      // Clear cache directory
      final cacheDir = Directory(_videoCacheDir);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      
      CacheLogger.info('Cleared all video cache data');
    } catch (e, stackTrace) {
      _log.severe('Error clearing video cache', e, stackTrace);
    }
  }

  /// Get the size of the video cache in bytes
  Future<int> getCacheSize() async {
    if (!_initialized) await initialize();
    
    try {
      int totalSize = 0;
      
      // Get size of cache directory
      final cacheDir = Directory(_videoCacheDir);
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      _log.warning('Error getting video cache size', e);
      return 0;
    }
  }

  /// Get the file extension from an image URL
  String _getImageExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    
    // Extract extension
    final extensionIndex = path.lastIndexOf('.');
    if (extensionIndex != -1 && extensionIndex < path.length - 1) {
      return path.substring(extensionIndex);
    }
    
    // Default to .jpg if no extension found
    return '.jpg';
  }
}
