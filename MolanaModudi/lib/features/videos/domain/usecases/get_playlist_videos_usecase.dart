import '../entities/video_entity.dart';
import '../repositories/video_repository.dart';

/// Use case for fetching videos from a specific playlist.
class GetPlaylistVideosUseCase {
  final VideoRepository repository;

  GetPlaylistVideosUseCase(this.repository);

  Future<List<VideoEntity>> call(String playlistId) async {
    return await repository.getPlaylistVideos(playlistId);
  }
} 