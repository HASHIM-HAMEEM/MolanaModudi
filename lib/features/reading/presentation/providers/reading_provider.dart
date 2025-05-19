// For File operations
import 'dart:convert'; // For utf8 encoding/decoding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// For repository provider dependency
// Removed unused import // Import for geminiServiceProvider
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
// NOTE: Moved to reading_repository_impl.dart to avoid circular dependencies
// Import the provider from there instead of defining it here

// StateNotifier for Reading Screen logic
class ReadingNotifier extends StateNotifier<ReadingState> {
  final AsyncValue<ReadingRepository> _repositoryAsyncValue;
  final String _bookId;
  final _log = Logger('ReadingNotifier');
  
  // Reading progress tracking
  static const _allowedLanguages = {'eng', 'ara', 'urd'}; // Allowed language codes

  // Map to store relationships between different chapter identifiers
  final Map<String, int> _chapterIdToLogicalIndex = {};

  ReadingNotifier(this._repositoryAsyncValue, this._bookId) 
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

    state = state.copyWith(status: ReadingStatus.loadingMetadata, bookId: _bookId);

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          final book = await repo.getBookData(_bookId);
          state = state.copyWith(book: book, bookTitle: book.title, currentLanguage: book.languageCode ?? 'en');
          _log.info('Fetched book title: ${book.title}');

          await _loadReadingProgress(); // Load progress first

          final headings = await repo.getBookHeadings(_bookId);
          state = state.copyWith(headings: headings);
          _log.info('Fetched ${headings.length} headings for book ID: $_bookId');

