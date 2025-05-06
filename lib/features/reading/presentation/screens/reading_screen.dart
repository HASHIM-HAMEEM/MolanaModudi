import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// No longer using EnhancedTheme for reading styles
import 'dart:async'; // Import for Completer
import 'dart:math';

import '../../../../core/providers/settings_provider.dart';
// Import widgets as they are created
import '../widgets/reading_settings_panel.dart';
import '../widgets/reading_library_panel.dart'; // Import Library Panel
// Import shared models
import '../models/reading_models.dart'; 
// Import GoRouter for navigation extensions
import 'package:go_router/go_router.dart'; 
// Import RouteNames for route constants
import '../../../../routes/route_names.dart';
// Import EpubView
import 'package:epub_view/epub_view.dart';
// Import reading provider and state
import '../providers/reading_provider.dart';
import '../providers/reading_state.dart';
// Import url_launcher
import 'package:url_launcher/url_launcher.dart';
// Import PDFView
import 'package:flutter_pdfview/flutter_pdfview.dart';
// Add import for dictionary popup widget
import '../widgets/vocabulary_assist_popup.dart';
// Add import for AI-related widgets
import '../widgets/ai_tools_panel.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

  // Keep track of PDF controller and pages
  Completer<PDFViewController> _pdfViewController = Completer<PDFViewController>();
  int? _pdfPages = 0;
  int? _pdfCurrentPage = 0;
  bool _pdfIsReady = false;
  String _pdfErrorMessage = '';

  // Add to the class variables in the _ReadingScreenState class
  bool _showAiToolsPanel = false;
  bool _showVocabularyPopup = false;
  String _selectedWord = '';
  String _wordDefinition = '';
  bool _isSpeaking = false;
  TextStyle? _ttsHighlightStyle;
  String? _translatedText;
  String _targetLanguage = 'English';
  Map<String, dynamic>? _recommendedSettings;
  Timer? _speechTimer;
  TextSelection? _selectedText;

  @override
  void initState() {
    super.initState();
    // Content loading is handled by ReadingNotifier, triggered by the provider watch
    // TODO: Load initial font size, line spacing, font type from settings provider if needed
    // Example:
    // final settings = ref.read(settingsProvider);
    // _fontSize = settings.fontSize;
    // _lineSpacing = settings.lineSpacing;
    // _fontType = settings.fontType;
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
      }
    });
    _log.info("Header/Footer visibility toggled: $_showHeaderFooter");
  }

  void _toggleSettingsPanel() {
    _log.info("[DEBUG] _toggleSettingsPanel called - current state: $_showSettingsPanel");
    setState(() {
      _showSettingsPanel = !_showSettingsPanel;
      // Ensure other panels are closed
      if (_showSettingsPanel) {
        _showLibraryPanel = false;
        _showHeaderFooter = true; // Keep header/footer visible when panel is open
      }
    });
    _log.info("[DEBUG] Settings Panel visibility after toggle: $_showSettingsPanel");
  }

  void _toggleLibraryPanel() {
    _log.info("[DEBUG] _toggleLibraryPanel called - current state: $_showLibraryPanel");
    setState(() {
      _showLibraryPanel = !_showLibraryPanel;
      // Ensure other panels are closed
      if (_showLibraryPanel) {
        _showSettingsPanel = false;
        _showHeaderFooter = true; // Keep header/footer visible when panel is open
      }
    });
    _log.info("[DEBUG] Library Panel visibility after toggle: $_showLibraryPanel");
  }

  // Add method to toggle AI tools panel
  void _toggleAiToolsPanel() {
    setState(() {
      _showAiToolsPanel = !_showAiToolsPanel;
      // Ensure other panels are closed
      if (_showAiToolsPanel) {
        _showSettingsPanel = false;
        _showLibraryPanel = false;
        _showHeaderFooter = true; // Keep header/footer visible when panel is open
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingState = ref.watch(readingNotifierProvider(widget.bookId));
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _showHeaderFooter 
        ? AppBar(
            backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Navigate to book detail page using the correct route
                context.go('/book-detail/${widget.bookId}');
                _log.info('Navigating back to book detail page');
              },
            ),
            title: Text(
              readingState.bookTitle ?? 'Reading',
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _toggleSettingsPanel,
                tooltip: 'Settings',
              ),
            ],
          )
        : null,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content area with improved gesture handling
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _log.info("Content tapped - toggling header/footer");
                setState(() {
                  _showHeaderFooter = !_showHeaderFooter;
                });
              },
              child: _buildReadingContent(readingState, context),
            ),

            // Settings panel with smooth animation
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _showSettingsPanel ? 0 : -size.width,
              top: 0,
              bottom: 0,
              width: size.width * 0.85,
              child: _buildSettingsPanel(theme),
            ),

            // Chapters panel with smooth animation
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _showLibraryPanel ? 0 : -size.width,
              top: 0,
              bottom: 0,
              width: size.width * 0.85,
              child: _buildChaptersPanel(theme, readingState),
            ),
            
            // Other panels remain unchanged
            if (_showAiToolsPanel)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: AiToolsPanel(
                  onClose: () {
                    setState(() {
                      _showAiToolsPanel = false;
                    });
                  },
                  bookId: widget.bookId,
                  bookState: readingState,
                ),
              ),

            if (_showVocabularyPopup)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: VocabularyAssistPopup(
                  word: _selectedWord,
                  definition: _wordDefinition,
                  onClose: _closeVocabularyPopup,
                ),
              ),

            if (_translatedText != null)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: TranslationOverlay(
                  onClose: _clearTranslation,
                  text: _translatedText,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _showHeaderFooter ? _buildBottomBar(context, readingState) : null,
      floatingActionButton: readingState.status == ReadingStatus.displayingText
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showAiToolsPanel = true;
                });
              },
              child: const Icon(Icons.smart_toy),
            )
          : null,
    );
  }

  // Redesigned bottom bar with improved navigation controls
  Widget _buildBottomBar(BuildContext context, ReadingState readingState) {
    final theme = Theme.of(context);
    
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous Page button (always visible for consistency, disabled when not applicable)
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded, 
              color: readingState.status == ReadingStatus.displayingPdf && 
                     _pdfCurrentPage != null && 
                     _pdfCurrentPage! > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            onPressed: () async {
              if (readingState.status == ReadingStatus.displayingPdf && 
                  _pdfViewController.isCompleted && 
                  _pdfCurrentPage != null && 
                  _pdfCurrentPage! > 0) {
                final controller = await _pdfViewController.future;
                controller.setPage(_pdfCurrentPage! - 1);
                _log.info("Navigated to previous page");
              }
            },
          ),
          
          // Chapters button with improved UI
          TextButton.icon(
            onPressed: () {
              _log.info("Chapters button tapped");
              _toggleLibraryPanel();
            },
            icon: Icon(Icons.menu_book, color: theme.colorScheme.primary),
            label: const Text('Chapters'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
                  
          // Pages indicator with improved design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              readingState.status == ReadingStatus.displayingPdf && _pdfPages != null
                  ? '${(_pdfCurrentPage ?? 0) + 1} / $_pdfPages'
                  : '${readingState.currentChapter + 1} / ${readingState.totalChapters}',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Next Page button (always visible for consistency, disabled when not applicable)
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded, 
              color: readingState.status == ReadingStatus.displayingPdf && 
                     _pdfCurrentPage != null && 
                     _pdfPages != null && 
                     _pdfCurrentPage! < _pdfPages! - 1
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            onPressed: () async {
              if (readingState.status == ReadingStatus.displayingPdf && 
                  _pdfViewController.isCompleted && 
                  _pdfCurrentPage != null && 
                  _pdfPages != null && 
                  _pdfCurrentPage! < _pdfPages! - 1) {
                final controller = await _pdfViewController.future;
                controller.setPage(_pdfCurrentPage! + 1);
                _log.info("Navigated to next page");
              }
            },
          ),
        ],
      ),
    );
  }

  // New minimalist settings panel
  Widget _buildSettingsPanel(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
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
    final chapters = _extractChapters(readingState);
    
    return Container(
      color: theme.colorScheme.surface,
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
                    'Chapters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleLibraryPanel,
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Chapter list
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final isCurrentChapter = index == readingState.currentChapter;
                  
                  return ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrentChapter
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrentChapter
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          color: isCurrentChapter
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentChapter
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: chapter.subtitle != null
                        ? Text(chapter.subtitle!,
                            style: theme.textTheme.bodySmall)
                        : null,
                    onTap: () {
                      // Enhanced navigation that works for all content types
                      _navigateToChapter(readingState, chapter, index);
                      _toggleLibraryPanel();
                    },
                    tileColor: isCurrentChapter
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
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
            activeColor: theme.colorScheme.primary,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toStringAsFixed(min.truncateToDouble() == min ? 0 : 1),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                max.toStringAsFixed(max.truncateToDouble() == max ? 0 : 1),
                style: theme.textTheme.bodySmall,
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
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
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
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
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Build Helper for Reading Content ---
  Widget _buildReadingContent(ReadingState state, BuildContext context) {
    final theme = Theme.of(context); // Get theme here
    final textStyle = TextStyle(
      fontFamily: _fontType == 'Serif' ? 'serif' : 'sans-serif',
      fontSize: _fontSize,
      height: _lineSpacing,
    );

    switch (state.status) {
      case ReadingStatus.initial:
      case ReadingStatus.loadingMetadata:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('Loading book details...',
                  style: theme.textTheme.titleMedium)
            ],
          )
        );
      case ReadingStatus.downloading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: state.downloadProgress > 0 ? state.downloadProgress : null,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Downloading book (${(state.downloadProgress * 100).toStringAsFixed(0)}%)...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        );
      case ReadingStatus.loadingContent:
         return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text('Preparing content...', style: theme.textTheme.titleMedium),
            ],
          ),
        );
      case ReadingStatus.displayingEpub:
        if (state.epubController == null) {
          return Center(child: Text('Error: EPUB controller not available.', style: theme.textTheme.titleMedium));
        }
        return EpubView(
          controller: state.epubController!,
          onExternalLinkPressed: (url) { /* Handle external links */ },
          builders: EpubViewBuilders<DefaultBuilderOptions>(
            options: DefaultBuilderOptions(
              textStyle: textStyle,
            ),
          ),
        );
      case ReadingStatus.displayingText:
        return _buildTextContent(context, state, textStyle);
      case ReadingStatus.displayingPdf:
        if (state.pdfPath == null) {
          return Center(child: Text('Error: PDF path not available.', style: theme.textTheme.titleMedium));
        }
        return Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: PDFView(
                filePath: state.pdfPath!,
                enableSwipe: true,
                swipeHorizontal: false, // Vertical scrolling (up/down)
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                defaultPage: _pdfCurrentPage ?? 0,
                fitPolicy: FitPolicy.WIDTH, // Keep WIDTH for better reading
                preventLinkNavigation: false,
                onRender: (pages) {
                  setState(() {
                    _pdfPages = pages;
                    _pdfIsReady = true;
                  });
                  _log.info('PDF Rendered: $pages pages');
                  // Update total pages in state for reading history
                  ref.read(readingNotifierProvider(widget.bookId).notifier).updatePdfPosition(_pdfCurrentPage ?? 0, pages ?? 0);
                },
                onError: (error) {
                  setState(() { _pdfErrorMessage = error.toString(); });
                  _log.severe('PDFView Error: $error');
                },
                onPageError: (page, error) {
                  setState(() { _pdfErrorMessage = 'Error on page $page: $error'; });
                  _log.severe('PDFView Page Error: $page: $error');
                },
                onViewCreated: (PDFViewController pdfViewController) {
                  if (!_pdfViewController.isCompleted) {
                    _pdfViewController.complete(pdfViewController);
                  }
                },
                onLinkHandler: (String? uri) {
                  _log.info('PDF link tapped: $uri');
                  // Handle links if needed (e.g., using url_launcher)
                },
                onPageChanged: (int? page, int? total) {
                  setState(() {
                    _pdfCurrentPage = page;
                  });
                  _log.fine('PDF Page Changed: ${page ?? '?'}/${total ?? '?'}');
                  // Update current page in state for reading history
                  if (page != null && total != null) {
                    ref.read(readingNotifierProvider(widget.bookId).notifier).updatePdfPosition(page, total);
                  }
                },
              ),
            ),
            
            // Show loading indicator or error message
            _pdfErrorMessage.isNotEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: theme.colorScheme.error),
                          const SizedBox(height: 8),
                          Text(
                            'Error loading PDF: $_pdfErrorMessage',
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : !_pdfIsReady
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: theme.colorScheme.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Preparing document...',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : Container(),
          ],
        );
      case ReadingStatus.error:
        // Enhanced Error Display with back navigation
        String errorMessage = state.errorMessage ?? 'An unknown error occurred.';
        String detailedMessage = 'Could not load this book.'; // Default

        // Provide more specific user-facing messages based on known error strings
        if (errorMessage.contains('No supported file format')) {
          detailedMessage = 'This book isn\'t available in a readable format (EPUB, Text, PDF) that the app currently supports.';
        } else if (errorMessage.contains('PDF format is available but not supported')) {
          detailedMessage = 'This book is available as a PDF, but PDF reading is not supported yet.';
        } else if (errorMessage.contains('Unsupported format: DjVu')) {
          detailedMessage = 'This book is in DjVu format, which is not supported yet.';
        } else if (errorMessage.contains('Failed to decompress')) {
          detailedMessage = 'There was a problem processing the downloaded file.';
        } else if (errorMessage.contains('Failed to read text file content')) {
           detailedMessage = 'Could not read the downloaded text file.';
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 20),
                Text(
                  'Failed to load content',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  detailedMessage, // Show the user-friendly message
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(readingNotifierProvider(widget.bookId).notifier).reload();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate back to book detail page
                    context.go('/book-detail/${widget.bookId}');
                  },
                  child: const Text('Go Back'),
                  style: TextButton.styleFrom(
                     foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  // --- Build Helper Methods ---

  // Extract chapters from EPUB controller
  List<PlaceholderChapter> _extractChapters(ReadingState state) {
    List<PlaceholderChapter> chapters = [];
    
    // First check if we have AI-extracted chapters
    if (state.aiExtractedChapters != null && state.aiExtractedChapters!.isNotEmpty) {
      _log.info('Using AI-extracted chapters: ${state.aiExtractedChapters!.length}');
      
      chapters = state.aiExtractedChapters!.asMap().entries.map((entry) {
        final chapter = entry.value;
        return PlaceholderChapter(
          id: (entry.key).toString(),
          title: chapter['title'] ?? 'Chapter ${entry.key + 1}',
          pageStart: chapter['pageStart'] ?? (entry.key + 1),
          subtitle: chapter['subtitle'],
        );
      }).toList();
      
      return chapters;
    }
    
    // Otherwise fallback to existing extraction logic
    if (state.status == ReadingStatus.displayingEpub && state.epubController != null) {
      // Get chapters from state instead
      final totalChapters = state.totalChapters;
      
      // Create placeholder chapters based on total count
      for (int i = 0; i < totalChapters; i++) {
        chapters.add(PlaceholderChapter(
          id: i.toString(),
          title: 'Chapter ${i + 1}',
          pageStart: i + 1,
        ));
      }
    } else if (state.status == ReadingStatus.displayingText) {
      // For text files, create simple chapter divisions
      chapters = [
        const PlaceholderChapter(id: '1', title: 'Beginning', pageStart: 1),
        const PlaceholderChapter(id: '2', title: 'Middle', pageStart: 2),
        const PlaceholderChapter(id: '3', title: 'End', pageStart: 3),
      ];
    } else if (state.status == ReadingStatus.displayingPdf) {
      // For PDFs, create better chapter markers
      final totalPages = _pdfPages ?? state.totalChapters;
      
      if (totalPages > 0) {
        _log.info('Creating improved chapter markers for PDF with $totalPages pages');
        
        // Create chapters for first few pages - likely to contain table of contents
        chapters.add(PlaceholderChapter(
          id: '0',
          title: 'Cover Page',
          pageStart: 1,
        ));
        
        if (totalPages > 2) {
          chapters.add(PlaceholderChapter(
            id: '1',
            title: 'Table of Contents',
            pageStart: 2,
          ));
        }
        
        // Add regularly spaced chapter markers throughout the book
        // Adjust the approach based on book length
        if (totalPages <= 10) {
          // For short books, create a marker for each page
          for (int i = 2; i < totalPages; i++) {
            chapters.add(PlaceholderChapter(
              id: i.toString(),
              title: 'Page ${i + 1}',
              pageStart: i + 1,
            ));
          }
        } else if (totalPages <= 30) {
          // For medium-length books, create more granular chapter markers
          final numberOfMarkers = 10;
          final interval = (totalPages - 2) ~/ numberOfMarkers;
          
          for (int i = 0; i < numberOfMarkers; i++) {
            final pageNum = 2 + (i * interval);
            chapters.add(PlaceholderChapter(
              id: pageNum.toString(),
              title: 'Section ${i + 1}',
              pageStart: pageNum + 1,
              subtitle: 'Page ${pageNum + 1}',
            ));
          }
        } else {
          // For longer books, create approximately 15-20 chapter markers
          final numberOfMarkers = min(20, totalPages ~/ 15);
          final interval = (totalPages - 2) ~/ numberOfMarkers;
          
          for (int i = 0; i < numberOfMarkers; i++) {
            final pageNum = 2 + (i * interval);
            chapters.add(PlaceholderChapter(
              id: pageNum.toString(),
              title: 'Chapter ${i + 1}',
              pageStart: pageNum + 1,
              subtitle: 'Page ${pageNum + 1}',
            ));
          }
        }
        
        // Add the last page if not already included
        if (totalPages > 2 && (chapters.isEmpty || chapters.last.pageStart != totalPages)) {
          chapters.add(PlaceholderChapter(
            id: (totalPages - 1).toString(),
            title: 'Last Page',
            pageStart: totalPages,
          ));
        }
        
        _log.info('Created ${chapters.length} chapter markers for PDF');
      }
    }
    
    return chapters;
  }
  
  // Navigate to a specific chapter
  void _navigateToChapter(ReadingState state, PlaceholderChapter chapter, int index) {
    _log.info('Navigating to chapter: ${chapter.title} (ID: ${chapter.id}, Page: ${chapter.pageStart})');
    
    switch (state.status) {
      case ReadingStatus.displayingPdf:
        // For PDF, navigate to the specific page
        if (_pdfViewController.isCompleted) {
          _navigateToPdfPage(chapter.pageStart - 1); // Convert to 0-based index
          _log.info('PDF: Navigating to page ${chapter.pageStart}');
        } else {
          _log.warning('PDF controller not ready for navigation');
        }
        break;
        
      case ReadingStatus.displayingEpub:
        // For EPUB, use the chapter index-based navigation
        ref.read(readingNotifierProvider(widget.bookId).notifier).navigateToChapter(index);
        _log.info('EPUB: Navigating to chapter index $index');
        break;
        
      case ReadingStatus.displayingText:
        // For plain text, calculate position based on chapter
        final position = index / (state.totalChapters > 0 ? state.totalChapters : 1);
        ref.read(readingNotifierProvider(widget.bookId).notifier).updateTextPosition(position);
        _log.info('Text: Setting position to $position for chapter $index');
        break;
        
      default:
        _log.warning('Cannot navigate: invalid reading state ${state.status}');
    }
  }

  // Add helper method for PDF page navigation
  Future<void> _navigateToPdfPage(int pageIndex) async {
    try {
      if (!_pdfViewController.isCompleted) {
        _log.warning('PDF controller not initialized');
        return;
      }
      
      final controller = await _pdfViewController.future;
      if (_pdfPages == null || pageIndex < 0 || (_pdfPages != null && pageIndex >= _pdfPages!)) {
        _log.warning('Invalid page index: $pageIndex (total pages: $_pdfPages)');
        return;
      }
      
      await controller.setPage(pageIndex);
      setState(() {
        _pdfCurrentPage = pageIndex;
      });
      
      // Update position in provider for tracking
      if (_pdfPages != null) {
        ref.read(readingNotifierProvider(widget.bookId).notifier)
           .updatePdfPosition(pageIndex, _pdfPages!);
      }
      
      _log.info('Successfully navigated to PDF page ${pageIndex + 1}');
    } catch (e) {
      _log.severe('Error navigating to PDF page: $e');
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

  void _showPageJumpDialog(BuildContext context) {
    final textController = TextEditingController();
    final totalPages = _pdfPages ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Page Number (1-$totalPages)',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final pageNum = int.parse(textController.text);
                if (pageNum >= 1 && pageNum <= totalPages) {
                  if (_pdfViewController.isCompleted) {
                    final controller = await _pdfViewController.future;
                    controller.setPage(pageNum - 1); // Convert to 0-based index
                    Navigator.pop(context);
                  }
                }
              } catch (e) {
                // Handle parsing error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid page number')),
                );
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  // Add method for fetching AI-extracted chapters
  Future<void> _loadAiExtractedChapters(ReadingState state) async {
    if (state.status == ReadingStatus.displayingText || state.status == ReadingStatus.displayingPdf) {
      try {
        String textToAnalyze = '';
        bool isToc = false; // Flag to indicate if it's likely a TOC
        if (state.status == ReadingStatus.displayingText && state.textContent != null) {
          textToAnalyze = state.textContent!;
        } else if (state.status == ReadingStatus.displayingPdf) {
          // Use title/ID as context, check if it seems like TOC
          textToAnalyze = state.bookTitle ?? widget.bookId;
          if (state.currentChapter < 5) { // Heuristic: first few pages might be TOC
            isToc = true;
          }
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
      for (final wordData in difficultWords) {
        if (wordData['word']?.toLowerCase() == cleanWord) {
          _showWordDefinition(wordData['word'], wordData['definition']);
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
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: state.textScrollPosition * (MediaQuery.of(context).size.height * 10),
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
    
    String textContent = state.textContent ?? 'No text content available.';
    
    // Handle TTS highlighting if available
    if (state.isSpeaking && state.speechMarkers != null && state.speechMarkers!.isNotEmpty) {
      // Use RichText with TextSpans for highlighting
      return SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: GestureDetector(
          onLongPress: () => _showTextSelectionMenu(context),
          child: state.highlightedTextPosition != null ? 
            RichText(
              text: TextSpan(
                style: textStyle,
                children: _buildHighlightedTextSpans(
                  textContent, 
                  state.highlightedTextPosition!, 
                  textStyle, 
                  _ttsHighlightStyle!
                ),
              ),
            ) : 
            SelectableText(
              textContent,
              style: textStyle,
              onSelectionChanged: _handleSelectionChanged,
            ),
        ),
      );
    }
    
    // Regular selectable text
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SelectableText(
        textContent,
        style: textStyle,
        onSelectionChanged: _handleSelectionChanged,
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
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('Translate'),
            onTap: () {
              Navigator.pop(context);
              _translateSelectedText(selectedText);
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Speak'),
            onTap: () {
              Navigator.pop(context);
              _speakSelectedText(selectedText);
            },
          ),
          if (readingState.difficultWords == null || readingState.difficultWords!.isEmpty)
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('Analyze Vocabulary'),
              onTap: () {
                Navigator.pop(context);
                _analyzeDifficultWords(readingState);
              },
            ),
          ListTile(
            leading: const Icon(Icons.bookmark_add),
            title: const Text('Add to Bookmarks'),
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
      setState(() {
        _translatedText = translatedData?['translated'] as String? ?? 'Translation error';
      });

    } catch (e) {
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
    if (state.status == ReadingStatus.displayingText || state.status == ReadingStatus.displayingEpub) {
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
          setState(() {
            _recommendedSettings = settings;
          });
          
          // Offer to apply settings automatically if available
          if (_recommendedSettings != null && _recommendedSettings!.isNotEmpty) {
             _showRecommendedSettingsDialog(context);
          }
        }
      } catch (e) {
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
        title: const Text('AI-Recommended Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Based on this book\'s content, AI recommends:'),
            const SizedBox(height: 12),
            _buildSettingItem('Font Size', '${_recommendedSettings!['fontSize']}'),
            _buildSettingItem('Font Type', _recommendedSettings!['fontType'] as String),
            _buildSettingItem('Line Spacing', '${_recommendedSettings!['lineSpacing']}'),
            if (_recommendedSettings!['explanation'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _recommendedSettings!['explanation'] as String,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ignore'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyRecommendedSettings();
            },
            child: const Text('Apply Settings'),
          ),
        ],
      ),
    );
  }
  
  // Build a setting item for the dialog
  Widget _buildSettingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
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
}

// Simple TranslationOverlay widget
class TranslationOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final String? text;

  const TranslationOverlay({
    Key? key,
    required this.onClose,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    text ?? '',
                    style: theme.textTheme.bodyLarge,
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
