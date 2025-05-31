import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/category_model.dart';
import '../models/video_model.dart';

// Import cache-related classes
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import 'package:modudi/core/utils/firestore_retry_helper.dart';

class HomeRepositoryImpl implements HomeRepository {
  final Logger _logger = Logger('HomeRepositoryImpl');
  final FirebaseFirestore _firestore;
  final CacheService _cacheService;

  HomeRepositoryImpl({
    FirebaseFirestore? firestore,
    required CacheService cacheService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _cacheService = cacheService;

  @override
  Future<Book?> getBookById(String bookId) async {
    final cacheKey = '${CacheConstants.bookKeyPrefix}$bookId';
    
    try {
      // Try to get from cache first
      final cacheResult = await _cacheService.getCachedData<Book>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
      );
      
      if (cacheResult.hasData) {
        _logger.info('Retrieved book $bookId from cache');
        final book = cacheResult.data!;
        
        // Check if we need to fetch headings
        if (book.headings == null || book.headings!.isEmpty) {
          final enriched = await _fetchAndCacheHeadings(bookId, book);
          // store the enriched book so subsequent reads are fast
          await _cacheService.cacheData<Book>(
            key: cacheKey,
            data: enriched,
            boxName: CacheConstants.booksBoxName,
            ttl: CacheConstants.bookCacheTtl,
          );
          return enriched;
        }
        
        return book;
      }
      
      _logger.info('Book not in cache, fetching from network: $bookId');
      return await _fetchAndCacheBook(bookId);
    } catch (e) {
      _logger.severe('Error getting book $bookId: $e');
      return null;
    }
  }
  
  /// Fetch a book from Firestore and cache it
  Future<Book?> _fetchAndCacheBook(String bookId) async {
    try {
      final bookDoc = await FirestoreRetryHelper.executeWithRetry(
        () => _firestore.collection('books').doc(bookId).get(),
        'Fetch book document for $bookId',
      );
      
      if (!bookDoc.exists || bookDoc.data() == null) {
        _logger.warning('Book with ID $bookId not found');
        return null;
      }
      
      final book = Book.fromMap(bookDoc.id, bookDoc.data()!);
      final bookWithHeadings = await _fetchAndCacheHeadings(bookId, book);
      
      // Cache the complete book with headings
      await _cacheService.cacheData<Book>(
        key: '${CacheConstants.bookKeyPrefix}$bookId',
        data: bookWithHeadings,
        boxName: CacheConstants.booksBoxName,
        ttl: CacheConstants.bookCacheTtl,
      );
      
      return bookWithHeadings;
    } catch (e) {
      _logger.severe('Error fetching book $bookId: $e');
      return null;
    }
  }
  
  /// Fetch headings for a book and cache them
  Future<Book> _fetchAndCacheHeadings(String bookId, Book book) async {
    try {
      final headingsSnapshot = await FirestoreRetryHelper.executeWithRetry(
        () => _firestore
            .collection('headings')
            .where('book_id', isEqualTo: int.tryParse(bookId) ?? bookId)
            .orderBy('sequence')
            .get(),
        'Fetch headings for book $bookId',
      );
      
      if (headingsSnapshot.docs.isNotEmpty) {
        final headings = headingsSnapshot.docs
            .map((doc) => Heading.fromMap( (doc.data()..['firestoreDocId'] = doc.id) ))
            .toList();
            
// Cache headings separately
        await _cacheService.cacheData<List<Heading>>(
          key: '${CacheConstants.headingKeyPrefix}$bookId',
          data: headings,
          boxName: CacheConstants.headingsBoxName,
          ttl: CacheConstants.bookCacheTtl,
        );
        final enriched = book.copyWith(headings: headings);

        // ALSO cache the full book object for future look-ups
        await _cacheService.cacheData<Book>(
          key: '${CacheConstants.bookKeyPrefix}$bookId',
          data: enriched,
          boxName: CacheConstants.booksBoxName,
          ttl: CacheConstants.bookCacheTtl,
        );

        return enriched;
      }
      
      // Return the original book if no headings found
      return book;
    } catch (e) {
      _logger.severe('Error getting book by ID: $e');
      // Since we already have the book, return it even on error fetching headings
      return book;
    }
  }

  @override
  Future<List<Book>> getFeaturedBooks({int perPage = 10}) async {
    const cacheKey = CacheConstants.featuredBooksKey;
    
    try {
      // Try cache first
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
      );
      
      if (cacheResult.hasData) {
        _logger.info('Retrieved featured books from cache');
        final List<Book> books = List<Book>.from(cacheResult.data!);
        return books;
      }
      
      _logger.info('Fetching featured books from network');
      
      final querySnapshot = await FirestoreRetryHelper.executeWithRetry(
        () => _firestore
            .collection('books')
            .where('is_featured', isEqualTo: true)
            .limit(perPage)
            .get(),
        'Fetch featured books',
      );
          
      _logger.info('Found ${querySnapshot.docs.length} featured books');
      
      final books = querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();
      
      // Cache the result
      await _cacheService.cacheData<List<Book>>(
        key: cacheKey,
        data: books,
        boxName: CacheConstants.booksBoxName,
        ttl: CacheConstants.bookCacheTtl,
      );
      
      return books;
    } catch (e) {
      _logger.severe('Error fetching featured books: $e');
      return [];
    }
  }

