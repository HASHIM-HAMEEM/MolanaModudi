import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/providers/providers.dart'; // for cacheServiceProvider
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/favorites/providers/favorites_provider.dart'; // to interact with existing favorites
import 'package:modudi/core/cache/config/cache_constants.dart'; // For CacheConstants

// Logging
import 'package:logging/logging.dart';

final _log = Logger('BookActionsNotifier');

class BookActionsState {
  final bool isFavorite;
  final bool isPinned;
  final bool isLoading; // Not directly used in AsyncNotifier state, but can be for UI
  final String? errorMessage;

  const BookActionsState({
    this.isFavorite = false,
    this.isPinned = false,
    this.isLoading = false, // isLoading is implicitly handled by AsyncValue states
    this.errorMessage,
  });

  BookActionsState copyWith({
    bool? isFavorite,
    bool? isPinned,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookActionsState(
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class BookActionsNotifier extends FamilyAsyncNotifier<BookActionsState, String> {
  // bookId is the family parameter (arg)
  // String get bookId => arg; // 'arg' is automatically available

  Future<CacheService> _getCacheService() async {
    return ref.read(cacheServiceProvider.future);
  }

  @override
  Future<BookActionsState> build(String bookId) async {
    // arg is bookId
    // Watch favoritesProvider for changes
    final favoriteBooks = ref.watch(favoritesProvider);
    final isFavorite = favoriteBooks.any((favBook) => favBook.firestoreDocId == bookId);
    
    bool isPinnedStatus = false;
    String? pinCheckError;
    try {
      final cacheService = await _getCacheService();
      final bookCacheKey = CacheConstants.bookKeyPrefix + bookId; 
      isPinnedStatus = await cacheService.isItemPinned(bookCacheKey);
    } catch (e, stackTrace) {
      _log.severe('Error checking pinned status for $bookId: $e', e, stackTrace);
      pinCheckError = e.toString();
      // Default to false, error will be part of the state if needed
    }
    return BookActionsState(
      isFavorite: isFavorite, 
      isPinned: isPinnedStatus,
      errorMessage: pinCheckError
    );
  }

  Future<void> toggleFavorite(Book book) async {
    // The build method will automatically re-run due to ref.watch(favoritesProvider)
    // when favoritesProvider changes.
    // We just need to call the action on favoritesProvider.
    // The loading/error state will be managed by this AsyncNotifier if toggleFavorite itself is slow,
    // but here it's mostly reflecting another provider's change.
    
    // No direct state update here needed like "state = AsyncLoading()",
    // as the favorite change is external and build() will pick it up.
    // If toggleFavorite itself could fail independently:
    // state = const AsyncLoading(); // Indicate this specific action is loading
    try {
      await ref.read(favoritesProvider.notifier).toggleFavorite(book);
      // Re-fetch self to ensure state is updated if direct watch doesn't cover it fast enough
      // or if there were other dependent calculations in build.
      // However, since build watches favoritesProvider, this should be automatic.
      // Forcing a re-evaluation of isPinned as well, in case it's related or for consistency.
      ref.invalidateSelf(); 
      await future; // Ensure the invalidation and rebuild completes.
    } catch (e, stackTrace) {
       _log.severe('Error toggling favorite for ${book.firestoreDocId}: $e', e, stackTrace);
       state = AsyncError(e, stackTrace); // Set error state for this provider
    }
  }

  Future<void> togglePin() async {
    // Use 'arg' for bookId
    final bookId = arg;
    final currentData = state.valueOrNull;
    if (currentData == null) {
        _log.warning('Cannot toggle pin, current state is null for book $bookId');
        return; // Or handle error appropriately
    }

    state = const AsyncLoading(); // Set loading state for this operation

    final cacheService = await _getCacheService();
    final bookCacheKey = CacheConstants.bookKeyPrefix + bookId;
    // This boxName must match where the main book data is stored by ReadingRepositoryImpl
    // Based on ReadingRepositoryImpl.getBookData, it uses CacheConstants.booksBoxName
    const String boxName = CacheConstants.booksBoxName; 

    try {
      if (currentData.isPinned) {
        await cacheService.unpinItem(bookCacheKey, boxName);
      } else {
        // Ensure item is in cache before pinning (CacheService.pinItem should ideally handle this check or fail gracefully)
        // For now, we assume it's available if we are trying to pin it from book detail.
        await cacheService.pinItem(bookCacheKey, boxName);
      }
      // After action, invalidate self to re-run build and get updated pin status.
      ref.invalidateSelf();
      await future; // ensure rebuild completes
    } catch (e, stackTrace) {
      _log.severe('Error toggling pin for $bookId: $e', e, stackTrace);
      // Restore previous data on error if possible, or just set error
      state = AsyncError(e, stackTrace);
    }
  }
}

final bookActionsProvider = AsyncNotifierProvider.family<BookActionsNotifier, BookActionsState, String>(
  BookActionsNotifier.new,
); 