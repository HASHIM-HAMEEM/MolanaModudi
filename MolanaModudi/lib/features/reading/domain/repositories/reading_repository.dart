import 'package:modudi/features/books/data/models/book_models.dart';
import '../../data/models/bookmark_model.dart';
import 'package:modudi/core/cache/models/cache_result.dart';

/// Abstract repository for fetching book files.
abstract class ReadingRepository {
  /// Fetches the full Book object from Firestore.
  /// Returns a CacheResult to allow UI to distinguish between fresh/stale cache and network data.
  Future<CacheResult<Book>> getBookData(String bookId);
  
  /// Returns headings for a book. May leverage L1/L2 cache before network.
  Future<List<Heading>> getBookHeadings(String bookId);
  
  /// Extract chapters from book content using AI
  Future<List<Map<String, dynamic>>> extractChaptersFromContent(
    String content, {
    String? bookType,
    String? bookTitle,
    bool isTableOfContents = false,
  });
  
  /// Generate a comprehensive book summary with themes and key takeaways
  Future<Map<String, dynamic>> generateBookSummary(
    String text, {
    String? bookTitle,
    String? author,
    String? language,
  });
  
  /// Get detailed book recommendations based on reading history and preferences
  Future<List<Map<String, dynamic>>> getBookRecommendations(
    List<String> recentBooks, {
    String preferredGenre = '',
    List<String>? preferredAuthors,
    String? readerProfile,
  });
  
  /// Translate text to a target language with formatting preservation
  Future<Map<String, dynamic>> translateText(
    String text,
    String targetLanguage, {
    bool preserveFormatting = true,
  });
  
  /// Semantic search for relevant content with explanations
  Future<List<Map<String, dynamic>>> searchWithinContent(
    String query,
    String bookContent,
  );
  
  /// Get explanations for difficult words with examples and context
  Future<Map<String, dynamic>> explainDifficultWords(
    String text, {
    String? targetLanguage,
    String? difficulty,
  });
  
  /// Analyze text for themes and literary concepts
  Future<Map<String, dynamic>> analyzeThemesAndConcepts(
    String text,
  );
  
  /// Get recommended reading settings based on text sample and language
  Future<Map<String, dynamic>> getRecommendedReadingSettings(
    String textSample, {
    String? language,
  });
  
  /// Suggest important passages for bookmarking
  Future<List<Map<String, dynamic>>> suggestBookmarks(
    String text,
  );
  
  /// Generate speech markers for text-to-speech
  Future<Map<String, dynamic>> generateTtsPrompt(
    String text, {
    String? voiceStyle,
    String? language,
  });
  
  /// Fetches a specific heading by its ID
  Future<dynamic> getHeadingById(String headingId);

  // Bookmark methods
  Future<void> addBookmark(SimpleBookmark bookmark);
  Future<void> removeBookmark(String bookId, String bookmarkId);
  Future<List<SimpleBookmark>> getBookmarks(String bookId);

  // Debug method for Firestore structure (if you need to keep it)
  Future<void> debugFirestoreStructure(String bookId);
} 