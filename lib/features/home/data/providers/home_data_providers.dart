import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:modudi/core/services/api_service.dart'; // Removed
import 'package:modudi/features/home/domain/repositories/home_repository.dart';
import 'package:modudi/models/book_models.dart'; // Added for Book
import '../../domain/entities/category_entity.dart'; // Added for CategoryEntity
import '../../domain/entities/video_entity.dart'; // Added for VideoEntity
// import '../repositories/home_repository_impl.dart'; // Temporarily remove direct impl usage

// Provider for the ArchiveApiService instance (REMOVED)
// final archiveApiServiceProvider = Provider<ArchiveApiService>((ref) {
//   return ArchiveApiService(); // Create a single instance
// });

// Provider for the HomeRepository implementation
// This will be updated to a Firestore-based implementation later.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  // For now, return a placeholder that throws UnimplementedError
  // This avoids build errors while we refactor HomeRepositoryImpl
  return _UnimplementedHomeRepository();
});

// Placeholder implementation
class _UnimplementedHomeRepository implements HomeRepository {
  @override
  Future<List<Book>> getFeaturedBooks({int perPage = 500}) {
    throw UnimplementedError('getFeaturedBooks not implemented yet');
  }

  @override
  Future<List<CategoryEntity>> getCategories() {
    throw UnimplementedError('getCategories not implemented yet');
  }

  @override
  Future<List<VideoEntity>> getVideoLectures({int perPage = 5}) {
    throw UnimplementedError('getVideoLectures not implemented yet');
  }
} 