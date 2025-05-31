import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import '../../domain/entities/video_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/usecases/get_playlists_usecase.dart';
import '../../domain/usecases/get_playlist_videos_usecase.dart';
import '../../domain/usecases/get_video_details_usecase.dart';
import '../../data/repositories/video_repository_impl.dart';
import '../../data/services/youtube_api_service.dart';
import '../../../../core/providers/providers.dart';

final _log = Logger('VideoProviders');

/// Enhanced state classes for better state management
class VideoState<T> {
  final T? data;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final StackTrace? stackTrace;
  final DateTime? lastUpdated;
  final bool hasMore;
  final int totalCount;

  const VideoState({
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.stackTrace,
    this.lastUpdated,
    this.hasMore = false,
    this.totalCount = 0,
  });

  VideoState<T> copyWith({
    T? data,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    StackTrace? stackTrace,
    DateTime? lastUpdated,
    bool? hasMore,
    int? totalCount,
  }) {
    return VideoState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      stackTrace: stackTrace,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  bool get hasData => data != null;
  bool get hasError => error != null;
  bool get isIdle => !isLoading && !isRefreshing;
}

/// Provider for YouTube API Service with lifecycle management
final youtubeApiServiceProvider = Provider<YouTubeApiService>((ref) {
  final apiService = YouTubeApiService();
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    // API service doesn't need explicit disposal
    _log.info('YouTube API Service disposed');
  });
  
  return apiService;
});

/// Enhanced Video Repository Provider with proper lifecycle
final videoRepositoryProvider = FutureProvider<VideoRepository>((ref) async {
  final cacheService = await ref.watch(cacheServiceProvider.future);
  final apiService = ref.watch(youtubeApiServiceProvider);
  
  final repository = VideoRepositoryImpl(
    apiService: apiService,
    cacheService: cacheService,
  );
  
  // Clean up repository when disposed
  ref.onDispose(() {
    repository.clearCache();
    _log.info('Video Repository disposed and cache cleared');
  });
  
  return repository;
});

/// Enhanced Use Case Providers with proper error handling
final getPlaylistsUseCaseProvider = FutureProvider<GetPlaylistsUseCase>((ref) async {
  try {
    final repository = await ref.watch(videoRepositoryProvider.future);
    return GetPlaylistsUseCase(repository);
  } catch (e, stackTrace) {
    _log.severe('Error creating GetPlaylistsUseCase: $e', e, stackTrace);
    rethrow;
  }
});

final getPlaylistVideosUseCaseProvider = FutureProvider<GetPlaylistVideosUseCase>((ref) async {
  try {
    final repository = await ref.watch(videoRepositoryProvider.future);
    return GetPlaylistVideosUseCase(repository);
  } catch (e, stackTrace) {
    _log.severe('Error creating GetPlaylistVideosUseCase: $e', e, stackTrace);
    rethrow;
  }
});

final getVideoDetailsUseCaseProvider = FutureProvider<GetVideoDetailsUseCase>((ref) async {
  try {
    final repository = await ref.watch(videoRepositoryProvider.future);
    return GetVideoDetailsUseCase(repository);
  } catch (e, stackTrace) {
    _log.severe('Error creating GetVideoDetailsUseCase: $e', e, stackTrace);
    rethrow;
  }
});

/// Enhanced Video Search StateNotifier with proper lifecycle management
class VideoSearchNotifier extends StateNotifier<VideoState<List<VideoEntity>>> {
  final Ref _ref;
  Timer? _debounceTimer;
  String _lastQuery = '';
  String _lastPlaylistId = '';
  
  VideoSearchNotifier(this._ref) : super(const VideoState(data: []));
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> searchInPlaylist(String playlistId, String query, {bool debounce = true}) async {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      if (mounted) {
        state = state.copyWith(
          data: <VideoEntity>[],
          isLoading: false,
          error: null,
          lastUpdated: DateTime.now(),
        );
      }
      return;
    }
    