          // Load bookmarks
          await _loadBookmarks(repo); // Pass the resolved repository

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
          _log.severe('Error loading content for book ID: $_bookId', e, stackTrace);
          state = state.copyWith(status: ReadingStatus.error, errorMessage: 'Error loading content: ${e.toString()}');
        }
      },
      loading: () {
        // State is already loadingMetadata, or can be more specific if needed
        _log.info('ReadingRepository is loading for book ID: $_bookId');
        // state = state.copyWith(status: ReadingStatus.loadingMetadata); // Already set
      },
      error: (e, stackTrace) {
        _log.severe('ReadingRepository failed to load for book ID: $_bookId', e, stackTrace);
        state = state.copyWith(status: ReadingStatus.error, errorMessage: 'Repository error: ${e.toString()}');
      },
    );
  }

  // Helper to load bookmarks
  // Accepts ReadingRepository directly because it's called after _repositoryAsyncValue is resolved.
  Future<void> _loadBookmarks(ReadingRepository repo) async {
    if (state.bookId == null) return;
    try {
      final bookmarks = await repo.getBookmarks(state.bookId!);
      state = state.copyWith(bookmarks: bookmarks);
      _log.info('Loaded ${bookmarks.length} bookmarks for book ${state.bookId}');
    } catch (e, stackTrace) { // Added stackTrace
      _log.severe('Error loading bookmarks for book ${state.bookId}: $e', e, stackTrace);
      // Optionally set an error state or leave bookmarks as empty
    }
  }

  // Method to toggle a bookmark for a specific heading
  Future<void> toggleBookmark(Heading heading, String chapterId, String chapterTitle) async {
    if (state.bookId == null) {
      _log.warning('Cannot toggle bookmark: bookId is null.');
      return;
    }
    // heading.firestoreDocId is a non-nullable String.
    final String bookmarkIdToCheck = heading.firestoreDocId;

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          final existingBookmarkIndex =
      state.bookmarks?.indexWhere((b) => b.id == bookmarkIdToCheck) ?? -1;

          if (existingBookmarkIndex != -1) {
            // Bookmark exists, so remove it
            await repo.removeBookmark(state.bookId!, bookmarkIdToCheck);
            _log.info('Bookmark removed: $bookmarkIdToCheck');
          } else {
            // Bookmark does not exist, so add it
            String? snippet;
            if (heading.content != null && heading.content!.isNotEmpty) {
              final firstLine = heading.content!.first;
              snippet = firstLine.length > 100 ? '${firstLine.substring(0, 97)}...' : firstLine;
            }
            
            final Bookmark newBookmark = Bookmark(
              id: heading.firestoreDocId, 
              bookId: state.bookId!,
              chapterId: chapterId, 
              chapterTitle: chapterTitle,
              headingId: heading.firestoreDocId, // Corresponds to Bookmark.headingId
              headingTitle: heading.title ?? 'Unnamed Section',
              timestamp: Timestamp.now(),
              textContentSnippet: snippet,
            );
            await repo.addBookmark(newBookmark);
            _log.info('Bookmark added: ${newBookmark.id}');
          }
          // Refresh bookmarks from repository to ensure UI consistency
          await _loadBookmarks(repo);
        } catch (e, stackTrace) {
          _log.severe('Error toggling bookmark for heading ${heading.firestoreDocId}: $e', e, stackTrace);
          // Optionally notify UI of error
        }
      },
      loading: () {
        _log.info('Toggle bookmark: Repository is loading. Action deferred.');
        // Optionally, show a loading indicator or disable UI
      },
      error: (e, stackTrace) {
        _log.severe('Toggle bookmark: Repository not available. Error: $e', e, stackTrace);
        // Optionally, show an error message to the user
      },
    );
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
    
    // Clear previous mapping
    _chapterIdToLogicalIndex.clear();

    // First pass: group headings by chapter key and create mainChapterKeys
    for (var heading in headings) {
      String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
      if (!groupedHeadings.containsKey(chapterKey)) {
        mainChapterKeys.add(chapterKey);
      }
      (groupedHeadings[chapterKey] ??= []).add(heading);
    }
    
    // Second pass: create mappings between chapter IDs and logical indices
    // This is critical for navigation from the BookDetailScreen to work properly
    _log.info('Building mappings between chapter IDs and logical indices...');
    
    // Map the primary keys (chapter IDs or volume IDs) first
    for (int i = 0; i < mainChapterKeys.length; i++) {
      String key = mainChapterKeys[i];
      _chapterIdToLogicalIndex[key] = i;
      _log.info('Mapping chapter key: $key to logical index: $i');
    }
    
    // Map Firestore document IDs of headings to their chapter's logical index
    for (var heading in headings) {
      String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
      int logicalIndex = mainChapterKeys.indexOf(chapterKey);
      
      // Map the heading's Firestore document ID to the chapter's logical index
      if (heading.firestoreDocId.isNotEmpty) {
        _chapterIdToLogicalIndex[heading.firestoreDocId] = logicalIndex;
      }
      
      // Map numeric ID (if present) to the logical index
      if (heading.id != null) {
        _chapterIdToLogicalIndex[heading.id.toString()] = logicalIndex;
      }
    }
    
    _log.info('Total chapter ID mappings created: ${_chapterIdToLogicalIndex.length}');
    
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

  /// Navigate to a chapter by its logical index
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
  
  /// Navigate to a chapter by its ID (can be any type of chapter identifier)
  /// This method is used when navigating from BookDetailScreen or other screens
  /// that pass chapter IDs instead of logical indices
  bool navigateByChapterId(String chapterId) {
    _log.info('Attempting to navigate by chapter ID: $chapterId');
    _log.info('Available mappings: ${_chapterIdToLogicalIndex.length}');
    
    // Check if this chapterId is mapped to a logical index
    if (_chapterIdToLogicalIndex.containsKey(chapterId)) {
      int logicalIndex = _chapterIdToLogicalIndex[chapterId]!;
      _log.info('Found mapping for chapter ID: $chapterId -> logical index: $logicalIndex');
      navigateToLogicalChapter(logicalIndex);
      return true;
    } else {
      // If no mapping was found, try other approaches
      _log.warning('No direct mapping found for chapter ID: $chapterId. Trying fallback approaches.');
      
      // Fallback 1: Try matching as a string against mainChapterKeys
      for (int i = 0; i < state.mainChapterKeys.length; i++) {
        if (state.mainChapterKeys[i] == chapterId) {
          _log.info('Found match in mainChapterKeys at index $i for chapter ID: $chapterId');
          navigateToLogicalChapter(i);
          return true;
        }
      }
      
      // Fallback 2: If it's a number, try direct index navigation
      if (int.tryParse(chapterId) != null) {
        int index = int.parse(chapterId);
        if (index >= 0 && index < state.mainChapterKeys.length) {
          _log.info('Using numeric chapter ID directly as index: $index');
          navigateToLogicalChapter(index);
          return true;
        }
      }
      
      _log.warning('Failed to navigate by chapter ID: $chapterId - no matching chapter found');
      return false;
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

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          _log.info('Starting AI chapter extraction for book: ${state.bookTitle}');
          String fullContent = state.headings?.map((h) => h.content?.join('\n') ?? '').join('\n\n') ?? state.textContent ?? '';
          if (fullContent.isEmpty) {
            _log.warning('No content available for AI chapter extraction.');
            return;
          }

          final chapters = await repo.extractChaptersFromContent(
            fullContent,
            bookType: state.book?.type,
            bookTitle: state.bookTitle,
            isTableOfContents: forceTocExtraction,
          );
          state = state.copyWith(aiExtractedChapters: chapters, isTocExtracted: true);
          _log.info('AI chapter extraction complete. Found ${chapters.length} chapters.');
        } catch (e, stackTrace) {
          _log.severe('Error during AI chapter extraction: $e', e, stackTrace);
          state = state.copyWith(errorMessage: 'Failed to extract chapters with AI.');
        }
      },
      loading: () {
        _log.info('AI chapter extraction: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('AI chapter extraction: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(errorMessage: 'Failed to extract chapters with AI due to repository error.');
      },
    );
  }

  Future<void> analyzeDifficultWords(String textToAnalyze) async {
    if (state.difficultWords != null && state.difficultWords!.isNotEmpty) {
      _log.info('Difficult words already analyzed. Skipping.');
      return;
    }
    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          _log.info('Starting difficult word analysis.');
          final words = await repo.explainDifficultWords(
            textToAnalyze,
            targetLanguage: state.currentLanguage,
            // difficulty: 'intermediate' // Example, make this configurable if needed
          );
          state = state.copyWith(difficultWords: words.cast<String, String>());
          _log.info('Difficult word analysis complete. Found ${words.length} words.');
        } catch (e, stackTrace) {
          _log.severe('Error during difficult word analysis: $e', e, stackTrace);
          state = state.copyWith(errorMessage: 'Failed to analyze vocabulary.');
        }
      },
      loading: () {
        _log.info('Difficult word analysis: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Difficult word analysis: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(errorMessage: 'Failed to analyze vocabulary due to repository error.');
      },
    );
  }

  Future<void> translateText(String text, String targetLanguage) async {
    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          _log.info('Translating text to $targetLanguage.');
          final translationData = await repo.translateText(text, targetLanguage);
          state = state.copyWith(currentTranslation: translationData);
          _log.info('Text translation complete.');
        } catch (e, stackTrace) {
          _log.severe('Error during text translation: $e', e, stackTrace);
          state = state.copyWith(currentTranslation: {'translated': 'Translation failed.'});
        }
      },
      loading: () {
        _log.info('Text translation: Repository is loading. Action deferred.');
        // Optionally, show a loading indicator or set a temporary translation state
      },
      error: (e, stackTrace) {
        _log.severe('Text translation: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(currentTranslation: {'translated': 'Translation failed due to repository error.'});
      },
    );
  }
  
  Future<void> getRecommendedReadingSettings() async {
    if (state.recommendedSettings != null && state.recommendedSettings!.isNotEmpty) {
      _log.info('Recommended settings already fetched. Skipping.');
      return;
    }
    String sampleText = state.headings?.take(2).map((h) => h.content?.join(' ') ?? '').join('\n') ?? state.textContent?.substring(0, min(state.textContent?.length ?? 0, 500)) ?? '';
    if (sampleText.isEmpty) {
      _log.warning('No sample text available for recommending settings.');
      return;
    }

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          _log.info('Fetching recommended reading settings.');
          final settings = await repo.getRecommendedReadingSettings(sampleText, language: state.currentLanguage);
          state = state.copyWith(recommendedSettings: settings);
          _log.info('Recommended reading settings fetched: $settings');
        } catch (e, stackTrace) {
          _log.severe('Error fetching recommended reading settings: $e', e, stackTrace);
          state = state.copyWith(errorMessage: 'Failed to fetch recommended settings.');
        }
      },
      loading: () {
        _log.info('Recommended settings: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Recommended settings: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(errorMessage: 'Failed to fetch recommended settings due to repository error.');
      },
    );
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

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          _log.info('Starting AI bookmark suggestion.');
          final bookmarks = await repo.suggestBookmarks(fullContent);
          state = state.copyWith(suggestedBookmarks: bookmarks);
          _log.info('AI bookmark suggestion complete. Found ${bookmarks.length} suggestions.');
        } catch (e, stackTrace) {
          _log.severe('Error during AI bookmark suggestion: $e', e, stackTrace);
          // Optionally update state with an error message
          // state = state.copyWith(errorMessage: 'Failed to suggest bookmarks with AI.');
        }
      },
      loading: () {
        _log.info('AI bookmark suggestion: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('AI bookmark suggestion: Repository not available. Error: $e', e, stackTrace);
        // Optionally update state with an error message
      },
    );
  }
  
  Future<void> generateSpeechMarkers(String text) async {
    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          _log.info('Generating speech markers for TTS.');
          final markers = await repo.generateTtsPrompt(text, language: state.currentLanguage);
          state = state.copyWith(speechMarkers: markers, isSpeaking: true);
          _log.info('Speech markers generated successfully.');
        } catch (e, stackTrace) {
          _log.severe('Error generating speech markers: $e', e, stackTrace);
          // Optionally update state with an error message
          // state = state.copyWith(errorMessage: 'Failed to prepare text for speech.');
        }
      },
      loading: () {
        _log.info('Generate speech markers: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Generate speech markers: Repository not available. Error: $e', e, stackTrace);
        // Optionally update state with an error message
      },
    );
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
    _log.info('Generating book summary');
    state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'summary': AiFeatureStatus.loading});

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          String textToSummarize = '';
          String? effectiveLanguage = language ?? state.currentLanguage ?? 'en'; 
          
          if (state.textContent != null && state.textContent!.isNotEmpty) {
            textToSummarize = state.textContent!.length > 5000
                ? state.textContent!.substring(0, 5000)
                : state.textContent!;
          } else {
            textToSummarize = state.bookTitle ?? _bookId; 
             _log.warning('No extensive textContent for summary, using book title: $textToSummarize');
          }

          final summary = await repo.generateBookSummary(
            textToSummarize,
            bookTitle: state.bookTitle,
            language: effectiveLanguage,
          );
          state = state.copyWith(
            bookSummary: summary,
            aiFeatureStatus: {...state.aiFeatureStatus, 'summary': AiFeatureStatus.ready},
          );
          _log.info('Generated book summary');
        } catch (e, stackTrace) {
          _log.severe('Error generating book summary: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'summary': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Generate book summary: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Generate book summary: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'summary': AiFeatureStatus.error});
      },
    );
  }
  
  Future<void> getBookRecommendations({String? preferredGenre}) async {
    state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'recommendations': AiFeatureStatus.loading});

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          List<String> recentBooks = [state.bookTitle ?? _bookId];
          final recommendations = await repo.getBookRecommendations(
            recentBooks,
            preferredGenre: preferredGenre ?? '', 
          );
          state = state.copyWith(
            bookRecommendations: recommendations,
            aiFeatureStatus: {...state.aiFeatureStatus, 'recommendations': AiFeatureStatus.ready},
          );
          _log.info('Generated ${recommendations.length} book recommendations');
        } catch (e, stackTrace) {
          _log.severe('Error getting book recommendations: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'recommendations': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Get book recommendations: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Get book recommendations: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'recommendations': AiFeatureStatus.error});
      },
    );
  }
  
  Future<void> analyzeThemesAndConcepts() async {
    if (state.textContent == null || state.textContent!.isEmpty) {
        _log.warning('Cannot analyze themes: textContent is null or empty.');
        state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'themes': AiFeatureStatus.error});
        return;
    }
    state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'themes': AiFeatureStatus.loading});

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          final textToAnalyze = state.textContent!.length > 5000 
              ? state.textContent!.substring(0, 5000)
              : state.textContent!;
          final analysis = await repo.analyzeThemesAndConcepts(textToAnalyze);
          state = state.copyWith(
            themeAnalysis: analysis, 
            aiFeatureStatus: {...state.aiFeatureStatus, 'themes': AiFeatureStatus.ready}
          );
          _log.info('Analyzed themes and concepts');
        } catch (e, stackTrace) {
          _log.severe('Error analyzing themes and concepts: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'themes': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Analyze themes and concepts: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Analyze themes and concepts: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'themes': AiFeatureStatus.error});
      },
    );
  }
  
  Future<void> searchWithinContent(String query) async {
    if (state.textContent == null || state.textContent!.isEmpty) {
      _log.warning('Cannot search: textContent is null or empty.');
      state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'search': AiFeatureStatus.error});
      return;
    }
    state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'search': AiFeatureStatus.loading});

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          if (state.textContent == null || state.textContent!.isEmpty) {
             _log.warning('Cannot search content: textContent is null or empty inside repo call.');
             state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'search': AiFeatureStatus.error});
             return;
          }
          final results = await repo.searchWithinContent(query, state.textContent!);
          state = state.copyWith(
            searchResults: results,
            aiFeatureStatus: {...state.aiFeatureStatus, 'search': AiFeatureStatus.ready},
          );
          _log.info('Search completed with ${results.length} results for query "$query".');
        } catch (e, stackTrace) {
          _log.severe('Error searching within content: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'search': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Search within content: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Search within content: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...state.aiFeatureStatus, 'search': AiFeatureStatus.error});
      },
    );
  }
  
  void updateBookmarks(List<Map<String, dynamic>> bookmarks) {
    if (!mounted) return;
    _log.info('Updating bookmarks with ${bookmarks.length} entries');
    state = state.copyWith(suggestedBookmarks: bookmarks, aiFeatureStatus: {'bookmarks': AiFeatureStatus.ready});
    _saveProgress();
  }

  Future<void> loadContentForSection(String sectionId) async {
    _log.info('Loading content for section ID: $sectionId');
    state = state.copyWith(status: ReadingStatus.loadingContent);

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          final dynamic headingDynamic = await repo.getHeadingById(sectionId);
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
              } catch (e) {
                return false;
              }
            }) ?? 0,
            textScrollPosition: 0.0,
          );
          _saveProgress();
        } catch (e, stackTrace) {
          _log.severe('Error loading section content: $e', e, stackTrace);
          state = state.copyWith(status: ReadingStatus.error, errorMessage: 'Error loading content: ${e.toString()}');
        }
      },
      loading: () {
        _log.info('Load section content: Repository is loading. Action deferred.');
        // State is already set to ReadingStatus.loadingContent
      },
      error: (e, stackTrace) {
        _log.severe('Load section content: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(status: ReadingStatus.error, errorMessage: 'Repository error: ${e.toString()}');
      },
    );
  }
}

// Helper to get min of two ints, useful for substring safety
int min(int a, int b) => a < b ? a : b;

final readingNotifierProvider = StateNotifierProvider.family<ReadingNotifier, ReadingState, String>(
  (ref, bookId) => ReadingNotifier(ref.watch(readingRepositoryProvider), bookId),
); 