  /// Fetches language-specific books in order of popularity.
  /// This method is specialized for retrieving books in a specific language.
  Future<List<Book>> getBooksByLanguage({
    required String language,
    int perPage = 20,
  }) async {
    final cacheKey = 'books_language_$language';
    
    try {
      // Try cache first
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
      );
      
      if (cacheResult.hasData) {
        _logger.info('Retrieved books for language $language from cache');
        final List<Book> books = List<Book>.from(cacheResult.data!);
        return books;
      }
      
      _logger.info('Fetching books for language: $language from network');
      
      final querySnapshot = await _firestore
          .collection('books')
          .where('language', isEqualTo: language)
          .orderBy('popularity', descending: true)
          .limit(perPage)
          .get();
          
      _logger.info('Found ${querySnapshot.docs.length} books in language $language');
      
      final books = querySnapshot.docs
          .map((doc) => Book.fromMap(doc.id, doc.data()))
          .toList();
      
      // Cache the result
      await _cacheService.cacheData<List<Book>>(
        key: cacheKey,
        data: books,
        boxName: CacheConstants.booksBoxName,
        ttl: CacheConstants.bookCacheTtl,
      );
      
      return books;
    } catch (e) {
      _logger.severe('Error fetching books for language $language: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    const cacheKey = CacheConstants.categoriesKey;
    
    try {
      // Try cache first
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.categoriesBoxName,
      );
      
      if (cacheResult.hasData) {
        _logger.info('Retrieved categories from cache');
        final List<CategoryEntity> categories = List<CategoryEntity>.from(cacheResult.data!);
        return categories;
      }
      
      _logger.info('Fetching categories from Firestore');
      
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('sequence')
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        _logger.info('Found ${querySnapshot.docs.length} categories');
        
        final categories = querySnapshot.docs
            .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
            .toList();
        
        // Cache the result - categories rarely change, so cache for longer
        await _cacheService.cacheData<List<CategoryEntity>>(
          key: cacheKey,
          data: categories,
          boxName: CacheConstants.categoriesBoxName,
          ttl: const Duration(days: 7), // Cache for a week
        );
        
        return categories;
      }
      
      // Fallback to static categories if Firestore is empty
      _logger.info('No categories found in Firestore, returning static categories.');
      final staticCategories = [
        CategoryModel(id: 'tafsir', title: 'Tafsir'),
        CategoryModel(id: 'islamic_law', title: 'Islamic Law'),
        CategoryModel(id: 'biography', title: 'Biography'),
        CategoryModel(id: 'political_thought', title: 'Political Thought'),
        CategoryModel(id: 'islamic_studies', title: 'Islamic Studies'),
        CategoryModel(id: 'general', title: 'General'),
      ];
      
      // Cache the static categories
      await _cacheService.cacheData<List<CategoryEntity>>(
        key: cacheKey,
        data: staticCategories,
        boxName: CacheConstants.categoriesBoxName,
        ttl: const Duration(days: 7),
      );
      
      return staticCategories;
    } catch (e) {
      _logger.severe('Error fetching categories: $e');
      // Fallback to static categories in case of error
      return [
        CategoryModel(id: 'tafsir', title: 'Tafsir'),
        CategoryModel(id: 'islamic_law', title: 'Islamic Law'),
        CategoryModel(id: 'biography', title: 'Biography'),
        CategoryModel(id: 'political_thought', title: 'Political Thought'),
        CategoryModel(id: 'islamic_studies', title: 'Islamic Studies'),
        CategoryModel(id: 'general', title: 'General'),
      ];
    }
  }

  @override
  Future<List<VideoEntity>> getVideoLectures({int perPage = 5}) async {
    const cacheKey = CacheConstants.videoLecturesKey;
    
    try {
      // Try cache first
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.videosBoxName,
      );
      
      if (cacheResult.hasData) {
        _logger.info('Retrieved video lectures from cache');
        final List<VideoEntity> videos = List<VideoEntity>.from(cacheResult.data!);
        return videos;
      }
      
      _logger.info('Fetching video lectures from Firestore');
      
      final querySnapshot = await _firestore
          .collection('videos')
          .orderBy('publishedDate', descending: true)
          .limit(perPage)
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        _logger.info('No video lectures found');
        return [];
      }
      
      _logger.info('Found ${querySnapshot.docs.length} video lectures');
      
      // Assuming we have a VideoModel with a fromMap constructor
      final videos = querySnapshot.docs
          .map((doc) => VideoModel.fromMap(doc.id, doc.data()))
          .toList();
      
      // Cache the result
      await _cacheService.cacheData<List<VideoEntity>>(
        key: cacheKey,
        data: videos,
        boxName: CacheConstants.videosBoxName,
        ttl: CacheConstants.videoCacheTtl,
      );
      
      return videos;
    } catch (e) {
      _logger.severe('Error fetching video lectures: $e');
      return [];
    }
  }
}