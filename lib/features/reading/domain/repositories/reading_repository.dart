import 'package:modudi/models/book_models.dart';

/// Abstract repository for fetching book files.
abstract class ReadingRepository {
  /// Fetches the full Book object from Firestore.
  Future<Book> getBookData(String bookId);
  
  /// Fetches the Headings for a specific book from its subcollection.
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
} 