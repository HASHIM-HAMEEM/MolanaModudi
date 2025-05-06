import 'package:logging/logging.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../../data/services/youtube_api_service.dart';

class VideoProvider {
  final Logger _logger = Logger('VideoProvider');
  final YouTubeApiService _apiService = YouTubeApiService();
  
  // Cache playlists and videos to prevent redundant API calls
  final Map<String, PlaylistEntity> _playlists = {};
  final Map<String, List<VideoEntity>> _playlistVideos = {};
  final Map<String, VideoEntity> _videoDetails = {};
  
  // Placeholder playlists for development or when API fails
  final List<PlaylistEntity> placeholderPlaylists = [
    const PlaylistEntity(
      id: 'PLGlK3JqJXED-baSnv7lI6qX9GY0PhrpVe', 
      title: 'Al-Jiihaad fil Islam - Audiobook',
      description: 'Lectures covering Al Jihad fil Islam book by Maulana Maududi.',
      thumbnailUrl: 'https://i.ytimg.com/vi/rB4R8ETjJUE/hqdefault.jpg',
      videoCount: 20, 
    ),
    const PlaylistEntity(
      id: 'PLGlK3JqJXED9natBVnJAZ1-1PYyJ4DCup', 
      title: 'Khilaafat o Malookiat - Audiobook',
      description: 'Lectures covering Khilaafat o Malookiat book by Maulana Maududi.',
      thumbnailUrl: 'https://i.ytimg.com/vi/cqaGh_g_L-k/hqdefault.jpg',
      videoCount: 15,
    ),
    const PlaylistEntity(
      id: 'PLGlK3JqJXED8A6gC3aEZkIlYekrm7jUB7', 
      title: 'Tafheem Ul Quran - Molana Moududi',
      description: 'Lectures covering Tafheem Ul Quran by Maulana Maududi.',
      thumbnailUrl: 'https://i.ytimg.com/vi/WdK57O9esI8/hqdefault.jpg',
      videoCount: 25,
    ),
    const PlaylistEntity(
      id: 'PLGlK3JqJXED_kGKZDMOY3zlnbede4WjVt', 
      title: 'Molana Moududi - Audiobooks',
      description: 'Collection of audiobooks by Maulana Maududi.',
      thumbnailUrl: 'https://i.ytimg.com/vi/TbwjhsGXLFQ/hqdefault.jpg',
      videoCount: 30,
    ),
  ];

  // Get all playlists
  Future<List<PlaylistEntity>> getPlaylists() async {
    try {
      // Fetch real playlists if API key is configured
      List<PlaylistEntity> fetchedPlaylists = [];
      
      // For the demo, fetch details for our placeholder playlists
      for (var playlist in placeholderPlaylists) {
        final details = await _apiService.getPlaylistDetails(playlist.id);
        if (details != null) {
          fetchedPlaylists.add(details);
          _playlists[details.id] = details;
        } else {
          // Use the placeholder if API call fails
          fetchedPlaylists.add(playlist);
          _playlists[playlist.id] = playlist;
        }
      }
      
      return fetchedPlaylists;
    } catch (e) {
      _logger.severe('Error fetching playlists: $e');
      return placeholderPlaylists;
    }
  }

  // Get a single playlist by ID
  Future<PlaylistEntity?> getPlaylist(String playlistId) async {
    // Check cache first
    if (_playlists.containsKey(playlistId)) {
      return _playlists[playlistId];
    }
    
    try {
      // Fetch from API
      final playlist = await _apiService.getPlaylistDetails(playlistId);
      if (playlist != null) {
        _playlists[playlistId] = playlist;
        return playlist;
      }
      
      // If not found in API, check placeholders
      final placeholder = placeholderPlaylists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => const PlaylistEntity(
          id: '',
          title: 'Playlist Not Found',
          description: 'The requested playlist could not be found.',
          thumbnailUrl: '',
          videoCount: 0,
        ),
      );
      
      if (placeholder.id.isNotEmpty) {
        _playlists[playlistId] = placeholder;
        return placeholder;
      }
      
      return null;
    } catch (e) {
      _logger.severe('Error fetching playlist $playlistId: $e');
      
      // Fall back to placeholder
      final placeholder = placeholderPlaylists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => const PlaylistEntity(
          id: '',
          title: 'Error Loading Playlist',
          description: 'There was an error loading this playlist.',
          thumbnailUrl: '',
          videoCount: 0,
        ),
      );
      
      if (placeholder.id.isNotEmpty) {
        return placeholder;
      }
      
