import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import 'package:modudi/core/cache/models/cache_result.dart'; // Corrected import for CacheStatus and CacheResult

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
  final CacheService _cacheService;
  final _log = Logger('BooksRepository');
  
  BooksRepositoryImpl({
    FirebaseFirestore? firestore,
    required CacheService cacheService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheService = cacheService;
  
  /// Get a single book by ID, including its headings
  @override
  Future<Book?> getBook(String bookId) async {
      final cacheKey = '${CacheConstants.bookKeyPrefix}$bookId';
    _log.info('Fetching book $bookId using CacheService.fetch (key: $cacheKey)');
      
    Future<Book> firestoreFetcher() async {
      _log.info('Book $bookId not in cache or stale, fetching from Firestore.');
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      
      if (!bookDoc.exists || bookDoc.data() == null) {
        _log.warning('Book $bookId not found in Firestore.');
        throw Exception('Book not found in Firestore: $bookId');
      }
      
      final bookData = bookDoc.data() as Map<String, dynamic>;
      final book = Book.fromMap(bookDoc.id, bookData);
      
      _log.fine('Fetched book metadata for ${book.title}, now fetching headings.');
      final headings = await _getBookHeadingsFromFirestore(bookId);
      _log.fine('Fetched ${headings.length} headings for ${book.title}.');
      
      return book.copyWith(headings: headings);
    }

    try {
      final cacheResult = await _cacheService.fetch<Book>(
        key: cacheKey,
         boxName: CacheConstants.booksBoxName,
        networkFetch: firestoreFetcher,
        ttl: const Duration(days: 7),
       );
      
      if (cacheResult.status == CacheStatus.error || cacheResult.data == null) {
        _log.severe(
            'Failed to get book $bookId. Status: ${cacheResult.status}, Error: ${cacheResult.error}');
        return null;
      }
      
      _log.info('Successfully fetched book $bookId. Status: ${cacheResult.status}, Source: ${cacheResult.metadata?.source}');
      return cacheResult.data;

    } catch (e, stackTrace) {
      _log.severe('Error in getBook for $bookId: $e', e, stackTrace);
      return null;
    }
  }
  
  // Helper method to get headings from Firestore
  Future<List<Heading>> _getBookHeadingsFromFirestore(String bookId) async {
    try {
      final headingsSnapshot = await _firestore
          .collection('headings')
          .where('book_id', isEqualTo: int.tryParse(bookId) ?? bookId)
          .orderBy('sequence')
          .get();
      
      return headingsSnapshot.docs
          .map((doc) => Heading.fromMap( (doc.data()..['firestoreDocId'] = doc.id) ))
          .toList();
    } catch (e) {
      _log.severe('Error getting book headings: $e');
      return [];
    }
  }
  
  /// Get all books, with optional filters (using cache-first approach)
  @override
  Future<List<Book>> getBooks({
    String? category,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Generate a unique cache key based on the query parameters
      final cacheKey = category != null 
          ? '${CacheConstants.bookKeyPrefix}category_$category'
          : CacheConstants.recentBooksKey;
      
      // Check cache first for faster response
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
      );
      
      if (cacheResult.hasData) {
        _log.info('Found ${cacheResult.data!.length} books in cache for category: ${category ?? "all"}');
        
        List<Book> books = [];
        for (var item in cacheResult.data!) {
          if (item is Map<String, dynamic> &&
              item['id'] is String &&
              item['data'] is Map<String, dynamic>) {
            try {
              final book = Book.fromMap(
                item['id'] as String,
                item['data'] as Map<String, dynamic>,
              );
              books.add(book);
            } catch (e) {
              _log.warning('Error parsing cached book: $e');
            }
          }
        }
        
        // If we have a valid response, use it immediately
        if (books.isNotEmpty) {
          // Refresh data in background for next time without blocking UI
          if (cacheResult.metadata != null) {
            final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheResult.metadata!.timestamp;
            if (cacheAge > const Duration(hours: 12).inMilliseconds) {
              _log.info('Cache data is older than 12 hours, refreshing in background');
              _refreshBooksInBackground(category, limit, cacheKey);
            }
          }
          return books;
        }
      }
      
      // If cache misses or is invalid, fetch from Firestore
      _log.info('Cache miss for books, fetching from Firestore');
      Query query = _firestore.collection('books');
      
      if (category != null) {
        query = query.where('tags', arrayContains: category);
      }
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final querySnapshot = await query.limit(limit).get();
      
      // Build list of books from Firestore results
      final books = querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Cache the results for future use
      if (books.isNotEmpty) {
        // Convert to a cacheable format
        final cacheData = books.map((book) => {
          'id': book.firestoreDocId,
          'data': book.toMap(),
        }).toList();
        
        await _cacheService.cacheData(
          key: cacheKey,
          data: cacheData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(days: 1), // Cache for 1 day
        );
        
        _log.info('Cached ${books.length} books for category: ${category ?? "all"}');
      }
      
      return books;
    } catch (e) {
      _log.severe('Error getting books: $e');
      return [];
    }
  }
  
  /// Refresh books data in background without blocking UI
  Future<void> _refreshBooksInBackground(String? category, int limit, String cacheKey) async {
    try {
      // Check if we have a network connection first
      final hasNetwork = await _cacheService.isConnected();
      if (!hasNetwork) {
        _log.info('Skipping background refresh: No network connection');
        return;
      }
      
      _log.info('Starting background refresh for books category: ${category ?? "all"}');
      
      // Fetch from Firestore
      Query query = _firestore.collection('books');
      
      if (category != null) {
        query = query.where('tags', arrayContains: category);
      }
      
      final querySnapshot = await query.limit(limit).get();
      
      // Build list of books from Firestore results
      final books = querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Update cache with fresh data
      if (books.isNotEmpty) {
        // Convert to a cacheable format
        final cacheData = books.map((book) => {
          'id': book.firestoreDocId,
          'data': book.toMap(),
        }).toList();
        
        await _cacheService.cacheData(
          key: cacheKey,
          data: cacheData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(days: 1),
        );
        
        _log.info('Background refresh completed for ${books.length} books');
      }
    } catch (e) {
      _log.warning('Error during background refresh for books: $e');
      // Don't propagate error as this is a background operation
    }
  }
  
  /// Get headings for a specific book
  @override
  Future<List<Heading>> getBookHeadings(String bookId) async {
    try {
      // First try to get book from cache, which would include headings
      _log.info('Attempting to get headings for book $bookId from cache');
      final cacheKey = '${CacheConstants.bookKeyPrefix}$bookId';
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
      );
      
      // Convert cache result to book if available
      Book? cachedBook;
      if (cacheResult.hasData) {
        cachedBook = Book.fromMap(bookId, cacheResult.data!);
      }
      
      if (cachedBook != null && cachedBook.headings != null && cachedBook.headings!.isNotEmpty) {
        _log.info('Found headings in cache for book ${cachedBook.title}');
        return cachedBook.headings!;
      }
      
      _log.info('Headings not found in cache, loading from Firestore');
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
  
  /// Search for books by title - using network only approach
  /// Note: We don't cache search results because they're query-specific and less likely to be reused
  @override
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // For search functionality, it's usually better to always get fresh results
      // However, we will store the results in memory cache for the current session
      // in case the same search is performed multiple times
      
      // Generate a cache key for this specific search query
      final cacheKey = '${CacheConstants.bookKeyPrefix}search_${query.trim().toLowerCase()}';
      
      // Check if we have this search result in cache
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
      );
      
      if (cacheResult.hasData) {
        _log.info('Found search results in cache for "$query"');
        
        List<Book> books = [];
        for (var item in cacheResult.data!) {
          if (item is Map<String, dynamic>) {
            try {
              final bookId = item['id']?.toString() ?? 'unknown';
              final bookData = Map<String, dynamic>.from(item['data'] as Map);
              books.add(Book.fromMap(bookId, bookData));
            } catch (e) {
              _log.warning('Error parsing cached search result: $e');
            }
          }
        }
        
        if (books.isNotEmpty) {
          return books;
        }
      }
      
      // If not in cache, fetch from Firestore
      _log.info('Searching books from Firestore for query "$query"');
      
      final querySnapshot = await _firestore
          .collection('books')
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();
      
      final books = querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();
      
      // Cache search results for a short period (10 minutes)
      if (books.isNotEmpty) {
        // Convert to cacheable format
        final cacheData = books.map((book) => {
          'id': book.firestoreDocId,
          'data': book.toMap(),
        }).toList();
        
        await _cacheService.cacheData(
          key: cacheKey,
          data: cacheData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(minutes: 10), // Short TTL for search results
        );
        
        _log.info('Cached ${books.length} search results for "$query"');
      }
      
      return books;
    } catch (e) {
      _log.severe('Error searching books: $e');
      return [];
    }
  }
  
  /// Get all available categories with book counts using cache-first approach
  @override
  Future<Map<String, int>> getCategories() async {
    try {
      const cacheKey = CacheConstants.categoriesKey;
      
      // STEP 1: Try to get from cache first
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.categoriesBoxName,
      );
      
      if (cacheResult.hasData) {
        _log.info('Found categories in cache');
        
        // Convert to the correct format (Map<String, int>)
        final Map<String, int> categoryCounts = {};
        cacheResult.data!.forEach((key, value) {
          if (value is int) {
            categoryCounts[key] = value;
          } else if (value is num) {
            categoryCounts[key] = value.toInt();
          } else if (value is String) {
            final intValue = int.tryParse(value);
            if (intValue != null) {
              categoryCounts[key] = intValue;
            }
          }
        });
        
        // If we have valid data, use it immediately
        if (categoryCounts.isNotEmpty) {
          // Trigger background refresh if cache is older than 24 hours
          if (cacheResult.metadata != null) {
            final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheResult.metadata!.timestamp;
            if (cacheAge > const Duration(days: 1).inMilliseconds) {
              _log.info('Categories cache is older than 24 hours, refreshing in background');
              _refreshCategoriesInBackground();
            }
          }
          return categoryCounts;
        }
      }
      
      // STEP 2: If cache misses or is invalid, fetch from Firestore
      _log.info('Categories not found in cache, fetching from Firestore');
      
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
      
      // Cache the results
      if (categoryCounts.isNotEmpty) {
        await _cacheService.cacheData(
          key: cacheKey,
          data: categoryCounts,
          boxName: CacheConstants.categoriesBoxName,
          ttl: const Duration(days: 7), // Cache for a week since categories rarely change
        );
        
        _log.info('Cached ${categoryCounts.length} categories');
      }
      
      return categoryCounts;
    } catch (e) {
      _log.severe('Error getting categories: $e');
      return {};
    }
  }
  
  /// Refresh categories in background without blocking UI
  Future<void> _refreshCategoriesInBackground() async {
    try {
      // Check if we have a network connection
      final hasNetwork = await _cacheService.isConnected();
      if (!hasNetwork) {
        _log.info('Skipping categories refresh: No network connection');
        return;
      }
      
      _log.info('Starting background refresh for categories');
      
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
      
      // Update cache
      if (categoryCounts.isNotEmpty) {
        await _cacheService.cacheData(
          key: CacheConstants.categoriesKey,
          data: categoryCounts,
          boxName: CacheConstants.categoriesBoxName,
          ttl: const Duration(days: 7),
        );
        
        _log.info('Background refresh completed for ${categoryCounts.length} categories');
      }
    } catch (e) {
      _log.warning('Error during background refresh for categories: $e');
      // Don't propagate errors from background operations
    }
  }
  
  /// Get featured books using cache-first approach
  @override
  Future<List<Book>> getFeaturedBooks({int limit = 10}) async {
    try {
      const cacheKey = CacheConstants.featuredBooksKey;
      
      // STEP 1: Try to get from cache first for immediate response
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
      );
      
      if (cacheResult.hasData) {
        _log.info('Found featured books in cache');
        
        List<Book> books = [];
        for (var item in cacheResult.data!) {
          if (item is Map<String, dynamic>) {
            try {
              final bookId = item['id']?.toString() ?? 'unknown';
              final bookData = Map<String, dynamic>.from(item['data'] as Map);
              final book = Book.fromMap(bookId, bookData);
              books.add(book);
            } catch (e) {
              _log.warning('Error parsing cached featured book: $e');
            }
          }
        }
        
        // If we have a valid cache response, use it
        if (books.isNotEmpty) {
          // Trigger background refresh if cache is older than 6 hours
          if (cacheResult.metadata != null) {
            final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheResult.metadata!.timestamp;
            if (cacheAge > const Duration(hours: 6).inMilliseconds) {
              _log.info('Featured books cache is older than 6 hours, refreshing in background');
              _refreshFeaturedBooksInBackground(limit);
            }
          }
          return books;
        }
      }
      
      // STEP 2: If cache misses or is invalid, fetch from Firestore
      _log.info('Featured books not found in cache, fetching from Firestore');
      
      // We're going to be smarter about featured books - get books with 'featured' tag or most popular
      var query = _firestore.collection('books');
      
      // First try to find books tagged as 'featured'
      var featuredSnapshot = await query
          .where('tags', arrayContains: 'featured')
          .limit(limit)
          .get();
      
      // If we don't have enough featured books, supplement with most recent
      if (featuredSnapshot.docs.length < limit) {
        final remainingCount = limit - featuredSnapshot.docs.length;
        final recentSnapshot = await query
            .orderBy('createdAt', descending: true)
            .limit(remainingCount)
            .get();
            
        // Combine the two result sets
        final combinedDocs = [...featuredSnapshot.docs, ...recentSnapshot.docs];
        
        // Remove duplicates
        final uniqueDocs = <String, QueryDocumentSnapshot>{};
        for (var doc in combinedDocs) {
          uniqueDocs[doc.id] = doc;
        }
        
        final books = uniqueDocs.values
            .map((doc) => Book.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
        
        // Cache results
        final cacheData = books.map((book) => {
          'id': book.firestoreDocId,
          'data': book.toMap(),
        }).toList();
        
        await _cacheService.cacheData(
          key: cacheKey,
          data: cacheData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(hours: 12), // Cache for 12 hours
        );
        
        return books;
      } else {
        // Just use the featured books
        final books = featuredSnapshot.docs
            .map((doc) => Book.fromMap(doc.id, doc.data()))
            .toList();
        
        // Cache results
        final cacheData = books.map((book) => {
          'id': book.firestoreDocId,
          'data': book.toMap(),
        }).toList();
        
        await _cacheService.cacheData(
          key: cacheKey,
          data: cacheData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(hours: 12), // Cache for 12 hours
        );
        
        return books;
      }
    } catch (e) {
      _log.severe('Error getting featured books: $e');
      return [];
    }
  }
  
  /// Refresh featured books in background without blocking UI
  Future<void> _refreshFeaturedBooksInBackground(int limit) async {
    try {
      // Check if we have a network connection
      final hasNetwork = await _cacheService.isConnected();
      if (!hasNetwork) {
        _log.info('Skipping featured books refresh: No network connection');
        return;
      }
      
      _log.info('Starting background refresh for featured books');
      
      // Fetch featured books from Firestore
      var query = _firestore.collection('books');
      var featuredSnapshot = await query
          .where('tags', arrayContains: 'featured')
          .limit(limit)
          .get();
      
      // Similar logic as the main method
      if (featuredSnapshot.docs.length < limit) {
        final remainingCount = limit - featuredSnapshot.docs.length;
        final recentSnapshot = await query
            .orderBy('createdAt', descending: true)
            .limit(remainingCount)
            .get();
            
        final combinedDocs = [...featuredSnapshot.docs, ...recentSnapshot.docs];
        final uniqueDocs = <String, QueryDocumentSnapshot>{};
        for (var doc in combinedDocs) {
          uniqueDocs[doc.id] = doc;
        }
        
        final books = uniqueDocs.values
            .map((doc) => Book.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
        
        // Update cache
        final cacheData = books.map((book) => {
          'id': book.firestoreDocId,
          'data': book.toMap(),
        }).toList();
        
        await _cacheService.cacheData(
          key: CacheConstants.featuredBooksKey,
          data: cacheData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(hours: 12), 
        );
        
        _log.info('Background refresh completed for ${books.length} featured books');
      } else {
        // Just use the featured books
        final books = featuredSnapshot.docs
            .map((doc) => Book.fromMap(doc.id, doc.data()))
            .toList();
        
        // Update cache
        final cacheData = books.map((book) => {
          'id': book.firestoreDocId,
          'data': book.toMap(),
        }).toList();
        
        await _cacheService.cacheData(
          key: CacheConstants.featuredBooksKey,
          data: cacheData,
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(hours: 12),
        );
        
        _log.info('Background refresh completed for ${books.length} featured books');
      }
    } catch (e) {
      _log.warning('Error during background refresh for featured books: $e');
      // Don't propagate errors from background operations
    }
  }
} 