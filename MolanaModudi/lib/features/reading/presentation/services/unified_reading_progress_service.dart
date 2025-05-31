import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../screens/reading_tab_screen.dart';
import '../../../books/data/models/book_models.dart';
import '../providers/live_reading_progress_provider.dart';

/// Unified service for managing reading progress and recent books
/// Handles both chapter-level and book-level progress tracking
/// Automatically updates recent books list from reading sessions
class UnifiedReadingProgressService {
  static final UnifiedReadingProgressService _instance = UnifiedReadingProgressService._internal();
  factory UnifiedReadingProgressService() => _instance;
  UnifiedReadingProgressService._internal();

  final Logger _log = Logger('UnifiedReadingProgressService');
  SharedPreferences? _prefs;
  Timer? _saveTimer;
  Timer? _sessionTimer;
  
  // Reading session tracking
  String? _currentBookId;
  String? _currentBookTitle;
  String? _currentAuthor;
  String? _currentCoverUrl;
  DateTime? _sessionStartTime;
  double _sessionStartProgress = 0.0;
  double _lastSavedProgress = 0.0;
  int _currentChapter = 0;
  int _totalChapters = 0;
  
  // Progress update streams
  final StreamController<ReadingProgressUpdate> _progressController = 
      StreamController<ReadingProgressUpdate>.broadcast();
  
