import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:modudi/core/services/gemini_service.dart'; // Import Gemini service
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'package:modudi/models/book_models.dart'; // Import new models
import 'package:logging/logging.dart'; // Import logger

class ReadingRepositoryImpl implements ReadingRepository {
  final GeminiService geminiService;
  final FirebaseFirestore _firestore; // Add Firestore instance
  final _log = Logger('ReadingRepository'); // Add logger instance

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
      print('Error fetching book data: $e');
      rethrow;
    }
  }

  @override
  Future<List<Heading>> getBookHeadings(String bookId) async {
    try {
      final headingsSnap = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('headings')
          .orderBy('sequence') // Assuming sequence field for ordering
          .get();
          
      return headingsSnap.docs
          .map((doc) => Heading.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
       // Log error
      print('Error fetching book headings: $e');
      rethrow;
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
      
      if (summary == null) {
        return {
          'summary': 'Failed to generate summary.',
          'themes': [],
          'keyTakeaways': []
        };
      }
      
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
}

// Define the provider for ReadingRepository
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  final geminiService = ref.watch(geminiServiceProvider); // Get GeminiService via its provider
  return ReadingRepositoryImpl(
    geminiService: geminiService,
  );
}); 