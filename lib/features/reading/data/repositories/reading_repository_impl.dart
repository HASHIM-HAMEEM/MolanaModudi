import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:modudi/core/services/gemini_service.dart'; // Import Gemini service
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'package:modudi/features/books/data/models/book_models.dart'; // Import new models
import '../models/bookmark_model.dart'; // Corrected import for Bookmark
import 'package:logging/logging.dart'; // Import logger
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

class ReadingRepositoryImpl implements ReadingRepository {
  final GeminiService geminiService;
  final FirebaseFirestore _firestore; // Add Firestore instance
  final _log = Logger('ReadingRepository'); // Add logger instance

  // Simple in-memory cache for headings
  final Map<String, dynamic> _headingCache = {};

  // Key prefix for storing bookmarks in shared_preferences
  static const String _bookmarkStorePrefix = 'bookmarks_';

  ReadingRepositoryImpl({
    required this.geminiService,
    FirebaseFirestore? firestore, // Inject Firestore
  })
   : _firestore = firestore ?? FirebaseFirestore.instance; // Initialize Firestore

  @override
  Future<Book> getBookData(String bookId) async {
    try {
      final docSnap = await _firestore.collection('books').doc(bookId).get();
      if (!docSnap.exists || docSnap.data() == null) {
        throw Exception('Book with ID $bookId not found in Firestore.');
      }
      return Book.fromMap(docSnap.id, docSnap.data()!); 
    } catch (e) {
      // Log error
      _log.severe('Error fetching book data for bookId $bookId: $e');
      rethrow;
    }
  }

