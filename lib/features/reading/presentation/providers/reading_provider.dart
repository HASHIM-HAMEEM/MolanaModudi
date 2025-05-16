// For File operations
import 'dart:convert'; // For utf8 encoding/decoding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// For repository provider dependency
import 'package:modudi/core/services/gemini_service.dart'; // Import for geminiServiceProvider
import 'package:modudi/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'reading_state.dart';
import 'dart:async';
// Need book details for language check
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/reading/data/models/bookmark_model.dart'; // Explicitly import the correct Bookmark
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Timestamp

// Provider for ReadingRepository
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  // final apiService = ref.watch(archiveApiServiceProvider); // Use existing API service
  final geminiService = ref.watch(geminiServiceProvider); // Add GeminiService
  return ReadingRepositoryImpl(
    // apiService: apiService, // Removed apiService parameter
    geminiService: geminiService
  );
});

// StateNotifier for Reading Screen logic
class ReadingNotifier extends StateNotifier<ReadingState> {
  final ReadingRepository _repository;
  final String _bookId;
  final _log = Logger('ReadingNotifier');
  
  // Reading progress tracking
  static const _allowedLanguages = {'eng', 'ara', 'urd'}; // Allowed language codes

  ReadingNotifier(this._repository, this._bookId) 
      : super(const ReadingState()) {
    _log.info('ReadingNotifier initialized for bookId: $_bookId');
    loadContent();
  }

