// For File operations
import 'dart:convert'; // For utf8 encoding/decoding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// For repository provider dependency
// Removed unused import // Import for geminiServiceProvider
import 'package:modudi/features/reading/data/reading_repository_provider.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'reading_state.dart';
import 'dart:async';
// Need book details for language check
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
// Explicitly import the correct Bookmark
// Import Timestamp
import 'package:flutter_markdown/flutter_markdown.dart'; // Added for MarkdownBody
import './live_reading_progress_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for font families
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart'; // Added for settings
import 'package:modudi/features/reading/presentation/providers/reading_settings_provider.dart'; // Added for reading-specific settings
import 'package:modudi/core/themes/app_color.dart'; // Added for theme colors
import 'package:modudi/core/extensions/string_extensions.dart' show LanguageExtensions; // Added for language checks
import 'package:url_launcher/url_launcher.dart'; // Added for launchUrl
import 'package:modudi/core/cache/config/cache_constants.dart';
import 'package:modudi/core/providers/providers.dart';
import 'package:modudi/core/utils/firestore_retry_helper.dart';
import 'dart:math' as math;

// Provider for ReadingRepository
// NOTE: Moved to reading_repository_impl.dart to avoid circular dependencies
// Import the provider from there instead of defining it here

// StateNotifier for Reading Screen logic
class ReadingNotifier extends StateNotifier<ReadingState> {
  final AsyncValue<ReadingRepository> _repositoryAsyncValue;
  final String _bookId;
  final Ref _ref;
  final _log = Logger('ReadingNotifier');

  // Map to store relationships between different chapter identifiers
  final Map<String, int> _chapterIdToLogicalIndex = {};

  ReadingNotifier(this._repositoryAsyncValue, this._bookId, this._ref) 
      : super(const ReadingState()) {
    _log.info('ReadingNotifier initialized for bookId: $_bookId');
    loadContent();
  }

  Future<void> loadContent() async {
    _log.info('Loading content for book ID: $_bookId...');
    if (state.status == ReadingStatus.loadingMetadata || 
        state.status == ReadingStatus.loadingContent) {
      _log.info('Already loading, skipping. Current status: ${state.status}');
      return;
    }

    _log.info('Setting state to loadingMetadata for book ID: $_bookId');
    state = state.copyWith(status: ReadingStatus.loadingMetadata, bookId: _bookId);

    // Clear any stale cache for this book to force fresh data
    try {
      final cacheService = await _ref.read(cacheServiceProvider.future);
      await cacheService.remove('${CacheConstants.headingKeyPrefix}$_bookId', CacheConstants.headingsBoxName);
      await cacheService.remove('${CacheConstants.bookKeyPrefix}$_bookId', CacheConstants.booksBoxName);
      _log.info('Cleared stale cache for book $_bookId');
    } catch (e) {
      _log.warning('Failed to clear cache: $e');
    }

    _log.info('Checking repository async value state...');
    _repositoryAsyncValue.when(
      data: (repo) async {
        _log.info('Repository resolved successfully, proceeding with data loading...');
        try {
          _log.info('Fetching book data for book ID: $_bookId...');
          final bookResult = await repo.getBookData(_bookId);
          // ReadingState.book expects Book?, so use bookResult.data
          state = state.copyWith(
            book: bookResult.data, 
            bookTitle: bookResult.data?.title,
            currentLanguage: bookResult.data?.languageCode ?? 'en'
          );
          _log.info('Fetched book title: ${bookResult.data?.title}');

          await _loadReadingProgress(); // Load progress first

          _log.info('Fetching book headings for book ID: $_bookId...');
          // repo.getBookHeadings returns List<Heading>, not CacheResult<List<Heading>>
          final List<Heading> headingsResult = await repo.getBookHeadings(_bookId);
          state = state.copyWith(headings: headingsResult);
          _log.info('Fetched ${headingsResult.length} headings for book ID: $_bookId');

          // Debug: Log first few headings
          if (headingsResult.isNotEmpty) {
            for (int i = 0; i < math.min(3, headingsResult.length); i++) {
              final heading = headingsResult[i];
              _log.info('Heading $i: ${heading.title}, ID: ${heading.id}, Content length: ${heading.content?.length ?? 0}');
            }
          }

          if (headingsResult.isNotEmpty) { // headingsResult is List<Heading>, check directly
            _log.info('Processing ${headingsResult.length} headings for text display...');
            _prepareTextDisplayFromHeadings(headingsResult);
          } else {
            _log.warning('No headings found for book $_bookId. Attempting to create basic reading structure...');
            // Create a basic reading structure from book data
            await _createBasicReadingStructure();
          }
        } catch (e, stackTrace) {
          _log.severe('Error loading content for book ID: $_bookId', e, stackTrace);
          
          // Get user-friendly error message using the retry helper
          String userFriendlyMessage = FirestoreRetryHelper.getUserFriendlyErrorMessage(e);
          
          state = state.copyWith(status: ReadingStatus.error, errorMessage: userFriendlyMessage);
        }
      },
      loading: () {
        _log.info('ReadingRepository is still loading for book ID: $_bookId, waiting...');
        // State is already loadingMetadata, or can be more specific if needed
        // state = state.copyWith(status: ReadingStatus.loadingMetadata); // Already set
      },
      error: (e, stackTrace) {
        _log.severe('ReadingRepository failed to load for book ID: $_bookId', e, stackTrace);
        state = state.copyWith(status: ReadingStatus.error, errorMessage: 'Repository error: ${e.toString()}');
      },
    );
  }

