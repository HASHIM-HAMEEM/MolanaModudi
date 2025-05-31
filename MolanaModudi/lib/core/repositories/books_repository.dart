import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/core/cache/models/cache_result.dart'; // Added import
import 'package:modudi/core/cache/config/cache_config.dart' as config; // Added import

/// Abstract repository definition for fetching books.
abstract class BooksRepository {
  /// Fetches a list of books, optionally filtered by category.
  Future<List<Book>> getBooks({String? category});

  /// Fetches a single book by its ID.
  Future<CacheResult<Book?>> getBook(String id);

  /// Searches books by title.
  Future<List<Book>> searchBooks(String query);
  
  /// Fetches a list of featured books.
  Future<List<Book>> getFeaturedBooks();

  /// Fetches headings for a specific book.
  Future<List<Heading>> getBookHeadings(String bookId);

  /// Fetches all available categories with book counts.
  Future<Map<String, int>> getCategories();
}

class BooksRepositoryImpl implements BooksRepository {
  final FirebaseFirestore _firestore;
  final CacheService _cacheService;
  
  BooksRepositoryImpl({
    required CacheService cacheService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheService = cacheService;
  
  /// Get a single book by ID, including its headings
  @override
  Future<CacheResult<Book?>> getBook(String bookId) async {
    final String cacheKey = '${CacheConstants.bookKeyPrefix}$bookId';

    // Define the network fetch logic that returns Future<Map<String, dynamic>?>
    // This map will be what's stored in the cache by CacheService.fetch
    Future<Map<String, dynamic>?> networkFetchLogic() async {
      try {
        final bookDoc = await _firestore.collection('books').doc(bookId).get();

        if (!bookDoc.exists || bookDoc.data() == null) {
          debugPrint('Book not found in Firestore: $bookId');
          return null; // Book does not exist
        }

        final bookData = bookDoc.data()!;
        // Create book from the main document data
        final book = Book.fromMap(bookDoc.id, bookData);

        // Fetch headings
        final headingsSnapshot = await _firestore
            .collection('headings')
            .where('book_id', isEqualTo: int.tryParse(bookId) ?? bookId)
            .orderBy('sequence')
            .get();

        final headings = headingsSnapshot.docs
            .map((doc) => Heading.fromMap((doc.data()..['firestoreDocId'] = doc.id)))
            .toList();
        
        // Create book with headings
        final bookWithHeadings = book.copyWith(headings: headings);
        debugPrint('Fetched book from Firestore: ${bookWithHeadings.title}');
        return bookWithHeadings.toMap(); // Return the map representation for caching
      } catch (e, s) {
        debugPrint('Error fetching book $bookId from Firestore: $e\n$s');
        rethrow; 
      }
    }

    // Use CacheService.fetch to get CacheResult<Map<String, dynamic>?>
    final cacheResultMap = await _cacheService.fetch<Map<String, dynamic>?>(
      key: cacheKey,
      boxName: CacheConstants.booksBoxName,
      networkFetch: networkFetchLogic,
      ttl: const Duration(days: 7), // As per comprehensive plan
      policy: config.CachePolicy.staleWhileRevalidate, // Use SWR-like policy
    );

    // Convert CacheResult<Map<String, dynamic>?> to CacheResult<Book?>
    if (cacheResultMap.hasData && cacheResultMap.data != null) {
      try {
        // The bookId from the outer scope is reliable here as it's the ID we are fetching for.
        // If Book.toMap() correctly stores 'firestoreDocId', that could also be used from cacheResultMap.data.
        final book = Book.fromMap(bookId, cacheResultMap.data!);
        return CacheResult.fresh(book, metadata: cacheResultMap.metadata); // Or .stale based on original status if available
      } catch (e) {
        debugPrint('Error parsing book from cached map for key $cacheKey: $e');
        // If parsing fails, treat it as if data is missing or error, return original error/missing status
        return CacheResult.fromError(CacheError('Failed to parse cached book: $e', StackTrace.current), previousMetadata: cacheResultMap.metadata);
      }
    } else {
      // If data is null (e.g. network fetch returned null meaning book not found, or cache miss and no network)
      // or if there was an error reported by fetch, propagate that status.
      return CacheResult<Book?>(status: cacheResultMap.status, error: cacheResultMap.error, metadata: cacheResultMap.metadata, data: null);
    }
  }
  
  /// Get all books, with optional filters
  @override
  Future<List<Book>> getBooks({
    String? category,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection('books');
      
      if (category != null) {
        query = query.where('tags', arrayContains: category);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final querySnapshot = await query.limit(limit).get();
      
      return querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting books: $e');
      return [];
    }
  }
  
  /// Get headings for a specific book
  @override
  Future<List<Heading>> getBookHeadings(String bookId) async {
    try {
      final querySnapshot = await _firestore
          .collection('headings')
          .where('book_id', isEqualTo: int.tryParse(bookId) ?? bookId)
          .orderBy('sequence')
          .get();
      
      return querySnapshot.docs
          .map((doc) => Heading.fromMap( (doc.data()..['firestoreDocId'] = doc.id) ))
          .toList();
    } catch (e) {
      debugPrint('Error getting book headings: $e');
      return [];
    }
  }
  
  /// Search for books by title
  @override
  Future<List<Book>> searchBooks(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error searching books: $e');
      return [];
    }
  }
  
  /// Get all available categories with book counts
  @override
  Future<Map<String, int>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .get();
          
      final Map<String, int> categoryCounts = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data(); 
        final currentTags = data['tags'];
        if (currentTags is List) {
          for (var tag in currentTags) {
            final tagStr = tag.toString();
            categoryCounts[tagStr] = (categoryCounts[tagStr] ?? 0) + 1;
          }
        }
      }
      
      return categoryCounts;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return {};
    }
  }
  
  /// Get featured books
  @override
  Future<List<Book>> getFeaturedBooks({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .orderBy('title')
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting featured books: $e');
      return [];
    }
  }
} 