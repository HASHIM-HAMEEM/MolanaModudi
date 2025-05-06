import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

/// Service for interacting with Firebase Firestore.
/// This service implements the data structure described in the specification:
/// - Root collection 'books' contains book documents
/// - Each book document has a 'headings' subcollection for its chapters
class FirebaseService {
  final FirebaseFirestore _firestore;
  final _log = Logger('FirebaseService');
  
  // Collection names (configurable as per specifications)
  final String _booksCollection;
  final String _headingsCollection;
  
  /// Creates a FirebaseService instance
  /// [firestore] - The Firestore instance to use (useful for testing with mock instances)
  /// [booksCollection] - The name of the root books collection (defaults to "books")
  /// [headingsCollection] - The name of the headings subcollection (defaults to "headings")
  FirebaseService({
    FirebaseFirestore? firestore,
    this.rootCollection = 'books',
    this.headingsCollection = 'headings',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _booksCollection = rootCollection,
       _headingsCollection = headingsCollection;
  
  // Public properties for collection names
  final String rootCollection;
  final String headingsCollection;

  /// Initialize Firebase if it hasn't been initialized yet.
  /// Call this before accessing Firebase services.
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      Logger('FirebaseService').info('Firebase initialized successfully');
    } catch (e) {
      Logger('FirebaseService').severe('Failed to initialize Firebase: $e');
      rethrow;
    }
  }
  
  /// Get a book document by its ID
  Future<Map<String, dynamic>?> getBook(String bookId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_booksCollection)
          .doc(bookId)
          .get();
          
      if (!docSnapshot.exists) {
        _log.warning('Book with ID $bookId not found');
        return null;
      }
      
      return docSnapshot.data();
    } catch (e) {
      _log.severe('Error fetching book $bookId: $e');
      rethrow;
    }
  }
  
  /// Get a list of books with optional filtering and pagination
  Future<List<Map<String, dynamic>>> getBooks({
    int? limit,
    DocumentSnapshot? startAfter,
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query query = _firestore.collection(_booksCollection);
      
      // Apply filters if provided
      if (filters != null) {
        filters.forEach((field, value) {
          if (value != null) {
            query = query.where(field, isEqualTo: value);
          }
        });
      }
      
      // Apply pagination if provided
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      // Transform QueryDocumentSnapshot to Map<String, dynamic>
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      _log.severe('Error fetching books: $e');
      rethrow;
    }
  }
  
  /// Get headings (chapters) for a specific book
  /// Important: Headings are ordered by their 'sequence' field as specified in the data structure
  Future<List<Map<String, dynamic>>> getBookHeadings(String bookId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_booksCollection)
          .doc(bookId)
          .collection(_headingsCollection)
          .orderBy('sequence', descending: false) // Order by sequence as specified
          .get();
          
      // Transform QueryDocumentSnapshot to Map<String, dynamic>
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      _log.severe('Error fetching headings for book $bookId: $e');
      rethrow;
    }
  }
  
  /// Search books by title, returning a list of matching books
  Future<List<Map<String, dynamic>>> searchBooksByTitle(String titleQuery) async {
    try {
      // Firestore doesn't support direct text search, so we need to use a StartsWith approach
      // For more advanced search, consider Firebase extensions like Algolia
      final querySnapshot = await _firestore
          .collection(_booksCollection)
          .where('title', isGreaterThanOrEqualTo: titleQuery)
          .where('title', isLessThanOrEqualTo: titleQuery + '\uf8ff')
          .get();
          
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      _log.severe('Error searching books by title "$titleQuery": $e');
      rethrow;
    }
  }
  
  /// Get books by category
  Future<List<Map<String, dynamic>>> getBooksByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_booksCollection)
          .where('categories', arrayContains: category)
          .get();
          
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      _log.severe('Error fetching books in category "$category": $e');
      rethrow;
    }
  }
  
  /// Get a featured books list (e.g., most downloaded or recently added)
  Future<List<Map<String, dynamic>>> getFeaturedBooks({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_booksCollection)
          .orderBy('downloads', descending: true) // Sort by downloads
          .limit(limit)
          .get();
          
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      _log.severe('Error fetching featured books: $e');
      rethrow;
    }
  }
  
  /// Get list of available book categories with their counts
  /// This simulates a groupBy query which isn't directly available in Firestore
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      // First, get all books
      final querySnapshot = await _firestore
          .collection(_booksCollection)
          .get();
      
      // Process categories
      final Map<String, int> categoryCounts = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final List<dynamic>? categories = data['categories'] as List<dynamic>?;
        
        if (categories != null) {
          for (var category in categories) {
            if (category is String) {
              categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
            }
          }
        }
      }
      
      // Convert to the expected return format
      return categoryCounts.entries
          .map((entry) => {
            'name': entry.key,
            'count': entry.value,
            // You might add other category metadata here if available
          })
          .toList();
    } catch (e) {
      _log.severe('Error fetching book categories: $e');
      rethrow;
    }
  }
} 