import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/video_entity.dart';

class YouTubeApiService {
  final Logger _logger = Logger('YouTubeApiService');
  // Improved API key management - could be moved to a secure location for production
  final String _apiKey = 'AIzaSyCsghCtqCySFT3-S4NZWMOzSfs_nnXMLL8'; 
  final String _baseUrl = 'www.googleapis.com';

  // Test the API connection with a basic request - useful for debugging
  Future<bool> testApiConnection() async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/videos', {
        'part': 'snippet',
        'id': 'dQw4w9WgXcQ', // Use a known video ID for testing
        'key': _apiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        _logger.info('YouTube API connection successful');
        return true;
      } else {
        _logger.warning('YouTube API connection failed: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.severe('Exception testing YouTube API connection: $e');
      return false;
    }
  }

  // Fetch a playlist's metadata
  Future<PlaylistEntity?> getPlaylistDetails(String playlistId) async {
    try {
      // Add debug logging
      _logger.info('Fetching playlist details for ID: $playlistId');
      
      final uri = Uri.https(_baseUrl, '/youtube/v3/playlists', {
        'part': 'snippet,contentDetails',
        'id': playlistId,
        'key': _apiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _logger.warning('Failed to fetch playlist details: Status ${response.statusCode}, Response: ${response.body}');
        return null;
      }

      final data = json.decode(response.body);
      if (data['items'] == null || data['items'].isEmpty) {
        _logger.warning('Playlist not found or empty for ID: $playlistId');
        return null;
      }

      final item = data['items'][0];
      final snippet = item['snippet'];
      
      // Add additional safety checks to extract thumbnail URL
      String thumbnailUrl = '';
      if (snippet['thumbnails'] != null && 
          snippet['thumbnails']['high'] != null &&
          snippet['thumbnails']['high']['url'] != null) {
        thumbnailUrl = snippet['thumbnails']['high']['url'];
      } else if (snippet['thumbnails'] != null && 
                 snippet['thumbnails']['default'] != null &&
                 snippet['thumbnails']['default']['url'] != null) {
        thumbnailUrl = snippet['thumbnails']['default']['url'];
      }

      return PlaylistEntity(
        id: playlistId,
        title: snippet['title'],
        description: snippet['description'],
        thumbnailUrl: thumbnailUrl,
        videoCount: item['contentDetails']['itemCount'],
      );
    } catch (e, stackTrace) {
      _logger.severe('Error fetching playlist details: $e', e, stackTrace);
      return null;
    }
  }

  // Fetch videos from a playlist with pagination support
  Future<List<VideoEntity>> getPlaylistVideos(String playlistId, {String? pageToken}) async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/playlistItems', {
        'part': 'snippet,contentDetails',
        'playlistId': playlistId,
        'maxResults': '20',
        'key': _apiKey,
        if (pageToken != null) 'pageToken': pageToken,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _logger.warning('Failed to fetch playlist videos: ${response.body}');
        return [];
      }

      final data = json.decode(response.body);
      if (data['items'] == null) {
        return [];
      }

      final nextPageToken = data['nextPageToken'];
      final List<VideoEntity> videos = [];

      for (var item in data['items']) {
        final snippet = item['snippet'];
        final videoId = item['contentDetails']['videoId'];
        
        // Skip deleted or private videos
        if (snippet['title'] == 'Deleted video' || 
            snippet['title'] == 'Private video') {
          continue;
        }

        String thumbnailUrl = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
        if (snippet['thumbnails'] != null && 
            snippet['thumbnails']['high'] != null) {
          thumbnailUrl = snippet['thumbnails']['high']['url'];
        }

        videos.add(VideoEntity(
          id: videoId,
          title: snippet['title'],
          description: snippet['description'],
          thumbnailUrl: thumbnailUrl,
          youtubeUrl: 'https://www.youtube.com/watch?v=$videoId',
          publishedAt: snippet['publishedAt'],
          channelTitle: snippet['channelTitle'] ?? 'Channel',
        ));
      }

      // If we have more pages and less than 50 videos, fetch the next page
      if (nextPageToken != null && videos.length < 50) {
        final moreVideos = await getPlaylistVideos(playlistId, pageToken: nextPageToken);
        videos.addAll(moreVideos);
      }

      return videos;
    } catch (e) {
      _logger.severe('Error fetching playlist videos: $e');
      return [];
    }
  }

  // Get video details for additional info (optional)
  Future<VideoEntity?> getVideoDetails(VideoEntity basicVideo) async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/videos', {
        'part': 'contentDetails,statistics',
        'id': basicVideo.id,
        'key': _apiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return basicVideo;
      }

      final data = json.decode(response.body);
      if (data['items'] == null || data['items'].isEmpty) {
        return basicVideo;
      }

      final item = data['items'][0];
      final contentDetails = item['contentDetails'];
      final statistics = item['statistics'];

      // Parse duration from ISO 8601 format
      String? formattedDuration;
      if (contentDetails['duration'] != null) {
        final duration = contentDetails['duration'];
        // Simple parsing for PT1H30M15S format
        formattedDuration = duration
            .replaceAll('PT', '')
            .replaceAll('H', ':')
            .replaceAll('M', ':')
            .replaceAll('S', '');
      }

      // Format view count
      String? formattedViewCount;
      if (statistics['viewCount'] != null) {
        final viewCount = int.parse(statistics['viewCount']);
        if (viewCount > 1000000) {
          formattedViewCount = '${(viewCount / 1000000).toStringAsFixed(1)}M views';
        } else if (viewCount > 1000) {
          formattedViewCount = '${(viewCount / 1000).toStringAsFixed(1)}K views';
        } else {
          formattedViewCount = '$viewCount views';
        }
      }

      return VideoEntity(
        id: basicVideo.id,
        title: basicVideo.title,
        description: basicVideo.description,
        thumbnailUrl: basicVideo.thumbnailUrl,
        youtubeUrl: basicVideo.youtubeUrl,
        publishedAt: basicVideo.publishedAt,
        channelTitle: basicVideo.channelTitle,
        duration: formattedDuration,
        viewCount: formattedViewCount,
      );
    } catch (e) {
      _logger.severe('Error fetching video details: $e');
      return basicVideo;
    }
  }
} 