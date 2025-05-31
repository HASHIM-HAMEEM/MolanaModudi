import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../providers/reading_state.dart';
import '../../../providers/reading_provider.dart';

/// Performance-optimized reading content manager
class ReadingPerformanceManager {
  static final Map<String, ReadingState> _contentCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);
  static const int _maxCacheSize = 10; // Limit memory usage
  static final _log = Logger('ReadingPerformanceManager');

  /// Get cached reading state if available
  static ReadingState? getCached(String bookId) {
    final timestamp = _cacheTimestamps[bookId];
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _log.info('Reading cache expired for book: $bookId');
      _removeFromCache(bookId);
      return null;
    }
    
    return _contentCache[bookId];
  }

  /// Cache reading state with memory management
  static void setCached(String bookId, ReadingState state) {
    // Implement LRU eviction if cache is full
    if (_contentCache.length >= _maxCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _removeFromCache(oldestKey);
      _log.info('Evicted oldest cache entry: $oldestKey');
    }
    
    _contentCache[bookId] = state;
    _cacheTimestamps[bookId] = DateTime.now();
    _log.info('Cached reading state: $bookId (${_contentCache.length}/$_maxCacheSize)');
  }

  /// Remove from cache
  static void _removeFromCache(String bookId) {
    _contentCache.remove(bookId);
    _cacheTimestamps.remove(bookId);
  }

  /// Clear all cache
  static void clearAll() {
    _contentCache.clear();
    _cacheTimestamps.clear();
    _log.info('Cleared all reading cache');
  }

  /// Get memory usage statistics
  static Map<String, dynamic> getMemoryStats() {
    final totalStates = _contentCache.length;
    final estimatedMemoryKB = totalStates * 50; // Rough estimate
    
    return {
      'cachedBooks': totalStates,
      'maxCacheSize': _maxCacheSize,
      'estimatedMemoryKB': estimatedMemoryKB,
      'cacheKeys': _contentCache.keys.toList(),
    };
  }
}

/// Performance-optimized content chunking for large books
class ContentChunkManager {
  static const int _chunkSize = 1000; // Characters per chunk
  static final Map<String, List<String>> _chunkCache = {};
  static final _log = Logger('ContentChunkManager');

  /// Split content into performance-optimized chunks
  static List<String> getChunks(String bookId, String content) {
    // Check cache first
    if (_chunkCache.containsKey(bookId)) {
      return _chunkCache[bookId]!;
    }

    final stopwatch = Stopwatch()..start();
    
    final chunks = <String>[];
    for (int i = 0; i < content.length; i += _chunkSize) {
      final end = (i + _chunkSize).clamp(0, content.length);
      chunks.add(content.substring(i, end));
    }
    
    stopwatch.stop();
    _log.info('Content chunked in ${stopwatch.elapsedMilliseconds}ms: ${chunks.length} chunks for book $bookId');
    
    // Cache the chunks
    _chunkCache[bookId] = chunks;
    
    return chunks;
  }

  /// Get specific chunk for lazy loading
  static String? getChunk(String bookId, int index) {
    final chunks = _chunkCache[bookId];
    if (chunks == null || index >= chunks.length) return null;
    return chunks[index];
  }

  /// Clear chunk cache for memory management
  static void clearChunks(String bookId) {
    _chunkCache.remove(bookId);
    _log.info('Cleared chunks for book: $bookId');
  }
}

/// Performance-optimized reading notifier
class ReadingPerformanceNotifier extends StateNotifier<AsyncValue<ReadingState>> {
  final String bookId;
  final Ref ref;
  final _log = Logger('ReadingPerformanceNotifier');
  
  Timer? _performanceTimer;
  Timer? _memoryCleanupTimer;
  int _performanceMetrics = 0;

  ReadingPerformanceNotifier(this.bookId, this.ref) : super(const AsyncValue.loading()) {
    _initializePerformanceTracking();
    _loadOptimizedContent();
  }