  // Bookmark functionality has been moved to SimpleBookmarkService
  // for simpler local-only bookmark management

  /// Create a basic reading structure when no headings are found
  Future<void> _createBasicReadingStructure() async {
    try {
      final book = state.book;
      if (book == null) {
        _log.severe('Cannot create basic structure: book data is null');
        state = state.copyWith(
          status: ReadingStatus.error,
          errorMessage: 'Book data not available.'
        );
        return;
      }

      // Create a single basic heading from the book
      final basicHeading = Heading(
        firestoreDocId: '${book.firestoreDocId}_main',
        id: 1,
        title: book.title ?? 'Main Content',
        sequence: 1,
        content: ['This book content is being prepared for reading...'],
        chapterId: 1,
        volumeId: 1,
      );

      final basicHeadings = [basicHeading];
      
      _log.info('Created basic reading structure with 1 heading for book $_bookId');
      
      // Update state with basic structure
      state = state.copyWith(headings: basicHeadings);
      
      // Process the basic structure
      _prepareTextDisplayFromHeadings(basicHeadings);
      
    } catch (e, stackTrace) {
      _log.severe('Error creating basic reading structure for book $_bookId', e, stackTrace);
      state = state.copyWith(
        status: ReadingStatus.error,
        errorMessage: 'Failed to prepare book for reading: ${e.toString()}'
      );
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
    Map<String, List<Widget>> cachedWidgets = {}; 
    
    _chapterIdToLogicalIndex.clear();

    // Access reading-specific settings for styling
    final readingSettings = _ref.read(readingSettingsProvider);
    final currentThemeMode = readingSettings.themeMode;
    final double currentFontSize = readingSettings.fontSize.size;
    final String currentFontType = "SansSerif"; // Default, as ReadingSettingsState has custom font family handling
    final double currentLineSpacing = readingSettings.lineSpacing;
    final double textScaleFactor = 1.0; // Default, MarkdownStyleSheet also defaults to 1.0. Base size is readingSettings.fontSize.size.

    // Determine theme-based colors based on reading theme mode
    final onSurfaceColor = currentThemeMode == ReadingThemeMode.dark 
        ? AppColor.textPrimaryDark 
        : currentThemeMode == ReadingThemeMode.sepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;

    for (var heading in headings) {
      String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
      if (!groupedHeadings.containsKey(chapterKey)) {
        mainChapterKeys.add(chapterKey);
      }
      (groupedHeadings[chapterKey] ??= []).add(heading);

      final String headingContent = heading.content?.join('\n\n') ?? "";
      if (headingContent.isNotEmpty) {
        final bookLanguage = state.book?.languageCode ?? 'en';
        final bool isRTL = LanguageExtensions(bookLanguage).isRTL;
        final TextDirection textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
        
        String fontFamily;
        if (bookLanguage.isUrdu) {
          fontFamily = 'NotoNastaliqUrdu';
        } else if (bookLanguage.isArabic) {
          fontFamily = 'NotoNaskhArabic'; // Assuming NotoNaskhArabic is bundled or available
        } else {
          fontFamily = currentFontType == 'Serif' 
              ? GoogleFonts.ptSerif().fontFamily! 
              : GoogleFonts.openSans().fontFamily!;
        }

        final TextStyle paragraphStyle = TextStyle(
          fontFamily: fontFamily,
          fontSize: currentFontSize,
          height: currentLineSpacing,
          color: onSurfaceColor, // Adjust color as needed based on theme
        );

        // Create a base Material theme for MarkdownStyleSheet.fromTheme with complete text theme
        // This ensures that even if current app theme isn't directly passed, defaults are sensible.
        _log.info('Creating MarkdownStyleSheet for heading: ${heading.title ?? "Untitled"}, font size: $currentFontSize, theme: $currentThemeMode');
        
        ThemeData markdownTheme;
        if (currentThemeMode == ReadingThemeMode.dark) {
          markdownTheme = ThemeData.dark().copyWith(
            textTheme: ThemeData.dark().textTheme.copyWith(
              bodyMedium: TextStyle(fontSize: currentFontSize, color: onSurfaceColor),
              bodyLarge: TextStyle(fontSize: currentFontSize + 2, color: onSurfaceColor),
              bodySmall: TextStyle(fontSize: currentFontSize - 2, color: onSurfaceColor),
            ),
          );
        } else {
          markdownTheme = ThemeData.light().copyWith(
            textTheme: ThemeData.light().textTheme.copyWith(
              bodyMedium: TextStyle(fontSize: currentFontSize, color: onSurfaceColor),
              bodyLarge: TextStyle(fontSize: currentFontSize + 2, color: onSurfaceColor),
              bodySmall: TextStyle(fontSize: currentFontSize - 2, color: onSurfaceColor),
            ),
          );
        }

        _log.info('MarkdownTheme bodyMedium fontSize: ${markdownTheme.textTheme.bodyMedium?.fontSize}');
        
        final markdownStyleSheet = MarkdownStyleSheet.fromTheme(markdownTheme).copyWith(
          p: paragraphStyle,
          textAlign: isRTL ? WrapAlignment.end : WrapAlignment.start, // Use WrapAlignment based on isRTL
          textScaler: TextScaler.linear(textScaleFactor), // Updated to textScaler
          // Potentially add more styles for h1, h2, blockquote, etc., applying textDirection and fontFamily
          // For example, for headings:
          // h1: paragraphStyle.copyWith(fontSize: currentFontSize + 6, fontWeight: FontWeight.bold),
          // h2: paragraphStyle.copyWith(fontSize: currentFontSize + 4, fontWeight: FontWeight.bold),
        );
        
        _log.info('Successfully created MarkdownStyleSheet for heading: ${heading.title ?? "Untitled"}');

        final List<Widget> parsedWidgets = [
          Directionality(
            textDirection: textDirection, 
            child: MarkdownBody(
              data: headingContent, 
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
              styleSheet: markdownStyleSheet,
              // textScaler is handled by MarkdownStyleSheet
              // textDirection is handled by Directionality
            ),
          ),
        ];
        cachedWidgets[heading.firestoreDocId] = parsedWidgets;
      } else {
        cachedWidgets[heading.firestoreDocId] = [const Text("No content for this section.")];
      }
    }
    
    // Second pass: create mappings between chapter IDs and logical indices
    // This is critical for navigation from the BookDetailScreen to work properly
    _log.info('Building mappings between chapter IDs and logical indices...');
    
    // Clear any existing mappings to avoid conflicts
    _chapterIdToLogicalIndex.clear();
    
    // Map the primary keys (chapter IDs or volume IDs) first - ENSURE UNIQUE MAPPING
    for (int i = 0; i < mainChapterKeys.length; i++) {
      String key = mainChapterKeys[i];
      _chapterIdToLogicalIndex[key] = i;
      _log.info('Mapping chapter key: $key to logical index: $i');
    }
    
    // Map Firestore document IDs of headings to their CORRESPONDING UNIQUE chapter's logical index
    for (var heading in headings) {
      String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
      int logicalIndex = mainChapterKeys.indexOf(chapterKey);
      
      if (logicalIndex >= 0) {
      // Map the heading's Firestore document ID to the chapter's logical index
      if (heading.firestoreDocId.isNotEmpty) {
        _chapterIdToLogicalIndex[heading.firestoreDocId] = logicalIndex;
          _log.info('Mapping heading ID ${heading.firestoreDocId} to logical index: $logicalIndex');
      }
      
      // Map numeric ID (if present) to the logical index
      if (heading.id != null) {
        _chapterIdToLogicalIndex[heading.id.toString()] = logicalIndex;
          _log.info('Mapping numeric heading ID ${heading.id} to logical index: $logicalIndex');
        }
      } else {
        _log.warning('Failed to find logical index for chapter key: $chapterKey');
      }
    }
    
    _log.info('Total chapter ID mappings created: ${_chapterIdToLogicalIndex.length}');
    
    // Ensure currentChapter is within bounds after processing
    int initialChapterIndex = state.currentChapter.clamp(0, mainChapterKeys.isNotEmpty ? mainChapterKeys.length - 1 : 0);

    _log.info('Setting final state to displayingText with ${mainChapterKeys.length} chapters and ${cachedWidgets.length} cached widgets');
    state = state.copyWith(
      status: ReadingStatus.displayingText,
      mainChapterKeys: mainChapterKeys,
      currentChapter: initialChapterIndex, // Use the clamped initial chapter index
      cachedMarkdownWidgetsPerHeading: cachedWidgets, // Store cached widgets in state
      chapterIdToIndex: Map.unmodifiable(_chapterIdToLogicalIndex),
      currentChapterId: mainChapterKeys.isNotEmpty ? mainChapterKeys[state.currentChapter] : null,
      // textContent will be built by PageView itemBuilder based on groupedHeadings
    );
    
    _log.info('FINAL STATE: Processing ${headings.length} headings for text display, organized into ${mainChapterKeys.length} main chapters.');
    _log.info('FINAL STATE: Set up for text display with ${mainChapterKeys.length} main chapters. Current logical chapter: ${state.currentChapter}');
    _log.info('FINAL STATE: Status is now ${state.status}');
  }

  /// Preferred canonical navigation API
  void goToChapter(String chapterId, {String? headingId}) {
    _log.info('goToChapter requested: chapterId=$chapterId, headingId=$headingId');
    _log.info('Current mapping state: ${_chapterIdToLogicalIndex.toString()}');
    _log.info('Available chapters: ${state.mainChapterKeys}');

    // First, handle direct navigation if the chapterId is in mainChapterKeys
    final chapterKeys = state.mainChapterKeys;
    if (chapterKeys != null && chapterKeys.contains(chapterId)) {
      final targetIndex = chapterKeys.indexOf(chapterId);
      _log.info('Direct navigation to chapter ID $chapterId at index $targetIndex');
      navigateToLogicalChapter(targetIndex);
      return;
    }

    // If not found directly, try the mapping
    int? logicalIndex = _chapterIdToLogicalIndex[chapterId];
    _log.info('Initial mapping lookup for $chapterId: $logicalIndex');
    
    // If not found, try fallback methods in priority order
    if (logicalIndex == null) {
      _log.info('ChapterId $chapterId not found in mapping, trying fallbacks...');
      
      // Fallback 1: Direct search in mainChapterKeys (most reliable)
      if (chapterKeys != null) {
        for (int i = 0; i < chapterKeys.length; i++) {
          if (chapterKeys[i] == chapterId) {
            logicalIndex = i;
            _log.info('Found chapter $chapterId at index $i via direct search in mainChapterKeys');
            // Update the mapping for future use
            _chapterIdToLogicalIndex[chapterId] = i;
            break;
          }
        }
      }
      
      // Fallback 2: Only if direct search failed, try numeric parsing with priority
      if (logicalIndex == null) {
        final parsedId = int.tryParse(chapterId);
        if (parsedId != null && chapterKeys != null && chapterKeys.isNotEmpty) {
          _log.info('Trying numeric parsing for chapter ID $chapterId (parsed as $parsedId)');
          
          // Strategy: Check if parsedId matches any existing chapter key exactly first
          bool foundExactMatch = false;
          for (int i = 0; i < chapterKeys.length; i++) {
            if (chapterKeys[i] == parsedId.toString()) {
              logicalIndex = i;
              foundExactMatch = true;
              _log.info('Found exact numeric match: chapter $chapterId -> index $i');
              _chapterIdToLogicalIndex[chapterId] = i;
              break;
            }
          }
          
          // If no exact match, try 1-based indexing as fallback
          if (!foundExactMatch && parsedId > 0 && parsedId <= chapterKeys.length) {
            logicalIndex = parsedId - 1;
            _log.info('Using 1-based indexing for chapter $chapterId: $parsedId -> index $logicalIndex');
            _chapterIdToLogicalIndex[chapterId] = logicalIndex;
          }
        }
      }
    }
    
    if (logicalIndex != null) {
      _log.info('Final resolution: chapter $chapterId -> logical index $logicalIndex');
      navigateToLogicalChapter(logicalIndex);
    } else {
      _log.warning('Failed to resolve chapter $chapterId. Available chapters: ${state.mainChapterKeys}');
      _log.warning('Current mapping: ${_chapterIdToLogicalIndex}');
    }

    // optional: handle specific heading scroll later (not implemented here)
  }

  // TODO: deprecate; kept for backward compatibility while UI migrates
  void navigateToLogicalChapter(int logicalChapterIndex) {
    final chapterKeys = state.mainChapterKeys;
    if (chapterKeys == null || chapterKeys.isEmpty) {
      _log.warning('Cannot navigate: mainChapterKeys is null or empty. Attempted index: $logicalChapterIndex');
      return;
    }

    if (logicalChapterIndex >= 0 && logicalChapterIndex < chapterKeys.length) {
      // FIXED NAVIGATION ISSUE: Don't check for currentChapter equality, always force navigation
      // This ensures we actually navigate when multiple chapters map to the same logical index
        _log.info('Navigating to logical main chapter index: $logicalChapterIndex. Total main chapters: ${chapterKeys.length}');
        state = state.copyWith(
          currentChapter: logicalChapterIndex,
          currentChapterId: chapterKeys[logicalChapterIndex],
        );
        // Save progress asynchronously without blocking UI
        _saveReadingProgress();
        _log.info('Successfully navigated to logical main chapter: $logicalChapterIndex');
    } else {
      _log.warning('Invalid logical chapter index: $logicalChapterIndex. Total chapters: ${chapterKeys.length}');
    }
  }
  
  // legacy fallback
  bool navigateByChapterId(String chapterId) {
    _log.info('Attempting to navigate by chapter ID (legacy): $chapterId');
    final int? logicalIndex = _chapterIdToLogicalIndex[chapterId];

    if (logicalIndex != null) {
      navigateToLogicalChapter(logicalIndex);
      return true;
    } else {
      _log.warning('No mapping for chapterID $chapterId');
      final chapterKeys = state.mainChapterKeys;
      if (chapterKeys != null) {
        for (int i = 0; i < chapterKeys.length; i++) {
          if (chapterKeys[i] == chapterId) {
          _log.info('Found match in mainChapterKeys at index $i for chapter ID: $chapterId');
            navigateToLogicalChapter(i); // Async call, consider if await is needed or if method should be async
          return true;
        }
      }
      
      // Fallback 2: If it's a number, try direct index navigation
        final parsedIndex = int.tryParse(chapterId);
        if (parsedIndex != null) {
          int index = parsedIndex;
          if (index >= 0 && index < chapterKeys.length) {
          _log.info('Using numeric chapter ID directly as index: $index');
            navigateToLogicalChapter(index); // Async call, consider if await is needed or if method should be async
          return true;
          }
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
      final double currentProgress = (state.textScrollPosition ?? 0.0).clamp(0.0, 1.0);

      // Save fine-grained progress for live updates
      final liveProgressData = {'scrollPosition': currentProgress};
      await prefs.setString('live_progress_${state.bookId}', jsonEncode(liveProgressData));
      _log.info('Saved live reading progress for book ${state.bookId}: $currentProgress');

      // Update the live progress provider
      _ref.read(liveReadingProgressProvider(state.bookId!).notifier).setProgress(currentProgress);

      // Continue to save the chapter-based progress for recent books list / coarse-grained progress
      final chapterKeys = state.mainChapterKeys;
      final totalChapters = chapterKeys?.length ?? 0;
      final currentChapterIndex = state.currentChapter; // is int, not nullable

      final percentage = (chapterKeys != null && chapterKeys.isNotEmpty && currentChapterIndex >= 0 && currentChapterIndex < chapterKeys.length)
          ? ((currentChapterIndex + 1) / chapterKeys.length * 100).round()
          : 0;

      final chapterBasedProgress = {
        'bookId': state.bookId!,
        'bookTitle': state.bookTitle!,
        'currentChapter': currentChapterIndex,
        'totalChapters': totalChapters,
        'percentage': percentage,
        'lastReadTimestamp': DateTime.now().toIso8601String(),
        'fineGrainPercentage': currentProgress, 
      };
      await prefs.setString('reading_progress_${state.bookId}', jsonEncode(chapterBasedProgress));
      _log.info('Saved chapter-based reading progress for book: ${state.bookTitle}, coarse percentage: ${chapterBasedProgress['percentage']}% (Logical Chapter: $currentChapterIndex/${totalChapters > 0 ? totalChapters - 1 : 0}), fineGrain: $currentProgress');

    } catch (e, stackTrace) {
      _log.severe('Error saving reading progress: $e', stackTrace);
    }
  }

  Future<void> _loadReadingProgress() async {
    if (state.bookId == null) return;
    SharedPreferences? prefs; 
    try {
      prefs = await SharedPreferences.getInstance(); 
      double loadedFineGrainProgress = 0.0;
      int loadedChapter = 0;

      // Try loading fine-grained progress first
      final liveProgressString = prefs.getString('live_progress_${state.bookId}');
      if (liveProgressString != null) {
        final liveProgressData = jsonDecode(liveProgressString);
        if (liveProgressData is Map<String, dynamic> && liveProgressData.containsKey('scrollPosition')) {
          loadedFineGrainProgress = (liveProgressData['scrollPosition'] as num?)?.toDouble() ?? 0.0;
          _log.info('Loaded live reading progress for book ${state.bookId}: $loadedFineGrainProgress');
        } else if (liveProgressData is double) { // Backwards compatibility
            loadedFineGrainProgress = liveProgressData;
             _log.info('Loaded live reading progress (double) for book ${state.bookId}: $loadedFineGrainProgress');
        }
      }

      // Try loading chapter-based progress (this also contains a fineGrainPercentage now)
      final chapterProgressString = prefs.getString('reading_progress_${state.bookId}');
      if (chapterProgressString != null) {
        final chapterProgress = jsonDecode(chapterProgressString);
        loadedChapter = chapterProgress['currentChapter'] ?? 0;
        // If live progress wasn't found, or chapter-based has a more recent fineGrainPercentage, consider using it
        // For now, let's assume live_progress_ is the most up-to-date for scroll position.
        // However, we can use fineGrainPercentage from here if live_progress_ was missing.
        if (liveProgressString == null && chapterProgress.containsKey('fineGrainPercentage')) {
            loadedFineGrainProgress = (chapterProgress['fineGrainPercentage'] as num?)?.toDouble() ?? loadedFineGrainProgress;
        }
        _log.info('Loaded chapter-based progress for book ${state.bookId}: Chapter $loadedChapter');
      } else if (liveProgressString == null) {
        // No progress found at all
         _log.info('No reading progress found for book ${state.bookId}');
         state = state.copyWith(currentChapter: 0, textScrollPosition: 0.0);
         // Initialize live progress provider if no progress found
         _ref.read(liveReadingProgressProvider(state.bookId!).notifier).setProgress(0.0);
        return;
      }

          state = state.copyWith(
        currentChapter: loadedChapter,
        textScrollPosition: loadedFineGrainProgress.clamp(0.0, 1.0),
      );
      // Initialize/update the live progress provider with the loaded fine-grain progress
      _ref.read(liveReadingProgressProvider(state.bookId!).notifier).setProgress(loadedFineGrainProgress.clamp(0.0, 1.0));
      _log.info('Final loaded progress for book ${state.bookId}: Chapter ${state.currentChapter}, Scroll: ${state.textScrollPosition}');

    } catch (e, stackTrace) {
      _log.warning('Error loading reading progress for book ${state.bookId}: $e. Data for live: ${prefs?.getString('live_progress_${state.bookId}')} Data for chapter: ${prefs?.getString('reading_progress_${state.bookId}')}', stackTrace);
      // If there's an error, reset progress for this book
      final prefsInstance = prefs ?? await SharedPreferences.getInstance(); 
      await prefsInstance.remove('reading_progress_${state.bookId}');
      await prefsInstance.remove('live_progress_${state.bookId}');
      _log.info('Corrupted reading progress for book ${state.bookId} removed.');
      state = state.copyWith(currentChapter: 0, textScrollPosition: 0.0); 
      _ref.read(liveReadingProgressProvider(state.bookId!).notifier).setProgress(0.0);
    }
  }

  Future<void> updateTextPosition(double scrollRatio) async {
    if (state.textScrollPosition != scrollRatio) {
      state = state.copyWith(textScrollPosition: scrollRatio);
      // Consider if progress should be saved on every scroll update or less frequently
      // For now, let's save it, but this could be throttled.
      await _saveReadingProgress(); 
    }
  }

  /// Optimized method: Update scroll position immediately in memory for UI responsiveness
  /// without triggering persistence operations that can cause jank
  void updateScrollPositionOnly(double scrollRatio) {
    if (state.textScrollPosition != scrollRatio) {
      state = state.copyWith(textScrollPosition: scrollRatio);
      // Update live progress provider immediately for UI responsiveness
      _ref.read(liveReadingProgressProvider(state.bookId!).notifier).setProgress(scrollRatio);
      _log.fine('Updated scroll position in memory: $scrollRatio');
    }
  }

  /// Optimized method: Persist text position asynchronously without blocking UI
  Future<void> persistTextPosition(double scrollRatio) async {
    if (state.bookId == null || state.bookTitle == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final double currentProgress = scrollRatio.clamp(0.0, 1.0);

      // Save fine-grained progress for live updates (asynchronous, non-blocking)
      final liveProgressData = {'scrollPosition': currentProgress};
      await prefs.setString('live_progress_${state.bookId}', jsonEncode(liveProgressData));
      
      // Update coarse-grained progress less frequently
      final chapterKeys = state.mainChapterKeys;
      final totalChapters = chapterKeys?.length ?? 0;
      final currentChapterIndex = state.currentChapter;

      final percentage = (chapterKeys != null && chapterKeys.isNotEmpty && currentChapterIndex >= 0 && currentChapterIndex < chapterKeys.length)
          ? ((currentChapterIndex + 1) / chapterKeys.length * 100).round()
          : 0;

      final chapterBasedProgress = {
        'bookId': state.bookId!,
        'bookTitle': state.bookTitle!,
        'currentChapter': currentChapterIndex,
        'totalChapters': totalChapters,
        'percentage': percentage,
        'lastReadTimestamp': DateTime.now().toIso8601String(),
        'fineGrainPercentage': currentProgress, 
      };
      await prefs.setString('reading_progress_${state.bookId}', jsonEncode(chapterBasedProgress));
      
      _log.fine('Persisted reading progress for book ${state.bookId}: $currentProgress');
    } catch (e, stackTrace) {
      _log.warning('Error persisting reading progress: $e', e, stackTrace);
      // Non-critical error, don't propagate to UI
    }
  }

  /// Optimized method: Update scroll position immediately in memory for UI responsiveness
  /// without triggering persistence - this is for real-time UI updates during scrolling
  void updateScrollPositionImmediate(double scrollRatio) {
    if (state.textScrollPosition != scrollRatio) {
      state = state.copyWith(textScrollPosition: scrollRatio);
      // Update live progress provider immediately for UI responsiveness
      _ref.read(liveReadingProgressProvider(state.bookId!).notifier).setProgress(scrollRatio);
      // No persistence here - just immediate in-memory update for smooth UI
    }
  }

  /// Optimized method: Persist scroll position asynchronously for background saves
  /// This is called from the debounced timer to avoid blocking the UI thread
  Future<void> persistScrollPosition() async {
    try {
      await _saveReadingProgress();
    } catch (e) {
      _log.warning('Failed to persist scroll position: $e');
      rethrow;
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

          final dynamic chapters = await repo.extractChaptersFromContent(
            fullContent,
            bookType: state.book?.type,
            bookTitle: state.bookTitle,
            isTableOfContents: forceTocExtraction,
          );
          // Convert chapters to Map if necessary
          Map<String, dynamic> chaptersMap;
          if (chapters is Map<String, dynamic>) {
            chaptersMap = chapters;
          } else if (chapters is List) {
            chaptersMap = {};
            for (int i = 0; i < chapters.length; i++) {
              chaptersMap[i.toString()] = chapters[i];
            }
          } else {
            chaptersMap = {};
          }
          state = state.copyWith(aiExtractedChapters: chaptersMap, isTocExtracted: true);
          _log.info('AI chapter extraction complete. Found ${chaptersMap.length} chapters.');
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
          Map<String, String> wordMap = {};
          if (words is Map<String, String>) {
            wordMap = words;
          } else {
            words.forEach((key, value) {
            if (value is String) {
              wordMap[key] = value;
            }
          });
          }
        
                  state = state.copyWith(
            difficultWords: wordMap,
            aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'vocabulary': AiFeatureStatus.ready}
          );
          _log.info('Difficult word analysis complete. Found ${words.length ?? 0} words.');
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
          state = state.copyWith(currentTranslation: translationData ?? {});
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
    String sampleText = state.headings?.take(2).map((h) => h.content?.join(' ') ?? '').join('\n') ?? state.textContent?.substring(0, math.min(state.textContent?.length ?? 0, 500)) ?? '';
    if (sampleText.isEmpty) {
      _log.warning('No sample text available for recommending settings.');
      return;
    }

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          _log.info('Fetching recommended reading settings.');
          final settings = await repo.getRecommendedReadingSettings(sampleText, language: state.currentLanguage);
          state = state.copyWith(
            recommendedSettings: settings ?? {},
            aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'settings': AiFeatureStatus.ready}
          );
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
          state = state.copyWith(
            suggestedBookmarks: bookmarks ?? [],
            aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'bookmarks': AiFeatureStatus.ready}
          );
          _log.info('AI bookmark suggestion complete. Found ${bookmarks.length ?? 0} suggestions.');
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
          state = state.copyWith(speechMarkers: markers ?? {}, isSpeaking: true);
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
        state.aiFeatureStatus?.map((key, value) => MapEntry(key, AiFeatureStatus.initial)) ?? {};

    switch (feature) {
      case 'extract_chapters':
        state = state.copyWith(aiExtractedChapters: {}, aiFeatureStatus: currentStatus);
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

  /// Retry loading content with exponential backoff
  /// This is useful when the initial load fails due to network issues
  Future<void> retryLoading() async {
    _log.info('Retrying content load for book ID: $_bookId');
    
    // Clear any error state
    state = state.copyWith(
      status: ReadingStatus.loadingMetadata, 
      errorMessage: null
    );
    
    try {
      await loadContent();
    } catch (e) {
      _log.warning('Retry failed for book ID: $_bookId - $e');
      // The error will be handled by loadContent's error handling
    }
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
    // Convert list to map for aiExtractedChapters
    Map<String, dynamic> chaptersMap = {};
    for (int i = 0; i < chapters.length; i++) {
      chaptersMap[i.toString()] = chapters[i];
    }
    
    state = state.copyWith(
      aiExtractedChapters: chaptersMap,
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
      aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'vocabulary': AiFeatureStatus.ready}, // Ensure 'vocabulary' matches the feature key
    );
  }

  void updateBookSummary(Map<String, dynamic> summary) {
    if (!mounted) return;
    _log.info('Updating book summary');
    final updatedBookSummary = state.bookSummary != null ? {...state.bookSummary!} : <String, dynamic>{};
    state = state.copyWith(
      bookSummary: updatedBookSummary,
      aiFeatureStatus: {'summary': AiFeatureStatus.ready},
    );
    _saveProgress();
  }

  Future<void> generateBookSummary({String? language}) async {
    _log.info('Generating book summary');
    state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'summary': AiFeatureStatus.loading});

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
            bookSummary: summary ?? {},

            aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'summary': AiFeatureStatus.ready},
          );
          _log.info('Generated book summary');
        } catch (e, stackTrace) {
          _log.severe('Error generating book summary: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'summary': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Generate book summary: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Generate book summary: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'summary': AiFeatureStatus.error});
      },
    );
  }
  
  Future<void> getBookRecommendations({String? preferredGenre}) async {
    state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'recommendations': AiFeatureStatus.loading});

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          List<String> recentBooks = [state.bookTitle ?? _bookId];
          final recommendations = await repo.getBookRecommendations(
            recentBooks,
            preferredGenre: preferredGenre ?? '', 
          );
          state = state.copyWith(
            bookRecommendations: recommendations ?? [],
            aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'recommendations': AiFeatureStatus.ready},
          );
          _log.info('Generated ${recommendations.length ?? 0} book recommendations');
        } catch (e, stackTrace) {
          _log.severe('Error getting book recommendations: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'recommendations': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Get book recommendations: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Get book recommendations: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'recommendations': AiFeatureStatus.error});
      },
    );
  }
  
  Future<void> analyzeThemesAndConcepts() async {
    if (state.textContent == null || state.textContent!.isEmpty) {
        _log.warning('Cannot analyze themes: textContent is null or empty.');
        state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'themes': AiFeatureStatus.error});
        return;
    }
    state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'themes': AiFeatureStatus.loading});

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          final textToAnalyze = state.textContent!.length > 5000 
              ? state.textContent!.substring(0, 5000)
              : state.textContent!;
          final analysis = await repo.analyzeThemesAndConcepts(textToAnalyze);
          state = state.copyWith(
            themeAnalysis: analysis ?? {},
            aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'themes': AiFeatureStatus.ready}
          );
          _log.info('Analyzed themes and concepts');
        } catch (e, stackTrace) {
          _log.severe('Error analyzing themes and concepts: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'themes': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Analyze themes and concepts: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Analyze themes and concepts: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'themes': AiFeatureStatus.error});
      },
    );
  }
  
  Future<void> searchWithinContent(String query) async {
    if (state.textContent == null || state.textContent!.isEmpty) {
      _log.warning('Cannot search: textContent is null or empty.');
      state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'search': AiFeatureStatus.error});
      return;
    }
    state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'search': AiFeatureStatus.loading});

    _repositoryAsyncValue.when(
      data: (repo) async {
        try {
          if (state.textContent == null || state.textContent!.isEmpty) {
             _log.warning('Cannot search content: textContent is null or empty inside repo call.');
             state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'search': AiFeatureStatus.error});
             return;
          }
          final results = await repo.searchWithinContent(query, state.textContent!);
          state = state.copyWith(
            searchResults: results ?? [],
            aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'search': AiFeatureStatus.ready},
          );
          _log.info('Search completed with ${results.length ?? 0} results for query "$query".');
        } catch (e, stackTrace) {
          _log.severe('Error searching within content: $e', e, stackTrace);
          state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'search': AiFeatureStatus.error});
        }
      },
      loading: () {
        _log.info('Search within content: Repository is loading. Action deferred.');
      },
      error: (e, stackTrace) {
        _log.severe('Search within content: Repository not available. Error: $e', e, stackTrace);
        state = state.copyWith(aiFeatureStatus: {...(state.aiFeatureStatus ?? {}), 'search': AiFeatureStatus.error});
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
            currentChapter: state.headings?.indexWhere((h) => h.firestoreDocId == sectionId) ?? 0,
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

  /// Update current chapter without full navigation (for UI updates)
  void updateCurrentChapter(int chapterIndex) {
    final mainChapterKeys = state.mainChapterKeys;
    if (mainChapterKeys == null || chapterIndex < 0 || chapterIndex >= mainChapterKeys.length) {
      return;
    }
    
    state = state.copyWith(
      currentChapter: chapterIndex,
      currentChapterId: mainChapterKeys[chapterIndex],
    );
  }
}

// Helper to get min of two ints, useful for substring safety
int min(int a, int b) => a < b ? a : b;

final readingNotifierProvider = StateNotifierProvider.family<ReadingNotifier, ReadingState, String>((ref, bookId) {
  final repositoryAsyncValue = ref.watch(readingRepositoryProvider);
  return ReadingNotifier(repositoryAsyncValue, bookId, ref);
}); 