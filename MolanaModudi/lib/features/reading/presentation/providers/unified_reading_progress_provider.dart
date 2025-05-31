import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/reading_tab_screen.dart';
import '../services/unified_reading_progress_service.dart';

/// Provider for the unified reading progress service
final unifiedReadingProgressServiceProvider = Provider<UnifiedReadingProgressService>((ref) {
  return unifiedReadingProgressService;
});

/// Provider for recent books using the unified service
final unifiedRecentBooksProvider = FutureProvider<List<RecentBook>>((ref) async {
  final service = ref.read(unifiedReadingProgressServiceProvider);
  return await service.getRecentBooks();
});

/// Provider for live progress updates stream
final liveProgressUpdatesProvider = StreamProvider<ReadingProgressUpdate>((ref) {
  final service = ref.read(unifiedReadingProgressServiceProvider);
  return service.progressUpdates;
});

/// Provider for specific book's live progress
final bookLiveProgressProvider = FutureProvider.family<double, String>((ref, bookId) async {
  final service = ref.read(unifiedReadingProgressServiceProvider);
  return await service.getLiveProgress(bookId);
});

/// Provider for triggering manual refresh of recent books
final refreshRecentBooksProvider = StateProvider<int>((ref) => 0);

/// Enhanced recent books provider that auto-refreshes when progress updates occur
final autoRefreshRecentBooksProvider = StreamProvider<List<RecentBook>>((ref) async* {
  final service = ref.read(unifiedReadingProgressServiceProvider);
  
  // Initial load
  yield await service.getRecentBooks();
  
  // Listen to progress updates and refresh when books are updated
  await for (final _ in service.progressUpdates) {
    // Small delay to ensure persistence is complete
    await Future.delayed(const Duration(milliseconds: 100));
    yield await service.getRecentBooks();
  }
});

/// Provider to check if a reading session is active
final readingSessionActiveProvider = StateProvider<bool>((ref) => false); 