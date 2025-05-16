import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/books/data/cache/book_cache_service.dart';

/// Abstract repository definition for fetching books.
abstract class BooksRepository {
  /// Fetches a list of books, optionally filtered by category.
  Future<List<Book>> getBooks({String? category});

  /// Fetches a single book by its ID.
  Future<Book?> getBook(String id);

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
  final BookCacheService _cacheService;
  final _log = Logger('BooksRepository');
  
  BooksRepositoryImpl({
    FirebaseFirestore? firestore,
    BookCacheService? cacheService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheService = cacheService ?? BookCacheService();
  
  /// Get a single book by ID, including its headings
  @override
  Future<Book?> getBook(String bookId) async {
    try {
      // First try to get from cache
      _log.info('Attempting to get book $bookId from cache');
      final cachedBook = await _cacheService.getCachedBook(bookId);
      
      if (cachedBook != null) {
        _log.info('Found book ${cachedBook.title} in cache');
        
        // Load headings if needed
        if (cachedBook.headings == null || cachedBook.headings!.isEmpty) {
          _log.info('Loading headings for cached book');
          final headings = await _getBookHeadingsFromFirestore(bookId);
          return cachedBook.copyWith(headings: headings);
        }
        
        return cachedBook;
      }
      
      _log.info('Book not found in cache, loading from Firestore');
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      
      if (!bookDoc.exists || bookDoc.data() == null) {
        return null;
      }
      
      final book = Book.fromMap(bookDoc.id, bookDoc.data() as Map<String, dynamic>);
      
      // Get headings
      final headings = await _getBookHeadingsFromFirestore(bookId);
      final bookWithHeadings = book.copyWith(headings: headings);
      
      // Cache the book
      await _cacheService.cacheBook(bookWithHeadings);
      
      // Cache headings individually
      for (final heading in headings) {
        // We don't have volume and chapter info in this context,
        // so we use placeholders for the cache key
        await _cacheService.cacheHeading(bookId, 'main', 'main', heading);
      }
      
      return bookWithHeadings;
    } catch (e) {
      _log.severe('Error getting book: $e');
      return null;
    }
  }
  
  // Helper method to get headings from Firestore
  Future<List<Heading>> _getBookHeadingsFromFirestore(String bookId) async {
    try {
      final headingsSnapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('headings')
          .orderBy('sequence')
          .get();
      
      return headingsSnapshot.docs
          .map((doc) => Heading.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      _log.severe('Error getting book headings: $e');
      return [];
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
      // First try to get book from cache, which would include headings
      _log.info('Attempting to get headings for book $bookId from cache');
      final cachedBook = await _cacheService.getCachedBook(bookId);
      
      if (cachedBook != null && cachedBook.headings != null && cachedBook.headings!.isNotEmpty) {
        _log.info('Found headings in cache for book ${cachedBook.title}');
        return cachedBook.headings!;
      }
      
      _log.info('Headings not found in cache, loading from Firestore');
      final querySnapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('headings')
          .orderBy('sequence')
          .get();
      
      return querySnapshot.docs
          .map((doc) => Heading.fromMap(doc.id, doc.data()))
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