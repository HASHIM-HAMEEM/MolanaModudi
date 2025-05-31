import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/repositories/books_repository.dart'; // Corrected import path
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'package:modudi/features/reading/data/reading_repository_provider.dart'; // Import for readingRepositoryProvider
import 'book_detail_state.dart';
import 'package:modudi/features/reading/presentation/providers/reading_state.dart';
import 'package:modudi/core/providers/books_providers.dart'; // Import for the global booksRepositoryProvider
import 'package:modudi/core/cache/models/cache_result.dart'; // Import for CacheResult and CacheStatus

// StateNotifier for Book Detail logic
class BookDetailNotifier extends StateNotifier<BookDetailState> {
  final AsyncValue<BooksRepository> _booksRepositoryAsyncValue;
  final AsyncValue<ReadingRepository> _readingRepositoryAsyncValue; // For AI features and reading state
  final String _bookId;
  final _log = Logger('BookDetailNotifier');

  BookDetailNotifier(this._booksRepositoryAsyncValue, this._readingRepositoryAsyncValue, this._bookId) 
    : super(const BookDetailState()) {
      loadBookDetails(); // Load details when notifier is created
    }

  Future<void> loadBookDetails() async {
    if (state.status == BookDetailStatus.loading) return; // Prevent concurrent loads

    state = state.copyWith(status: BookDetailStatus.loading, clearError: true);
    _log.info('Loading details for book ID: $_bookId...');

    // Use the AsyncValue.when pattern for safer and cleaner repository access
    await _booksRepositoryAsyncValue.when(
      data: (booksRepo) async {
        try {
          final bookCacheResult = await booksRepo.getBook(_bookId);

          if (bookCacheResult.hasData && bookCacheResult.data != null) {
            // Successfully got book data
            _log.info('Successfully loaded book: ${bookCacheResult.data!.title} (Status: ${bookCacheResult.status})');
            // Determine BookDetailStatus based on CacheStatus
            BookDetailStatus detailStatus;
            switch (bookCacheResult.status) {
              case CacheStatus.fresh:
                detailStatus = BookDetailStatus.success;
                break;
              case CacheStatus.stale:
                // Treat stale as success for now, UI might indicate staleness if needed
                detailStatus = BookDetailStatus.success;
                _log.info('Book data for $_bookId is stale, background refresh might be happening.');
                break;
              default:
                // For loading, error, missing if they somehow slip through hasData check (should not happen for .hasData)
                detailStatus = BookDetailStatus.success; // Default to success if data is present
            }
            state = state.copyWith(
              status: detailStatus,
              bookDetail: bookCacheResult.data,
              errorMessage: null, // Clear previous error
            );
          } else if (bookCacheResult.status == CacheStatus.error) {
            // Error reported by CacheResult
            _log.severe('Failed to load book details for $_bookId. CacheResult error: ${bookCacheResult.error}');
            state = state.copyWith(
              status: BookDetailStatus.error,
              errorMessage: bookCacheResult.error?.toString() ?? 'Unknown cache error',
              bookDetail: null, // Ensure bookDetail is cleared on error
            );
          } else {
            // Book not found (e.g., status is missing, or data is null without specific error)
            _log.warning('Book not found or data missing for $_bookId. Status: ${bookCacheResult.status}');
            state = state.copyWith(
              status: BookDetailStatus.error, // Or a specific 'notFound' status if BookDetailStatus supports it
              errorMessage: 'Book not found.',
              bookDetail: null, // Ensure bookDetail is cleared
            );
          }
        } catch (e, stackTrace) {
          _log.severe('Exception while loading book details for $_bookId', e, stackTrace);
          state = state.copyWith(
            status: BookDetailStatus.error,
            errorMessage: e.toString(),
            bookDetail: null, // Ensure bookDetail is cleared on exception
          );
        }
      },
      loading: () {
        // Repository is loading, state is already BookDetailStatus.loading
        _log.info('Repository is still loading, waiting...');
      },
      error: (error, stackTrace) {
        _log.severe('BooksRepository is in error state', error, stackTrace);
        state = state.copyWith(
          status: BookDetailStatus.error,
          errorMessage: 'Book service unavailable: ${error.toString()}',
        );
      },
    );
  }
  