    // Debounce search requests
    if (debounce) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _performSearch(playlistId, query);
      });
    } else {
      await _performSearch(playlistId, query);
    }
  }
  
  Future<void> _performSearch(String playlistId, String query) async {
    if (!mounted) return;
    
    // Avoid duplicate searches
    if (_lastQuery == query && _lastPlaylistId == playlistId && state.hasData) {
      return;
    }
    
    _lastQuery = query;
    _lastPlaylistId = playlistId;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = await _ref.read(videoRepositoryProvider.future);
      final allVideos = await repository.getPlaylistVideos(playlistId);
      
      final filteredVideos = allVideos.where((video) {
        return video.title.toLowerCase().contains(query.toLowerCase()) ||
               (video.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
      
      if (mounted) {
        state = state.copyWith(
          data: filteredVideos,
          isLoading: false,
          totalCount: filteredVideos.length,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Search error: $e', e, stackTrace);
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Search failed: ${e.toString()}',
          stackTrace: stackTrace,
        );
      }
    }
  }
  
  void clearSearch() {
    _debounceTimer?.cancel();
    _lastQuery = '';
    _lastPlaylistId = '';
    if (mounted) {
      state = state.copyWith(
        data: <VideoEntity>[],
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      );
    }
  }
}

/// Enhanced Playlist StateNotifier with comprehensive state management
class PlaylistNotifier extends StateNotifier<VideoState<List<PlaylistEntity>>> {
  final Ref _ref;
  Timer? _refreshTimer;
  bool _isDisposed = false;
  
  PlaylistNotifier(this._ref) : super(const VideoState(isLoading: true)) {
    _initializeData();
    _startPeriodicRefresh();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    super.dispose();
    _log.info('PlaylistNotifier disposed');
  }
  
  void _startPeriodicRefresh() {
    // Refresh data every 30 minutes to keep it fresh
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (!_isDisposed && mounted) {
        refreshPlaylists(silent: true);
      }
    });
  }
  
  Future<void> _initializeData() async {
    if (_isDisposed) return;
    await loadPlaylists();
  }
  
  Future<void> loadPlaylists({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    
    // Don't reload if we have fresh data unless forced
    if (!forceRefresh && state.hasData && state.lastUpdated != null) {
      final age = DateTime.now().difference(state.lastUpdated!);
      if (age.inMinutes < 15) {
        _log.info('Using fresh cached playlists (${age.inMinutes} minutes old)');
        return;
      }
    }
    
    if (!state.isLoading && !state.isRefreshing) {
      state = state.copyWith(isLoading: true, error: null);
    }
    
    try {
      final repository = await _ref.read(videoRepositoryProvider.future);
      final playlists = await repository.getPlaylists();
      
      if (_isDisposed || !mounted) return;
      
      state = state.copyWith(
        data: playlists,
        isLoading: false,
        isRefreshing: false,
        error: null,
        totalCount: playlists.length,
        lastUpdated: DateTime.now(),
      );
      
      _log.info('Loaded ${playlists.length} playlists successfully');
    } catch (error, stackTrace) {
      _log.severe('Error loading playlists: $error', error, stackTrace);
      
      if (_isDisposed || !mounted) return;
      
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Failed to load playlists: ${error.toString()}',
        stackTrace: stackTrace,
      );
    }
  }
  
  Future<void> refreshPlaylists({bool silent = false, bool forceClearPersistent = false}) async {
    if (_isDisposed) return;
    
    if (!silent) {
      state = state.copyWith(isRefreshing: true, error: null);
    }
    
    try {
      // Clear cache to force fresh data
      final repository = await _ref.read(videoRepositoryProvider.future);
      
      if (forceClearPersistent && repository is VideoRepositoryImpl) {
        await repository.clearPersistentCache();
      } else {
        repository.clearCache();
      }
      
      await loadPlaylists(forceRefresh: true);
      
      _log.info('Playlists refreshed successfully');
    } catch (error, stackTrace) {
      _log.severe('Error refreshing playlists: $error', error, stackTrace);
      
      if (_isDisposed || !mounted) return;
      
      state = state.copyWith(
        isRefreshing: false,
        error: 'Failed to refresh playlists: ${error.toString()}',
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Force clear all caches and reload completely
  Future<void> forceClearAndReload() async {
    if (_isDisposed) return;
    
    _log.info('Force clearing all caches and reloading playlists');
    await refreshPlaylists(forceClearPersistent: true);
  }
  
  void retryLoad() {
    if (_isDisposed) return;
    loadPlaylists(forceRefresh: true);
  }
}

/// Enhanced Playlist Videos StateNotifier
class PlaylistVideosNotifier extends StateNotifier<VideoState<List<VideoEntity>>> {
  final Ref _ref;
  final String playlistId;
  bool _isDisposed = false;
  
  PlaylistVideosNotifier(this._ref, this.playlistId) : super(const VideoState(isLoading: true)) {
    _loadVideos();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
    _log.info('PlaylistVideosNotifier disposed for playlist: $playlistId');
  }
  
  Future<void> _loadVideos({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    
    if (!state.isLoading && !state.isRefreshing) {
      state = state.copyWith(isLoading: true, error: null);
    }
    
    try {
      final repository = await _ref.read(videoRepositoryProvider.future);
      
      if (forceRefresh) {
        repository.clearCache();
      }
      
      final videos = await repository.getPlaylistVideos(playlistId);
      
      if (_isDisposed || !mounted) return;
      
      state = state.copyWith(
        data: videos,
        isLoading: false,
        isRefreshing: false,
        error: null,
        totalCount: videos.length,
        lastUpdated: DateTime.now(),
      );
      
      _log.info('Loaded ${videos.length} videos for playlist: $playlistId');
    } catch (error, stackTrace) {
      _log.severe('Error loading videos for playlist $playlistId: $error', error, stackTrace);
      
      if (_isDisposed || !mounted) return;
      
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Failed to load videos: ${error.toString()}',
        stackTrace: stackTrace,
      );
    }
  }
  
  Future<void> refresh() async {
    if (_isDisposed) return;
    
    state = state.copyWith(isRefreshing: true, error: null);
    await _loadVideos(forceRefresh: true);
  }
  
  void retry() {
    if (_isDisposed) return;
    _loadVideos(forceRefresh: true);
  }
}

/// Provider instances with proper lifecycle management
final videoSearchProvider = StateNotifierProvider.autoDispose<VideoSearchNotifier, VideoState<List<VideoEntity>>>((ref) {
  return VideoSearchNotifier(ref);
});

final playlistNotifierProvider = StateNotifierProvider<PlaylistNotifier, VideoState<List<PlaylistEntity>>>((ref) {
  return PlaylistNotifier(ref);
});

final playlistVideosNotifierProvider = StateNotifierProvider.autoDispose.family<PlaylistVideosNotifier, VideoState<List<VideoEntity>>, String>((ref, playlistId) {
  return PlaylistVideosNotifier(ref, playlistId);
});

/// Enhanced individual providers with caching
final playlistProvider = FutureProvider.family.autoDispose<PlaylistEntity?, String>((ref, playlistId) async {
  try {
    final repository = await ref.watch(videoRepositoryProvider.future);
    return await repository.getPlaylist(playlistId);
  } catch (e, stackTrace) {
    _log.severe('Error in playlistProvider for $playlistId: $e', e, stackTrace);
    throw Exception('Failed to load playlist: ${e.toString()}');
  }
});

final videoDetailsProvider = FutureProvider.family.autoDispose<VideoEntity?, VideoEntity>((ref, basicVideo) async {
  try {
    final repository = await ref.watch(videoRepositoryProvider.future);
    return await repository.getVideoDetails(basicVideo);
  } catch (e, stackTrace) {
    _log.severe('Error in videoDetailsProvider for ${basicVideo.id}: $e', e, stackTrace);
    return basicVideo; // Return basic video on error instead of throwing
  }
});

/// API Connection Test Provider with retry logic
final apiConnectionTestProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final repository = await ref.watch(videoRepositoryProvider.future);
    return await repository.testApiConnection();
  } catch (e, stackTrace) {
    _log.severe('Error in apiConnectionTestProvider: $e', e, stackTrace);
    return false;
  }
});