      return null;
    }
  }

  // Get videos in a playlist
  Future<List<VideoEntity>> getPlaylistVideos(String playlistId) async {
    // Check cache first
    if (_playlistVideos.containsKey(playlistId)) {
      return _playlistVideos[playlistId]!;
    }
    
    try {
      // Fetch from API
      final videos = await _apiService.getPlaylistVideos(playlistId);
      if (videos.isNotEmpty) {
        _playlistVideos[playlistId] = videos;
        return videos;
      }
      
      _logger.warning('No videos found for playlist $playlistId');
      return [];
    } catch (e) {
      _logger.severe('Error fetching videos for playlist $playlistId: $e');
      return [];
    }
  }
  
  // Get detailed info for a video
  Future<VideoEntity?> getVideoDetails(VideoEntity basicVideo) async {
    // Check cache first
    if (_videoDetails.containsKey(basicVideo.id)) {
      return _videoDetails[basicVideo.id];
    }
    
    try {
      // Fetch from API
      final detailedVideo = await _apiService.getVideoDetails(basicVideo);
      if (detailedVideo != null) {
        _videoDetails[basicVideo.id] = detailedVideo;
        return detailedVideo;
      }
      
      return basicVideo;
    } catch (e) {
      _logger.severe('Error fetching details for video ${basicVideo.id}: $e');
      return basicVideo;
    }
  }
  
  // Clear cache for fresh data
  void clearCache() {
    _playlists.clear();
    _playlistVideos.clear();
    _videoDetails.clear();
  }

  // Test the API connection - pass through to service
  Future<bool> testApiConnection() async {
    try {
      return await _apiService.testApiConnection();
    } catch (e) {
      _logger.severe('Error testing YouTube API connection: $e');
      return false;
    }
  }
}

// --- In a production app, you would implement a proper API integration ---
// Example of how to fetch real data from YouTube API:
//
// final videoProvider = StateNotifierProvider<VideoNotifier, VideoState>((ref) {
//   return VideoNotifier();
// });
//
// class VideoNotifier extends StateNotifier<VideoState> {
//   VideoNotifier() : super(VideoStateLoading()) {
//     fetchPlaylists();
//   }
//
//   Future<void> fetchPlaylists() async {
//     try {
//       state = VideoStateLoading();
//       final apiKey = 'YOUR_API_KEY'; // Would be stored securely
//       
//       // Channel ID or list of playlist IDs
//       final playlistIds = [
//         'PLGlK3JqJXED8rfyxfkBCQc0yB4bT7D_PF',
//         'PLGlK3JqJXED_9-vjnr6U9A2u25upBn0zi'
//       ];
//       
//       List<PlaylistEntity> playlists = [];
//       Map<String, List<VideoEntity>> videos = {};
//       
//       // Fetch each playlist
//       for (final playlistId in playlistIds) {
//         // Get playlist details
//         final playlistResponse = await http.get(Uri.parse(
//           'https://www.googleapis.com/youtube/v3/playlists?part=snippet,contentDetails&id=$playlistId&key=$apiKey'
//         ));
//         
//         final playlistData = json.decode(playlistResponse.body);
//         final playlistItem = playlistData['items'][0];
//         
//         final playlist = PlaylistEntity(
//           id: playlistId,
//           title: playlistItem['snippet']['title'],
//           description: playlistItem['snippet']['description'],
//           thumbnailUrl: playlistItem['snippet']['thumbnails']['high']['url'],
//           videoCount: playlistItem['contentDetails']['itemCount'],
//         );
//         
//         playlists.add(playlist);
//         
//         // Get videos for this playlist
//         final videoResponse = await http.get(Uri.parse(
//           'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=$playlistId&key=$apiKey'
//         ));
//         
//         final videoData = json.decode(videoResponse.body);
//         final videoItems = videoData['items'];
//         
//         videos[playlistId] = videoItems.map<VideoEntity>((item) {
//           final snippet = item['snippet'];
//           final videoId = snippet['resourceId']['videoId'];
//           
//           return VideoEntity(
//             id: videoId,
//             title: snippet['title'],
//             thumbnailUrl: snippet['thumbnails']['high']['url'],
//             youtubeUrl: 'https://www.youtube.com/watch?v=$videoId',
//           );
//         }).toList();
//       }
//       
//       state = VideoStateLoaded(playlists: playlists, videos: videos);
//     } catch (e) {
//       state = VideoStateError(message: e.toString());
//     }
//   }
// }
//
// sealed class VideoState {}
//
// class VideoStateLoading extends VideoState {}
//
// class VideoStateLoaded extends VideoState {
//   final List<PlaylistEntity> playlists;
//   final Map<String, List<VideoEntity>> videos; // Map playlist ID to videos
//   VideoStateLoaded({required this.playlists, required this.videos});
// }
//
// class VideoStateError extends VideoState {
//   final String message;
//   VideoStateError({required this.message});
// } 