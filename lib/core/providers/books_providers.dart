import 'dart:async'; // Required for FutureOr
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
// import 'package:modudi/core/repositories/books_repository.dart'; // No longer needed
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart'; // Import consolidated repo
import 'package:modudi/features/reading/data/repositories/reading_repository_impl.dart'; // Import impl for provider
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modudi/features/home/presentation/providers/home_notifier.dart'; // Keep for featuredBooksProvider if still relevant
import 'package:modudi/features/home/presentation/providers/home_state.dart'; // Keep for featuredBooksProvider
import 'package:modudi/core/providers/providers.dart'; // For geminiServiceProvider and cacheServiceProvider

// Using centralized cacheServiceProvider from core/providers/providers.dart

/// Provider for the consolidated repository
final consolidatedBookRepoProvider = FutureProvider<ReadingRepository>((ref) async {
  final geminiService = ref.watch(geminiServiceProvider);
  final cacheService = await ref.watch(cacheServiceProvider.future);
  return ReadingRepositoryImpl(
    geminiService: geminiService,
    cacheService: cacheService,
    firestore: FirebaseFirestore.instance,
  );
});

/// Provider for fetching a single book by ID
final bookProvider = FutureProvider.family<Book, String>((ref, bookId) async {
  final repository = await ref.watch(consolidatedBookRepoProvider.future);
  // Assuming getBookData returns non-nullable Book and handles errors internally or throws
  return repository.getBookData(bookId);
});

/// Provider for fetching all books
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = await ref.watch(consolidatedBookRepoProvider.future);
  return repository.getBooks();
});

/// Provider for fetching all books, potentially for a global list or less frequent updates
/// This seems redundant if booksProvider serves the same purpose.
/// Consider removing if it's identical to booksProvider.
/// For now, updating it as well.
final allBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = await ref.watch(consolidatedBookRepoProvider.future);
  return repository.getBooks(); // Using getBooks without parameters
});

/// Provider for fetching books by category
final booksByCategoryProvider = FutureProvider.family<List<Book>, String>((ref, category) async {
  final repository = await ref.watch(consolidatedBookRepoProvider.future);
  return repository.getBooks(category: category);
});

/// Provider for fetching headings of a book
final bookHeadingsProvider = FutureProvider.family<List<Heading>, String>((ref, bookId) async {
  final repository = await ref.watch(consolidatedBookRepoProvider.future);
  return repository.getBookHeadings(bookId);
});

/// Provider for getting all categories with their counts
final categoriesProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = await ref.watch(consolidatedBookRepoProvider.future);
  return repository.getCategories();
});

/// Provider for featured books
/// This provider depends on homeNotifierProvider. Ensure homeNotifierProvider is updated
/// if it previously relied on the old BooksRepository.
/// Assuming homeNotifierProvider fetches featured books and stores them in its state.
final featuredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final homeState = ref.watch(homeNotifierProvider);
  
  if (homeState.status == HomeStatus.success) {
    // Assuming homeState.featuredBooks is populated correctly by homeNotifierProvider
    // homeNotifierProvider itself might need to use consolidatedBookRepoProvider.getFeaturedBooks()
    return AsyncValue.data(homeState.featuredBooks);
  }
  if (homeState.status == HomeStatus.error) {
    return AsyncValue.error(homeState.errorMessage ?? 'Unknown error', StackTrace.current);
  }
  return const AsyncValue.loading();
});


/// Notifier for book search using AsyncNotifier
class BookSearchNotifier extends AsyncNotifier<List<Book>> {
  @override
  FutureOr<List<Book>> build() => []; // Initial state is an empty list

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    // No need to check for mounted here as AsyncNotifier handles it.
    
    // Fetch the repository
    // Note: It's generally better to fetch services like repositories directly in methods 
    // rather than storing them as instance variables in AsyncNotifiers if their lifecycle 
    // is managed by other providers (like consolidatedBookRepoProvider).
    try {
      final repository = await ref.watch(consolidatedBookRepoProvider.future);
      final results = await repository.searchBooks(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

/// Provider for book search notifier
final bookSearchNotifierProvider = AsyncNotifierProvider<BookSearchNotifier, List<Book>>(() {
  return BookSearchNotifier();
});

/// Provider for fetching the book structure (volumes, chapters, headings)
final bookStructureProvider = FutureProvider.family<BookStructure, String>((ref, bookId) async {
  final repository = await ref.watch(consolidatedBookRepoProvider.future);
  return repository.getBookStructure(bookId);
});

// Ensure BookStructure is imported
// This might already be covered if ReadingRepository import brings it transitively,
// but explicit import is safer.
import 'package:modudi/features/reading/domain/entities/book_structure.dart';