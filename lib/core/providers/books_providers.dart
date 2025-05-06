import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/models/book_models.dart';
import 'package:modudi/core/repositories/books_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modudi/features/home/presentation/providers/home_notifier.dart';
import 'package:modudi/features/home/presentation/providers/home_state.dart';

/// Provider for the books repository
final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  return BooksRepositoryImpl(firestore: FirebaseFirestore.instance);
});

/// Provider for fetching a single book by ID
final bookProvider = FutureProvider.family<Book?, String>((ref, bookId) async {
  final repository = ref.watch(booksRepositoryProvider);
  return repository.getBook(bookId);
});

/// Provider for fetching all books
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(booksRepositoryProvider);
  return repository.getBooks();
});

/// Provider for fetching books by category
final booksByCategoryProvider = FutureProvider.family<List<Book>, String>((ref, category) async {
  final repository = ref.watch(booksRepositoryProvider);
  return repository.getBooks(category: category);
});

/// Provider for fetching headings of a book
final bookHeadingsProvider = FutureProvider.family<List<Heading>, String>((ref, bookId) async {
  final repository = ref.watch(booksRepositoryProvider);
  return repository.getBookHeadings(bookId);
});

/// Provider for searching books by title
final bookSearchProvider = StateNotifierProvider<BookSearchNotifier, AsyncValue<List<Book>>>((ref) {
  final repository = ref.watch(booksRepositoryProvider);
  return BookSearchNotifier(repository);
});

/// Provider for getting all categories with their counts
final categoriesProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(booksRepositoryProvider);
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
  final BooksRepository _repository;
  
  BookSearchNotifier(this._repository) : super(const AsyncValue.data([]));
  
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final results = await _repository.searchBooks(query);
      state = AsyncValue.data(results);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
} 