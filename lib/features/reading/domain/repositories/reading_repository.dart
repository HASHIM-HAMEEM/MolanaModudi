import 'package:modudi/features/books/data/models/book_models.dart';
import '../../data/models/bookmark_model.dart';

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
  
  /// Fetches a specific heading by its ID
  Future<dynamic> getHeadingById(String headingId);

  // Bookmark methods
  Future<void> addBookmark(Bookmark bookmark);
  Future<void> removeBookmark(String bookId, String bookmarkId);
  Future<List<Bookmark>> getBookmarks(String bookId);

  // Debug method for Firestore structure (if you need to keep it)
  Future<void> debugFirestoreStructure(String bookId);
  
  // Offline reading methods
  /// Download book and all related content for offline reading
  Future<bool> downloadBookForOfflineReading(String bookId);
  
  /// Check if book is fully downloaded and available offline
  Future<bool> isBookAvailableOffline(String bookId);
  
  /// Get a list of all downloaded book IDs
  Future<List<String>> getDownloadedBookIds();
  
  /// Get a stream of download progress events
  Stream<Map<String, dynamic>> getDownloadProgressStream();

  // Methods from BooksRepository
  Future<List<Book>> getBooks({String? category, int limit = 50, dynamic startAfter});
  Future<List<Book>> searchBooks(String query);
  Future<List<Book>> getFeaturedBooks({int limit = 10});
  Future<Map<String, int>> getCategories();

  // Method to get structured book content (volumes, chapters, headings)
  Future<BookStructure> getBookStructure(String bookId);
}
// Ensure BookStructure is imported if defined in a separate file
// For example, if it's in 'package:modudi/features/reading/domain/entities/book_structure.dart'
import 'package:modudi/features/reading/domain/entities/book_structure.dart';