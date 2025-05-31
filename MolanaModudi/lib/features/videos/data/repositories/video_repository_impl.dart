import 'package:logging/logging.dart';
import 'dart:async';
import '../../domain/entities/video_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/repositories/video_repository.dart';
import '../services/youtube_api_service.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/cache/config/cache_constants.dart';

/// Enhanced implementation of VideoRepository with improved caching and memory management.
class VideoRepositoryImpl implements VideoRepository {
  final YouTubeApiService _apiService;
  final CacheService _cacheService;
  final Logger _log = Logger('VideoRepositoryImpl');

  // Enhanced memory cache with timestamps for expiration
  final Map<String, _CacheEntry<List<PlaylistEntity>>> _playlistsCache = {};
  final Map<String, _CacheEntry<List<VideoEntity>>> _playlistVideosCache = {};
  final Map<String, _CacheEntry<VideoEntity>> _videoDetailsCache = {};
  final Map<String, _CacheEntry<PlaylistEntity>> _singlePlaylistCache = {};

  // Cache configuration
  static const Duration _memoryCacheExpiry = Duration(minutes: 10);
  static const Duration _persistentCacheExpiry = Duration(hours: 2);
  static const int _maxMemoryCacheSize = 100; // Maximum items per cache type

  Timer? _cleanupTimer;

  VideoRepositoryImpl({
    required YouTubeApiService apiService,
    required CacheService cacheService,
  }) : _apiService = apiService, _cacheService = cacheService {
    _startPeriodicCleanup();
  }

