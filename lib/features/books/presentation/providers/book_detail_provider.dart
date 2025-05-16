import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// import 'package:modudi/core/services/api_service.dart'; // Needed for repository provider - REMOVED
import 'package:modudi/features/books/data/repositories/book_detail_repository_impl.dart';
import 'package:modudi/features/books/domain/repositories/book_detail_repository.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart'; // Import Reading Repository
import 'package:modudi/features/reading/presentation/providers/reading_provider.dart'; // Import Reading Repository Provider
// import '../../../home/data/providers/home_data_providers.dart'; // archiveApiServiceProvider was here, no longer needed for this context
import 'book_detail_state.dart';
import 'package:modudi/features/reading/presentation/providers/reading_state.dart'; // Import AI Status

// Provider for BookDetailRepository
final bookDetailRepositoryProvider = Provider<BookDetailRepository>((ref) {
  // final apiService = ref.watch(archiveApiServiceProvider); // Reuse provider from core - REMOVED
  final readingRepository = ref.watch(readingRepositoryProvider); // Get reading repository
  return BookDetailRepositoryImpl(
    // apiService: apiService, // REMOVED
    readingRepository: readingRepository,
  );
});

// StateNotifier for Book Detail logic
class BookDetailNotifier extends StateNotifier<BookDetailState> {
  final BookDetailRepository _repository;
  final ReadingRepository _readingRepository; // Add Reading Repository for AI calls
  final String _bookId;
  final _log = Logger('BookDetailNotifier');

  BookDetailNotifier(this._repository, this._readingRepository, this._bookId) 
    : super(const BookDetailState()) {
      loadBookDetails(); // Load details when notifier is created
    }

  Future<void> loadBookDetails() async {
    if (state.status == BookDetailStatus.loading) return; // Prevent concurrent loads

    state = state.copyWith(status: BookDetailStatus.loading, clearError: true);
    _log.info('Loading details for book ID: $_bookId...');

    try {
      final details = await _repository.getBookDetails(_bookId);
      
      // Check if details has description field with an error message
      if (details.description?.startsWith('Error loading book details:') == true) {
        _log.warning('Book details returned with error description: ${details.description}');
        state = state.copyWith(
          status: BookDetailStatus.success, // Still mark as success to display partial details
          bookDetail: details,
          errorMessage: details.description, // Store error for UI feedback if needed
        );
      } else {
        _log.info('Successfully loaded details for book: ${details.title}');
        state = state.copyWith(
          status: BookDetailStatus.success,
          bookDetail: details,
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to load book details for $_bookId', e, stackTrace);
      state = state.copyWith(
        status: BookDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  // --- AI Details Fetching ---
  Future<void> fetchAiEnhancedDetails() async {
    if (state.aiDetailsStatus == AiFeatureStatus.loading) return;
    
    _log.info('Fetching AI enhanced details for $_bookId');
    state = state.copyWith(aiDetailsStatus: AiFeatureStatus.loading, errorMessage: null);
    
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
      final summaryData = await _readingRepository.generateBookSummary(
        textToAnalyze,
        bookTitle: state.bookDetail?.title ?? _bookId,
        author: state.bookDetail?.author ?? 'Unknown',
        language: state.bookDetail?.language, 
      );
      
      _log.info('Successfully generated summary for book: ${state.bookDetail?.title}');
      
      // Fetch Recommendations
      List<String> history = [state.bookDetail?.title ?? _bookId]; // Simple history
      final recommendations = await _readingRepository.getBookRecommendations(history);
      
      state = state.copyWith(
        aiSummaryData: summaryData,
        aiRecommendations: recommendations,
        aiDetailsStatus: AiFeatureStatus.ready,
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
  }
  // --- End AI Details Fetching ---
  
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
// Using family to pass the bookId
final bookDetailNotifierProvider = 
  StateNotifierProvider.family<BookDetailNotifier, BookDetailState, String>((ref, bookId) {
    final repository = ref.watch(bookDetailRepositoryProvider);
    final readingRepository = ref.watch(readingRepositoryProvider); // Watch reading repository
    return BookDetailNotifier(repository, readingRepository, bookId);
}); 