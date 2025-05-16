import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dio/dio.dart'; // Dio no longer needed directly here

// import '../../../../core/services/api_service.dart'; // Removed ArchiveApiService import
import 'package:modudi/features/books/data/models/book_models.dart'; // Use new models
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/category_model.dart';
// import '../models/video_model.dart'; // VideoModel might need rework or removal if IA specific

// import 'package:modudi/config/book_collections.dart'; // BookCollections might be IA specific

class HomeRepositoryImpl implements HomeRepository {
  final Logger _logger = Logger('HomeRepositoryImpl');
  final FirebaseFirestore _firestore;

  HomeRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Book?> getBookById(String bookId) async {
    try {
      _logger.info('Fetching book by ID: $bookId');
      
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      
      if (!bookDoc.exists || bookDoc.data() == null) {
        _logger.warning('Book with ID $bookId not found');
        return null;
      }
      
      final book = Book.fromMap(bookDoc.id, bookDoc.data()!);
      
      // Fetch headings if available
      final headingsSnapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('headings')
          .orderBy('sequence')
          .get();
      
      if (headingsSnapshot.docs.isNotEmpty) {
        final headings = headingsSnapshot.docs
            .map((doc) => Heading.fromMap(doc.id, doc.data()))
            .toList();
            
        return book.copyWith(headings: headings);
      }
      
      return book;
    } catch (e) {
      _logger.severe('Error getting book by ID: $e');
      return null;
    }
  }

  @override
  Future<List<Book>> getFeaturedBooks({int perPage = 500}) async {
    _logger.info('getFeaturedBooks called - to be reimplemented with Firestore');
    // try {
    //   _logger.info('Fetching featured books with limit: $perPage');
      
    //   // Check if we have curated book identifiers available
    //   if (BookCollections.featuredBooks.isNotEmpty) {
    //     // Use the curated list of featured books from the config
    //     _logger.info('Using curated featured books list with ${BookCollections.featuredBooks.length} identifiers');
        
    //     final bookDocs = await _apiService.fetchBooksByIdentifiers(
    //       identifiers: BookCollections.featuredBooks,
    //       includeOcrInfo: true,
    //     );
        
    //     final books = bookDocs.map<Book>((doc) {
    //       // Create Book from the doc
    //       final book = Book.fromMap(doc['identifier'] ?? doc['id'], doc as Map<String, dynamic>);
          
    //       // Evaluate OCR quality and add as metadata
    //       final ocrQuality = _apiService.evaluateOcrQuality(doc as Map<String, dynamic>);
          
    //       // Use the spread operator to include OCR quality in the model's additionalFields
    //       return book.copyWith(
    //         additionalFields: {
    //           ...book.additionalFields,
    //           'ocr_quality': ocrQuality['quality_score'],
    //           'ocr_info': ocrQuality['ocr_info'],
    //         },
    //       );
    //     }).toList();
        
    //     _logger.info('Retrieved ${books.length} curated featured books');
    //     return books;
    //   }
      
    //   // Fallback to API search if curated list is empty
    //   final bookDocs = await _apiService.searchBooks(
    //     query: 'creator:"Syed Abul A ala Maududi"',
    //     perPage: perPage,
    //     languages: ['eng', 'ara', 'urd'], // Support multilingual content
    //     additionalFields: ['subject'], // Request additional fields for better categorization
    //   );
      
    //   // Convert the docs to Book objects
    //   final List<Book> books = bookDocs.map<Book>((doc) => Book.fromMap(doc['identifier'] ?? doc['id'], doc as Map<String, dynamic>)).toList();
    //   _logger.info('Retrieved ${books.length} featured books via API search');
    //   return books;
      
    // } on DioException catch (e) {
    //   _logger.severe('Failed to fetch featured books: ${e.message}', e);
    //   throw Exception('Failed to fetch featured books: ${e.message}');
    // } catch (e) {
    //   _logger.severe('Unexpected error fetching featured books', e);
    //   throw Exception('An unexpected error occurred');
    // }
    throw UnimplementedError('getFeaturedBooks needs to be reimplemented with Firestore');
  }