  // --- AI Details Fetching ---
  Future<void> fetchAiEnhancedDetails() async {
    if (state.aiDetailsStatus == AiFeatureStatus.loading) return;
    
    _log.info('Fetching AI enhanced details for $_bookId');
    state = state.copyWith(aiDetailsStatus: AiFeatureStatus.loading, errorMessage: null);
    
    // Use the AsyncValue.when pattern for safer and cleaner repository access
    await _readingRepositoryAsyncValue.when(
      data: (readingRepo) async {
        try {
          // Validate book details exist
          if (state.bookDetail == null) {
            throw Exception('Book details not available. Please load book details first.');
          }
          
          // Determine text for analysis (use description or title)
          String textToAnalyze = state.bookDetail?.description ?? state.bookDetail?.title ?? _bookId;
          // Limit length
          textToAnalyze = textToAnalyze.length > 5000 ? textToAnalyze.substring(0, 5000) : textToAnalyze;
          
          // Add more logging for debugging
          _log.info('Analyzing text (length: ${textToAnalyze.length}) for book: ${state.bookDetail?.title}');
          
          // Fetch Summary & Themes
          final summaryData = await readingRepo.generateBookSummary(
            textToAnalyze,
            bookTitle: state.bookDetail?.title ?? _bookId,
            author: state.bookDetail?.author ?? 'Unknown',
            language: state.bookDetail?.defaultLanguage ?? 'en', 
          );
          
          _log.info('Successfully generated summary for book: ${state.bookDetail?.title}');
          
          // Fetch Recommendations
          List<String> history = [state.bookDetail?.title ?? _bookId]; // Simple history
          final recommendations = await readingRepo.getBookRecommendations(history);
          
          state = state.copyWith(
            aiSummaryData: summaryData,
            aiRecommendations: recommendations,
            aiDetailsStatus: AiFeatureStatus.success,
            errorMessage: null, // Clear any previous errors
          );
          _log.info('Successfully fetched AI enhanced details');
          
        } catch (e, stackTrace) {
          _log.severe('Failed to fetch AI enhanced details for $_bookId', e, stackTrace);
          
          // Extract meaningful error message for display
          String errorMessage;
          if (e.toString().contains('API key')) {
            errorMessage = 'Invalid or missing API key for the AI service.';
          } else if (e.toString().contains('timed out') || e.toString().contains('timeout')) {
            errorMessage = 'Connection timed out. Please check your internet connection and try again.';
          } else if (e.toString().contains('404')) {
            errorMessage = 'AI model not found. The model may have been updated or deprecated.';
          } else if (e.toString().contains('rate limit') || e.toString().contains('429')) {
            errorMessage = 'Rate limit exceeded. Please wait a moment and try again.';
          } else {
            errorMessage = 'Failed to analyze book: ${e.toString().split('\n')[0]}';
          }
          
          state = state.copyWith(
            aiDetailsStatus: AiFeatureStatus.error,
            errorMessage: errorMessage,
          );
        }
      },
      loading: () {
        // Repository is loading, state is already AiFeatureStatus.loading
        _log.info('Reading repository is still loading, waiting...');
      },
      error: (error, stackTrace) {
        _log.severe('ReadingRepository is in error state', error, stackTrace);
        state = state.copyWith(
          aiDetailsStatus: AiFeatureStatus.error,
          errorMessage: 'AI service unavailable: ${error.toString()}',
        );
      },
    );
  }
  
  // Reset AI details state
  void resetAiDetails() {
    _log.info('Resetting AI details state');
    state = state.copyWith(
      aiDetailsStatus: AiFeatureStatus.initial,
      aiSummaryData: null,
      aiRecommendations: null,
      errorMessage: null,
    );
  }
  
  // Add a retry method for convenience
  void retry() {
    loadBookDetails();
  }
}

// Provider for the BookDetailNotifier
// Using family with autoDispose to prevent memory leaks
final bookDetailNotifierProvider = 
  StateNotifierProvider.autoDispose.family<BookDetailNotifier, BookDetailState, String>((ref, bookId) {
  final booksRepository = ref.watch(booksRepositoryProvider);
  final readingRepo = ref.watch(readingRepositoryProvider);
  return BookDetailNotifier(booksRepository, readingRepo, bookId);
});