  void _startPeriodicCleanup() {
    // Clean up expired cache entries every 5 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performMemoryCleanup();
    });
  }

  void _performMemoryCleanup() {
    final now = DateTime.now();
    
    // Clean expired playlists cache
    _playlistsCache.removeWhere((key, entry) => entry.isExpired(now));
    
    // Clean expired videos cache
    _playlistVideosCache.removeWhere((key, entry) => entry.isExpired(now));
    
    // Clean expired video details cache
    _videoDetailsCache.removeWhere((key, entry) => entry.isExpired(now));
    
    // Clean expired single playlist cache
    _singlePlaylistCache.removeWhere((key, entry) => entry.isExpired(now));
    
    // Enforce size limits
    _enforceCacheSizeLimit(_playlistVideosCache);
    _enforceCacheSizeLimit(_videoDetailsCache);
    _enforceCacheSizeLimit(_singlePlaylistCache);
    
    _log.info('Memory cache cleanup completed. Cache sizes: '
        'playlists: ${_playlistsCache.length}, '
        'videos: ${_playlistVideosCache.length}, '
        'details: ${_videoDetailsCache.length}, '
        'single: ${_singlePlaylistCache.length}');
  }

  void _enforceCacheSizeLimit<T>(Map<String, _CacheEntry<T>> cache) {
    if (cache.length > _maxMemoryCacheSize) {
      // Remove oldest entries
      final sortedEntries = cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = sortedEntries.take(cache.length - _maxMemoryCacheSize);
      for (final entry in toRemove) {
        cache.remove(entry.key);
      }
    }
  }

  @override
  Future<List<PlaylistEntity>> getPlaylists() async {
    const cacheKey = CacheConstants.videoLecturesKey;
    
    try {
      // Check memory cache first
      final memoryEntry = _playlistsCache['playlists'];
      if (memoryEntry != null && !memoryEntry.isExpired(DateTime.now())) {
        _log.info('Returning playlists from memory cache');
        return memoryEntry.data;
      }

      // Check persistent cache
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.playlistBoxName,
      );

      if (cacheResult.hasData && cacheResult.data != null) {
        _log.info('Found ${cacheResult.data!.length} playlists in persistent cache');
        
        List<PlaylistEntity> playlists = [];
        for (var item in cacheResult.data!) {
          if (item is Map<String, dynamic>) {
            try {
              final playlist = PlaylistEntity(
                id: item['id'] as String,
                title: item['title'] as String,
                description: item['description'] as String?,
                thumbnailUrl: item['thumbnailUrl'] as String?,
                videoCount: item['videoCount'] as int,
              );
              playlists.add(playlist);
            } catch (e) {
              _log.warning('Error parsing cached playlist: $e');
            }
          }
        }

        if (playlists.isNotEmpty) {
          // Cache in memory for quick access
          _playlistsCache['playlists'] = _CacheEntry(playlists, DateTime.now());
          return playlists;
        }
      }

      // Fetch from API if cache miss or empty
      _log.info('Cache miss for playlists, fetching from YouTube API');
      
      final playlists = await _fetchPlaylistsFromApi();
      
      // Cache the results
      if (playlists.isNotEmpty) {
        await _cachePlaylistsPersistently(playlists, cacheKey);
        _playlistsCache['playlists'] = _CacheEntry(playlists, DateTime.now());
        _log.info('Cached ${playlists.length} playlists');
      }

      return playlists;
    } catch (e, stackTrace) {
      _log.severe('Error getting playlists: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<PlaylistEntity?> getPlaylist(String playlistId) async {
    try {
      // Check memory cache first
      final memoryEntry = _singlePlaylistCache[playlistId];
      if (memoryEntry != null && !memoryEntry.isExpired(DateTime.now())) {
        _log.info('Returning playlist $playlistId from memory cache');
        return memoryEntry.data;
      }

      final cacheKey = '${CacheConstants.playlistKeyPrefix}$playlistId';
      
      // Check persistent cache
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.playlistBoxName,
      );

      if (cacheResult.hasData && cacheResult.data != null) {
        _log.info('Found playlist $playlistId in persistent cache');
        final data = cacheResult.data!;
        final playlist = PlaylistEntity(
          id: data['id'] as String,
          title: data['title'] as String,
          description: data['description'] as String?,
          thumbnailUrl: data['thumbnailUrl'] as String?,
          videoCount: data['videoCount'] as int,
        );
        
        // Cache in memory
        _singlePlaylistCache[playlistId] = _CacheEntry(playlist, DateTime.now());
        return playlist;
      }

      // Fetch from API
      _log.info('Cache miss for playlist $playlistId, fetching from API');
      final playlist = await _apiService.getPlaylistDetails(playlistId);
      
      if (playlist != null) {
        await _cachePlaylistPersistently(playlist, cacheKey);
        _singlePlaylistCache[playlistId] = _CacheEntry(playlist, DateTime.now());
        _log.info('Cached playlist: ${playlist.title}');
      }

      return playlist;
    } catch (e, stackTrace) {
      _log.severe('Error getting playlist $playlistId: $e', e, stackTrace);
      return null;
    }
  }

  @override
  Future<List<VideoEntity>> getPlaylistVideos(String playlistId) async {
    try {
      // Check memory cache first
      final memoryEntry = _playlistVideosCache[playlistId];
      if (memoryEntry != null && !memoryEntry.isExpired(DateTime.now())) {
        _log.info('Returning videos for playlist $playlistId from memory cache');
        return memoryEntry.data;
      }

      final cacheKey = '${CacheConstants.playlistKeyPrefix}${playlistId}_videos';
      
      // Check persistent cache
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.videosBoxName,
      );

      if (cacheResult.hasData && cacheResult.data != null) {
        _log.info('Found ${cacheResult.data!.length} videos in persistent cache for playlist $playlistId');
        
        final videos = await _parseVideosFromCache(cacheResult.data!);
        if (videos.isNotEmpty) {
          _playlistVideosCache[playlistId] = _CacheEntry(videos, DateTime.now());
          return videos;
        }
      }

      // Fetch from API
      _log.info('Cache miss for playlist videos $playlistId, fetching from API');
      final videos = await _apiService.getPlaylistVideos(playlistId);
      
      if (videos.isNotEmpty) {
        await _cacheVideosPersistently(videos, cacheKey);
        _playlistVideosCache[playlistId] = _CacheEntry(videos, DateTime.now());
        _log.info('Cached ${videos.length} videos for playlist $playlistId');
      }

      return videos;
    } catch (e, stackTrace) {
      _log.severe('Error getting videos for playlist $playlistId: $e', e, stackTrace);
      return [];
    }
  }

  @override
  Future<VideoEntity?> getVideoDetails(VideoEntity basicVideo) async {
    try {
      // Check memory cache first
      final memoryEntry = _videoDetailsCache[basicVideo.id];
      if (memoryEntry != null && !memoryEntry.isExpired(DateTime.now())) {
        _log.info('Returning video details for ${basicVideo.id} from memory cache');
        return memoryEntry.data;
      }

      final cacheKey = '${CacheConstants.videoKeyPrefix}${basicVideo.id}_details';
      
      // Check persistent cache
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.videoMetadataBoxName,
      );

      if (cacheResult.hasData && cacheResult.data != null) {
        _log.info('Found video details in persistent cache for ${basicVideo.id}');
        final detailedVideo = _parseVideoFromCache(cacheResult.data!);
        _videoDetailsCache[basicVideo.id] = _CacheEntry(detailedVideo, DateTime.now());
        return detailedVideo;
      }

      // Fetch from API
      _log.info('Cache miss for video details ${basicVideo.id}, fetching from API');
      final detailedVideo = await _apiService.getVideoDetails(basicVideo);
      
      if (detailedVideo != null) {
        await _cacheVideoDetailsPersistently(detailedVideo, cacheKey);
        _videoDetailsCache[basicVideo.id] = _CacheEntry(detailedVideo, DateTime.now());
        _log.info('Cached video details: ${detailedVideo.title}');
        return detailedVideo;
      }

      return basicVideo; // Return basic video if details fetch fails
    } catch (e, stackTrace) {
      _log.severe('Error getting video details for ${basicVideo.id}: $e', e, stackTrace);
      return basicVideo;
    }
  }

  @override
  Future<bool> testApiConnection() async {
    try {
      return await _apiService.testApiConnection();
    } catch (e, stackTrace) {
      _log.severe('Error testing API connection: $e', e, stackTrace);
      return false;
    }
  }

  @override
  void clearCache() {
    _playlistsCache.clear();
    _playlistVideosCache.clear();
    _videoDetailsCache.clear();
    _singlePlaylistCache.clear();
    _log.info('Cleared all video memory caches');
  }

  /// Force clear all persistent cache - for debugging/resetting 
  Future<void> clearPersistentCache() async {
    try {
      // Clear persistent cache keys
      await _cacheService.remove(
        CacheConstants.videoLecturesKey,
        CacheConstants.playlistBoxName,
      );
      
      // Clear individual playlist caches
      final playlistIds = [
        'PLGlK3JqJXED-baSnv7lI6qX9GY0PhrpVe',
        'PLGlK3JqJXED9natBVnJAZ1-1PYyJ4DCup', 
        'PLGlK3JqJXED8A6gC3aEZkIlYekrm7jUB7',
        'PLGlK3JqJXED_kGKZDMOY3zlnbede4WjVt',
      ];
      
      for (final id in playlistIds) {
        await _cacheService.remove(
          '${CacheConstants.playlistKeyPrefix}$id',
          CacheConstants.playlistBoxName,
        );
        await _cacheService.remove(
          '${CacheConstants.playlistKeyPrefix}${id}_videos',
          CacheConstants.videosBoxName,
        );
      }
      
      // Clear memory caches too
      clearCache();
      
      _log.info('Force cleared all persistent and memory caches');
    } catch (e) {
      _log.warning('Error clearing persistent cache: $e');
    }
  }

  /// Clear specific cache entries for selective invalidation
  void clearPlaylistCache(String? playlistId) {
    if (playlistId != null) {
      _playlistVideosCache.remove(playlistId);
      _singlePlaylistCache.remove(playlistId);
      _log.info('Cleared cache for playlist: $playlistId');
    } else {
      _playlistsCache.clear();
      _log.info('Cleared all playlists cache');
    }
  }

  void clearVideoCache(String videoId) {
    _videoDetailsCache.remove(videoId);
    _log.info('Cleared cache for video: $videoId');
  }

  /// Enhanced memory usage monitoring
  Map<String, int> getMemoryCacheStats() {
    return {
      'playlists': _playlistsCache.length,
      'playlistVideos': _playlistVideosCache.length,
      'videoDetails': _videoDetailsCache.length,
      'singlePlaylists': _singlePlaylistCache.length,
    };
  }

  // Helper methods for caching
  Future<void> _cachePlaylistsPersistently(List<PlaylistEntity> playlists, String cacheKey) async {
    final cacheData = playlists.map((playlist) => {
      'id': playlist.id,
      'title': playlist.title,
      'description': playlist.description,
      'thumbnailUrl': playlist.thumbnailUrl,
      'videoCount': playlist.videoCount,
    }).toList();
    
    await _cacheService.cacheData(
      key: cacheKey,
      data: cacheData,
      boxName: CacheConstants.playlistBoxName,
      ttl: _persistentCacheExpiry,
    );
  }

  Future<void> _cachePlaylistPersistently(PlaylistEntity playlist, String cacheKey) async {
    final cacheData = {
      'id': playlist.id,
      'title': playlist.title,
      'description': playlist.description,
      'thumbnailUrl': playlist.thumbnailUrl,
      'videoCount': playlist.videoCount,
    };
    
    await _cacheService.cacheData(
      key: cacheKey,
      data: cacheData,
      boxName: CacheConstants.playlistBoxName,
      ttl: _persistentCacheExpiry,
    );
  }

  Future<void> _cacheVideosPersistently(List<VideoEntity> videos, String cacheKey) async {
    final cacheData = videos.map((video) => {
      'id': video.id,
      'title': video.title,
      'description': video.description,
      'thumbnailUrl': video.thumbnailUrl,
      'youtubeUrl': video.youtubeUrl,
      'publishedAt': video.publishedAt,
      'channelTitle': video.channelTitle,
      'duration': video.duration,
      'viewCount': video.viewCount,
    }).toList();
    
    await _cacheService.cacheData(
      key: cacheKey,
      data: cacheData,
      boxName: CacheConstants.videosBoxName,
      ttl: _persistentCacheExpiry,
    );
  }

  Future<void> _cacheVideoDetailsPersistently(VideoEntity video, String cacheKey) async {
    final cacheData = {
      'id': video.id,
      'title': video.title,
      'description': video.description,
      'thumbnailUrl': video.thumbnailUrl,
      'youtubeUrl': video.youtubeUrl,
      'publishedAt': video.publishedAt,
      'channelTitle': video.channelTitle,
      'duration': video.duration,
      'viewCount': video.viewCount,
    };
    
    await _cacheService.cacheData(
      key: cacheKey,
      data: cacheData,
      boxName: CacheConstants.videoMetadataBoxName,
      ttl: _persistentCacheExpiry,
    );
  }

  Future<List<VideoEntity>> _parseVideosFromCache(List<dynamic> cacheData) async {
    List<VideoEntity> videos = [];
    for (var item in cacheData) {
      if (item is Map<String, dynamic>) {
        try {
          final video = VideoEntity(
            id: item['id'] as String,
            title: item['title'] as String,
            description: item['description'] as String?,
            thumbnailUrl: item['thumbnailUrl'] as String,
            youtubeUrl: item['youtubeUrl'] as String,
            publishedAt: item['publishedAt'] as String?,
            channelTitle: item['channelTitle'] as String?,
            duration: item['duration'] as String?,
            viewCount: item['viewCount'] as String?,
          );
          videos.add(video);
        } catch (e) {
          _log.warning('Error parsing cached video: $e');
        }
      }
    }
    return videos;
  }

  VideoEntity _parseVideoFromCache(Map<String, dynamic> data) {
    return VideoEntity(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String,
      youtubeUrl: data['youtubeUrl'] as String,
      publishedAt: data['publishedAt'] as String?,
      channelTitle: data['channelTitle'] as String?,
      duration: data['duration'] as String?,
      viewCount: data['viewCount'] as String?,
    );
  }

  /// Fetch playlists from API - now fetches your actual playlists
  Future<List<PlaylistEntity>> _fetchPlaylistsFromApi() async {
    try {
      // These are your actual playlist IDs that should be shown in the app
      final yourPlaylistIds = [
        'PLGlK3JqJXED-baSnv7lI6qX9GY0PhrpVe', // Al-Jiihaad fil Islam - Audiobook
        'PLGlK3JqJXED9natBVnJAZ1-1PYyJ4DCup', // Khilaafat o Malookiat - Audiobook
        'PLGlK3JqJXED8A6gC3aEZkIlYekrm7jUB7', // Tafheem Ul Quran - Molana Moududi
        'PLGlK3JqJXED_kGKZDMOY3zlnbede4WjVt', // Molana Moududi - Audiobooks
      ];

      List<PlaylistEntity> fetchedPlaylists = [];
      
      for (var playlistId in yourPlaylistIds) {
        try {
          _log.info('Fetching details for playlist: $playlistId');
          final details = await _apiService.getPlaylistDetails(playlistId);
          if (details != null) {
            fetchedPlaylists.add(details);
            _log.info('Successfully fetched playlist: ${details.title}');
          } else {
            _log.warning('Failed to fetch details for playlist: $playlistId');
          }
        } catch (e) {
          _log.warning('Error fetching playlist $playlistId: $e');
        }
      }
      
      // If no playlists were successfully fetched, return empty list instead of mock data
      if (fetchedPlaylists.isEmpty) {
        _log.warning('No playlists were successfully fetched from API');
      }
      
      return fetchedPlaylists;
    } catch (e, stackTrace) {
      _log.severe('Error in _fetchPlaylistsFromApi: $e', e, stackTrace);
      return [];
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    clearCache();
    _log.info('VideoRepositoryImpl disposed');
  }
}

/// Cache entry with timestamp for expiration tracking
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);

  bool isExpired(DateTime now) {
    return now.difference(timestamp) > VideoRepositoryImpl._memoryCacheExpiry;
  }
} 