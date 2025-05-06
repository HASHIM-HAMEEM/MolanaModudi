import 'package:modudi/features/book_detail/domain/entities/book_detail_entity.dart';
import 'package:modudi/features/book_detail/domain/repositories/book_detail_repository.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'package:logging/logging.dart';

class BookDetailRepositoryImpl implements BookDetailRepository {
  // final ArchiveApiService _apiService; // Removed
  final ReadingRepository _readingRepository;
  final _log = Logger('BookDetailRepository');

  BookDetailRepositoryImpl({
    // required ArchiveApiService apiService, // Removed
    required ReadingRepository readingRepository,
  }) : /*_apiService = apiService,*/ // Removed
      _readingRepository = readingRepository;

  @override
  Future<BookDetailEntity> getBookDetails(String bookId) async {
    _log.info('getBookDetails called for $bookId - to be reimplemented or removed as BookDetailScreen fetches from Firestore.');
    // try {
    //   final response = await _apiService.getBookDetails(bookId);
      
    //   // The metadata API response structure can vary.
    //   // Primary details are usually under 'metadata'. Files under 'files'.
    //   Map<String, dynamic>? metadata;
      
    //   // Handle varying response structures
    //   if (response.containsKey('metadata')) {
    //     metadata = response['metadata'] as Map<String, dynamic>?;
    //   } else {
    //     // Some endpoints might return metadata directly at root level
    //     metadata = response;
    //   }
      
    //   // If we still can't find metadata, create a placeholder
    //   if (metadata == null || metadata.isEmpty) {
    //     _log.warning('No metadata found for book ID: $bookId, using placeholder data');
        
    //     // Return a placeholder object instead of throwing
    //     return BookDetailEntity(
    //       id: bookId,
    //       title: 'Book #$bookId',
    //       author: 'Unknown Author',
    //       coverUrl: null,
    //       description: 'No description available',
    //       chapters: [],
    //     );
    //   }

    //   // Helper function to safely extract list of strings
    //   List<String>? _getListStrings(dynamic field) {
    //      if (field is List) return List<String>.from(field.map((e) => e.toString()));
    //      if (field is String) return [field];
    //      return null;
    //   }

    //   // Construct the cover URL
    //   String? coverUrl;
    //   if (metadata['identifier'] != null) {
    //      // Attempt to find a suitable image file or construct from identifier
    //      coverUrl = "https://archive.org/services/img/${metadata['identifier']}";
    //   }
      
    //   // Fallback for empty essential fields
    //   final title = metadata['title'] as String? ?? 'Book #$bookId';
    //   final author = metadata['creator'] as String? ?? 'Unknown Author';
      
    //   // Extract chapters from OCR or other metadata
    //   // List<ChapterEntity> chapters = await _extractChapters(bookId, metadata); // _extractChapters is removed
    //   List<ChapterEntity> chapters = []; // Placeholder as _extractChapters is removed

    //   return BookDetailEntity(
    //     id: metadata['identifier'] as String? ?? bookId, // Use identifier if available
    //     title: title,
    //     author: author,
    //     coverUrl: coverUrl,
    //     categories: _getListStrings(metadata['collection']), // Use collection as category?
    //     description: metadata['description'] as String? ?? 'No description available',
    //     language: metadata['language'] as String?,
    //     publishYear: metadata['date'] as String? ?? metadata['publicdate'] as String?, // Prefer 'date' over 'publicdate'
    //     format: _getListStrings(metadata['format']), 
    //     chapters: chapters, // Assign extracted chapters
    //     publisher: metadata['publisher'] as String?,
    //     subjects: _getListStrings(metadata['subject']),
    //     publicDate: metadata['publicdate'] as String?,
    //     downloads: metadata['downloads'] is int ? metadata['downloads'] : null,
    //     collection: metadata['collection'] is String ? metadata['collection'] : null,
    //     // Rating, review count, pages are not directly available in standard IA metadata
    //     rating: null, 
    //     reviewCount: null,
    //     pages: null, 
    //   );
    // } catch (e) {
    //   _log.severe('Error mapping book details: $e'); // Log specific mapping error
    //   // Create a fallback book entity instead of rethrowing
    //   return BookDetailEntity(
    //     id: bookId,
    //     title: 'Book #$bookId',
    //     author: 'Unknown Author',
    //     coverUrl: null,
    //     description: 'Error loading book details: $e',
    //     chapters: [],
    //   );
    // }
    throw UnimplementedError('getBookDetails is not functional after removing ArchiveApiService. BookDetailScreen now loads data from Firestore.');
  }
  
  // /// Extract chapters from OCR or Internet Archive metadata (REMOVED as it was IA specific)
  // Future<List<ChapterEntity>> _extractChapters(String bookId, Map<String, dynamic> metadata) async {
  //   // ... entire method body removed ...
  // }

  // Helper method to determine book type from metadata for AI extraction.
  String _determineBookType(Map<String, dynamic> metadata) {
    final format = metadata['format'];
    if (format is List && format.isNotEmpty) {
      final lowerFormats = format.map((f) => f.toString().toLowerCase()).toList();
      if (lowerFormats.contains('epub')) return 'epub';
      if (lowerFormats.contains('pdf')) return 'pdf';
      if (lowerFormats.contains('text')) return 'text';
    }
    return 'unknown'; // Default type
  }
} 