import '../entities/playlist_entity.dart';
import '../repositories/video_repository.dart';

/// Use case for fetching video playlists.
class GetPlaylistsUseCase {
  final VideoRepository repository;

  GetPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call() async {
    return await repository.getPlaylists();
  }
} 