import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/providers/home_data_providers.dart'; 
import '../../domain/repositories/home_repository.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import '../../domain/entities/category_entity.dart'; 
import '../../domain/entities/video_entity.dart'; 
import 'package:modudi/features/books/presentation/providers/library_books_provider.dart'; 
import 'package:modudi/features/books/data/models/library_state.dart';
import '../../domain/services/book_categorization_service.dart';
import 'home_state.dart';

// StateNotifier for Home Screen logic
class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;
  final Ref _ref;
  final _log = Logger('HomeNotifier');

  HomeNotifier(this._repository, this._ref) : super(const HomeState());

  Future<void> loadHomeData() async {
    if (state.status == HomeStatus.loading) return; 

    state = state.copyWith(status: HomeStatus.loading, clearError: true);
    _log.info('Loading home screen data...');

    try {
      // Fetch home data (assuming getFeaturedBooks now uses Firestore or is adapted)
      // TODO: Ensure _repository.getFeaturedBooks returns List<BookModel> or adapt
      final results = await Future.wait([
        _repository.getFeaturedBooks(perPage: 20), 
        _repository.getCategories(),
        _repository.getVideoLectures(perPage: 10),
      ]);

      // Adjust type casting if getFeaturedBooks returns BookModel
      final featuredBooks = results[0] as List<Book>; 
      final videoLectures = results[2] as List<VideoEntity>;

      // Get library books for accurate category counts
      final libraryState = _ref.read(libraryBooksProvider);
      List<Book> allLibraryBooks = [];
      
      // Extract books from library state using the new structure
      if (libraryState is LibraryStateData) {
        allLibraryBooks = libraryState.books;
      } else if (libraryState is LibraryLoading) {
        // Library is loading, maybe wait or show partial counts
        _log.info('Library books are loading, category counts might be incomplete initially.');
      } else if (libraryState is LibraryStateError) {
        _log.warning('Library books failed to load, category counts unavailable.');
      }

      // If library is empty or hasn't loaded, attempt to load
      if (allLibraryBooks.isEmpty && libraryState is! LibraryStateError) {
        _log.info('Library books not loaded, attempting to load them for category counts.');
        await _ref.read(libraryBooksProvider.notifier).loadBooks();
        
        // Try reading the state again
        final updatedLibraryState = _ref.read(libraryBooksProvider);
        if (updatedLibraryState is LibraryStateData) {
          allLibraryBooks = updatedLibraryState.books;
        }
      }

      // Use Gemini API to intelligently categorize books
      List<CategoryEntity> categorizedBooks;
      
      // If we have library books, use them for categorization
      if (allLibraryBooks.isNotEmpty) {
        _log.info('Categorizing ${allLibraryBooks.length} library books');
        categorizedBooks = BookCategorizationService.categorizeBooks(allLibraryBooks);
      } 
      // If no library books but we have featured books, use those
      else if (featuredBooks.isNotEmpty) {
        _log.info('No library books available, categorizing ${featuredBooks.length} featured books');
        categorizedBooks = BookCategorizationService.categorizeBooks(featuredBooks);
      } 
      // If no books at all, create empty categories
      else {
        _log.info('No books available for categorization, using predefined categories');
        // Create empty categories from predefined categories
        categorizedBooks = BookCategorizationService.getPredefinedCategories().map((categoryData) {
          return CategoryEntity(
            id: categoryData['id'] as String,
            name: categoryData['name'] as String,
            description: categoryData['description'] as String,
            displayColor: categoryData['color'] as Color,
            icon: categoryData['icon'] as IconData,
            count: 1, // Minimum count to ensure visibility
          );
        }).toList();
      }
      
      // Sort categories by count (descending)
      categorizedBooks.sort((a, b) => b.count.compareTo(a.count));
      
      // Ensure all categories have at least a minimum count for display
      // This ensures all our categories always show up even if they have no books
      final predefinedCategoryIds = [
        'tafsir', 'islamic_law_social', 'biography', 'political_thought'
      ];
      
      // Check if any predefined category is missing or has zero count
      for (final categoryId in predefinedCategoryIds) {
        final existingCategory = categorizedBooks.where((cat) => cat.id == categoryId).toList();
        if (existingCategory.isEmpty) {
          // Add missing category with a minimum count of 1
          final categoryData = BookCategorizationService.getPredefinedCategories()
              .firstWhere((cat) => cat['id'] == categoryId);
          
          categorizedBooks.add(CategoryEntity(
            id: categoryId,
            name: categoryData['name'] as String,
            description: categoryData['description'] as String,
            displayColor: categoryData['color'] as Color,
            icon: categoryData['icon'] as IconData,
            count: 1, // Minimum count to ensure visibility
          ));
          _log.info('Added missing category: $categoryId with minimum count');
        } else if (existingCategory.first.count == 0) {
          // Update category with zero count to have a minimum count
          final index = categorizedBooks.indexOf(existingCategory.first);
          categorizedBooks[index] = existingCategory.first.copyWith(count: 1);
          _log.info('Updated zero-count category: $categoryId with minimum count');
        }
      }
      
      // Re-sort after adding missing categories
      categorizedBooks.sort((a, b) => b.count.compareTo(a.count));
      
      // We'll show all categories now since we've ensured they all have at least a minimum count
      final updatedCategories = categorizedBooks;
      
      // Log category counts for debugging
      _log.info('Category counts: ${updatedCategories.map((c) => "${c.name}: ${c.count}").join(', ')}');

      _log.info('Home data loaded successfully: ${featuredBooks.length} books, ${updatedCategories.length} categories, ${videoLectures.length} videos.');
      state = state.copyWith(
        status: HomeStatus.success,
        featuredBooks: featuredBooks, // Pass List<Book>
        categories: updatedCategories, 
        videos: videoLectures,
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to load home data', e, stackTrace);
      state = state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

// Provider for the HomeNotifier
final homeNotifierProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository, ref);
});