  /// Fetches language-specific books in order of popularity.
  /// This method is specialized for retrieving books in a specific language.
  Future<List<Book>> getBooksByLanguage({
    required String language,
    int perPage = 100,
  }) async {
    _logger.info('getBooksByLanguage called - to be reimplemented with Firestore');
    // try {
    //   _logger.info('Fetching books in $language with limit: $perPage');
      
    //   // Use the specialized method for language-specific retrieval
    //   final bookDocs = await _apiService.fetchAuthorBooksByLanguage(
    //     author: 'Syed Abul A ala Maududi',
    //     language: language,
    //     maxResults: perPage,
    //     includeOcrInfo: true,
    //   );
      
    //   // Convert the docs to Book objects with OCR quality metadata
    //   final List<Book> books = bookDocs.map<Book>((doc) {
    //     final book = Book.fromMap(doc['identifier'] ?? doc['id'], doc as Map<String, dynamic>);
    //     final ocrQuality = _apiService.evaluateOcrQuality(doc as Map<String, dynamic>);
        
    //     return book.copyWith(
    //       additionalFields: {
    //         ...book.additionalFields,
    //         'ocr_quality': ocrQuality['quality_score'],
    //         'ocr_info': ocrQuality['ocr_info'],
    //       },
    //     );
    //   }).toList();
      
    //   _logger.info('Retrieved ${books.length} books in $language');
    //   return books;
      
    // } on DioException catch (e) {
    //   _logger.severe('Failed to fetch $language books: ${e.message}', e);
    //   throw Exception('Failed to fetch books: ${e.message}');
    // } catch (e) {
    //   _logger.severe('Unexpected error fetching $language books', e);
    //   throw Exception('An unexpected error occurred');
    // }
    throw UnimplementedError('getBooksByLanguage needs to be reimplemented with Firestore');
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      // For now, return static categories; in the future, this could be derived from Firestore or config
      _logger.info('Returning static categories. To be updated with Firestore.');
      return [
        CategoryModel(id: 'tafsir', title: 'Tafsir'),
        CategoryModel(id: 'islamic_law', title: 'Islamic Law'),
        CategoryModel(id: 'biography', title: 'Biography'),
        CategoryModel(id: 'political_thought', title: 'Political Thought'),
        CategoryModel(id: 'islamic_studies', title: 'Islamic Studies'),
        CategoryModel(id: 'general', title: 'General'),
      ];
    } catch (e) {
      _logger.severe('Unexpected error fetching categories', e);
      throw Exception('Failed to fetch categories');
    }
  }

  @override
  Future<List<VideoEntity>> getVideoLectures({int perPage = 5}) async {
    _logger.info('getVideoLectures called - to be reimplemented or removed');
    // try {
    //   final videoDocs = await _apiService.searchBooks(
    //     query: 'creator:"Syed Abul A ala Maududi" AND (mediatype:audio OR mediatype:movies)',
    //     perPage: perPage,
    //   );
      
    //   // Convert the docs to VideoEntity objects
    //   final List<VideoEntity> videos = videoDocs.map((doc) => VideoModel.fromJson(doc)).toList();
    //   _logger.info('Retrieved ${videos.length} video lectures');
    //   return videos;
      
    // } on DioException catch (e) {
    //   _logger.severe('Failed to fetch video lectures: ${e.message}', e);
    //   throw Exception('Failed to fetch video lectures: ${e.message}');
    // } catch (e) {
    //   _logger.severe('Unexpected error fetching video lectures', e);
    //   throw Exception('An unexpected error occurred');
    // }
    throw UnimplementedError('getVideoLectures needs to be reimplemented or removed if IA specific');
  }
} 