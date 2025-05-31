import '../entities/video_entity.dart';
import '../repositories/video_repository.dart';

/// Use case for fetching detailed video information.
class GetVideoDetailsUseCase {
  final VideoRepository repository;

  GetVideoDetailsUseCase(this.repository);

  Future<VideoEntity?> call(VideoEntity basicVideo) async {
    return await repository.getVideoDetails(basicVideo);
  }
} 