import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'dart:async'; // Import for Completer
import 'package:google_fonts/google_fonts.dart';

import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
// Import widgets as they are created
// Import Library Panel
// Import shared models
import '../models/reading_models.dart'; 
// Import GoRouter for navigation extensions
import 'package:go_router/go_router.dart'; 
// Import RouteNames for route constants
import 'package:modudi/routes/route_names.dart';
// Import reading provider and state
import '../providers/reading_provider.dart';
import '../providers/reading_state.dart';
// Import url_launcher
// Add import for dictionary popup widget
import '../widgets/vocabulary_assist_popup.dart';
// Add import for AI-related widgets
// Removed self-import
import 'package:modudi/core/themes/app_color.dart'; // Import app colors
import 'package:modudi/core/extensions/string_extensions.dart'; // Import string extensions
import 'package:modudi/features/books/data/models/book_models.dart'; // Ensure Heading model is imported
// Import for readingRepositoryProvider

class ReadingScreen extends ConsumerStatefulWidget {
  final String bookId; // Add bookId field

  const ReadingScreen({
    super.key,
    required this.bookId, // Require bookId in constructor
  });

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState(); // Implement createState
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  final _log = Logger('ReadingScreen'); // Logger

  // State variables for UI panels and settings (local UI state)
  bool _showHeaderFooter = true;
  bool _showSettingsPanel = false;
  bool _showLibraryPanel = false;

  // Reading settings - Initialize with defaults or from provider
  double _fontSize = 16.0; // Example default
  double _lineSpacing = 1.5; // Example default
  String _fontType = 'Serif'; // Example default

  // Add to the class variables in the _ReadingScreenState class
  bool _showAiToolsPanel = false;
  bool _showVocabularyPopup = false;
  String _selectedWord = '';
  String _wordDefinition = '';
  bool _isSpeaking = false;
  String? _translatedText;
  final String _targetLanguage = 'English';
  Map<String, dynamic>? _recommendedSettings;
  Timer? _speechTimer;
  TextSelection? _selectedText;

  // Add new state variables
  String _chapterSearchQuery = ''; // Added for chapter search

  String? _chapterId;
  String? _headingId;

