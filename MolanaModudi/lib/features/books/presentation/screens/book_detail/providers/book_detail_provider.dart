import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

// Fix import paths to existing working models
import '../../../../../reading/data/reading_repository_provider.dart';
import '../../../../data/models/book_models.dart';
import '../../../../../../core/cache/models/cache_result.dart';
import '../../../../../favorites/providers/favorites_provider.dart';

/// Simple state model for book detail data - avoiding Freezed for now
class BookDetailState {
  final Book book;
  final bool isBookPinned;
  final bool isFavorite;

  const BookDetailState({
    required this.book,
    this.isBookPinned = false,
    this.isFavorite = false,
  });

  BookDetailState copyWith({
    Book? book,
    bool? isBookPinned,
    bool? isFavorite,
  }) {
    return BookDetailState(
      book: book ?? this.book,
      isBookPinned: isBookPinned ?? this.isBookPinned,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Business logic provider for BookDetail - extracted from monolithic widget
class BookDetailNotifier extends FamilyAsyncNotifier<BookDetailState, String> {
  final _log = Logger('BookDetailNotifier');

  @override
  Future<BookDetailState> build(String bookId) async {
    _log.info('Loading book detail for: $bookId');
    
    try {
      final readingRepo = await ref.read(readingRepositoryProvider.future);
      final CacheResult<Book> cacheResult = await readingRepo.getBookData(bookId);
      
      if (cacheResult.hasData && cacheResult.data != null) {
        _log.info('Loaded book: ${cacheResult.data!.title} from ${cacheResult.status.name}');
        
        // Initialize pin and favorite status
        final pinStatus = await _loadPinStatus(bookId);
        final favoriteStatus = await _loadFavoriteStatus(bookId);
        
        return BookDetailState(
          book: cacheResult.data!,
          isBookPinned: pinStatus,
          isFavorite: favoriteStatus,
        );
      } else {
        throw Exception(cacheResult.error?.toString() ?? 'Failed to load book details');
      }
    } catch (e, stackTrace) {
      _log.severe('Error loading book details: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle pin status with optimistic updates
  Future<void> togglePin() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    _log.info('Toggling pin status for book: ${currentState.book.id}');
    
    // Optimistic update
    state = AsyncData(currentState.copyWith(
      isBookPinned: !currentState.isBookPinned,
    ));
    
    try {
      // TODO: Implement actual pin persistence
      await _persistPinStatus(currentState.book.id.toString(), !currentState.isBookPinned);
      HapticFeedback.lightImpact();
    } catch (e) {
      _log.warning('Error toggling pin: $e');
      // Revert optimistic update
      state = AsyncData(currentState);
      rethrow;
    }
  }

  /// Toggle favorite status with optimistic updates
  Future<void> toggleFavorite() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    _log.info('Toggling favorite status for book: ${currentState.book.id}');
    
    try {
      // Use the actual favorites provider to toggle the favorite status
      await ref.read(favoritesProvider.notifier).toggleFavorite(currentState.book);
      
      // Refresh the state to reflect the change
      ref.invalidateSelf();
      await future; // Wait for the refresh to complete
      
      HapticFeedback.lightImpact();
    } catch (e) {
      _log.warning('Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Share book with robust fallback handling
  Future<void> shareBook() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final book = currentState.book;
    _log.info('Sharing book: ${book.title}');

    try {
      HapticFeedback.mediumImpact();
      
      final shareText = '''Check out "${book.title}" by ${book.author ?? 'Unknown Author'} on the Maulana Maududi app!

${book.description != null && book.description!.isNotEmpty 
  ? '${book.description!.substring(0, book.description!.length > 100 ? 100 : book.description!.length)}...' 
  : 'A great book to explore!'}

Download the app to read more.''';

      try {
        await Share.share(shareText);
        _log.info('Successfully shared book via native share sheet');
      } catch (e) {
        _log.warning('Native sharing failed, using clipboard fallback: $e');
        await Clipboard.setData(ClipboardData(text: shareText));
        // TODO: Show snackbar feedback via ref.read(snackbarProvider.notifier)
        _log.info('Book details copied to clipboard for sharing');
      }
    } catch (e) {
      _log.warning('Error sharing book: $e');
      rethrow;
    }
  }

  /// Load pin status from persistence layer
  Future<bool> _loadPinStatus(String bookId) async {
    try {
      // TODO: Implement actual pin status loading
      // For now, return default
      return false;
    } catch (e) {
      _log.warning('Error loading pin status: $e');
      return false;
    }
  }

  /// Load favorite status from persistence layer
  Future<bool> _loadFavoriteStatus(String bookId) async {
    try {
      // Check if this book is in the favorites provider
      final favorites = ref.read(favoritesProvider);
      return favorites.any((book) => book.firestoreDocId == bookId);
    } catch (e) {
      _log.warning('Error loading favorite status: $e');
      return false;
    }
  }

  /// Persist pin status
  Future<void> _persistPinStatus(String bookId, bool isPinned) async {
    // TODO: Implement pin persistence to local storage/cache
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async work
  }
}

/// Provider factory for book detail with family support
final bookDetailProvider = AsyncNotifierProvider.family<BookDetailNotifier, BookDetailState, String>(
  () => BookDetailNotifier(),
); 