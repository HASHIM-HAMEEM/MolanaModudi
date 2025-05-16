import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:modudi/features/books/data/cache/book_cache_service.dart';
import 'package:modudi/features/books/data/models/book_models.dart';

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
  
  BooksRepositoryImpl({
    required BookCacheService cacheService,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheService = cacheService;
  
  /// Get a single book by ID, including its headings
  @override
  Future<Book?> getBook(String bookId) async {
    try {
      // Try to get from cache first
      final cachedBook = await _cacheService.getCachedBook(bookId);
      if (cachedBook != null) {
        debugPrint('Retrieved book from cache: ${cachedBook.title}');
        return cachedBook;
      }
      
      // If not in cache, fetch from Firestore
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      
      if (!bookDoc.exists || bookDoc.data() == null) {
        return null;
      }
      
      final book = Book.fromMap(bookDoc.id, bookDoc.data() as Map<String, dynamic>);
      
      final headingsSnapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('headings')
          .orderBy('sequence')
          .get();
      
      final headings = headingsSnapshot.docs
          .map((doc) => Heading.fromMap(doc.id, doc.data()))
          .toList();
          
      final bookWithHeadings = book.copyWith(headings: headings);
      
      // Cache the book for future use
      await _cacheService.cacheBook(bookWithHeadings);
      
      return bookWithHeadings;
    } catch (e) {
      debugPrint('Error getting book: $e');
      return null;
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