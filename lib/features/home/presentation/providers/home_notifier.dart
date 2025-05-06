import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/providers/home_data_providers.dart'; 
import '../../domain/repositories/home_repository.dart';
import 'package:modudi/models/book_models.dart'; // Use new models
import '../../domain/entities/category_entity.dart'; 
import '../../domain/entities/video_entity.dart'; 
import '../../../library/providers/library_books_provider.dart'; 
import '../../../library/models/library_state.dart'; // Import updated LibraryState
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
      final baseCategories = results[1] as List<CategoryEntity>;
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

      // Calculate category counts from allLibraryBooks (List<BookModel>)
      final Map<String, int> categoryCounts = {};
      for (final book in allLibraryBooks) {
        if (book.tags != null) {
          for (String categoryId in book.tags!) {
             // Normalize category IDs for comparison
            String normalizedCategoryId = categoryId.toLowerCase().replaceAll('_', ' '); // Example normalization
            
            // Check against baseCategories
            bool categoryMatched = false;
            for (final baseCategory in baseCategories) {
              String normalizedBaseId = baseCategory.id.toLowerCase().replaceAll('_', ' ');
              if (normalizedCategoryId == normalizedBaseId) {
                 categoryCounts[baseCategory.id] = (categoryCounts[baseCategory.id] ?? 0) + 1;
                 categoryMatched = true;
                 break; // Count only once per book even if it matches multiple ways
              }
            }
            // Optional: Handle categories in books that are not in baseCategories?
          }
        }
      }

      // Update category entities with accurate counts
      final updatedCategories = baseCategories.map((category) {
        return category.copyWith(count: categoryCounts[category.id] ?? 0);
      }).toList();

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