  Future<void> loadContent() async {
    _log.info('Loading content for book ID: $_bookId...');
    if (state.status == ReadingStatus.loadingMetadata || 
        state.status == ReadingStatus.loadingContent || 
        state.status == ReadingStatus.downloading) {
      return;
    }

    try {
      state = state.copyWith(status: ReadingStatus.loadingMetadata, bookId: _bookId);

      final book = await _repository.getBookData(_bookId);
      state = state.copyWith(book: book, bookTitle: book.title, currentLanguage: book.languageCode ?? 'en');
      _log.info('Fetched book title: ${book.title}');

      await _loadReadingProgress(); // Load progress first

      final headings = await _repository.getBookHeadings(_bookId);
      state = state.copyWith(headings: headings);
      _log.info('Fetched ${headings.length} headings for book ID: $_bookId');

      // Load bookmarks
      await _loadBookmarks();

      if (headings.isNotEmpty) {
        _prepareTextDisplayFromHeadings(headings);
      } else {
        _log.warning('No headings found for book $_bookId. Check Firestore data structure.');
        state = state.copyWith(
          status: ReadingStatus.error,
          errorMessage: 'No content structure (headings) found for this book.'
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Error loading book content for $_bookId: $e', e, stackTrace);
      state = state.copyWith(status: ReadingStatus.error, errorMessage: e.toString());
    }
  }

  // Helper to load bookmarks
  Future<void> _loadBookmarks() async {
    if (state.bookId == null) return;
    try {
      final bookmarks = await _repository.getBookmarks(state.bookId!);
      state = state.copyWith(bookmarks: bookmarks);
      _log.info('Loaded ${bookmarks.length} bookmarks for book ${state.bookId}');
    } catch (e) {
      _log.severe('Error loading bookmarks for book ${state.bookId}: $e');
      // Optionally set an error state or leave bookmarks as empty
    }
  }

  // Method to toggle a bookmark for a specific heading
  Future<void> toggleBookmark(Heading heading, String chapterId, String chapterTitle) async {
    if (state.bookId == null) {
      _log.warning('Cannot toggle bookmark: bookId or headingId is null.');
      return;
    }

    final existingBookmarkIndex = state.bookmarks.indexWhere((b) => b.headingId == heading.firestoreDocId);

    try {
      if (existingBookmarkIndex != -1) {
        // Bookmark exists, remove it
        final bookmarkToRemove = state.bookmarks[existingBookmarkIndex];
        await _repository.removeBookmark(state.bookId!, bookmarkToRemove.id); // Assuming bookmark.id is headingId
        _log.info('Bookmark removed: ${bookmarkToRemove.id}');
        } else {
        // Bookmark does not exist, add it
        // Create a snippet of the content
        String? snippet;
        if (heading.content != null && heading.content!.isNotEmpty) {
          snippet = heading.content!.first.length > 100 
              ? '${heading.content!.first.substring(0, 97)}...' 
              : heading.content!.first;
        }

        final newBookmark = Bookmark(
          id: heading.firestoreDocId, // Using headingId as the bookmark's own ID in Firestore doc path
          bookId: state.bookId!,
          chapterId: chapterId, 
          chapterTitle: chapterTitle,
          headingId: heading.firestoreDocId, 
          headingTitle: heading.title ?? 'Unnamed Section',
          timestamp: Timestamp.now(),
          textContentSnippet: snippet,
        );
        await _repository.addBookmark(newBookmark);
        _log.info('Bookmark added: ${newBookmark.id}');
      }
      // Refresh bookmarks from repository to ensure UI consistency
      await _loadBookmarks();
    } catch (e) {
      _log.severe('Error toggling bookmark for heading ${heading.firestoreDocId}: $e');
      // Optionally notify UI of error
    }
  }

  void _prepareTextDisplayFromHeadings(List<Heading> headings) {
      if (headings.isEmpty) {
      state = state.copyWith(
          status: ReadingStatus.error, 
          errorMessage: 'No headings available to display.'
      );
      _log.warning('prepareTextDisplayFromHeadings called with empty headings.');
      return;
    }

    List<String> mainChapterKeys = [];
    Map<String, List<Heading>> groupedHeadings = {};

    for (var heading in headings) {
      String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
      if (!groupedHeadings.containsKey(chapterKey)) {
        mainChapterKeys.add(chapterKey);
      }
      (groupedHeadings[chapterKey] ??= []).add(heading);
    }
    
    // Ensure currentChapter is within bounds after processing
    int initialChapterIndex = state.currentChapter.clamp(0, mainChapterKeys.isNotEmpty ? mainChapterKeys.length - 1 : 0);

        state = state.copyWith(
          status: ReadingStatus.displayingText,
        mainChapterKeys: mainChapterKeys,
        currentChapter: initialChapterIndex, // Use the clamped initial chapter index
        // textContent will be built by PageView itemBuilder based on groupedHeadings
    );
    _log.info('Processing ${headings.length} headings for text display, organized into ${mainChapterKeys.length} main chapters.');
    _log.info('Set up for text display with ${mainChapterKeys.length} main chapters. Current logical chapter: ${state.currentChapter}');
  }

  void navigateToLogicalChapter(int logicalChapterIndex) {
    if (logicalChapterIndex >= 0 && logicalChapterIndex < state.mainChapterKeys.length) {
      if (state.currentChapter != logicalChapterIndex) {
        _log.info('Navigating to logical main chapter index: $logicalChapterIndex. Total main chapters: ${state.mainChapterKeys.length}');
        state = state.copyWith(currentChapter: logicalChapterIndex);
        _saveReadingProgress(); // Save progress when chapter changes
        _log.info('Successfully navigated to logical main chapter: $logicalChapterIndex');
      } else {
        _log.info('Already on logical main chapter: $logicalChapterIndex. No navigation needed.');
      }
    } else {
      _log.warning('Invalid logical chapter index: $logicalChapterIndex. Total chapters: ${state.mainChapterKeys.length}');
    }
  }
  
  Future<void> _saveReadingProgress() async {
    if (state.bookId == null || state.bookTitle == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = {
        'bookId': state.bookId!,
        'bookTitle': state.bookTitle!,
        'currentChapter': state.currentChapter,
        'totalChapters': state.mainChapterKeys.length,
        'percentage': state.mainChapterKeys.isNotEmpty 
            ? ((state.currentChapter + 1) / state.mainChapterKeys.length * 100).round()
            : 0,
        'lastReadTimestamp': DateTime.now().toIso8601String(),
        'textScrollPosition': state.textScrollPosition, // Save scroll position
      };
      await prefs.setString('reading_progress_${state.bookId}', jsonEncode(progress));
      _log.info('Saved reading progress for book: ${state.bookTitle}, progress: ${progress['percentage']}% (Logical Chapter: ${state.currentChapter}/${state.mainChapterKeys.length-1})');
    } catch (e) {
      _log.severe('Error saving reading progress: $e');
    }
  }

  Future<void> _loadReadingProgress() async {
    if (state.bookId == null) return;
    SharedPreferences? prefs; // Declare prefs here to be accessible in catch
    try {
      prefs = await SharedPreferences.getInstance(); // Assign here
      final progressString = prefs.getString('reading_progress_${state.bookId}');
      if (progressString != null) {
        final progress = jsonDecode(progressString);
          state = state.copyWith(
          currentChapter: progress['currentChapter'] ?? 0,
          textScrollPosition: progress['textScrollPosition'] ?? 0.0,
          );
        _log.info('Loaded reading progress for book ${state.bookId}: Chapter ${state.currentChapter}, Scroll: ${state.textScrollPosition}');
      }
    } catch (e) {
      _log.warning('Error loading reading progress: $e. Data: ${prefs?.getString('reading_progress_${state.bookId}')}'); // Use null-aware access for prefs in catch
      // If there's an error (e.g., FormatException), reset progress for this book
      final prefsInstance = prefs ?? await SharedPreferences.getInstance(); // Ensure prefsInstance is initialized
      await prefsInstance.remove('reading_progress_${state.bookId}');
      _log.info('Corrupted reading progress for book ${state.bookId} removed.');
      state = state.copyWith(currentChapter: 0, textScrollPosition: 0.0); 
    }
  }

  void updateTextPosition(double scrollRatio) {
    if (state.textScrollPosition != scrollRatio) {
      state = state.copyWith(textScrollPosition: scrollRatio);
      // Consider if progress should be saved on every scroll update or less frequently
      // For now, let's save it, but this could be throttled.
      _saveReadingProgress(); 
    }
  }

  // Placeholder for missing method
  Future<void> _saveProgress() async {
    _log.info("[_saveProgress] Progress saving logic to be implemented.");
    // Actual implementation for saving progress will go here
    // This might involve SharedPreferences or a backend service
  }

  // AI Related Methods (Preserve these and ensure they fit with new state management)
  Future<void> extractChaptersWithAi({bool forceTocExtraction = false}) async {
    if (state.status != ReadingStatus.displayingText || state.book == null) {
      _log.warning('Cannot extract chapters: Not in displaying state or book data missing.');
      return;
    }
    if (state.isTocExtracted && !forceTocExtraction) {
      _log.info('Chapters already extracted by AI. Skipping.');
      return;
    }

    try {
      _log.info('Starting AI chapter extraction for book: ${state.bookTitle}');
      // Concatenate content from all headings for AI analysis
      String fullContent = state.headings?.map((h) => h.content?.join('\n') ?? '').join('\n\n') ?? state.textContent ?? '';
      if (fullContent.isEmpty) {
        _log.warning('No content available for AI chapter extraction.');
        return;
      }

      final chapters = await _repository.extractChaptersFromContent(
        fullContent,
        bookType: state.book?.type,
        bookTitle: state.bookTitle,
        isTableOfContents: forceTocExtraction, // Use parameter
      );
      state = state.copyWith(aiExtractedChapters: chapters, isTocExtracted: true);
      _log.info('AI chapter extraction complete. Found ${chapters.length} chapters.');

    } catch (e) {
      _log.severe('Error during AI chapter extraction: $e');
      state = state.copyWith(errorMessage: 'Failed to extract chapters with AI.');
    }
  }

  Future<void> analyzeDifficultWords(String textToAnalyze) async {
    if (state.difficultWords != null && state.difficultWords!.isNotEmpty) {
      _log.info('Difficult words already analyzed. Skipping.');
      return;
    }
    try {
      _log.info('Starting difficult word analysis.');
      final words = await _repository.explainDifficultWords(
        textToAnalyze, 
        targetLanguage: state.currentLanguage,
        // difficulty: 'intermediate' // Example, make this configurable if needed
      );
      state = state.copyWith(difficultWords: words.cast<String, String>()); // Ensure correct type casting
      _log.info('Difficult word analysis complete. Found ${words.length} words.');
    } catch (e) {
      _log.severe('Error during difficult word analysis: $e');
      state = state.copyWith(errorMessage: 'Failed to analyze vocabulary.');
    }
  }

  Future<void> translateText(String text, String targetLanguage) async {
    try {
      _log.info('Translating text to $targetLanguage.');
      final translationData = await _repository.translateText(text, targetLanguage);
      state = state.copyWith(currentTranslation: translationData);
      _log.info('Text translation complete.');
    } catch (e) {
      _log.severe('Error during text translation: $e');
      state = state.copyWith(currentTranslation: {'translated': 'Translation failed.'});
    }
  }
  
  Future<void> getRecommendedReadingSettings() async {
    if (state.recommendedSettings != null && state.recommendedSettings!.isNotEmpty) {
      _log.info('Recommended settings already fetched. Skipping.');
      return;
    }
    // Use a sample of the book content
    String sampleText = state.headings?.take(2).map((h) => h.content?.join(' ') ?? '').join('\n') ?? state.textContent?.substring(0, min(state.textContent?.length ?? 0, 500)) ?? '';
    if (sampleText.isEmpty) {
      _log.warning('No sample text available for recommending settings.');
      return;
    }

    try {
      _log.info('Fetching recommended reading settings.');
      final settings = await _repository.getRecommendedReadingSettings(sampleText, language: state.currentLanguage);
      state = state.copyWith(recommendedSettings: settings);
      _log.info('Recommended reading settings fetched.');
    } catch (e) {
      _log.severe('Error fetching recommended settings: $e');
      // state = state.copyWith(errorMessage: 'Failed to get settings recommendations.');
    }
  }

  Future<void> suggestBookMarksFromAi() async {
    if (state.suggestedBookmarks != null && state.suggestedBookmarks!.isNotEmpty) {
      _log.info('AI Bookmarks already suggested. Skipping.');
      return;
    }
    String fullContent = state.headings?.map((h) => h.content?.join('\n') ?? '').join('\n\n') ?? state.textContent ?? '';
    if (fullContent.isEmpty) {
      _log.warning('No content available for AI bookmark suggestion.');
      return;
    }

    try {
      _log.info('Starting AI bookmark suggestion.');
      final bookmarks = await _repository.suggestBookmarks(fullContent);
      state = state.copyWith(suggestedBookmarks: bookmarks);
      _log.info('AI bookmark suggestion complete. Found ${bookmarks.length} suggestions.');
    } catch (e) {
      _log.severe('Error during AI bookmark suggestion: $e');
      // state = state.copyWith(errorMessage: 'Failed to suggest bookmarks with AI.');
    }
  }
  
  Future<void> generateSpeechMarkers(String text) async {
    try {
      final markers = await _repository.generateTtsPrompt(text, language: state.currentLanguage);
      state = state.copyWith(speechMarkers: markers, isSpeaking: true);
    } catch (e) {
      _log.severe('Error generating speech markers: $e');
      // state = state.copyWith(errorMessage: 'Failed to prepare text for speech.');
    }
  }

  void startSpeaking() {
    // Placeholder: actual TTS would start here using speechMarkers
    state = state.copyWith(isSpeaking: true);
    _log.info('TTS Started (simulated)');
  }

  void stopSpeaking() {
    state = state.copyWith(isSpeaking: false, highlightedTextPosition: null);
    _log.info('TTS Stopped');
  }

  void updateHighlightedTextPosition(Map<String, dynamic> position) {
    state = state.copyWith(highlightedTextPosition: position);
  }

  // Method to navigate to a chapter (potentially called from older UI parts or AI tools)
  void navigateToChapter(int chapterIndex) {
    _log.info("navigateToChapter called with: $chapterIndex. Forwarding to navigateToLogicalChapter.");
    navigateToLogicalChapter(chapterIndex);
  }

  // Method to clear specific AI-generated data from state
  void clearAiFeature(String feature) {
    _log.info("Clearing AI feature: $feature");
    final Map<String, AiFeatureStatus> currentStatus = 
        state.aiFeatureStatus.map((key, value) => MapEntry(key, AiFeatureStatus.initial));

    switch (feature) {
      case 'extract_chapters':
        state = state.copyWith(aiExtractedChapters: [], aiFeatureStatus: currentStatus);
        break;
      case 'summarize_book':
        state = state.copyWith(bookSummary: null, aiFeatureStatus: currentStatus);
        break;
      case 'identify_themes':
        state = state.copyWith(themeAnalysis: null, aiFeatureStatus: currentStatus);
        break;
      case 'define_word':
        state = state.copyWith(difficultWords: {}, aiFeatureStatus: currentStatus);
        break;
      case 'suggest_recommendations':
        state = state.copyWith(bookRecommendations: [], aiFeatureStatus: currentStatus);
        break;
      case 'search_book':
        state = state.copyWith(searchResults: [], lastSearchQuery: null, aiFeatureStatus: currentStatus);
        break;
      case 'suggest_bookmarks':
         state = state.copyWith(suggestedBookmarks: [], aiFeatureStatus: currentStatus);
        break;
      case 'recommend_settings':
        state = state.copyWith(recommendedSettings: null, aiFeatureStatus: currentStatus);
        break;
      default:
        _log.warning("Unknown AI feature to clear: $feature");
        // Optionally, clear all or a generic state. If so, ensure currentStatus is a fresh map for all features.
        // For example, to reset all known AI features:
        // state = state.copyWith(
        //   aiExtractedChapters: [], bookSummary: null, themeAnalysis: null, difficultWords: {},
        //   bookRecommendations: [], searchResults: [], lastSearchQuery: null, suggestedBookmarks: [],
        //   recommendedSettings: null, 
        //   aiFeatureStatus: Map.fromEntries(state.aiFeatureStatus.keys.map((k) => MapEntry(k, AiFeatureStatus.initial)))
        // );
        break;
    }
    _log.info("AI feature $feature cleared. Status updated.");
  }

  // Reload content method
  Future<void> reload() async {
    _log.info('Reloading content for book ID: $_bookId');
    // Reset relevant parts of the state before reloading
    state = ReadingState(bookId: _bookId, currentChapter: state.currentChapter, textScrollPosition: state.textScrollPosition); // Preserve bookId and potentially last known position
    await loadContent();
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  String _formatTextContent(String text) {
    if (text.isEmpty) return text;
    _log.info('Formatting text content for better readability');
    try {
      String formatted = text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');
      formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      formatted = formatted.replaceAll(RegExp(r'([^\n])\n([^\n])'), r'$1\n\n$2');
      formatted = formatted.replaceAll(RegExp(r'([a-zA-Z])- ([a-zA-Z])'), r'$1$2');
      formatted = formatted.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0900-\u097F]'), ' ');
      List<String> paragraphs = formatted.split('\n\n');
      List<String> cleanedParagraphs = [];
      for (String p in paragraphs) {
        if (p.trim().isEmpty) continue;
        p = p.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (p == p.toUpperCase() || p.startsWith('#') || p.length < 50) {
          cleanedParagraphs.add(p);
        } else {
          cleanedParagraphs.add('    $p');
        }
      }
      return cleanedParagraphs.join('\n\n');
    } catch (e, st) {
      _log.severe('Error formatting text content: $e', e, st);
      return text;
    }
  }

  Future<void> saveReadingProgress({
    required String bookId,
    required String title,
    String? author,
    String? coverUrl,
    required double progress,
    int? currentPage,
    int? totalPages,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentBooksJson = prefs.getStringList('recentBooks') ?? [];
      final newBook = {
        'id': bookId,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'progress': progress,
        'lastReadTime': DateTime.now().millisecondsSinceEpoch,
        'currentPage': currentPage,
        'totalPages': totalPages,
      };
      final newBookJson = json.encode(newBook);
      final updatedList = recentBooksJson.where((item) {
        try {
          final Map<String, dynamic> data = json.decode(item);
          return data['id'] != bookId;
        } catch (e) {
          return true; 
        }
      }).toList();
      updatedList.insert(0, newBookJson);
      if (updatedList.length > 20) {
        updatedList.removeRange(20, updatedList.length);
      }
      await prefs.setStringList('recentBooks', updatedList);
      _log.info('Saved reading progress for book: $title, progress: ${(progress * 100).toInt()}% (Logical Chapter: $currentPage/$totalPages)');
    } catch (e) {
      _log.severe('Error saving reading progress: $e');
    }
  }

  double? _lastSavedProgress;

  void _positionUpdate(double position) {
    final progress = position.clamp(0.0, 1.0);
    if (_lastSavedProgress == null || (_lastSavedProgress! - progress).abs() > 0.05 || state.currentChapter != (_lastSavedProgress! * state.totalChapters).floor()) {
      final bookTitle = state.bookTitle ?? _bookId;
      saveReadingProgress(
        bookId: _bookId,
        title: bookTitle,
        progress: progress,
        currentPage: state.currentChapter,
        totalPages: state.totalChapters,
      );
      _lastSavedProgress = progress;
    }
  }
  
  void updateChapters(List<Map<String, dynamic>> chapters) {
    if (!mounted) return;
    _log.info('Updating chapters with AI extraction: ${chapters.length} chapters found');
    state = state.copyWith(
      aiExtractedChapters: chapters,
      totalChapters: chapters.length, 
    );
    _saveProgress();
  }

  void updateVocabulary(List<Map<String, dynamic>> words) {
    if (!mounted) return;
    _log.info('Updating vocabulary with ${words.length} difficult words');

    Map<String, String> newDifficultWords = {};
    for (var wordData in words) {
      // Assuming wordData contains 'term' and 'definition' keys
      // Adjust keys if necessary based on actual data structure from AI service
      final term = wordData['term'] as String?;
      final definition = wordData['definition'] as String?;
      if (term != null && definition != null) {
        newDifficultWords[term] = definition;
      }
    }

    state = state.copyWith(
      difficultWords: newDifficultWords,
      aiFeatureStatus: {...state.aiFeatureStatus, 'vocabulary': AiFeatureStatus.ready}, // Ensure 'vocabulary' matches the feature key
    );
  }

  void updateBookSummary(Map<String, dynamic> summary) {
    if (!mounted) return;
    _log.info('Updating book summary');
    state = state.copyWith(
      bookSummary: summary,
      aiFeatureStatus: {'summary': AiFeatureStatus.ready},
    );
    _saveProgress();
  }

  Future<void> generateBookSummary({String? language}) async {
    if (!mounted) return;
    _log.info('Generating book summary');
    state = state.copyWith(aiFeatureStatus: {'summary': AiFeatureStatus.loading});
    try {
      String textToSummarize = '';
      String? currentLanguage = language;
      if (state.textContent != null && state.textContent!.isNotEmpty) {
        textToSummarize = state.textContent!.length > 5000
            ? state.textContent!.substring(0, 5000)
            : state.textContent!;
      } else {
        textToSummarize = state.bookTitle ?? _bookId;
      }
      final summary = await _repository.generateBookSummary(
        textToSummarize,
        bookTitle: state.bookTitle,
        language: currentLanguage,
      );
      state = state.copyWith(
        bookSummary: summary,
        aiFeatureStatus: {'summary': AiFeatureStatus.ready},
      );
      _log.info('Generated book summary');
      return;
          state = state.copyWith(aiFeatureStatus: {'summary': AiFeatureStatus.error});
    } catch (e) {
      _log.warning('Error generating book summary: $e');
      state = state.copyWith(aiFeatureStatus: {'summary': AiFeatureStatus.error});
    }
  }
  
  Future<void> getBookRecommendations({String? preferredGenre}) async {
    if (!mounted) return;
    state = state.copyWith(aiFeatureStatus: {'recommendations': AiFeatureStatus.loading});
    try {
      List<String> recentBooks = [state.bookTitle ?? _bookId];
      final recommendations = await _repository.getBookRecommendations(
        recentBooks,
        preferredGenre: preferredGenre ?? '',
      );
      state = state.copyWith(
        bookRecommendations: recommendations,
        aiFeatureStatus: {'recommendations': AiFeatureStatus.ready},
      );
      _log.info('Generated ${recommendations.length} book recommendations');
    } catch (e) {
      _log.severe('Error getting book recommendations: $e');
      state = state.copyWith(aiFeatureStatus: {'recommendations': AiFeatureStatus.error});
    }
  }
  
  Future<void> analyzeThemesAndConcepts() async {
    if (!mounted || state.textContent == null) return;
    state = state.copyWith(aiFeatureStatus: {'themes': AiFeatureStatus.loading});
    try {
      final textToAnalyze = state.textContent!.length > 5000
          ? state.textContent!.substring(0, 5000)
          : state.textContent!;
      final analysis = await _repository.analyzeThemesAndConcepts(textToAnalyze);
      state = state.copyWith(themeAnalysis: analysis, aiFeatureStatus: {'themes': AiFeatureStatus.ready});
      _log.info('Analyzed themes and concepts');
    } catch (e) {
      _log.severe('Error analyzing themes and concepts: $e');
      state = state.copyWith(aiFeatureStatus: {'themes': AiFeatureStatus.error});
    }
  }
  
  Future<void> searchWithinContent(String query) async {
    if (!mounted || state.textContent == null || query.trim().isEmpty) return;
    state = state.copyWith(aiFeatureStatus: {'search': AiFeatureStatus.loading}, lastSearchQuery: query);
    try {
      final results = await _repository.searchWithinContent(query, state.textContent!);
      state = state.copyWith(searchResults: results, aiFeatureStatus: {'search': AiFeatureStatus.ready});
      _log.info('Found ${results.length} search results for query: $query');
    } catch (e) {
      _log.severe('Error searching within content: $e');
      state = state.copyWith(aiFeatureStatus: {'search': AiFeatureStatus.error});
    }
  }
  
  void updateBookmarks(List<Map<String, dynamic>> bookmarks) {
    if (!mounted) return;
    _log.info('Updating bookmarks with ${bookmarks.length} entries');
    state = state.copyWith(suggestedBookmarks: bookmarks, aiFeatureStatus: {'bookmarks': AiFeatureStatus.ready});
    _saveProgress();
  }

  Future<void> loadContentForSection(String sectionId) async {
    _log.info('Loading content for section ID: $sectionId');
    try {
      state = state.copyWith(status: ReadingStatus.loadingContent);
      final dynamic headingDynamic = await _repository.getHeadingById(sectionId);
      if (headingDynamic == null) {
        _log.warning('No heading found with ID: $sectionId');
        state = state.copyWith(status: ReadingStatus.error, errorMessage: 'Content for section \'$sectionId\' not found.');
        return;
      }
      final heading = headingDynamic as Map<String, dynamic>;
      final String? headingTitle = heading['title'] as String?;
      final List<dynamic>? headingContentDynamic = heading['content'] as List<dynamic>?;
      final String? chapterTitle = heading['chapterTitle'] as String?;
      final String? language = heading['language'] as String?;
      _log.info('Found heading: ${headingTitle ?? "N/A"}, content length: ${headingContentDynamic?.length ?? 0}');
      String textContent = '';
      if (headingTitle != null) {
        textContent += '## $headingTitle\n\n';
      }
      if (headingContentDynamic != null && headingContentDynamic.isNotEmpty) {
        final contentList = headingContentDynamic.map((item) => item.toString()).toList();
        textContent += contentList.join('\n\n'); 
      } else {
        textContent += 'No content available for this section.';
      }
      textContent = _formatTextContent(textContent);
      state = state.copyWith(
        status: ReadingStatus.displayingText,
        textContent: textContent,
        currentHeadingTitle: headingTitle, 
        currentChapterTitle: chapterTitle, 
        currentLanguage: language ?? state.currentLanguage ?? 'en',
        currentChapter: state.headings?.indexWhere((h) {
          if (h is Map) return h['id']?.toString() == sectionId; 
          try {
             return (h as dynamic).id?.toString() == sectionId;
          } catch (_) {
            if (h is Map<String, dynamic> && h.containsKey('id')){
                 return h['id']?.toString() == sectionId; 
            }
            return false;
          }
        }) ?? state.currentChapter,
        textScrollPosition: 0.0,
      );
      _log.info('Successfully loaded content for section: ${headingTitle ?? sectionId}');
    } catch (e, stackTrace) {
      _log.severe('Error loading section content for ID $sectionId: $e', e, stackTrace);
      state = state.copyWith(status: ReadingStatus.error, errorMessage: 'Error loading section: ${e.toString()}');
    }
  }
}

// Helper to get min of two ints, useful for substring safety
int min(int a, int b) => a < b ? a : b;

final readingNotifierProvider = StateNotifierProvider.family<ReadingNotifier, ReadingState, String>(
  (ref, bookId) => ReadingNotifier(ref.watch(readingRepositoryProvider), bookId),
); 