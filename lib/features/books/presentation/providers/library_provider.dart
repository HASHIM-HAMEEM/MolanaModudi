import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/books_providers.dart';
import 'package:modudi/features/books/data/models/book_models.dart';

// Provider that fetches the list of books for the library
final libraryBooksProvider = FutureProvider<List<Book>>((ref) async {
  final booksRepository = ref.watch(booksRepositoryProvider);
  // Fetch a larger number of books for the library view
  return await booksRepository.getBooks(); // Fetch books for library
});