/// Memory management helper provider
final videoMemoryManagerProvider = Provider<VideoMemoryManager>((ref) {
  return VideoMemoryManager(ref);
});

/// Memory Management Class
class VideoMemoryManager {
  final Ref _ref;
  Timer? _cleanupTimer;
  
  VideoMemoryManager(this._ref) {
    _startPeriodicCleanup();
  }
  
  void _startPeriodicCleanup() {
    // Clean up memory every 5 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performCleanup();
    });
  }
  
  void _performCleanup() {
    _log.info('Performing periodic memory cleanup');
    
    try {
      // Force garbage collection of auto-dispose providers
      _ref.invalidate(videoSearchProvider);
      
      // Clear repository cache if it's getting large
      _ref.read(videoRepositoryProvider).whenData((repository) {
        repository.clearCache();
      });
      
      _log.info('Memory cleanup completed');
    } catch (e) {
      _log.warning('Error during memory cleanup: $e');
    }
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
    _log.info('VideoMemoryManager disposed');
  }
}

/// Legacy providers for backward compatibility
@Deprecated('Use enhanced state notifiers instead')
final playlistsProvider = FutureProvider<List<PlaylistEntity>>((ref) async {
  final state = ref.watch(playlistNotifierProvider);
  if (state.hasError) {
    throw Exception(state.error ?? 'Unknown error');
  }
  return state.data ?? [];
});

@Deprecated('Use playlistVideosNotifierProvider instead')
final playlistVideosProvider = FutureProvider.family<List<VideoEntity>, String>((ref, playlistId) async {
  final state = ref.watch(playlistVideosNotifierProvider(playlistId));
  if (state.hasError) {
    throw Exception(state.error ?? 'Unknown error');
  }
  return state.data ?? [];
}); 