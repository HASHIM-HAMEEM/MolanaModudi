import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// Remove if BookCollections is no longer the source for featured books
// import 'package:modudi/config/book_collections.dart'; 
// Remove ArchiveApiService if not used for books anymore
// import 'package:modudi/core/services/api_service.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
// import 'package:modudi/core/models/book_model.dart'; // Use the core BookModel
import 'package:modudi/models/book_models.dart'; // Use the new Book model
// Remove BookEntity from home feature if BookModel from core is sufficient
// import 'package:modudi/features/home/domain/entities/book_entity.dart';
import 'package:modudi/features/library/models/library_state.dart';

// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Define the provider that will expose the LibraryBooksNotifier
final libraryBooksProvider = StateNotifierProvider<LibraryBooksNotifier, LibraryState>((ref) {
  // final apiService = ref.watch(apiServiceProvider); // Keep if apiService is used for other things
  final firestore = ref.watch(firestoreProvider);
  return LibraryBooksNotifier(firestore /*, apiService (if still needed) */);
});

// Provider for the API service (keep if used for non-book data, e.g., videos)
// final apiServiceProvider = Provider<ArchiveApiService>((ref) {
//   return ArchiveApiService();
// });

/// Notifier for managing library books state
class LibraryBooksNotifier extends StateNotifier<LibraryState> {
  // final ArchiveApiService _apiService; // Keep if used for other things
  final FirebaseFirestore _firestore;
  final _logger = Logger('LibraryBooksNotifier');
  
  // Languages supported in the library - consider if this should come from Firestore or config
  static const supportedLanguages = ['eng', 'urd', 'ara']; // Example
  static const int booksPerPage = 20; // For pagination

  // LibraryBooksNotifier(this._apiService, this._firestore) : super(const LibraryState.loading()) {
  LibraryBooksNotifier(this._firestore) : super(LibraryLoading()) {
    // Initialize by loading books
    loadBooks();
  }
  
  /// Load books from Firestore
  Future<void> loadBooks({String? languageCode, String? category}) async {
    try {
      _logger.info('Loading library books from Firestore. Language: $languageCode, Category: $category');
      state = LibraryLoading(); // Use LibraryLoading state
      
      Query query = _firestore.collection('books'); // Your root collection for books

      if (languageCode != null && languageCode.toLowerCase() != 'all') {
        query = query.where('language', isEqualTo: languageCode.toLowerCase());
      }
      if (category != null && category.toLowerCase() != 'all') {
        // Assuming 'categories' is an array field in Firestore
        // Update field name if needed based on new Book model (e.g., 'tags'?)
        // query = query.where('categories', arrayContains: category); 
        query = query.where('tags', arrayContains: category); // Assuming tags replace categories for filtering
      }
      
      // Add ordering, e.g., by title or a timestamp field if you have one
      query = query.orderBy('title').limit(booksPerPage); 

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _logger.info('No books found in Firestore for the given criteria.');
        // Use LibraryStateData with empty list
        state = LibraryStateData(books: [], lastUpdated: DateTime.now(), lastDocument: null);
        return;
      }
      
      final books = snapshot.docs.map((doc) {
        // Use the new Book.fromMap factory
        return Book.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      _logger.info('Loaded ${books.length} books from Firestore.');
      // Use LibraryStateData
      state = LibraryStateData(books: books, lastUpdated: DateTime.now(), lastDocument: lastDoc);

    } catch (e, stackTrace) {
      _logger.severe('Failed to load library books from Firestore', e, stackTrace);
      state = LibraryStateError(e.toString()); // Use LibraryStateError
    }
  }

  Future<void> loadMoreBooks({String? languageCode, String? category}) async {
    // Use pattern matching or `is` check for type safety
    final currentState = state;
    if (currentState is! LibraryStateData || currentState.lastDocument == null) {
      _logger.info('Cannot load more books, not in data state or no last document.');
      return; 
    }

    if (currentState.isLoadingMore) {
      _logger.info('Already loading more books.');
      return;
    }

    _logger.info('Loading more library books from Firestore.');
    state = currentState.copyWith(isLoadingMore: true); // Use copyWith on LibraryStateData

    try {
      Query query = _firestore.collection('books');

      if (languageCode != null && languageCode.toLowerCase() != 'all') {
        query = query.where('language', isEqualTo: languageCode.toLowerCase());
      }
      if (category != null && category.toLowerCase() != 'all') {
        // query = query.where('categories', arrayContains: category);
        query = query.where('tags', arrayContains: category); // Assuming tags replace categories
      }
      
      query = query.orderBy('title').startAfterDocument(currentState.lastDocument!).limit(booksPerPage);

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _logger.info('No more books found in Firestore.');
        // Use copyWith, explicitly set lastDocument to null to indicate end
        state = currentState.copyWith(isLoadingMore: false, lastDocument: null); 
        return;
      }

      final newBooks = snapshot.docs.map((doc) {
        // Use the new Book.fromMap factory
        return Book.fromMap(doc.id, doc.data() as Map<String, dynamic>); 
      }).toList();
      
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      
      // Use copyWith to update existing data state
      state = currentState.copyWith(
        books: [...currentState.books, ...newBooks], 
        lastUpdated: DateTime.now(),
        lastDocument: lastDoc,
        isLoadingMore: false,
      );
      _logger.info('Loaded ${newBooks.length} more books. Total: ${(currentState.books.length + newBooks.length)}');

    } catch (e, stackTrace) {
      _logger.severe('Failed to load more library books from Firestore', e, stackTrace);
      // Use copyWith to add error to the existing data state
      state = currentState.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
  
  /// Refresh all books from Firestore
  Future<void> refreshBooks({String? languageCode, String? category}) async {
    _logger.info('Refreshing all books from Firestore.');
    await loadBooks(languageCode: languageCode, category: category);
  }

  // Example for getBooksByCategory adapted to new state structure
  List<Book> getBooksByCategory(String categoryId) {
    // Use maybeWhen extension or `is` check
    final currentState = state;
    // Correctly check the type and use the maybeWhen extension if preferred, or stick to the `is` check
    // Using the maybeWhen extension:
    return currentState.maybeWhen(
      // Ensure the signature matches all parameters of LibraryStateData 
      // even if some are not used (use underscores)
      data: (books, _lastUpdated, _lastDoc, _isLoadingMore, _error) { 
        List<Book> filteredBooks = [];
        for (final Book book in books) { // Iterate directly over Book
          // Assuming tags replace categories
          // if (categoryId.toLowerCase() == 'all' || (book.categories?.any((c) => c.toLowerCase() == categoryId.toLowerCase()) ?? false)) {
          if (categoryId.toLowerCase() == 'all' || (book.tags?.any((tag) => tag.toLowerCase() == categoryId.toLowerCase()) ?? false)) { 
            filteredBooks.add(book);
          }
        }
        return filteredBooks;
      },
      // Provide implementations or fallbacks for other states if needed
      loading: () => [], // Return empty list while loading
      error: (message) => [], // Return empty list on error
      orElse: () => [], // Default fallback
    );
  }
} 