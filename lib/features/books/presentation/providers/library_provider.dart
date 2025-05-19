import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/books_providers.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:logging/logging.dart';

// Logger for this provider
final _log = Logger('LibraryNotifier');

// StateNotifier for managing the library's book list
class LibraryNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final Ref _ref;
  bool _hasLoadedBooks = false;

  LibraryNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchBooks(); // Initial fetch when the notifier is created
  }

  Future<void> fetchBooks({bool forceRefresh = false}) async {
    // If we already have data and this isn't a forced refresh, return immediately
    if (!forceRefresh && _hasLoadedBooks && state is AsyncData<List<Book>>) {
      _log.info('Using cached book list from LibraryNotifier state');
      return;
    }

    // Set loading state only if we don't already have data or if it's a force refresh
    if (forceRefresh || state is! AsyncData<List<Book>> || !state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      // Assuming booksRepositoryProvider resolves to AsyncValue<BooksRepositoryType>
      // We need to await its future to get the actual repository instance.
      // Correct way for a FutureProvider: read provider.future
      final booksRepository = await _ref.read(booksRepositoryProvider.future);
      // Repository will check cache first
      final books = await booksRepository.getBooks();
      state = AsyncValue.data(books);
      
      if (!_hasLoadedBooks) {
        _hasLoadedBooks = true;
      }
      _log.info('Loaded ${books.length} books from repository');
    } catch (error, stackTrace) {
      _log.severe('Error fetching books: $error\n$stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Provider for the LibraryNotifier
final libraryNotifierProvider = 
    StateNotifierProvider<LibraryNotifier, AsyncValue<List<Book>>>((ref) {
  return LibraryNotifier(ref);
});