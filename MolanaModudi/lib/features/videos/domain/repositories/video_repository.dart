import '../entities/video_entity.dart';
import '../entities/playlist_entity.dart';

/// Abstract repository definition for fetching videos and playlists.
abstract class VideoRepository {
  /// Fetches a list of playlists.
  Future<List<PlaylistEntity>> getPlaylists();

  /// Fetches a single playlist by its ID.
  Future<PlaylistEntity?> getPlaylist(String playlistId);

  /// Fetches videos from a specific playlist.
  Future<List<VideoEntity>> getPlaylistVideos(String playlistId);

  /// Fetches detailed info for a video.
  Future<VideoEntity?> getVideoDetails(VideoEntity basicVideo);

  /// Tests the API connection.
  Future<bool> testApiConnection();

  /// Clears all cached video data.
  void clearCache();
} 