  Stream<ReadingProgressUpdate> get progressUpdates => _progressController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _log.info('UnifiedReadingProgressService initialized');
  }

  /// Start a reading session for a book
  Future<void> startReadingSession({
    required String bookId,
    required String bookTitle,
    String? author,
    String? coverUrl,
    int currentChapter = 0,
    int totalChapters = 0,
    double initialProgress = 0.0,
  }) async {
    await initialize();
    
    _currentBookId = bookId;
    _currentBookTitle = bookTitle;
    _currentAuthor = author;
    _currentCoverUrl = coverUrl;
    _sessionStartTime = DateTime.now();
    _sessionStartProgress = initialProgress;
    _lastSavedProgress = initialProgress;
    _currentChapter = currentChapter;
    _totalChapters = totalChapters;
    
    _log.info('Started reading session for: $bookTitle (Chapter $currentChapter/$totalChapters, Progress: ${(initialProgress * 100).toInt()}%)');
    
    // Load existing progress
    await _loadExistingProgress();
    
    // Start session monitoring
    _startSessionMonitoring();
  }

  /// Update reading progress (called frequently during reading)
  Future<void> updateProgress({
    required double scrollProgress,
    int? currentChapter,
    String? currentChapterTitle,
    String? currentHeadingId,
    WidgetRef? ref,
  }) async {
    if (_currentBookId == null) return;
    
    // Update current progress
    if (currentChapter != null) _currentChapter = currentChapter;
    
    // Calculate book-level progress from chapter and scroll position
    final bookProgress = _calculateBookProgress(scrollProgress);
    
    // Create progress update
    final update = ReadingProgressUpdate(
      bookId: _currentBookId!,
      bookTitle: _currentBookTitle!,
      chapterProgress: scrollProgress,
      bookProgress: bookProgress,
      currentChapter: _currentChapter,
      totalChapters: _totalChapters,
      currentChapterTitle: currentChapterTitle,
      currentHeadingId: currentHeadingId,
      timestamp: DateTime.now(),
    );
    
    // Update live reading progress provider if ref is available
    if (ref != null) {
      try {
        ref.read(liveReadingProgressProvider(_currentBookId!).notifier).setProgress(bookProgress);
      } catch (e) {
        _log.warning('Failed to update live reading progress provider: $e');
      }
    }
    
    // Broadcast update for real-time UI
    _progressController.add(update);
    
    // Debounced save to avoid performance issues
    _debouncedSave(update);
  }

  /// Calculate overall book progress from chapter and scroll position
  double _calculateBookProgress(double scrollProgress) {
    if (_totalChapters <= 0) return scrollProgress;
    
    // Book progress = (completed chapters + current chapter progress) / total chapters
    final completedChapters = _currentChapter;
    final currentChapterProgress = scrollProgress;
    final overallProgress = (completedChapters + currentChapterProgress) / _totalChapters;
    
    return overallProgress.clamp(0.0, 1.0);
  }

  /// Debounced save to prevent excessive I/O operations
  void _debouncedSave(ReadingProgressUpdate update) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      await _persistProgress(update);
    });
  }

  /// Persist progress to storage
  Future<void> _persistProgress(ReadingProgressUpdate update) async {
    if (_prefs == null) return;
    
    try {
      // Save fine-grained live progress using BOOK progress (not chapter progress)
      final liveProgressData = {
        'scrollPosition': update.bookProgress, // Use bookProgress instead of chapterProgress
        'lastUpdated': update.timestamp.toIso8601String(),
      };
      await _prefs!.setString('live_progress_${update.bookId}', jsonEncode(liveProgressData));
      
      // Save chapter-based progress
      final chapterProgressData = {
        'bookId': update.bookId,
        'bookTitle': update.bookTitle,
        'currentChapter': update.currentChapter,
        'totalChapters': update.totalChapters,
        'percentage': (update.bookProgress * 100).round(),
        'lastReadTimestamp': update.timestamp.toIso8601String(),
        'fineGrainPercentage': update.chapterProgress,
        'currentChapterTitle': update.currentChapterTitle,
        'currentHeadingId': update.currentHeadingId,
      };
      await _prefs!.setString('reading_progress_${update.bookId}', jsonEncode(chapterProgressData));
      
      _lastSavedProgress = update.bookProgress;
      _log.fine('Persisted progress for ${update.bookTitle}: ${(update.bookProgress * 100).toInt()}%');
      
      // Update recent books if significant progress made
      await _updateRecentBooksIfNeeded(update);
      
    } catch (e, stackTrace) {
      _log.warning('Error persisting reading progress: $e', e, stackTrace);
    }
  }

  /// Update recent books list when meaningful progress is made
  Future<void> _updateRecentBooksIfNeeded(ReadingProgressUpdate update) async {
    try {
      // Only update if progress has increased significantly (at least 1% or changed chapter)
      final progressDiff = update.bookProgress - _sessionStartProgress;
      final shouldUpdate = progressDiff >= 0.01 || 
                          update.currentChapter != _currentChapter ||
                          DateTime.now().difference(_sessionStartTime ?? DateTime.now()).inMinutes >= 1;
      
      if (!shouldUpdate) return;
      
      await _addToRecentBooks(
        bookId: update.bookId,
        title: update.bookTitle,
        author: _currentAuthor,
        coverUrl: _currentCoverUrl,
        progress: update.bookProgress,
        currentChapter: update.currentChapter,
        totalChapters: update.totalChapters,
      );
      
    } catch (e) {
      _log.warning('Error updating recent books: $e');
    }
  }

  /// Add or update book in recent books list
  Future<void> _addToRecentBooks({
    required String bookId,
    required String title,
    String? author,
    String? coverUrl,
    required double progress,
    int currentChapter = 0,
    int totalChapters = 0,
  }) async {
    if (_prefs == null) return;
    
    try {
      final recentBooksJson = _prefs!.getStringList('recentBooks') ?? [];
      
      // Create new book entry
      final newBook = {
        'id': bookId,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'progress': progress,
        'lastReadTime': DateTime.now().millisecondsSinceEpoch,
        'currentPage': currentChapter,
        'totalPages': totalChapters,
      };
      
      // Remove existing entry for this book
      final updatedList = recentBooksJson.where((item) {
        try {
          final Map<String, dynamic> data = json.decode(item);
          return data['id'] != bookId;
        } catch (e) {
          return true; // Keep malformed entries for now
        }
      }).toList();
      
      // Add new entry at the beginning
      updatedList.insert(0, json.encode(newBook));
      
      // Keep only last 20 books
      if (updatedList.length > 20) {
        updatedList.removeRange(20, updatedList.length);
      }
      
      await _prefs!.setStringList('recentBooks', updatedList);
      
      _log.info('Updated recent books: $title (${(progress * 100).toInt()}% progress)');
      
    } catch (e, stackTrace) {
      _log.severe('Error adding to recent books: $e', e, stackTrace);
    }
  }

  /// End current reading session
  Future<void> endReadingSession() async {
    if (_currentBookId == null || _sessionStartTime == null) return;
    
    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    final progressMade = _lastSavedProgress - _sessionStartProgress;
    
    _log.info('Ended reading session for: $_currentBookTitle (Duration: ${sessionDuration.inMinutes}min, Progress: +${(progressMade * 100).toInt()}%)');
    
    // Force final save
    _saveTimer?.cancel();
    if (_currentBookId != null) {
      final finalUpdate = ReadingProgressUpdate(
        bookId: _currentBookId!,
        bookTitle: _currentBookTitle!,
        chapterProgress: _lastSavedProgress,
        bookProgress: _lastSavedProgress,
        currentChapter: _currentChapter,
        totalChapters: _totalChapters,
        timestamp: DateTime.now(),
      );
      await _persistProgress(finalUpdate);
    }
    
    // Clear session
    _clearSession();
  }

  /// Load existing progress for current book
  Future<void> _loadExistingProgress() async {
    if (_prefs == null || _currentBookId == null) return;
    
    try {
      final progressString = _prefs!.getString('reading_progress_$_currentBookId');
      if (progressString != null) {
        final progressData = json.decode(progressString);
        _currentChapter = progressData['currentChapter'] ?? 0;
        _totalChapters = progressData['totalChapters'] ?? 0;
        final fineGrainProgress = progressData['fineGrainPercentage'] ?? 0.0;
        _sessionStartProgress = fineGrainProgress;
        _lastSavedProgress = fineGrainProgress;
        
        _log.info('Loaded existing progress for $_currentBookTitle: Chapter $_currentChapter/$_totalChapters, ${(fineGrainProgress * 100).toInt()}%');
      }
    } catch (e) {
      _log.warning('Error loading existing progress: $e');
    }
  }

  /// Start monitoring reading session
  void _startSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_currentBookId != null) {
        _log.fine('Reading session active: $_currentBookTitle (${DateTime.now().difference(_sessionStartTime!).inMinutes}min)');
      }
    });
  }

  /// Clear current session
  void _clearSession() {
    _currentBookId = null;
    _currentBookTitle = null;
    _currentAuthor = null;
    _currentCoverUrl = null;
    _sessionStartTime = null;
    _sessionStartProgress = 0.0;
    _lastSavedProgress = 0.0;
    _currentChapter = 0;
    _totalChapters = 0;
    _sessionTimer?.cancel();
    _saveTimer?.cancel();
  }

  /// Get recent books (for reading tab)
  Future<List<RecentBook>> getRecentBooks() async {
    await initialize();
    
    final recentBooksJson = _prefs!.getStringList('recentBooks') ?? [];
    final List<RecentBook> books = [];
    
    for (final bookJson in recentBooksJson) {
      try {
        final Map<String, dynamic> bookData = json.decode(bookJson);
        books.add(RecentBook.fromJson(bookData));
      } catch (e) {
        _log.warning('Failed to parse recent book: $e');
      }
    }
    
    books.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
    return books;
  }

  /// Get live progress for a specific book
  Future<double> getLiveProgress(String bookId) async {
    await initialize();
    
    try {
      // First try to get from live_progress
      final progressString = _prefs!.getString('live_progress_$bookId');
      if (progressString != null) {
        final progressData = json.decode(progressString);
        if (progressData is Map<String, dynamic> && progressData.containsKey('scrollPosition')) {
          return (progressData['scrollPosition'] as num?)?.toDouble() ?? 0.0;
        } else if (progressData is double) {
          return progressData;
        }
      }
      
      // Fallback: try to get from reading_progress if live_progress doesn't exist
      final readingProgressString = _prefs!.getString('reading_progress_$bookId');
      if (readingProgressString != null) {
        final readingProgressData = json.decode(readingProgressString);
        if (readingProgressData is Map<String, dynamic>) {
          // Calculate book progress from chapter-based data
          final currentChapter = readingProgressData['currentChapter'] ?? 0;
          final totalChapters = readingProgressData['totalChapters'] ?? 1;
          final fineGrainProgress = readingProgressData['fineGrainPercentage'] ?? 0.0;
          
          if (totalChapters > 0) {
            final bookProgress = (currentChapter + fineGrainProgress) / totalChapters;
            return bookProgress.clamp(0.0, 1.0);
          }
        }
      }
    } catch (e) {
      _log.warning('Error getting live progress for $bookId: $e');
    }
    
    return 0.0;
  }

  /// Clear all reading progress (for debugging/reset)
  Future<void> clearAllProgress() async {
    await initialize();
    
    final keys = _prefs!.getKeys();
    final progressKeys = keys.where((key) => 
        key.startsWith('live_progress_') || 
        key.startsWith('reading_progress_')).toList();
    
    for (final key in progressKeys) {
      await _prefs!.remove(key);
    }
    
    await _prefs!.remove('recentBooks');
    _log.info('Cleared all reading progress');
  }

  /// Refresh live progress data for all books from stored reading progress
  Future<void> refreshAllLiveProgress() async {
    await initialize();
    
    try {
      final keys = _prefs!.getKeys();
      final readingProgressKeys = keys.where((key) => key.startsWith('reading_progress_')).toList();
      
      for (final key in readingProgressKeys) {
        final bookId = key.substring('reading_progress_'.length);
        final progressString = _prefs!.getString(key);
        
        if (progressString != null) {
          final progressData = json.decode(progressString);
          if (progressData is Map<String, dynamic>) {
            final currentChapter = progressData['currentChapter'] ?? 0;
            final totalChapters = progressData['totalChapters'] ?? 1;
            final fineGrainProgress = progressData['fineGrainPercentage'] ?? 0.0;
            
            if (totalChapters > 0) {
              final bookProgress = (currentChapter + fineGrainProgress) / totalChapters;
              final clampedProgress = bookProgress.clamp(0.0, 1.0);
              
              // Update live progress with calculated book progress
              final liveProgressData = {
                'scrollPosition': clampedProgress,
                'lastUpdated': DateTime.now().toIso8601String(),
              };
              await _prefs!.setString('live_progress_$bookId', jsonEncode(liveProgressData));
              
              _log.info('Refreshed live progress for book $bookId: ${(clampedProgress * 100).toInt()}%');
            }
          }
        }
      }
      
      _log.info('Completed refreshing live progress for all books');
    } catch (e, stackTrace) {
      _log.warning('Error refreshing live progress: $e', stackTrace);
    }
  }

  /// Dispose resources
  void dispose() {
    _saveTimer?.cancel();
    _sessionTimer?.cancel();
    _progressController.close();
  }
}

/// Progress update data class
class ReadingProgressUpdate {
  final String bookId;
  final String bookTitle;
  final double chapterProgress; // 0.0 to 1.0 for current chapter
  final double bookProgress; // 0.0 to 1.0 for entire book
  final int currentChapter;
  final int totalChapters;
  final String? currentChapterTitle;
  final String? currentHeadingId;
  final DateTime timestamp;

  ReadingProgressUpdate({
    required this.bookId,
    required this.bookTitle,
    required this.chapterProgress,
    required this.bookProgress,
    required this.currentChapter,
    required this.totalChapters,
    this.currentChapterTitle,
    this.currentHeadingId,
    required this.timestamp,
  });
}

/// Global instance
final unifiedReadingProgressService = UnifiedReadingProgressService(); 