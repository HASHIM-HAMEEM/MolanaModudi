import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/cache/cache_service.dart';

final splashProvider = StateNotifierProvider<SplashNotifier, SplashState>((ref) {
  return SplashNotifier(ref);
});

class SplashState {
  final double progress;
  final String currentTask;
  final bool isCompleted;
  final String? error;

  const SplashState({
    this.progress = 0.0,
    this.currentTask = '',
    this.isCompleted = false,
    this.error,
  });

  SplashState copyWith({
    double? progress,
    String? currentTask,
    bool? isCompleted,
    String? error,
  }) {
    return SplashState(
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
    );
  }
}

class SplashNotifier extends StateNotifier<SplashState> {
  static final Logger _log = Logger('SplashNotifier');

  SplashNotifier(Ref ref) : super(const SplashState());

  /// Helper method to reset splash preferences (for testing/debugging)
  static Future<void> resetSplashPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_first_launch');
    await prefs.remove('app_last_data_update');
    Logger('SplashNotifier').info('Splash preferences reset - next app launch will show splash');
  }

  Future<void> preloadEssentialData() async {
    try {
      _log.info('Starting essential data preloading...');
      
      // Total tasks for progress calculation
      const totalTasks = 6;
      int completedTasks = 0;

      // Task 1: Initialize cache service
      state = state.copyWith(
        currentTask: 'کیش سروس شروع کی جا رہی ہے...',
        progress: completedTasks / totalTasks,
      );
      
      await _initializeCacheService();
      completedTasks++;
      
      // Task 2: Load essential books data
      state = state.copyWith(
        currentTask: 'کتابوں کی فہرست لوڈ ہو رہی ہے...',
        progress: completedTasks / totalTasks,
      );
      
      await _preloadBooksData();
      completedTasks++;

      // Task 3: Load home screen data
      state = state.copyWith(
        currentTask: 'ہوم سکرین ڈیٹا لوڈ ہو رہا ہے...',
        progress: completedTasks / totalTasks,
      );
      
      await _preloadHomeData();
      completedTasks++;

      // Task 4: Load video playlists
      state = state.copyWith(
        currentTask: 'ویڈیو پلے لسٹ لوڈ ہو رہی ہے...',
        progress: completedTasks / totalTasks,
      );
      
      await _preloadVideoData();
      completedTasks++;

      // Task 5: Preload images and thumbnails
      state = state.copyWith(
        currentTask: 'امیجز اور تھمبنیلز لوڈ ہو رہے ہیں...',
        progress: completedTasks / totalTasks,
      );
      
      await _preloadImages();
      completedTasks++;

      // Task 6: Finalize preloading
      state = state.copyWith(
        currentTask: 'فائنلائز کیا جا رہا ہے...',
        progress: completedTasks / totalTasks,
      );
      
      await _finalizePreloading();
      completedTasks++;

      // Complete
      state = state.copyWith(
        currentTask: 'مکمل!',
        progress: 1.0,
        isCompleted: true,
      );

      _log.info('Essential data preloading completed successfully');

    } catch (e, stackTrace) {
      _log.severe('Error during data preloading: $e', e, stackTrace);
      state = state.copyWith(
        error: e.toString(),
        currentTask: 'خرابی ہوئی ہے...',
        isCompleted: true, // Still complete to proceed with the app
      );
    }
  }

  Future<void> _initializeCacheService() async {
    try {
      // Initialize CacheService properly
      await CacheService.init();
      await Future.delayed(const Duration(milliseconds: 500)); // Visual feedback time
      _log.fine('Cache service initialized');
    } catch (e) {
      _log.warning('Error initializing cache service: $e');
      // Continue anyway as this is not critical - fallback to simulation
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _preloadBooksData() async {
    try {
      // Simulate book data preloading
      _log.fine('Simulating books data preloading...');
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate processing time
      _log.fine('Books data preloading simulation complete');
    } catch (e) {
      _log.warning('Error preloading books data: $e');
      // Continue anyway - books will load when needed
    }
  }

  Future<void> _preloadHomeData() async {
    try {
      // Simulate home data preloading
      _log.fine('Simulating home data preloading...');
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate processing time
      _log.fine('Home data preloading simulation complete');
    } catch (e) {
      _log.warning('Error preloading home data: $e');
      // Continue anyway
    }
  }

  Future<void> _preloadVideoData() async {
    try {
      // Simulate video data preloading
      _log.fine('Simulating video playlists preloading...');
      await Future.delayed(const Duration(milliseconds: 700)); // Simulate processing time
      _log.fine('Video data preloading simulation complete');
    } catch (e) {
      _log.warning('Error preloading video data: $e');
      // Continue anyway
    }
  }

  Future<void> _preloadImages() async {
    try {
      // Try to get cache service, fallback to simulation if not available
      try {
        final cacheService = CacheService.instance;
        
        // List of essential images to preload (these would be actual URLs in production)
        final essentialImages = [
          // Author portrait placeholder
          'https://example.com/author-portrait.jpg',
          // App icon/logo
          'https://example.com/app-logo.png',
          // Default book cover
          'https://example.com/default-book-cover.jpg',
        ];

        // Preload essential images
        int imagesPreloaded = 0;
        for (final imageUrl in essentialImages) {
          try {
            await cacheService.getImage(imageUrl);
            imagesPreloaded++;
          } catch (e) {
            _log.fine('Could not preload image $imageUrl: $e');
            // Continue with other images
          }
        }
        
        _log.fine('Preloaded $imagesPreloaded/${essentialImages.length} essential images');
      } catch (e) {
        _log.warning('CacheService not available for image preloading, simulating: $e');
        // Fallback to simulation
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      _log.warning('Error preloading images: $e');
      // Continue anyway
    }
  }

  Future<void> _finalizePreloading() async {
    try {
      // Perform any final cleanup or initialization
      try {
        final cacheService = CacheService.instance;
        
        // Get cache statistics for logging
        final cacheStats = await cacheService.getCacheSizeStats();
        _log.info('Cache statistics after preloading: $cacheStats');
        
        // Clean up any stale cache entries
        // (This is optional and runs in background)
        // await cacheService.clearExpiredCaches();
      } catch (e) {
        _log.warning('CacheService not available for finalization, continuing: $e');
      }
      
      await Future.delayed(const Duration(milliseconds: 300)); // Final processing time
      _log.fine('Preloading finalized successfully');
    } catch (e) {
      _log.warning('Error finalizing preloading: $e');
      // Continue anyway
    }
  }

  void reset() {
    state = const SplashState();
  }
} 