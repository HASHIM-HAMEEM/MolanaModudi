import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/books_providers.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/core/repositories/books_repository.dart';
import 'package:modudi/core/utils/app_logger.dart';

// Provider that fetches the list of books for the library
final libraryBooksProvider = FutureProvider<List<Book>>((ref) async {
  final logger = AppLogger.getLogger('LibraryProvider');
  final booksRepoAsyncValue = ref.watch(booksRepositoryProvider);
  
  // Properly handle the AsyncValue outside of the return statement
  if (booksRepoAsyncValue is AsyncLoading) {
    logger.info('Books repository is loading');
    return <Book>[];
  } else if (booksRepoAsyncValue is AsyncError) {
    final error = booksRepoAsyncValue.error;
    final stack = booksRepoAsyncValue.stackTrace;
    logger.severe('Error accessing books repository', error, stack);
    return <Book>[];
  } else if (booksRepoAsyncValue is AsyncData<BooksRepository>) {
    // We now have access to the repository safely
    final repository = booksRepoAsyncValue.value;
    try {
      // Fetch a larger number of books for the library view
      return await repository.getBooks();
    } catch (e, stack) {
      logger.severe('Failed to fetch books for library', e, stack);
      return <Book>[];
    }
  }
  
  // Fallback case (should not reach here, but just in case)
  return <Book>[];
});