  void _initializePerformanceTracking() {
    // Track performance metrics
    _performanceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performanceMetrics++;
      _log.info('Performance check #$_performanceMetrics for book: $bookId');
      _logMemoryStats();
    });

    // Memory cleanup timer
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performMemoryCleanup();
    });
  }

  Future<void> _loadOptimizedContent() async {
    try {
      _log.info('Loading optimized content for book: $bookId');
      final stopwatch = Stopwatch()..start();

      // Check cache first
      final cached = ReadingPerformanceManager.getCached(bookId);
      if (cached != null) {
        state = AsyncValue.data(cached);
        stopwatch.stop();
        _log.info('Served from cache in ${stopwatch.elapsedMilliseconds}ms');
        return;
      }

      // Load from original provider with performance monitoring
      final originalNotifier = ref.read(readingNotifierProvider(bookId).notifier);
      await originalNotifier.loadContent();
      
      final originalState = ref.read(readingNotifierProvider(bookId));
      
      // Simple direct state copy - no .when() needed since readingNotifierProvider returns ReadingState directly
      final optimizedState = _optimizeReadingState(originalState);
      
      // Cache the optimized state
      ReadingPerformanceManager.setCached(bookId, optimizedState);
      
      state = AsyncValue.data(optimizedState);
      stopwatch.stop();
      _log.info('Optimized content loaded in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      _log.severe('Error loading optimized content: $e', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Optimize reading state for performance
  ReadingState _optimizeReadingState(ReadingState original) {
    final stopwatch = Stopwatch()..start();
    
    // TODO: Implement state optimization logic
    // For now, return the original state
    // In a real implementation, you would:
    // 1. Chunk large content
    // 2. Optimize heading structures
    // 3. Precompute frequently accessed data
    // 4. Compress or eliminate redundant data
    
    stopwatch.stop();
    _log.info('State optimization completed in ${stopwatch.elapsedMilliseconds}ms');
    
    return original;
  }

  /// Navigate to chapter with performance optimization
  Future<void> navigateToChapterOptimized(int chapterIndex) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    _log.info('Optimized navigation to chapter: $chapterIndex');
    final stopwatch = Stopwatch()..start();

    try {
      // Use the original provider for navigation but with performance tracking
      final originalNotifier = ref.read(readingNotifierProvider(bookId).notifier);
      originalNotifier.navigateToLogicalChapter(chapterIndex);
      
      // Update our optimized state by getting the new state directly
      final newOriginalState = ref.read(readingNotifierProvider(bookId));
      final optimizedState = _optimizeReadingState(newOriginalState);
      ReadingPerformanceManager.setCached(bookId, optimizedState);
      state = AsyncValue.data(optimizedState);

      stopwatch.stop();
      _log.info('Optimized navigation completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      _log.warning('Error in optimized navigation: $e');
      rethrow;
    }
  }

  void _performMemoryCleanup() {
    final stats = ReadingPerformanceManager.getMemoryStats();
    _log.info('Memory cleanup: ${stats['estimatedMemoryKB']}KB used');
    
    // Clean up chunks for memory optimization
    ContentChunkManager.clearChunks(bookId);
  }

  void _logMemoryStats() {
    final stats = ReadingPerformanceManager.getMemoryStats();
    _log.info('Memory stats: $stats');
  }

  /// Preload next chapter for smoother navigation
  Future<void> preloadNextChapter() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final nextChapterIndex = currentState.currentChapter + 1;
    final totalChapters = currentState.mainChapterKeys?.length ?? 0;
    
    if (nextChapterIndex < totalChapters) {
      _log.info('Preloading next chapter: $nextChapterIndex');
      // TODO: Implement preloading logic
    }
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    _memoryCleanupTimer?.cancel();
    super.dispose();
  }
}

/// Performance provider factory
final readingPerformanceProvider = StateNotifierProvider.family<ReadingPerformanceNotifier, AsyncValue<ReadingState>, String>(
  (ref, bookId) => ReadingPerformanceNotifier(bookId, ref),
);

/// Memory stats provider for debugging
final readingMemoryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ReadingPerformanceManager.getMemoryStats();
}); 