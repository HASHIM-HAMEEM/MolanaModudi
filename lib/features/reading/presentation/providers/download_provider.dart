import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/reading/data/repositories/reading_repository_impl.dart';

/// StreamProvider that exposes the download progress stream
/// Returns a map where keys are book IDs and values are download progress percentages (0-100)
final downloadProgressStreamProvider = StreamProvider<Map<String, double>>((ref) {
  // Use AsyncValue.when pattern to safely access the repository
  return ref.watch(readingRepositoryProvider).when(
    data: (repository) {
      // Explicitly ensure we return Map<String, double> by mapping the values
      return repository.getDownloadProgressStream().map((progress) {
        // Create a new Map<String, double> to ensure correct typing
        final Map<String, double> typedProgress = {};
        progress.forEach((key, value) {
          // Ensure the value is double
          typedProgress[key] = value.toDouble();
        });
        return typedProgress;
      });
    },
    loading: () => Stream.value(<String, double>{}), // Empty map when loading
    error: (error, stackTrace) {
      // Log error and return empty stream
      print('Error accessing repository for download progress: $error');
      return Stream.value(<String, double>{});
    },
  );
});

/// Provider that exposes the list of downloaded book IDs
final downloadedBooksProvider = FutureProvider<List<String>>((ref) {
  // Use AsyncValue.when pattern to safely access the repository
  return ref.watch(readingRepositoryProvider).when(
    data: (repository) => repository.getDownloadedBookIds(),
    loading: () => Future.value(<String>[]), // Empty list when loading
    error: (error, stackTrace) {
      // Log error and return empty list
      print('Error accessing repository for downloaded books: $error');
      return Future.value(<String>[]);
    },
  );
});

/// Provider to check if a specific book is available offline
final isBookAvailableOfflineProvider = FutureProvider.family<bool, String>((ref, bookId) {
  // Use AsyncValue.when pattern to safely access the repository
  return ref.watch(readingRepositoryProvider).when(
    data: (repository) => repository.isBookAvailableOffline(bookId),
    loading: () => Future.value(false), // Default to false when loading
    error: (error, stackTrace) {
      // Log error and return false
      print('Error checking if book $bookId is available offline: $error');
      return Future.value(false);
    },
  );
});
