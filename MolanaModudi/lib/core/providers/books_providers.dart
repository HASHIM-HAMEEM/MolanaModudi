import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/core/cache/models/cache_result.dart'; // Added import for CacheResult
import 'package:modudi/core/repositories/books_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modudi/features/home/presentation/providers/home_notifier.dart';
import 'package:modudi/features/home/presentation/providers/home_state.dart';
import 'package:modudi/core/providers/providers.dart';

// Using centralized cacheServiceProvider from core/providers/providers.dart

/// Provider for the books repository
final booksRepositoryProvider = FutureProvider<BooksRepository>((ref) async {
  final cacheService = await ref.watch(cacheServiceProvider.future);
  return BooksRepositoryImpl(
    cacheService: cacheService,
    firestore: FirebaseFirestore.instance
  );
});

/// Provider for fetching a single book by ID
final bookProvider = FutureProvider.family<CacheResult<Book?>, String>((ref, bookId) async {
  final repository = await ref.watch(booksRepositoryProvider.future);
  return repository.getBook(bookId);
});

/// Provider for fetching all books
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = await ref.watch(booksRepositoryProvider.future);
  return repository.getBooks();
});

/// Provider for fetching all books, potentially for a global list or less frequent updates
final allBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = await ref.watch(booksRepositoryProvider.future);
  return repository.getBooks();
});

/// Provider for fetching books by category
final booksByCategoryProvider = FutureProvider.family<List<Book>, String>((ref, category) async {
  final repository = await ref.watch(booksRepositoryProvider.future);
  return repository.getBooks(category: category);
});

/// Provider for fetching headings of a book
final bookHeadingsProvider = FutureProvider.family<List<Heading>, String>((ref, bookId) async {
  final repository = await ref.watch(booksRepositoryProvider.future);
  return repository.getBookHeadings(bookId);
});

/// Provider for searching books by title
final bookSearchProvider = StateNotifierProvider<BookSearchNotifier, AsyncValue<List<Book>>>((ref) {
  final repository = ref.watch(booksRepositoryProvider);
  return BookSearchNotifier(repository);
});

/// Provider for getting all categories with their counts
final categoriesProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = await ref.watch(booksRepositoryProvider.future);
  return repository.getCategories();
});

/// Provider for featured books
final featuredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final homeState = ref.watch(homeNotifierProvider);
  
  if (homeState.status == HomeStatus.success) {
    return AsyncValue.data(homeState.featuredBooks);
  }
  if (homeState.status == HomeStatus.error) {
    return AsyncValue.error(homeState.errorMessage ?? 'Unknown error', StackTrace.current);
  }
  return const AsyncValue.loading();
});

/// Notifier for book search
class BookSearchNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final AsyncValue<BooksRepository> _repositoryAsyncValue;
  
  BookSearchNotifier(this._repositoryAsyncValue) : super(const AsyncValue.data([]));
  
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }
    
    if (mounted) state = const AsyncValue.loading();

    final AsyncValue<BooksRepository> currentRepoAsyncValue = _repositoryAsyncValue;

    if (currentRepoAsyncValue.isLoading) {
      // Repository is loading. State is already AsyncValue.loading().
      return;
    }

    if (currentRepoAsyncValue.hasError) {
      if (mounted) state = AsyncValue.error(currentRepoAsyncValue.error!, currentRepoAsyncValue.stackTrace ?? StackTrace.current);
      return;
    }

    // currentRepoAsyncValue has data
    final BooksRepository repo = currentRepoAsyncValue.value!;
    
    try {
      final results = await repo.searchBooks(query);
      if (mounted) state = AsyncValue.data(results);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
  
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
} 