  @override
  void initState() {
    super.initState();
    // Load settings initially
    _loadSettingsFromProvider();
    
    // Set up listener to update settings when they change
    ref.listenManual(settingsProvider, (previous, next) {
      if (previous?.fontSize != next.fontSize) {
        _log.info('Font size changed to: ${next.fontSize}');
        setState(() {
          _fontSize = next.fontSize.size;
        });
      }
    });

    // Process query parameters for chapter and heading navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure widget is still mounted before processing
        _processNavigationParameters();
      }
    });
  }
  
  void _loadSettingsFromProvider() {
    final settings = ref.read(settingsProvider);
    _fontSize = settings.fontSize.size;
    // Load other settings as needed
    // _lineSpacing = settings.lineSpacing;
    // _fontType = settings.fontType;
  }
  
  // Process navigation parameters from URL query parameters
  void _processNavigationParameters() {
    if (!mounted) return; // Check if widget is still in the tree

    try {
      // Use GoRouterState.of(context) for safer access to route information
      final routerState = GoRouterState.of(context);
      final uri = routerState.uri; // GoRouterState.uri is already a Uri object
      
      // Extract query parameters
      _chapterId = uri.queryParameters['chapterId'];
      _headingId = uri.queryParameters['headingId'];
      
      _log.info('Processing navigation parameters: chapterId=$_chapterId, headingId=$_headingId');
      
      if (_chapterId != null) {
        // Wait for content to load first
        ref.listenManual(
          readingNotifierProvider(widget.bookId), 
          (previous, current) {
            if (!mounted) return; // Check mounted status in listener callback
            // Only process once content is loaded successfully
            if (current.status == ReadingStatus.displayingText) {
              _navigateToSpecificContent(_chapterId!, _headingId);
            }
          },
        );
      }
    } catch (e) {
      _log.severe('Error processing navigation parameters: $e');
    }
  }
  
  // Navigate to specific content by chapter ID and heading ID
  void _navigateToSpecificContent(String chapterId, String? headingId) {
    _log.info('Navigating to specific content: chapterId=$chapterId, headingId=$headingId');
    
    try {
      final state = ref.read(readingNotifierProvider(widget.bookId));
      final notifier = ref.read(readingNotifierProvider(widget.bookId).notifier);
      
      if (state.mainChapterKeys == null) {
        _log.warning('mainChapterKeys is null for chapter ID: $chapterId');
        return;
      }
      
      _log.info('Looking for chapter ID: $chapterId in ${state.mainChapterKeys!.length} chapters');
      
      // 1. Direct match in mainChapterKeys
      int targetIndex = state.mainChapterKeys!.indexOf(chapterId);
      
      // 2. If not found, try numeric index
      if (targetIndex == -1) {
        final numericId = int.tryParse(chapterId);
        if (numericId != null) {
          // Try as 0-based index
          if (numericId >= 0 && numericId < state.mainChapterKeys!.length) {
            targetIndex = numericId;
            _log.info('Using numeric chapter ID as 0-based index: $numericId');
          }
          // Try as 1-based index
          else if (numericId > 0 && numericId <= state.mainChapterKeys!.length) {
            targetIndex = numericId - 1;
            _log.info('Using numeric chapter ID as 1-based index: $numericId -> $targetIndex');
          }
        }
      }
      
      if (targetIndex >= 0 && targetIndex < state.mainChapterKeys!.length) {
        final chapterIdToGo = state.mainChapterKeys![targetIndex];
        _log.info('Navigating to chapterId $chapterIdToGo at index $targetIndex');
        notifier.goToChapter(chapterIdToGo);
        
        // TODO: Handle heading navigation if headingId is provided
        if (headingId != null) {
          _log.info('Heading navigation not yet implemented: $headingId');
        }
      } else {
        _log.warning('Failed to find valid index for chapter ID: $chapterId');
      }
    } catch (e) {
      _log.severe('Error navigating to specific content: $e');
    }
  }
  
  // Find the logical chapter index from chapter ID
  int? _findLogicalChapterIndex(String chapterId) {
    try {
      final state = ref.read(readingNotifierProvider(widget.bookId));

      if (state.mainChapterKeys == null || state.mainChapterKeys!.isEmpty) {
        _log.info('mainChapterKeys is null or empty when searching for chapter ID: $chapterId in _findLogicalChapterIndex');
        return null;
      }
      
      // At this point, state.mainChapterKeys is guaranteed non-null and non-empty.
      _log.info('Searching for chapter ID: $chapterId in mainChapterKeys within _findLogicalChapterIndex');
      for (int i = 0; i < state.mainChapterKeys!.length; i++) {
        final key = state.mainChapterKeys![i];
        if (key == chapterId) {
          _log.info('Found chapter ID: $chapterId at index: $i in mainChapterKeys');
          return i;
        }
      }
      
      // Next check against any generated chapters if available
      if (state.aiExtractedChapters != null && state.aiExtractedChapters!.isNotEmpty) { // Added null check
        for (int i = 0; i < state.aiExtractedChapters!.length; i++) {
          final chapter = state.aiExtractedChapters![i];
          if (chapter['id']?.toString() == chapterId) {
            return i;
          }
        }
      }
      
      // If not found, check against headings if available
      if (state.headings != null && state.headings!.isNotEmpty) {
        // Create a mapping of chapter IDs to their index position
        Map<String, int> chapterIndexMap = {};
        for (var headingData in state.headings!) { // Changed var name for clarity
            String key = headingData.chapterId?.toString() ?? headingData.volumeId?.toString() ?? "default_chapter";
            if (!chapterIndexMap.containsKey(key)) {
              chapterIndexMap[key] = chapterIndexMap.length;
            }
        }
        
        // Check if our chapterId appears in this mapping
        if (chapterIndexMap.containsKey(chapterId)) {
          return chapterIndexMap[chapterId];
        }
        
        // Also check headings' IDs directly
        for (var headingData in state.headings!) {
            if (headingData.firestoreDocId == chapterId) {
              String key = headingData.chapterId?.toString() ?? headingData.volumeId?.toString() ?? "default_chapter";
              return chapterIndexMap[key]; // chapterIndexMap[key] could be null if key not found
            }
        }
      }
      
      // If we get here, we couldn't find the chapter
      _log.warning('Could not find chapter with ID: $chapterId');
      return null;
    } catch (e, stackTrace) { // Added stackTrace
      _log.severe('Error finding logical chapter index: $e', e, stackTrace);
      return null;
    }
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    super.dispose();
  }

  // --- Toggle Methods ---
  void _toggleHeaderFooter() {
    setState(() {
      _showHeaderFooter = !_showHeaderFooter;
      // Ensure panels are closed when header/footer is hidden
      if (!_showHeaderFooter) {
        _showSettingsPanel = false;
        _showLibraryPanel = false;
        _showAiToolsPanel = false;
      }
    });
    _log.info("AppBar visibility toggled: $_showHeaderFooter");
  }

  void _toggleSettingsPanel() {
    _log.info("[DEBUG] _toggleSettingsPanel called - current state: $_showSettingsPanel");
    setState(() {
      _showSettingsPanel = !_showSettingsPanel;
      if (_showSettingsPanel) {
        _showLibraryPanel = false;
        _showAiToolsPanel = false;
        _showHeaderFooter = true; // Keep AppBar visible
      }
    });
    _log.info("[DEBUG] Settings Panel visibility after toggle: $_showSettingsPanel");
  }

  void _toggleLibraryPanel() {
    _log.info("[DEBUG] _toggleLibraryPanel called - current state: $_showLibraryPanel");
    setState(() {
      _showLibraryPanel = !_showLibraryPanel;
      if (_showLibraryPanel) {
        _showSettingsPanel = false;
        _showAiToolsPanel = false;
        _showHeaderFooter = true; // Keep AppBar visible
      }
    });
    _log.info("[DEBUG] Library Panel visibility after toggle: $_showLibraryPanel");
  }

  void _toggleAiToolsPanel() {
    setState(() {
      _showAiToolsPanel = !_showAiToolsPanel;
      if (_showAiToolsPanel) {
        _showSettingsPanel = false;
        _showLibraryPanel = false;
        _showHeaderFooter = true; // Keep AppBar visible
      }
    });
    _log.info("AI Tools Panel visibility toggled: $_showAiToolsPanel");
  }

  // --- Settings Update Callbacks ---
  void _updateFontSize(double newSize) {
    setState(() => _fontSize = newSize);
    _log.info("Font size updated: $newSize");
    // TODO: Persist setting via settingsProvider.notifier.setFontSize(newSize);
  }

  void _updateLineSpacing(double newLineSpacing) {
    setState(() => _lineSpacing = newLineSpacing);
    _log.info("Line spacing updated: $newLineSpacing");
    // TODO: Persist setting via settingsProvider.notifier.setLineSpacing(newLineSpacing);
  }

  void _updateFontType(String newFontType) {
    setState(() => _fontType = newFontType);
    _log.info("Font type updated: $newFontType");
    // TODO: Persist setting via settingsProvider.notifier.setFontType(newFontType);
  }

  // Get theme colors based on current theme
  ColorScheme _getThemeColors() {
    final settings = ref.watch(settingsProvider);
    switch (settings.themeMode) {
      case AppThemeMode.light:
        return const ColorScheme.light(
          primary: AppColor.primary,
          secondary: AppColor.accent,
          surface: AppColor.surface,
          onSurface: AppColor.textPrimary,
        );
      case AppThemeMode.sepia:
        return const ColorScheme.light(
          primary: AppColor.primarySepia,
          secondary: AppColor.accentSepia,
          surface: AppColor.surfaceSepia,
          onSurface: AppColor.textPrimarySepia,
        );
      case AppThemeMode.dark:
        return const ColorScheme.dark(
          primary: AppColor.primaryDark,
          secondary: AppColor.accentDark,
          surface: AppColor.surfaceDark,
          onSurface: AppColor.textPrimaryDark,
        );
      // Add default case for system theme
      default:
        return const ColorScheme.light(
          primary: AppColor.primary,
          secondary: AppColor.accent,
          surface: AppColor.surface,
          onSurface: AppColor.textPrimary,
        );
    }
  }

  Widget _buildContentSection(String title, String content, String language) {
    final theme = Theme.of(context);
    final readingState = ref.watch(readingNotifierProvider(widget.bookId));
    final isThisSectionBookmarked = readingState.bookmarks.any((b) => b.headingTitle == title);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_books, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface ?? Colors.black, // Fallback color
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isThisSectionBookmarked
                    ? Icons.bookmark 
                    : Icons.bookmark_border,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: () {
                  _log.info("Bookmark toggle attempt in _buildContentSection for title '$title'. Needs refactor to use Heading object.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bookmarking from this view needs update.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith( // Ensure bodyLarge is not null
              color: theme.colorScheme.onSurface ?? Colors.black, // Fallback color
              fontSize: _fontSize,
              height: _lineSpacing,
              fontFamily: _getFontFamily(language),
            ),
            textAlign: _getTextAlignment(language),
          ),
          const SizedBox(height: 16),
          Divider(color: (theme.colorScheme.onSurface ?? Colors.black).withAlpha((0.1 * 255).round())), // Fallback color
        ],
      ),
    );
  }
  
  String _getFontFamily(String? language) { // Made language nullable
    // Use the extension to get the preferred font family
    return language?.preferredFontFamily ?? 'DefaultFont'; // Provide a default font
  }

  TextAlign _getTextAlignment(String? language) { // Made language nullable
    // Use the extension to determine text alignment based on RTL
    return language?.isRTL ?? false ? TextAlign.right : TextAlign.justify; // Default to LTR
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingState = ref.watch(readingNotifierProvider(widget.bookId));
    final size = MediaQuery.of(context).size; // Potentially unused, consider removing if not needed
    final colors = _getThemeColors(); // This uses settingsProvider, which is fine

    // Determine current language safely
    final currentLanguage = readingState.currentLanguage ?? 'en'; // Default to 'en'

    return Theme(
      data: ThemeData(
        colorScheme: colors,
        scaffoldBackgroundColor: colors.surface, 
        textTheme: theme.textTheme.copyWith( 
          bodyLarge: TextStyle(fontFamily: _getFontFamily(currentLanguage), fontSize: _fontSize, height: _lineSpacing, color: colors.onSurface),
          titleMedium: TextStyle(fontFamily: _getFontFamily(currentLanguage), fontWeight: FontWeight.bold, color: colors.onSurface),
          headlineSmall: TextStyle(fontFamily: _getFontFamily(currentLanguage), fontWeight: FontWeight.bold, color: colors.onSurface),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colors.surface, 
          elevation: 0, 
          iconTheme: IconThemeData(color: colors.onSurface),
          titleTextStyle: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: _getFontFamily(currentLanguage),
          ),
        )
      ),
      child: Scaffold(
      appBar: _showHeaderFooter 
        ? AppBar(
            leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
              onPressed: () {
                    if (mounted && context.canPop()) { // Added mounted check
                      context.pop();
                    } else if (mounted) { // Added mounted check
                      context.goNamed(RouteNames.bookDetail, pathParameters: {'bookId': widget.bookId});
                    }
              },
            ),
            title: Text(
              readingState.bookTitle ?? 'Reading',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: colors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            actions: [
              Builder(builder: (context) {
                // Determine the current chapter and its first heading
                Heading? firstHeadingOnPage;
                String? currentChapterKey;
                String? currentChapterTitleForAppBar;
                bool canToggleAppBarBookmark = false;

                if (readingState.status == ReadingStatus.displayingText && readingState.headings != null && readingState.headings!.isNotEmpty) {
                  Map<String, List<Heading>> groupedHeadings = {};
                  List<String> logicalChapterKeys = [];
                  for (var heading in readingState.headings!) {
                    String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
                    if (!groupedHeadings.containsKey(chapterKey)) {
                      logicalChapterKeys.add(chapterKey);
                    }
                    (groupedHeadings[chapterKey] ??= []).add(heading);
                  }

                  if (logicalChapterKeys.isNotEmpty && readingState.currentChapter >= 0 && readingState.currentChapter < logicalChapterKeys.length) {
                    currentChapterKey = logicalChapterKeys[readingState.currentChapter];
                    currentChapterTitleForAppBar = "Chapter ${readingState.currentChapter + 1}";
                    final headingsForCurrentPage = groupedHeadings[currentChapterKey];
                    if (headingsForCurrentPage != null && headingsForCurrentPage.isNotEmpty) {
                      firstHeadingOnPage = headingsForCurrentPage.first;
                      canToggleAppBarBookmark = firstHeadingOnPage.firestoreDocId != null;
                    }
                  }
                }
                
                return FutureBuilder<bool>(
                  future: Future.value(true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return IconButton(
                        icon: Icon(
                          firstHeadingOnPage?.firestoreDocId != null &&
                              readingState.bookmarks.any((b) => b.headingId == firstHeadingOnPage?.firestoreDocId)
                              ? Icons.bookmark 
                              : Icons.bookmark_border,
                          color: canToggleAppBarBookmark ? colors.primary : colors.onSurface.withAlpha((0.5 * 255).round()),
                        ),
                        onPressed: canToggleAppBarBookmark && firstHeadingOnPage != null && currentChapterKey != null && currentChapterTitleForAppBar != null
                            ? () {
                                // Bookmark functionality moved to SimpleBookmarkService
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Bookmark functionality updated - use reading screen settings')),
                                );
                              }
                            : null, // Disable if no valid heading to bookmark
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                );
              }),
              Builder(builder: (context) {
                // Determine the current chapter and its first heading
                Heading? firstHeadingOnPage;
                String? currentChapterKey;
                String? currentChapterTitleForAppBar;
                bool canToggleAppBarBookmark = false;

                if (readingState.status == ReadingStatus.displayingText && readingState.headings != null && readingState.headings!.isNotEmpty) {
                  Map<String, List<Heading>> groupedHeadings = {};
                  List<String> logicalChapterKeys = [];
                  for (var heading in readingState.headings!) {
                    String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
                    if (!groupedHeadings.containsKey(chapterKey)) {
                      logicalChapterKeys.add(chapterKey);
                    }
                    (groupedHeadings[chapterKey] ??= []).add(heading);
                  }

                  if (logicalChapterKeys.isNotEmpty && readingState.currentChapter >= 0 && readingState.currentChapter < logicalChapterKeys.length) {
                    currentChapterKey = logicalChapterKeys[readingState.currentChapter];
                    final headingsForCurrentPage = groupedHeadings[currentChapterKey];
                    if (headingsForCurrentPage != null && headingsForCurrentPage.isNotEmpty) {
                      firstHeadingOnPage = headingsForCurrentPage.first;
                      canToggleAppBarBookmark = firstHeadingOnPage.firestoreDocId != null;

                      // Try to get a title for this chapter
                      final List<PlaceholderChapter> allMainChapters = _extractChapters(readingState);
                      final mainChapterDetails = allMainChapters.firstWhere(
                        (ch) => ch.id == currentChapterKey,
                        orElse: () => PlaceholderChapter(id: currentChapterKey!, title: 'Chapter', pageStart: 0)
                      );
                      currentChapterTitleForAppBar = mainChapterDetails.title;
                    }
                  }
                }

                final bool isFirstHeadingBookmarked = firstHeadingOnPage?.firestoreDocId != null &&
                    readingState.bookmarks.any((b) => b.headingId == firstHeadingOnPage?.firestoreDocId);

                return IconButton(
                  icon: Icon(
                    isFirstHeadingBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: canToggleAppBarBookmark ? colors.primary : colors.onSurface.withAlpha((0.5 * 255).round()),
                  ),
                  onPressed: canToggleAppBarBookmark && firstHeadingOnPage != null && currentChapterKey != null && currentChapterTitleForAppBar != null
                      ? () {
                          if (firstHeadingOnPage != null && currentChapterKey != null && currentChapterTitleForAppBar != null) {
                            // Bookmark functionality moved to SimpleBookmarkService
                            // ref.read(readingNotifierProvider(widget.bookId).notifier).toggleBookmark(
                            //       firstHeadingOnPage,
                            //       currentChapterKey,
                            //       currentChapterTitleForAppBar,
                            //     );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bookmark functionality updated - use reading screen settings')),
                                );
                          }
                        }
                      : null, // Disable if no valid heading to bookmark
                );
              }),
              IconButton(
                icon: Icon(Icons.menu_book_outlined, color: colors.onSurface), // Chapters/Library
                onPressed: _toggleLibraryPanel,
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.onSurface),
                onSelected: (value) {
                  if (value == 'settings') {
                    _toggleSettingsPanel();
                  } else if (value == 'ai_tools') {
                    _toggleAiToolsPanel();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ai_tools',
                    child: ListTile(leading: Icon(Icons.psychology_outlined), title: Text('AI Tools')),
                  ),
                ],
              ),
            ],
          )
        : null,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleHeaderFooter, // Toggle AppBar visibility on tap
              child: _buildReadingContent(readingState, context, Theme.of(context).colorScheme),
            ),
            // Settings panel with smooth animation
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _showSettingsPanel ? 0 : -MediaQuery.of(context).size.width,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.85, // Keep panel size reasonable
              child: _buildSettingsPanel(Theme.of(context)), // Pass app theme
            ),
            // Chapters panel with smooth animation
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _showLibraryPanel ? 0 : -size.width,
              top: 0,
              bottom: 0,
                width: size.width * 0.85, // Keep panel size reasonable
                child: _buildChaptersPanel(theme, readingState), // Pass app theme
            ),
            // if (_showAiToolsPanel)
            //     Positioned.fill(
            //     // child: AiToolsPanel(
            //     //     onClose: _toggleAiToolsPanel,
            //     //   bookId: widget.bookId,
            //     //   bookState: readingState,
            //     // ),
            //   ),
            if (_showVocabularyPopup)
                Positioned.fill(
                child: VocabularyAssistPopup(
                  word: _selectedWord,
                  definition: _wordDefinition,
                  onClose: _closeVocabularyPopup,
                ),
              ),
            if (_translatedText != null)
                Positioned.fill(
                child: TranslationOverlay(
                  onClose: _clearTranslation,
                  text: _translatedText,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  // --- Build Helper for Reading Content (New Design) ---
  Widget _buildReadingContent(ReadingState state, BuildContext context, ColorScheme colors) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      fontFamily: _getFontFamily(state.currentLanguage ?? 'en'),
      fontSize: _fontSize,
      height: _lineSpacing,
      color: colors.onSurface,
    );

    switch (state.status) {
      case ReadingStatus.loading: // Original 'Loading...' case
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 20),
              Text('Loading...', style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface))
            ],
          )
        );
      case ReadingStatus.initial:
      case ReadingStatus.loadingMetadata:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 20),
              Text('Loading book details...', style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface))
            ],
          )
        );
      case ReadingStatus.success: // Added to fall through to displayingText
      case ReadingStatus.displayingText:
        return _buildNewTextContentDisplay(context, state, colors, textStyle);
      case ReadingStatus.error:
        String errorMessage = state.errorMessage ?? 'An unknown error occurred.';
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: colors.error),
                const SizedBox(height: 20),
                Text('Failed to load content', style: theme.textTheme.headlineSmall?.copyWith(color: colors.error)),
                const SizedBox(height: 12),
                Text(errorMessage, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onErrorContainer), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.read(readingNotifierProvider(widget.bookId).notifier).reload(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      // Removed downloading case - no longer needed with Firebase and cache
      case ReadingStatus.loadingContent:
         return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 20),
              Text('Preparing content...', style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface)),
            ],
          ),
        );
    }
  }

  // New method for displaying text content according to the reference image
  Widget _buildNewTextContentDisplay(BuildContext context, ReadingState state, ColorScheme colors, TextStyle baseTextStyle) {
    // Determine the order of chapter keys for PageView
    Map<String, List<Heading>> groupedHeadings = {};
    List<String> logicalChapterKeys = []; // Chapter keys in their logical order (e.g., Ch1, Ch2, Ch3)
    
    if (state.headings != null) {
      for (var heading in state.headings!) {
        String chapterKey = heading.chapterId?.toString() ?? heading.volumeId?.toString() ?? "default_chapter";
        if (!groupedHeadings.containsKey(chapterKey)) {
          logicalChapterKeys.add(chapterKey); // Add to maintain logical order
        }
        (groupedHeadings[chapterKey] ??= []).add(heading);
      }
    }

    // Get all main chapter details for titles
    final List<PlaceholderChapter> allMainChapters = _extractChapters(state);

    // We now use the logical order directly, no more reversed list
    // This ensures consistency between chapter selection and display
    List<String> displayedChapterKeys = logicalChapterKeys.toList();
    int N = displayedChapterKeys.length;

    // Calculate initialPageViewIndex to match currentChapter
    // We used to display chapters in reverse order, but now we want to show them
    // in the same order as they appear in the logical index for consistency
    int initialPageViewIndex = state.currentChapter.clamp(0, N - 1); // Ensure it's within bounds

    final PageController pageController = PageController(initialPage: initialPageViewIndex);

    pageController.addListener(() {
      if (pageController.page != null && N > 0) {
        int currentRawPvIndex = pageController.page!.round();
        if (currentRawPvIndex >=0 && currentRawPvIndex < N) {
          int currentLogicalPageIndex = currentRawPvIndex; // Direct mapping instead of reversed
          _log.info(
              "PageController scroll: PageView Index $currentRawPvIndex, Logical Index: $currentLogicalPageIndex. State's logical chapter: ${state.currentChapter}");
        } else {
          _log.warning("PageController scroll: PageView Index $currentRawPvIndex is out of bounds (0-${N-1}).");
        }
      }
    });
    
    // If no headings, show appropriate message or use state.textContent if available as a single page
    if (displayedChapterKeys.isEmpty) {
      if (state.textContent != null && state.textContent!.isNotEmpty) {
        // Display state.textContent as a single page/section if no other structure is found
        // For a single page, bookmarking needs a different context (e.g., whole book or manual selection)
        // This part is not covered by the current heading-based bookmarking logic.
        final String sectionTitle = state.currentHeadingTitle ?? state.bookTitle ?? "Content";
        final String bookmarkKey = state.bookId ?? sectionTitle; // Simple key for the whole content
        final bool isBookmarked = state.bookmarks.any((b) => b.headingId == bookmarkKey); // Check if bookmarked
        
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildNewContentSection(
              context,
              sectionTitle,
              state.textContent!,
              state.currentLanguage ?? 'en',
              colors,
              baseTextStyle, // Pass baseTextStyle as textStyle
              isBookmarked: isBookmarked,
              onBookmarkToggle: () {
                // This would require a different bookmarking strategy for plain text content
                // For now, let's log or disable it for plain text.
                _log.info("Bookmark toggle for plain text content (not fully implemented for this view yet).");
                // Example: Create a dummy Heading-like structure or a specific bookmark type
                // ref.read(readingNotifierProvider(widget.bookId).notifier).toggleBookmark(...);
              },
              onHeadingTap: () {
                // Handle tap for plain text content
                _log.info("Tapped on plain text content");
              },
              heading: null, // No specific heading for plain text
              chapterId: state.bookId!, // Use bookId as a chapterId placeholder
              chapterTitle: state.bookTitle ?? "Main Content", // Use bookTitle as chapterTitle placeholder
            )
          ],
        );
      }
      return Center(child: Text("No content segments to display.", style: baseTextStyle));
    }

    return Container(
      color: colors.surface, // Use themed background
      child: PageView.builder(
        key: ValueKey(state.currentChapter), // Ensure PageView re-initializes with new chapter
        controller: pageController,
        itemCount: N, // Use count of displayed (reversed) keys
        onPageChanged: (newPageViewIndex) {
          if (N > 0) {
            int currentRawPvIndex = newPageViewIndex;
            if (currentRawPvIndex >=0 && currentRawPvIndex < N) {
              int currentLogicalPageIndex = currentRawPvIndex; // Direct mapping instead of reversed
              _log.info(
                  "PageView changed to PageView Index: $currentRawPvIndex, Logical Index: $currentLogicalPageIndex. Chapter Key: ${displayedChapterKeys[newPageViewIndex]}");
              final chapterIdToGo = displayedChapterKeys[newPageViewIndex];
              ref.read(readingNotifierProvider(widget.bookId).notifier).goToChapter(chapterIdToGo);
            }
          }
        },
        itemBuilder: (context, pageViewIndex) {
          // pageViewIndex is from 0 to N-1, mapping to displayedChapterKeys
          final chapterKeyForDisplay = displayedChapterKeys[pageViewIndex];
          final List<Heading> headingsForThisPage = groupedHeadings[chapterKeyForDisplay]!;
          
          // Find the chapter title for this chapterKeyForDisplay
          final mainChapterDetails = allMainChapters.firstWhere(
            (ch) => ch.id == chapterKeyForDisplay,
            orElse: () => PlaceholderChapter(id: chapterKeyForDisplay, title: 'Chapter', pageStart: 0)
          );
          final String currentChapterTitle = mainChapterDetails.title;

          // This inner ListView displays all headings for the current main chapter page
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: headingsForThisPage.length,
            itemBuilder: (context, sectionIndex) {
              final heading = headingsForThisPage[sectionIndex];
              final String sectionTitle = heading.title ?? "Section ${sectionIndex + 1}";
              final String sectionContent = heading.content?.join('\n\n') ?? "No content for this section.";
              final String sectionLanguage = state.currentLanguage ?? 'en'; // Defaulting to state language for now
              
              // Determine if this heading is bookmarked
              final bool isBookmarked = state.bookmarks.any((b) => b.headingId == heading.firestoreDocId);

              return _buildNewContentSection(
                context,
                sectionTitle,
                sectionContent,
                sectionLanguage,
                colors,
                baseTextStyle, // Pass baseTextStyle as textStyle
                isBookmarked: isBookmarked,
                onBookmarkToggle: () {
                  // ref.read(readingNotifierProvider(widget.bookId).notifier).toggleBookmark(
                  //       heading, 
                  //       chapterKeyForDisplay, 
                  //       currentChapterTitle
                  //     );
                  // TODO: Implement simple bookmark functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bookmark functionality updated - use reading screen settings')),
                      );
                                },
                onHeadingTap: () {
                  // Navigate to this specific heading
                  _log.info('Navigating to heading: ${heading.firestoreDocId}');
                  ref.read(readingNotifierProvider(widget.bookId).notifier)
                     .goToChapter(chapterKeyForDisplay, headingId: heading.firestoreDocId);
                  Navigator.of(context).pop(); // Close the AI tools panel
                },
                heading: heading, // Pass the heading object
                chapterId: chapterKeyForDisplay,
                chapterTitle: currentChapterTitle,
              );
            },
          );
        },
      ),
    );
  }

  // New method to build a single content section according to the image
  Widget _buildNewContentSection(
    BuildContext context,
    String title,
    String textContent,
    String language,
    ColorScheme colors,
    TextStyle textStyle, // Changed parameter name from baseTextStyle to textStyle for consistency
    {
    required bool isBookmarked,
    required VoidCallback onBookmarkToggle,
    required VoidCallback onHeadingTap, // Added heading tap callback
    required Heading? heading, // Added heading parameter
    required String chapterId, // Added chapterId
    required String chapterTitle, // Added chapterTitle
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: InkWell(
        onTap: onHeadingTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: colors.primary,
                  size: 24,
                ),
                onPressed: onBookmarkToggle,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface, 
                    fontSize: textStyle.fontSize! + 2, // Use textStyle.fontSize here
                    fontWeight: FontWeight.bold,
                    fontFamily: _getFontFamily(language),
                  ),
                  textAlign: _getTextAlignment(language),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column( // New Column for paragraphs
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (heading?.content?.isNotEmpty ?? false)
                  ? heading!.content!.map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0), // Space between paragraphs
                      child: Text(
                        paragraph,
                        style: textStyle.copyWith( 
                          fontFamily: _getFontFamily(language), 
                          color: colors.onSurface.withAlpha((0.85 * 255).round()),
                        ),
                        textAlign: _getTextAlignment(language),
                      ),
                    )).toList()
                  : [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "No content for this section.",
                          style: textStyle.copyWith(
                            fontFamily: _getFontFamily(language),
                            color: colors.onSurface.withAlpha((0.6 * 255).round()), // Dimmer for fallback
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: _getTextAlignment(language),
                        ),
                      ),
                    ],
            ),
          ),
          Divider(color: colors.outline.withAlpha((0.3 * 255).round()), height: 32, thickness: 0.5),
            ],
          ),
        ),
      ),
    );
  }

  // --- Build Helper Methods ---

  // Extract chapters from EPUB controller
  List<PlaceholderChapter> _extractChapters(ReadingState state) {
    List<PlaceholderChapter> chapters = [];
    
    // First check if we have AI-extracted chapters (these are assumed to be main chapters)
    if (state.aiExtractedChapters != null && state.aiExtractedChapters!.isNotEmpty) {
      _log.info('Using AI-extracted chapters for main chapter display: ${state.aiExtractedChapters!.length}');
      chapters = state.aiExtractedChapters!.values.toList().asMap().entries.map((entry) {
        final chapter = entry.value;
        return PlaceholderChapter(
          id: (entry.key).toString(), // Or a more specific ID if available from AI
          title: chapter['title'] ?? 'Chapter ${entry.key + 1}',
          pageStart: entry.key + 1, // AI chapters are usually 1-based, for navigation this will be index
          subtitle: chapter['subtitle'],
        );
      }).toList();
      return chapters;
    }
    
    // If no AI chapters, use mainChapterKeys and headings from Firestore
    if (state.mainChapterKeys != null && state.mainChapterKeys!.isNotEmpty && state.headings != null && state.headings!.isNotEmpty) {
      _log.info('Using state.mainChapterKeys (${state.mainChapterKeys!.length}) and state.headings for main chapter display.');
      for (int i = 0; i < state.mainChapterKeys!.length; i++) {
        final chapterKey = state.mainChapterKeys![i];
        String chapterTitle = 'Chapter ${i + 1}'; // Default title

        // Find the first heading that matches this chapterKey to get a title
        Heading? firstMatchingHeading; // Initialize as nullable Heading
        for (final h_generic in state.headings!) {
          final h = h_generic; // Cast to Heading
          if ((h.chapterId?.toString() ?? h.volumeId?.toString() ?? "default_chapter") == chapterKey) {
            firstMatchingHeading = h;
            break; // Found the first match, exit loop
          }
                  // Add other type checks if headings can be other types
        }

        if (firstMatchingHeading != null) {
          chapterTitle = firstMatchingHeading.title ?? chapterTitle;
        }
        
            chapters.add(PlaceholderChapter(
          id: chapterKey, // Use the main chapter key as ID
          title: chapterTitle,
          pageStart: i + 1, // This is 1-based for display, navigation will use index (i)
        ));
      }
      if (chapters.isNotEmpty) return chapters;
    }
    
    // Fallback if no other chapter structure is found (e.g., plain text with no headings/keys)
    if (state.status == ReadingStatus.displayingText) {
      _log.info('Fallback: Creating a single chapter placeholder for plain text content.');
      chapters = [
        PlaceholderChapter(id: 'main', title: state.bookTitle ?? 'Book Content', pageStart: 1),
      ];
    }
    return chapters;
  }
  
  // Navigate to a specific chapter
  void _navigateToChapter(ReadingState state, PlaceholderChapter chapter, int index) {
    // The 'index' here is the index from the ListView.builder, which corresponds to the logical chapter index.
    _log.info('Navigating to main chapter: ${chapter.title} (ID: ${chapter.id}, Logical Index from ListView: $index)');
    
    if (state.status == ReadingStatus.displayingText) {
      // We need to ensure the ReadingNotifier.navigateToChapter or navigateToLogicalChapter
      // expects a 0-based logical index.
      // If PlaceholderChapter.pageStart was 1-based for display, we use 'index'.
      // If ReadingNotifier expects a 0-based index, 'index' is already correct.
      final chapterId = state.mainChapterKeys![index];
      ref.read(readingNotifierProvider(widget.bookId).notifier).goToChapter(chapterId);
      _log.info('Text: Navigating to chapter ID $chapterId at logical index $index');
        } else {
        _log.warning('Cannot navigate: invalid reading state ${state.status}');
    }
  }

  // Extract a readable title from the book ID
  String _getBookTitle(String bookId) {
    // Map of known book IDs to proper titles
    const Map<String, String> knownBooks = {
      'tafheem-ul-quran-urdu': 'Tafheem-ul-Quran',
      'let-us-be-muslims-maududi': 'Let Us Be Muslims',
      '055.surah-ar-rahman': 'Surah Ar-Rahman',
      'islamic-way-of-life': 'Islamic Way of Life',
      'purdah-status-women-islam': 'Purdah and Women in Islam',
      'first-principles-islamic-economics': 'Islamic Economics',
      'four-basic-quranic-terms': 'Basic Quranic Terms',
    };
    
    // Return known title or format the ID
    if (knownBooks.containsKey(bookId)) {
      return knownBooks[bookId]!;
    }
    
    // Format the ID by replacing hyphens with spaces and capitalizing words
    return bookId.split('-').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1);
      }
      return '';
    }).join(' ');
  }

  // Add method for fetching AI-extracted chapters
  Future<void> _loadAiExtractedChapters(ReadingState state) async {
    if (state.status == ReadingStatus.displayingText) {
      try {
        String textToAnalyze = '';
        bool isToc = false; // Flag to indicate if it's likely a TOC
        if (state.status == ReadingStatus.displayingText && state.textContent != null) {
          textToAnalyze = state.textContent!;
        }
        
        if (textToAnalyze.isNotEmpty) {
          // Request chapter extraction - Use the provider directly
          // No need to await here unless we need the result immediately in this screen
          ref.read(readingNotifierProvider(widget.bookId).notifier)
             .extractChaptersWithAi(forceTocExtraction: isToc); 
             
          // State update happens within the provider
          // We rely on watching the provider state for UI updates
          // No need to call updateChapters here anymore
        }
      } catch (e) {
        _log.severe('Error triggering AI chapter extraction: $e');
        // Show a snackbar with error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start chapter extraction')),
        );
      }
    }
  }

  // Add method to analyze difficult words
  Future<void> _analyzeDifficultWords(ReadingState state) async {
    if (state.textContent != null && state.textContent!.isNotEmpty) {
      try {
        // Request vocabulary analysis - Use provider
        await ref.read(readingNotifierProvider(widget.bookId).notifier)
            .analyzeDifficultWords(state.textContent!);
            
        // Show a snackbar to inform the user - based on provider state change
        // We might need to listen to state changes for this kind of feedback
        // Or handle it within the AiToolsPanel based on the ready status
        
      } catch (e) {
        if (!mounted) return;
      _log.severe('Error triggering difficult word analysis: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start vocabulary analysis')),
        );
      }
    }
  }

  // Add method to handle text selection for vocabulary assistance
  void _handleTextSelection(String selectedText) {
    // Ignore very short selections
    if (selectedText.length < 3) return;
    
    // Check if we have vocabulary data
    final readingState = ref.read(readingNotifierProvider(widget.bookId));
    final difficultWords = readingState.difficultWords;
    if (difficultWords == null || difficultWords.isEmpty) return;
    
    // Split into words and check each one
    final words = selectedText.split(' ');
    for (final word in words) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      
      // Look for this word in the difficultWords list
      for (final entry in difficultWords.entries) {
        if (entry.key.toLowerCase() == cleanWord) {
          _showWordDefinition(entry.key, entry.value);
          return;
        }
      }
    }
    
    // If word not found, check if we should look it up
    if (words.length == 1 && selectedText.length > 3) {
      // Could implement on-demand word lookup here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Definition not available for this word')),
      );
    }
  }
  
  // Add method to show vocabulary popup
  void _showWordDefinition(String? word, String? definition) {
    if (word != null && definition != null) {
      setState(() {
        _selectedWord = word;
        _wordDefinition = definition;
        _showVocabularyPopup = true;
      });
    }
  }

  // Add vocabulary popup method if it doesn't exist
  void _closeVocabularyPopup() {
    setState(() {
      _showVocabularyPopup = false;
    });
  }

  // Add vocabulary popup and translation methods if they don't exist
  void _clearTranslation() {
    setState(() {
      _translatedText = null;
    });
  }

  // --- Build Text Reading Content with Speech Highlighting ---
  Widget _buildTextContent(BuildContext context, ReadingState state, TextStyle textStyle) {
    final theme = Theme.of(context);
    final colors = _getThemeColors();
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: (state.textScrollPosition ?? 0.0) * (MediaQuery.of(context).size.height * 10),
    );
    
    // Listen to scroll changes to update progress
    scrollController.addListener(() {
      if (scrollController.hasClients && scrollController.position.hasContentDimensions) {
        final maxScroll = scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          final currentScroll = scrollController.offset;
          final scrollRatio = (currentScroll / maxScroll).clamp(0.0, 1.0);
          ref.read(readingNotifierProvider(widget.bookId).notifier).updateTextPosition(scrollRatio);
        }
      }
    });
    
    // Use the actual content from readingState
    String textContent = state.textContent ?? 'No text content available.';
    
    // Enhanced text style with theming
    final enhancedTextStyle = textStyle.copyWith(
      color: colors.onSurface,
      letterSpacing: 0.3,
    );
    
    // Split content into sections - parse the content more intelligently
    List<Map<String, String>> sections = [];
    
    // Parse content into sections based on markdown headers
    if (textContent.contains('##')) {
      // Simple parsing of markdown-style headers
      final parts = textContent.split('##').where((part) => part.trim().isNotEmpty).toList();
      for (final part in parts) {
        final lines = part.trim().split('\n');
        String title = lines.isNotEmpty ? lines.first.trim() : 'Section';
        String content = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
        sections.add({'title': title, 'content': content});
      }
    } else {
      // If no sections found, create a single section with available content
      String title = state.currentHeadingTitle ?? state.currentChapterTitle ?? state.bookTitle ?? 'Content';
      sections.add({'title': title, 'content': textContent});
    }
    
    // Container to provide better reading experience
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha((0.05 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main chapter title
              Text(
                state.bookTitle ?? 'Reading',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              Divider(color: colors.outline.withAlpha((0.1 * 255).round())),
              const SizedBox(height: 24),
              
              // If we have sections, display them
              if (sections.isNotEmpty)
                ...sections.map((section) => _buildContentSection(
                  section['title'] ?? 'Section',
                  section['content'] ?? 'No content available.',
                  state.currentLanguage ?? 'en',
                ))
              else
                // Fallback if somehow sections list is empty
                _buildContentSection(
                  state.currentHeadingTitle ?? state.currentChapterTitle ?? 'Content',
        textContent,
                  state.currentLanguage ?? 'en',
                ),
              
              // Add some bottom padding for comfortable reading
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build text spans with highlighting
  List<TextSpan> _buildHighlightedTextSpans(
    String text, 
    Map<String, dynamic> highlightPosition, 
    TextStyle normalStyle,
    TextStyle highlightStyle
  ) {
    final int start = highlightPosition['start'] as int? ?? 0;
    final int end = highlightPosition['end'] as int? ?? 0;
    
    if (start >= text.length || end > text.length || start >= end) {
      return [TextSpan(text: text, style: normalStyle)];
    }
    
    return [
      if (start > 0) 
        TextSpan(text: text.substring(0, start), style: normalStyle),
      TextSpan(text: text.substring(start, end), style: highlightStyle),
      if (end < text.length) 
        TextSpan(text: text.substring(end), style: normalStyle),
    ];
  }

  // Method to toggle text-to-speech
  void _toggleTextToSpeech() {
    final readingState = ref.read(readingNotifierProvider(widget.bookId));
    
    setState(() {
      _isSpeaking = !_isSpeaking;
    });
    
    if (_isSpeaking) {
      // Start speaking
      ref.read(readingNotifierProvider(widget.bookId).notifier).startSpeaking();
      
      // Simulate highlighting movement (in a real app, this would be driven by TTS engine events)
      // This is just a placeholder example
      _simulateSpeechHighlighting(readingState);
    } else {
      // Stop speaking
      ref.read(readingNotifierProvider(widget.bookId).notifier).stopSpeaking();
      _speechTimer?.cancel();
    }
  }
  
  // Simulate speech highlighting (this would be different in a real app with TTS events)
  void _simulateSpeechHighlighting(ReadingState state) {
    if (state.textContent == null || state.textContent!.isEmpty) return;
    
    final words = state.textContent!.split(' ');
    int currentWordIndex = 0;
    int currentPosition = 0;
    
    _speechTimer?.cancel();
    _speechTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isSpeaking || currentWordIndex >= words.length) {
        timer.cancel();
        setState(() {
          _isSpeaking = false;
        });
        ref.read(readingNotifierProvider(widget.bookId).notifier).stopSpeaking();
        return;
      }
      
      final word = words[currentWordIndex];
      final wordLength = word.length;
      
      // Calculate word start position in the full text
      int wordStart = currentPosition;
      int wordEnd = wordStart + wordLength;
      
      // Update position for next word
      currentPosition = wordEnd + 1; // +1 for the space
      currentWordIndex++;
      
      // Update the highlighted position in state
      ref.read(readingNotifierProvider(widget.bookId).notifier).updateHighlightedTextPosition({
        'start': wordStart,
        'end': wordEnd,
      });
    });
  }

  // Handle text selection changes
  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    if (selection.isValid && selection.isCollapsed == false) {
      // Store selection for possible actions
      setState(() {
        _selectedText = selection;
      });
    }
  }

  // Show context menu for text selection
  void _showTextSelectionMenu(BuildContext context) {
    final readingState = ref.read(readingNotifierProvider(widget.bookId));
    if (readingState.textContent == null) return;
    
    final TextSelection? selection = _selectedText;
    if (selection == null || !selection.isValid || selection.isCollapsed) return;
    
    final selectedText = selection.textInside(readingState.textContent!);
    if (selectedText.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _getThemeColors().surface,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.translate, color: _getThemeColors().onSurfaceVariant),
            title: Text('Translate', style: TextStyle(color: _getThemeColors().onSurface)),
            onTap: () {
              Navigator.pop(context);
              _translateSelectedText(selectedText);
            },
          ),
          ListTile(
            leading: Icon(Icons.volume_up, color: _getThemeColors().onSurfaceVariant),
            title: Text('Speak', style: TextStyle(color: _getThemeColors().onSurface)),
            onTap: () {
              Navigator.pop(context);
              _speakSelectedText(selectedText);
            },
          ),
          if (readingState.difficultWords == null || readingState.difficultWords!.isEmpty)
            ListTile(
              leading: Icon(Icons.psychology, color: _getThemeColors().onSurfaceVariant),
              title: Text('Analyze Vocabulary', style: TextStyle(color: _getThemeColors().onSurface)),
              onTap: () {
                Navigator.pop(context);
                _analyzeDifficultWords(readingState);
              },
            ),
          ListTile(
            leading: Icon(Icons.bookmark_add, color: _getThemeColors().onSurfaceVariant),
            title: Text('Add to Bookmarks', style: TextStyle(color: _getThemeColors().onSurface)),
            onTap: () {
              Navigator.pop(context);
              _addToBookmarks(selectedText);
            },
          ),
        ],
      ),
    );
  }

  // Method to translate selected text
  void _translateSelectedText(String text) async {
    try {
      // Use provider for translation
      await ref.read(readingNotifierProvider(widget.bookId).notifier)
          .translateText(text, _targetLanguage);
          
      // Update local state only for displaying the overlay
      final translatedData = ref.read(readingNotifierProvider(widget.bookId)).currentTranslation;
    if (!mounted) return;
    setState(() {
        _translatedText = translatedData?['translated'] as String? ?? 'Translation error';
      });

    } catch (e) {
      if (!mounted) return;
    _log.severe('Error translating text: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not translate the selected text')),
      );
    }
  }
  
  // Method to speak selected text
  void _speakSelectedText(String text) async {
    ref.read(readingNotifierProvider(widget.bookId).notifier)
       .generateSpeechMarkers(text);
       
    setState(() {
      _isSpeaking = true;
    });
    
    // This would be replaced with actual TTS implementation
    _simulateSpeechForSelection(text);
  }
  
  // Simulate speech for a selected text segment
  void _simulateSpeechForSelection(String text) {
    final words = text.split(' ');
    int currentWordIndex = 0;
    int currentPosition = 0;
    
    _speechTimer?.cancel();
    _speechTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isSpeaking || currentWordIndex >= words.length) {
        timer.cancel();
        setState(() {
          _isSpeaking = false;
        });
        ref.read(readingNotifierProvider(widget.bookId).notifier).stopSpeaking();
        return;
      }
      
      final word = words[currentWordIndex];
      final wordLength = word.length;
      
      // Calculate word start position in the full text
      int wordStart = currentPosition;
      int wordEnd = wordStart + wordLength;
      
      // Update position for next word
      currentPosition = wordEnd + 1; // +1 for the space
      currentWordIndex++;
      
      // Update the highlighted position in state
      ref.read(readingNotifierProvider(widget.bookId).notifier).updateHighlightedTextPosition({
        'start': wordStart,
        'end': wordEnd,
      });
    });
  }
  
  // Method to add text to bookmarks
  void _addToBookmarks(String text) {
    // Limit text to a reasonable length
    final trimmedText = text.length > 200 ? '${text.substring(0, 197)}...' : text;
    
    final bookmark = {
      'text': trimmedText,
      'type': 'User Selection',
      'importance': 3,
      'position': 'Manual Selection',
      'note': 'Added by user',
    };
    
    // Add to existing bookmarks or create new list
    final readingState = ref.read(readingNotifierProvider(widget.bookId));
    List<Map<String, dynamic>> updatedBookmarks = [
      ...readingState.suggestedBookmarks ?? [],
      bookmark,
    ];
    
    // Update bookmarks in state
    ref.read(readingNotifierProvider(widget.bookId).notifier)
       .updateBookmarks(updatedBookmarks);
       
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to bookmarks')),
    );
  }
  
  // Method to get recommended reading settings
  void _getRecommendedReadingSettings(ReadingState state) async {
    if (state.status == ReadingStatus.displayingText) {
      try {
        String language = 'English'; // Default
        if (state.textContent != null && state.textContent!.isNotEmpty) {
          // Use a sample of text to determine language
          final sample = state.textContent!.length > 500 
              ? state.textContent!.substring(0, 500) 
              : state.textContent!;
              
          // Use provider to get settings
          await ref.read(readingNotifierProvider(widget.bookId).notifier)
              .getRecommendedReadingSettings();
              
          // Get settings from state and update local variable for dialog
          final settings = ref.read(readingNotifierProvider(widget.bookId)).recommendedSettings;
          if (!mounted) return;
          setState(() {
            _recommendedSettings = settings;
          });
          
          // Offer to apply settings automatically if available
          if (_recommendedSettings != null && _recommendedSettings!.isNotEmpty) {
             if (!mounted) return;
           _showRecommendedSettingsDialog(context);
          }
        }
      } catch (e) {
        if (!mounted) return;
      _log.severe('Error getting recommended settings: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get recommended settings')),
        );
      }
    }
  }
  
  // Show dialog for recommended settings
  void _showRecommendedSettingsDialog(BuildContext context) {
    if (_recommendedSettings == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getThemeColors().surface,
        title: Text('AI-Recommended Settings', style: TextStyle(color: _getThemeColors().onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Based on this book\'s content, AI recommends:', style: TextStyle(color: _getThemeColors().onSurfaceVariant)),
            const SizedBox(height: 12),
            _buildSettingItem('Font Size', '${_recommendedSettings!['fontSize']}', _getThemeColors()),
            _buildSettingItem('Font Type', _recommendedSettings!['fontType'] as String, _getThemeColors()),
            _buildSettingItem('Line Spacing', '${_recommendedSettings!['lineSpacing']}', _getThemeColors()),
            if (_recommendedSettings!['explanation'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _recommendedSettings!['explanation'] as String,
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: _getThemeColors().onSurfaceVariant),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ignore', style: TextStyle(color: _getThemeColors().primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyRecommendedSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _getThemeColors().primary),
            child: Text('Apply Settings', style: TextStyle(color: _getThemeColors().onPrimary)),
          ),
        ],
      ),
    );
  }
  
  // Build a setting item for the dialog
  Widget _buildSettingItem(String label, String value, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
          Text(value, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
  
  // Apply recommended settings
  void _applyRecommendedSettings() {
    if (_recommendedSettings == null) return;
    
    setState(() {
      _fontSize = _recommendedSettings!['fontSize'] as double? ?? _fontSize;
      _lineSpacing = _recommendedSettings!['lineSpacing'] as double? ?? _lineSpacing;
      _fontType = _recommendedSettings!['fontType'] as String? ?? _fontType;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Applied AI-recommended reading settings')),
    );
  }

  // New minimalist settings panel
  Widget _buildSettingsPanel(ThemeData theme) {
    final colors = _getThemeColors();

    return Material(
      color: colors.surface,
      elevation: 4.0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reading Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSettingsPanel,
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Font size
            _buildSettingSlider(
              theme,
              'Font Size',
              Icons.format_size,
              _fontSize,
              (value) => _updateFontSize(value),
              min: 12,
              max: 24,
              divisions: 12,
            ),
            
            // Line spacing
            _buildSettingSlider(
              theme,
              'Line Spacing',
              Icons.format_line_spacing,
              _lineSpacing,
              (value) => _updateLineSpacing(value),
              min: 1.0,
              max: 2.5,
              divisions: 15,
            ),
            
            // Font type
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font Type',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFontOption(
                        theme,
                        'Serif',
                        _fontType == 'Serif',
                        () => _updateFontType('Serif'),
                      ),
                      const SizedBox(width: 16),
                      _buildFontOption(
                        theme,
                        'Sans Serif',
                        _fontType == 'Sans Serif',
                        () => _updateFontType('Sans Serif'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Theme mode
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildThemeOption(
                        theme,
                        'Light',
                        Icons.light_mode,
                        ref.watch(settingsProvider).themeMode == AppThemeMode.light,
                        () => ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.light),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        theme,
                        'Dark',
                        Icons.dark_mode,
                        ref.watch(settingsProvider).themeMode == AppThemeMode.dark,
                        () => ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        theme,
                        'Sepia',
                        Icons.color_lens,
                        ref.watch(settingsProvider).themeMode == AppThemeMode.sepia,
                        () => ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.sepia),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New minimalist chapters panel
  Widget _buildChaptersPanel(ThemeData theme, ReadingState readingState) {
    List<PlaceholderChapter> allChapters = _extractChapters(readingState);
    List<PlaceholderChapter> displayedChapters = allChapters;

    if (_chapterSearchQuery.isNotEmpty) {
      displayedChapters = allChapters.where((chapter) {
        return chapter.title.toLowerCase().contains(_chapterSearchQuery.toLowerCase());
      }).toList();
    }
    
    final colors = _getThemeColors();
    
    return Material(
      color: colors.surface,
      elevation: 4.0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table of Contents',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleLibraryPanel,
                  ),
                ],
              ),
            ),
            
            // Search box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search chapters...',
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha((0.5 * 255).round())),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha((0.5 * 255).round())),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                onChanged: (value) {
                  setState(() {
                    _chapterSearchQuery = value;
                  });
                },
              ),
            ),
            
            const Divider(),
            
            // Chapter list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                itemCount: displayedChapters.length, // Use displayedChapters
                itemBuilder: (context, index) {
                  final chapter = displayedChapters[index]; // Use displayedChapters
                  // To determine if it's the current chapter, we need to find its original index in allChapters
                  // if a search is active, because 'index' will be for the filtered list.
                  // However, navigating with 'index' (the filtered list index) to `navigateToLogicalChapter` 
                  // might be problematic if that method expects an index from the *original* full list of logical chapters.
                  // For now, let's assume navigateToChapter is smart enough or we adjust it later.
                  // A simpler approach for `isCurrentChapter` when searching is to compare chapter.id or a unique property if available
                  // and if the navigation is based on ID. If navigation is index-based on the original list, this needs care.

                  // Let's assume currentChapter in state is the index from the *original* list of logical chapters.
                  // We need to find the original index of the currently displayed chapter to compare.
                  // This is tricky if titles are not unique. A robust way is to navigate with chapter.id if possible.
                  // For now, we will highlight based on the index in the filtered list if it matches the state's currentChapter.
                  // This might not be perfectly accurate if the list is filtered.
                  // A better way for `isCurrentChapter` would be to compare chapter.id with a hypothetical state.currentChapterId.

                  // For now, let's simplify isCurrentChapter based on the current logical index in readingState
                  // and if the displayed chapter *is* that logical chapter.
                  // PlaceholderChapter.pageStart is 1-based logical chapter number.
                  final isCurrentChapter = (chapter.pageStart -1) == readingState.currentChapter;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isCurrentChapter
                          ? theme.colorScheme.primary.withAlpha((0.15 * 255).round())
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentChapter
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withAlpha((0.3 * 255).round()),
                        width: isCurrentChapter ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      leading: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrentChapter
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: isCurrentChapter
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        chapter.title,
                        style: TextStyle(
                          fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentChapter
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: chapter.subtitle != null
                          ? Text(
                              chapter.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      onTap: () {
                        // FIXED: Use direct chapter ID navigation instead of going through logical index
                        _log.info('Chapter panel navigation: ${chapter.title} -> direct navigation to ID: ${chapter.id}');
                        
                        // Navigate directly using the chapter ID to avoid mapping issues
                        ref.read(readingNotifierProvider(widget.bookId).notifier)
                          .goToChapter(chapter.id);
                        
                        _toggleLibraryPanel();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for the new UI components
  Widget _buildSettingSlider(
    ThemeData theme,
    String title,
    IconData icon,
    double value,
    ValueChanged<double> onChanged, {
    required double min,
    required double max,
    required int divisions,
  }) {
    final colors = _getThemeColors();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(color: colors.onSurface),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: colors.primary,
            inactiveColor: colors.primary.withAlpha((0.3 * 255).round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toStringAsFixed(min.truncateToDouble() == min ? 0 : 1),
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              Text(
                max.toStringAsFixed(max.truncateToDouble() == max ? 0 : 1),
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontOption(
    ThemeData theme,
    String fontType,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colors = _getThemeColors();
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer
                : colors.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withAlpha((0.3 * 255).round()),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            fontType,
            style: TextStyle(
              fontFamily: fontType == 'Serif' ? 'serif' : 'sans-serif',
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    ThemeData theme,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colors = _getThemeColors();
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer
                : colors.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : colors.outline.withAlpha((0.3 * 255).round()),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple TranslationOverlay widget
class TranslationOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final String? text;

  const TranslationOverlay({
    super.key,
    required this.onClose,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withAlpha((0.5 * 255).round()),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.2 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Translation',
                        style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurface),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.onSurface),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  Divider(color: colors.outline.withAlpha((0.5 * 255).round())),
                  const SizedBox(height: 16),
                  Text(
                    text ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}