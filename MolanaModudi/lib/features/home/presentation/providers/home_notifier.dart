import 'dart:async';
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

// Separate providers for better granular control and reduced rebuilds

// Featured Books Provider - optimized with cache control
final featuredBooksProvider = FutureProvider.family.autoDispose<List<Book>, int>((ref, perPage) async {
  // Keep the provider alive for 5 minutes to prevent unnecessary re-fetching
  final timer = Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());
  
  final repository = ref.watch(homeRepositoryProvider);
  final books = await repository.getFeaturedBooks(perPage: perPage);
  
  Logger('FeaturedBooks').info('Loaded ${books.length} featured books');
  return books;
});

// Video Lectures Provider - simplified without auto-dispose issues
final videoLecturesProvider = FutureProvider.family<List<VideoEntity>, int>((ref, perPage) async {
  final repository = ref.watch(homeRepositoryProvider);
  final videos = await repository.getVideoLectures(perPage: perPage);
  
  Logger('VideoLectures').info('Loaded ${videos.length} video lectures');
  return videos;
});

// Categories Provider - simplified without auto-dispose issues
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final libraryState = ref.watch(libraryBooksProvider);
  
  List<Book> allBooks = [];
      
  // Extract books from library state
      if (libraryState is LibraryStateData) {
    allBooks.addAll(libraryState.books);
  }
  
  // Add featured books if available and library is empty
  if (allBooks.isEmpty) {
    try {
      final featuredBooks = await ref.watch(featuredBooksProvider(20).future);
      allBooks.addAll(featuredBooks);
    } catch (e) {
      Logger('Categories').warning('Failed to load featured books for categorization: $e');
    }
  }
  
      List<CategoryEntity> categorizedBooks;
      
  if (allBooks.isNotEmpty) {
    Logger('Categories').info('Categorizing ${allBooks.length} books');
    categorizedBooks = BookCategorizationService.categorizeBooks(allBooks);
  } else {
    Logger('Categories').info('No books available, using predefined categories');
        categorizedBooks = BookCategorizationService.getPredefinedCategories().map((categoryData) {
          return CategoryEntity(
            id: categoryData['id'] as String,
            name: categoryData['name'] as String,
            description: categoryData['description'] as String,
            displayColor: categoryData['color'] as Color,
            icon: categoryData['icon'] as IconData,
        count: 1,
          );
        }).toList();
      }
      
  // Ensure predefined categories are present
  final predefinedCategoryIds = ['tafsir', 'islamic_law_social', 'biography', 'political_thought'];
      
      for (final categoryId in predefinedCategoryIds) {
        final existingCategory = categorizedBooks.where((cat) => cat.id == categoryId).toList();
        if (existingCategory.isEmpty) {
          final categoryData = BookCategorizationService.getPredefinedCategories()
              .firstWhere((cat) => cat['id'] == categoryId);
          
          categorizedBooks.add(CategoryEntity(
            id: categoryId,
            name: categoryData['name'] as String,
            description: categoryData['description'] as String,
            displayColor: categoryData['color'] as Color,
            icon: categoryData['icon'] as IconData,
        count: 1,
          ));
        } else if (existingCategory.first.count == 0) {
          final index = categorizedBooks.indexOf(existingCategory.first);
          categorizedBooks[index] = existingCategory.first.copyWith(count: 1);
        }
      }
      
      categorizedBooks.sort((a, b) => b.count.compareTo(a.count));
      
  Logger('Categories').info('Generated ${categorizedBooks.length} categories');
  return categorizedBooks;
});

// Optimized Home State Provider - combines data without cascading refreshes
final optimizedHomeStateProvider = FutureProvider<HomeState>((ref) async {
  // Watch all providers and wait for their completion
  final featuredBooks = await ref.watch(featuredBooksProvider(20).future);
  final categories = await ref.watch(categoriesProvider.future);
  final videos = await ref.watch(videoLecturesProvider(10).future);
  
  return HomeState(
    status: HomeStatus.success,
    featuredBooks: featuredBooks,
    categories: categories,
    videos: videos,
  );
});
      
// StateNotifier for Home Screen logic - now lighter and more focused
class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;
  final Ref _ref;
  final _log = Logger('HomeNotifier');

  HomeNotifier(this._repository, this._ref) : super(const HomeState());

  // Simplified load method that invalidates providers for fresh data
  Future<void> loadHomeData({bool forceRefresh = false}) async {
    if (state.status == HomeStatus.loading) return;

    state = state.copyWith(status: HomeStatus.loading, clearError: true);
    _log.info('Loading home screen data...');

    try {
      if (forceRefresh) {
        // Invalidate providers to force fresh data fetch
        _ref.invalidate(featuredBooksProvider);
        _ref.invalidate(videoLecturesProvider);
        _ref.invalidate(categoriesProvider);
      }
      
      // Watch the optimized provider which handles combining data efficiently
      try {
        final homeState = await _ref.read(optimizedHomeStateProvider.future);
        state = homeState;
        _log.info('Home data loaded successfully');
      } catch (error, stackTrace) {
        _log.severe('Failed to load home data', error, stackTrace);
      state = state.copyWith(
          status: HomeStatus.error,
          errorMessage: error.toString(),
      );
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to load home data', e, stackTrace);
      state = state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Method to refresh specific data types without affecting others
  Future<void> refreshFeaturedBooks() async {
    _ref.invalidate(featuredBooksProvider);
  }
  
  Future<void> refreshVideos() async {
    _ref.invalidate(videoLecturesProvider);
  }
  
  Future<void> refreshCategories() async {
    _ref.invalidate(categoriesProvider);
  }
}

// Provider for the HomeNotifier
final homeNotifierProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository, ref);
});