  @override
  Future<List<Heading>> getBookHeadings(String bookId) async {
    try {
      // Convert bookId to integer for querying against book_id field
      final numericBookId = int.tryParse(bookId);
      if (numericBookId == null) {
        _log.warning('Invalid book ID format: $bookId');
        return [];
      }
      
      _log.info('Querying top-level headings collection for book_id: $numericBookId');
      
      // Query the top-level headings collection where book_id equals the numeric ID
      final headingsSnap = await _firestore
          .collection('headings')
          .where('book_id', isEqualTo: numericBookId)
          .orderBy('sequence', descending: false)
          .get();
      
      _log.info('Found ${headingsSnap.docs.length} headings for book ID: $bookId');
      
      if (headingsSnap.docs.isEmpty) {
        _log.warning('No headings found for book ID: $bookId in the top-level headings collection');
      }
      
      return headingsSnap.docs
          .map((doc) => Heading.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
       // Log error with more details
      _log.severe('Error fetching book headings for bookId $bookId: $e');
      return []; // Return empty list instead of rethrowing to avoid app crashes
    }
  }

  @override
  Future<List<Map<String, dynamic>>> extractChaptersFromContent(
    String content, {
    String? bookType,
    String? bookTitle,
    bool isTableOfContents = false,
  }) async {
    try {
      _log.info('Extracting chapters using AI for ${bookTitle ?? "unknown book"}');
      final chapters = await geminiService.extractChapters(
        content,
        bookType: bookType,
        title: bookTitle,
        isTableOfContents: isTableOfContents,
      );
      _log.info('Extracted ${chapters.length} chapters');
      return chapters;
    } catch (e) {
      _log.severe('Error extracting chapters: $e');
      // Return empty list as fallback
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> explainDifficultWords(
    String text, {
    String? targetLanguage,
    String? difficulty,
  }) async {
    try {
      _log.info('Identifying and explaining difficult words');
      final explanations = await geminiService.explainDifficultWords(
        text,
        targetLanguage: targetLanguage,
        difficulty: difficulty,
      );
      _log.info('Explained ${explanations.length} words');
      
      // Convert list to map for easier lookup
      Map<String, dynamic> wordMap = {};
      for (var word in explanations) {
        if (word.containsKey('word') && word.containsKey('definition')) {
          wordMap[word['word']] = word['definition'];
        }
      }
      
      return wordMap;
    } catch (e) {
      _log.severe('Error explaining difficult words: $e');
      return {};
    }
  }
  
  @override
  Future<Map<String, dynamic>> getRecommendedReadingSettings(
    String textSample, {
    String? language,
  }) async {
    try {
      _log.info('Recommending reading settings for text');
      final lang = language ?? 'English'; // Default to English if not provided
      final settings = await geminiService.recommendReadingSettings(
        textSample,
        lang,
      );
      return settings;
    } catch (e) {
      _log.severe('Error recommending reading settings: $e');
      return {
        'fontType': 'Serif',
        'fontSize': 16.0,
        'lineSpacing': 1.5,
        'colorScheme': 'light',
        'explanation': 'Default settings. AI recommendation failed.'
      };
    }
  }
  
  @override
  Future<Map<String, dynamic>> generateBookSummary(
    String text, {
    String? bookTitle,
    String? author,
    String? language,
  }) async {
    try {
      _log.info('Generating book summary');
      final title = bookTitle ?? 'Unknown Book';
      final authorName = author ?? 'Unknown Author';
      
      final summary = await geminiService.generateBookSummary(
        title,
        authorName,
        excerpt: text,
        language: language,
      );
      
      return summary;
    } catch (e) {
      _log.severe('Error generating book summary: $e');
      return {
        'summary': 'Failed to generate summary.',
        'themes': [],
        'keyTakeaways': []
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getBookRecommendations(
    List<String> recentBooks, {
    String preferredGenre = '',
    List<String>? preferredAuthors,
    String? readerProfile,
  }) async {
    try {
      _log.info('Getting book recommendations based on: ${recentBooks.join(", ")}');
      final recommendations = await geminiService.getBookRecommendations(
        recentBooks,
        preferredGenre: preferredGenre,
        preferredAuthors: preferredAuthors,
        readerProfile: readerProfile,
      );
      _log.info('Got ${recommendations.length} recommendations');
      return recommendations;
    } catch (e) {
      _log.severe('Error getting book recommendations: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> translateText(
    String text,
    String targetLanguage, {
    bool preserveFormatting = true,
  }) async {
    try {
      _log.info('Translating text to $targetLanguage');
      final translated = await geminiService.translateText(
        text,
        targetLanguage,
        preserveFormatting: preserveFormatting,
      );
      return translated;
    } catch (e) {
      _log.severe('Error translating text: $e');
      return {
        'translated': 'Translation failed',
        'detectedLanguage': 'unknown'
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchWithinContent(
    String query,
    String bookContent,
  ) async {
    try {
      _log.info('Searching for: "$query" in book content');
      // Split content into paragraphs for searching
      final paragraphs = bookContent
          .split('\n\n')
          .where((p) => p.trim().length > 20) // Filter out short paragraphs
          .take(50) // Limit to 50 paragraphs to avoid token limits
          .toList();
      
      final results = await geminiService.semanticSearch(query, paragraphs);
      _log.info('Found ${results.length} relevant paragraphs');
      return results;
    } catch (e) {
      _log.severe('Error searching within content: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> analyzeThemesAndConcepts(String text) async {
    try {
      _log.info('Analyzing themes and concepts in text');
      final analysis = await geminiService.analyzeThemesAndConcepts(text);
      return analysis;
    } catch (e) {
      _log.severe('Error analyzing themes and concepts: $e');
      return {
        'majorThemes': [],
        'concepts': [],
        'tone': 'Analysis failed',
        'style': 'Analysis failed',
      };
    }
  }
  
  @override
  Future<Map<String, dynamic>> generateTtsPrompt(
    String text, {
    String? voiceStyle,
    String? language,
  }) async {
    try {
      _log.info('Generating TTS prompt for text');
      final markers = await geminiService.generateSpeechMarkers(
        text,
        voiceStyle: voiceStyle,
        language: language,
      );
      return markers;
    } catch (e) {
      _log.severe('Error generating TTS prompt: $e');
      return {
        'ssml': text,
        'markedText': text,
        'emotion': 'neutral',
        'pace': 'medium',
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> suggestBookmarks(String text) async {
    try {
      _log.info('Suggesting bookmarks for text');
      final bookmarks = await geminiService.suggestBookmarks(text);
      _log.info('Suggested ${bookmarks.length} bookmarks');
      return bookmarks;
    } catch (e) {
      _log.severe('Error suggesting bookmarks: $e');
      return [];
    }
  }

  @override
  Future<dynamic> getHeadingById(String headingId) async {
    _log.info('Fetching heading with ID: $headingId');
    // Check cache first
    if (_headingCache.containsKey(headingId)) {
      _log.info('Returning cached heading for ID: $headingId');
      return _headingCache[headingId];
    }

    try {
      // Try both approaches: direct document ID lookup and field ID query
      DocumentSnapshot? headingDoc;
      
      // First try direct document lookup by ID
      headingDoc = await _firestore.collection('headings').doc(headingId).get();
      
      // If not found by document ID, try numeric ID field query
      if (!headingDoc.exists) {
        final numericId = int.tryParse(headingId);
        if (numericId != null) {
          _log.info('Heading not found by document ID, trying numeric id field: $numericId');
          final querySnap = await _firestore
              .collection('headings')
              .where('id', isEqualTo: numericId)
              .limit(1)
              .get();
              
          if (querySnap.docs.isNotEmpty) {
            headingDoc = querySnap.docs.first;
          }
        }
      }
      
      // If still not found, return null
      if (!headingDoc.exists) {
        _log.warning('No heading found with ID: $headingId (tried both document ID and id field)');
        return null;
      }
      
      final headingData = headingDoc.data() as Map<String, dynamic>;

      if (!isValidHeadingData(headingData)) {
        _log.warning('Invalid heading data for ID: $headingId. Data: $headingData');
        return null; 
      }
      
      // Fetch the chapter associated with this heading to get the title
      String? chapterTitle;
      if (headingData['chapter_id'] != null) {
        // For chapter lookup, handle both string and int IDs
        final chapterId = headingData['chapter_id'];
        final chapterIdString = chapterId.toString();
        
        DocumentSnapshot? chapterDocSnap;
        // Try document ID first
        chapterDocSnap = await _firestore.collection('chapters')
            .doc(chapterIdString)
            .get();
        
        // If not found by document ID, try numeric ID field
        if (!chapterDocSnap.exists && chapterId is int) {
          final querySnap = await _firestore
              .collection('chapters')
              .where('id', isEqualTo: chapterId)
              .limit(1)
              .get();
              
          if (querySnap.docs.isNotEmpty) {
            chapterDocSnap = querySnap.docs.first;
          }
        }
        
        if (chapterDocSnap.exists && chapterDocSnap.data() != null) {
          chapterTitle = (chapterDocSnap.data() as Map<String,dynamic>)['title'];
        }
      }
      
      // Create a heading object with the necessary data
      final headingResult = {
        'id': headingDoc.id, // Use the actual document ID from Firestore
        'title': headingData['title'],
        'content': headingData['content'] is List 
            ? List<String>.from(headingData['content']) 
            : [headingData['content']?.toString() ?? ''],
        'chapterTitle': chapterTitle,
        'language': headingData['language'] ?? 'en',
        'subtitle': headingData['subtitle'], // Ensure subtitle is included
      };

      // Cache the result
      _headingCache[headingId] = headingResult;
      _log.info('Fetched and cached heading for ID: $headingId with ${headingResult['content'].length} content items');
      return headingResult;

    } catch (e, stackTrace) {
      _log.severe('Error fetching heading by ID: $e', e, stackTrace);
      return null; // Return null instead of throwing to avoid app crashes
    }
  }

  // Test method to verify Firestore structure
  @override
  Future<void> debugFirestoreStructure(String bookId) async {
    try {
      _log.info('--- DEBUGGING FIRESTORE STRUCTURE FOR BOOK ID: $bookId ---');
      // Check top-level books collection
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      _log.info('Book document exists: ${bookDoc.exists}');
      
      if (bookDoc.exists) {
        _log.info('Book data: ${bookDoc.data()}');
      }
      
      // Check if there's a nested headings subcollection
      final nestedHeadingsSnap = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('headings')
          .limit(1)
          .get();
      _log.info('Nested headings subcollection (under books/$bookId) has items: ${nestedHeadingsSnap.docs.isNotEmpty}');
      
      // Check top-level headings with book_id filter
      final numericBookId = int.tryParse(bookId);
      if (numericBookId != null) {
        _log.info('Querying top-level /headings collection with book_id == $numericBookId');
        final topLevelHeadingsSnap = await _firestore
            .collection('headings')
            .where('book_id', isEqualTo: numericBookId)
            .orderBy('sequence')
            .limit(10)
            .get();
        _log.info('Top-level /headings found: ${topLevelHeadingsSnap.docs.length}');
        
        for(var doc in topLevelHeadingsSnap.docs) {
          _log.info('  Heading ID: ${doc.id}, Data: ${doc.data()}');
        }
      } else {
         _log.warning('Book ID $bookId is not numeric, cannot query top-level headings by book_id.');
      }

      // Check top-level chapters with book_id filter
      if (numericBookId != null) {
        _log.info('Querying top-level /chapters collection with book_id == $numericBookId');
        final topLevelChaptersSnap = await _firestore
            .collection('chapters')
            .where('book_id', isEqualTo: numericBookId)
            .orderBy('sequence')
            .limit(10)
            .get();
        _log.info('Top-level /chapters found: ${topLevelChaptersSnap.docs.length}');
        
        for(var doc in topLevelChaptersSnap.docs) {
          _log.info('  Chapter ID: ${doc.id}, Data: ${doc.data()}');
        }
      } else {
        _log.warning('Book ID $bookId is not numeric, cannot query top-level chapters by book_id.');
      }
      _log.info('--- END DEBUGGING FIRESTORE STRUCTURE ---');

    } catch (e) {
      _log.severe('Debug error: $e');
    }
  }

  // Robust Data Validation Method
  bool isValidHeadingData(Map<String, dynamic> data) {
    // Check if required fields exist and have correct types
    if (!data.containsKey('title') || data['title'] == null) {
      _log.warning('Heading missing title field or title is null. Data: $data');
      return false;
    }
    
    if (!data.containsKey('content')) {
      _log.warning('Heading missing content field. Data: $data');
      return false;
    }
    
    // Check content field type and handle accordingly
    // Allow content to be null or empty, but it must exist
    if (data['content'] != null && data['content'] is! List && data['content'] is! String) {
      _log.warning('Heading content is not null, List, or String: ${data['content'].runtimeType}. Data: $data');
      return false;
    }
    
    // Check if 'sequence' field exists and is a number (important for ordering)
    if (!data.containsKey('sequence') || data['sequence'] is! num) {
        _log.warning('Heading missing or invalid sequence field. Data: $data');
        // Not returning false, as it might still be displayable, but logging a warning.
    }

    // Check if 'book_id' field exists (important for linking)
     if (!data.containsKey('book_id')) {
        _log.warning('Heading missing book_id field. Data: $data');
        // Not returning false, as it might still be displayable if fetched by direct ID, but logging.
    }
    return true;
  }

  // --- Bookmark Methods (Local Storage Implementation) ---

  Future<List<Bookmark>> _getLocalBookmarks(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? bookmarksJson = prefs.getString('$_bookmarkStorePrefix$bookId');
    if (bookmarksJson == null) {
      return [];
    }
    try {
      final List<dynamic> decodedJson = jsonDecode(bookmarksJson);
      return decodedJson.map((jsonItem) {
        // Manually reconstruct Bookmark from JSON, handling Timestamp
        return Bookmark(
          id: jsonItem['headingId'] as String, // Use headingId as id for local
          bookId: jsonItem['bookId'] as String,
          chapterId: jsonItem['chapterId'] as String,
          chapterTitle: jsonItem['chapterTitle'] as String,
          headingId: jsonItem['headingId'] as String,
          headingTitle: jsonItem['headingTitle'] as String,
          // Convert milliseconds_since_epoch (int) back to Timestamp
          timestamp: Timestamp.fromMillisecondsSinceEpoch(jsonItem['timestamp_epoch'] as int),
          textContentSnippet: jsonItem['textContentSnippet'] as String?,
        );
      }).toList();
    } catch (e) {
      _log.severe('Error decoding bookmarks for book $bookId from local storage: $e');
      return [];
    }
  }

  Future<void> _saveLocalBookmarks(String bookId, List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    // Sort by timestamp descending before saving, mimicking Firestore query
    bookmarks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final List<Map<String, dynamic>> encodableBookmarks = bookmarks.map((bookmark) {
      // Manually convert Bookmark to a JSON-encodable map
      return {
        'bookId': bookmark.bookId,
        'chapterId': bookmark.chapterId,
        'chapterTitle': bookmark.chapterTitle,
        'headingId': bookmark.headingId,
        'headingTitle': bookmark.headingTitle,
        // Convert Timestamp to milliseconds_since_epoch (int) for JSON
        'timestamp_epoch': bookmark.timestamp.millisecondsSinceEpoch,
        'textContentSnippet': bookmark.textContentSnippet,
      };
    }).toList();
    final String bookmarksJson = jsonEncode(encodableBookmarks);
    await prefs.setString('$_bookmarkStorePrefix$bookId', bookmarksJson);
  }

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    try {
      List<Bookmark> bookmarks = await _getLocalBookmarks(bookmark.bookId);
      // Remove if exists (to update)
      bookmarks.removeWhere((b) => b.headingId == bookmark.headingId);
      bookmarks.add(bookmark);
      await _saveLocalBookmarks(bookmark.bookId, bookmarks);
      _log.info('Local bookmark added/updated for book ${bookmark.bookId}, heading ${bookmark.headingId}');
    } catch (e) {
      _log.severe('Error adding local bookmark for book ${bookmark.bookId}, heading ${bookmark.headingId}: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeBookmark(String bookId, String bookmarkId) async {
    // bookmarkId here is expected to be the headingId
    try {
      List<Bookmark> bookmarks = await _getLocalBookmarks(bookId);
      bookmarks.removeWhere((b) => b.headingId == bookmarkId);
      await _saveLocalBookmarks(bookId, bookmarks);
      _log.info('Local bookmark removed for book $bookId, bookmark/heading $bookmarkId');
    } catch (e) {
      _log.severe('Error removing local bookmark for book $bookId, bookmark/heading $bookmarkId: $e');
      rethrow;
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks(String bookId) async {
    try {
      final bookmarks = await _getLocalBookmarks(bookId);
      _log.info('Fetched ${bookmarks.length} local bookmarks for book $bookId');
      return bookmarks; // Already sorted by _saveLocalBookmarks if needed, or sort here.
    } catch (e) {
      _log.severe('Error fetching local bookmarks for book $bookId: $e');
      return [];
    }
  }
}

// Define the provider for ReadingRepository
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  final geminiService = ref.watch(geminiServiceProvider); // Get GeminiService via its provider
  // Create and return an instance of ReadingRepositoryImpl
  final repository = ReadingRepositoryImpl(
    geminiService: geminiService,
  );
  
  // Example: Call debugFirestoreStructure for a specific book ID when provider is first read
  // repository.debugFirestoreStructure("101"); // Replace "101" with a known book ID
  
  return repository;
}); 