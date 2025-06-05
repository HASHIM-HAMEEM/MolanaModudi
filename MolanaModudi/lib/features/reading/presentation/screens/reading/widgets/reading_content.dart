import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../../providers/reading_state.dart';
import '../../../providers/reading_provider.dart';
import '../../../providers/reading_settings_provider.dart';
import '../../../../data/services/simple_bookmark_service.dart';
import '../../../../data/services/ai_word_meaning_service.dart';
import 'page_flip_widget.dart';
import 'focus_mode_overlay.dart';

// Provider for SimpleBookmarkService
final simpleBookmarkServiceProvider = Provider((ref) => SimpleBookmarkService());

// Provider for AI Word Meaning Service
final aiWordMeaningServiceProvider = Provider((ref) => AiWordMeaningService());

/// Content widget for reading screen - extracted from monolithic ReadingScreen
class ReadingContent extends ConsumerStatefulWidget {
  final String bookId;
  final ReadingState readingState;
  final void Function(void Function(String)) onNavigateToHeadingCallbackSet;

  const ReadingContent({
    super.key,
    required this.bookId,
    required this.readingState,
    required this.onNavigateToHeadingCallbackSet,
  });

  @override
  ConsumerState<ReadingContent> createState() => _ReadingContentState();
}

class _ReadingContentState extends ConsumerState<ReadingContent>
    with TickerProviderStateMixin {
  
  final _log = Logger('ReadingContent');
  late PageController _pageController;
  late Map<String, ScrollController> _chapterScrollControllers;
  late Map<String, GlobalKey> _headingKeys;
  String? _pendingHeadingNavigation;
  bool _isUpdatingProgrammatically = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize page controller with bounds checking
    final maxChapters = widget.readingState.mainChapterKeys?.length ?? 1;
    final initialPage = widget.readingState.currentChapter.clamp(0, maxChapters - 1);
    
    _pageController = PageController(
      initialPage: initialPage,
      keepPage: true, // Keep pages in memory to reduce rebuilds
    );
    
    // Initialize scroll controllers for each chapter
    _chapterScrollControllers = {};
    _headingKeys = {};
    
    // Set up navigation callback
    widget.onNavigateToHeadingCallbackSet(_navigateToHeading);
    
    // Initialize controllers and keys
    _initializeControllers();
    
    _log.info('ReadingContent initialized with page $initialPage of $maxChapters chapters');
  }

  void _initializeControllers() {
    // Clear existing controllers first
    for (var controller in _chapterScrollControllers.values) {
      controller.dispose();
    }
    _chapterScrollControllers.clear();
    _headingKeys.clear();
    
    // Initialize scroll controllers for chapters
    final mainChapterKeys = widget.readingState.mainChapterKeys ?? [];
    for (String chapterKey in mainChapterKeys) {
      if (!_chapterScrollControllers.containsKey(chapterKey)) {
        _chapterScrollControllers[chapterKey] = ScrollController();
      }
    }
    
    // Initialize heading keys for navigation with unique identifiers
    final allHeadings = widget.readingState.headings ?? [];
    for (var heading in allHeadings) {
      final headingId = heading.firestoreDocId.isNotEmpty 
        ? heading.firestoreDocId 
        : heading.id?.toString() ?? '';
      final chapterId = heading.chapterId?.toString() ?? '';
      final uniqueKey = '${chapterId}_$headingId';
      if (headingId.isNotEmpty && !_headingKeys.containsKey(uniqueKey)) {
        _headingKeys[uniqueKey] = GlobalKey();
      }
    }
    
    _log.info('Initialized ${_chapterScrollControllers.length} scroll controllers and ${_headingKeys.length} heading keys');
  }

  @override
  void didUpdateWidget(ReadingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Re-initialize controllers if structure changed
    if (widget.readingState.headings != oldWidget.readingState.headings ||
        widget.readingState.mainChapterKeys != oldWidget.readingState.mainChapterKeys) {
      _log.info('Content structure changed, re-initializing controllers');
      _initializeControllers();
    }
    
    // Synchronize PageView when current chapter changes externally
    if (widget.readingState.currentChapter != oldWidget.readingState.currentChapter) {
      final newPage = widget.readingState.currentChapter;
      if (_pageController.hasClients && (_pageController.page?.round() ?? -1) != newPage) {
        _log.fine('Synchronizing PageView to new chapter: $newPage');
        _isUpdatingProgrammatically = true;
        _pageController.jumpToPage(newPage);
        // Reset flag after a brief delay to ensure onPageChanged has processed
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _isUpdatingProgrammatically = false;
          }
        });
      }
    }
    
    // Handle pending heading navigation
    if (_pendingHeadingNavigation != null) {
      _log.info('Processing pending heading navigation: $_pendingHeadingNavigation');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _executeHeadingNavigation(_pendingHeadingNavigation!);
          _pendingHeadingNavigation = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _chapterScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Navigate to a specific heading by ID
  void _navigateToHeading(String headingId) {
    _log.info('Navigate to heading called with ID: $headingId');
    
    // First, find the heading and its chapter
    final allHeadings = widget.readingState.headings ?? [];
    final heading = allHeadings.where((h) => 
      h.firestoreDocId == headingId || h.id?.toString() == headingId
    ).firstOrNull;
    
    if (heading?.chapterId == null) {
      _log.warning('Could not find heading with ID: $headingId');
      return;
    }
    
    final chapterKey = heading!.chapterId.toString();
    final mainChapterKeys = widget.readingState.mainChapterKeys ?? [];
    final chapterIndex = mainChapterKeys.indexOf(chapterKey);
    
    _log.info('Heading $headingId belongs to chapter $chapterKey (index $chapterIndex)');
    
    // If we need to navigate to a different chapter first
    if (chapterIndex >= 0 && chapterIndex != widget.readingState.currentChapter) {
      _log.info('Need to change chapter first: ${widget.readingState.currentChapter} -> $chapterIndex');
      final chapterIdForNavigation = mainChapterKeys[chapterIndex];
      
      // Mark as programmatic to prevent duplicate navigation
      _isUpdatingProgrammatically = true;
      ref.read(readingNotifierProvider(widget.bookId).notifier)
         .goToChapter(chapterIdForNavigation);
      
      // Store for after chapter change
      _pendingHeadingNavigation = headingId;
      return;
    }
    
    // We're on the right chapter, try to scroll immediately
    _executeHeadingNavigation(headingId);
  }

  /// Execute the actual heading navigation - simplified with retries
  void _executeHeadingNavigation(String headingId, {int retryCount = 0}) {
    _log.info('Executing heading navigation to: $headingId (attempt ${retryCount + 1})');
    
    try {
      final globalKey = _headingKeys[headingId];
      if (globalKey?.currentContext == null) {
        if (retryCount < 5) { // Reduce retry attempts for faster response
          _log.info('Global key not ready for $headingId, retrying in 100ms');
          Future.delayed(const Duration(milliseconds: 100), () { // Shorter delay
            if (mounted) {
              _executeHeadingNavigation(headingId, retryCount: retryCount + 1);
            }
          });
          return;
        } else {
          _log.warning('Failed to find global key for heading $headingId after 5 attempts');
          return;
        }
      }
      
      // Find the chapter for this heading
      final allHeadings = widget.readingState.headings ?? [];
      final heading = allHeadings.where((h) => 
        h.firestoreDocId == headingId || h.id?.toString() == headingId
      ).firstOrNull;
      
      if (heading?.chapterId == null) {
        _log.warning('Could not find heading with ID: $headingId');
        return;
      }
      
      final chapterKey = heading!.chapterId.toString();
      final scrollController = _chapterScrollControllers[chapterKey];
      
      if (scrollController == null) {
        _log.warning('No scroll controller for chapter $chapterKey');
        return;
      }
      
      // Scroll to the heading
      _scrollToHeading(scrollController, globalKey!, headingId);
      
    } catch (e) {
      _log.severe('Error executing heading navigation: $e');
    }
  }
  
  /// Helper method to scroll to a specific heading
  void _scrollToHeading(ScrollController scrollController, GlobalKey globalKey, String headingId) {
    try {
      if (!scrollController.hasClients) {
        _log.warning('ScrollController has no clients for heading: $headingId');
        return;
      }
      
      final context = globalKey.currentContext;
      if (context == null) {
        _log.warning('GlobalKey context is null for heading: $headingId');
        return;
      }
      
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        _log.warning('RenderBox not available for heading: $headingId');
        return;
      }
      
      // Get the position relative to the scroll view
      final RenderObject? scrollViewRenderObject = scrollController.position.context.storageContext.findRenderObject();
      if (scrollViewRenderObject is RenderBox) {
        final localPosition = scrollViewRenderObject.globalToLocal(renderBox.localToGlobal(Offset.zero));
        final targetOffset = scrollController.offset + localPosition.dy - 80; // 80px padding from top
        
        final clampedOffset = targetOffset.clamp(0.0, scrollController.position.maxScrollExtent);
        
        _log.info('Scrolling to heading $headingId: current=${scrollController.offset}, target=$targetOffset, clamped=$clampedOffset');
        
        scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 150), // Faster scroll for better UX
          curve: Curves.easeOut,
        );
        
        // Haptic feedback
        HapticFeedback.lightImpact();
      } else {
        _log.warning('Could not find scroll view render object for heading: $headingId');
      }
    } catch (e) {
      _log.warning('Error scrolling to heading $headingId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainChapterKeys = widget.readingState.mainChapterKeys ?? [];
    final readingSettings = ref.watch(readingSettingsProvider);
    
    if (mainChapterKeys.isEmpty) {
      return const Center(child: Text('No content available'));
    }

    // Wrap PageView with PageFlipWidget for enhanced animations
    return PageFlipWidget(
      controller: _pageController,
      enabled: readingSettings.pageFlipAnimationEnabled,
      onPageChanged: (index) {
        // Prevent duplicate navigation when PageView is being updated programmatically
        if (_isUpdatingProgrammatically) {
          _log.fine('Skipping onPageChanged navigation - programmatic update in progress');
          return;
        }
        
        final chapterId = mainChapterKeys[index];
        _log.fine('User swiped to chapter $index (ID: $chapterId)');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isUpdatingProgrammatically) {
            ref.read(readingNotifierProvider(widget.bookId).notifier)
               .goToChapter(chapterId);
          }
        });
      },
      itemCount: mainChapterKeys.length,
      itemBuilder: (context, index) {
        final chapterKey = mainChapterKeys[index];
        return _buildChapterContent(context, ref, chapterKey, index, readingSettings);
      },
    );
  }

  Widget _buildChapterContent(BuildContext context, WidgetRef ref, String chapterKey, int chapterIndex, ReadingSettingsState readingSettings) {
    // Get headings for this chapter
    final allHeadings = widget.readingState.headings ?? [];
    final chapterHeadings = allHeadings.where((heading) => 
      heading.chapterId?.toString() == chapterKey
    ).toList();

    if (chapterHeadings.isEmpty) {
      return _buildEmptyChapterPage(chapterKey);
    }

    final scrollController = _chapterScrollControllers[chapterKey];
    final colors = Theme.of(context).colorScheme;

    final content = Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Chapter ${chapterIndex + 1}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Chapter headings
            ...chapterHeadings.map((heading) => _buildHeadingWidget(
              context, 
              ref, 
              heading, 
              chapterKey,
              readingSettings,
            )),
            
            // Bottom padding for last chapter
            const SizedBox(height: 80),
          ],
        ),
      ),
    );

    // Wrap with FocusModeOverlay if focus mode is enabled
    if (readingSettings.focusModeEnabled && scrollController != null) {
      return FocusModeOverlay(
        enabled: true,
        scrollController: scrollController,
        child: content,
      );
    }

    return content;
  }

  Widget _buildHeadingWidget(BuildContext context, WidgetRef ref, heading, String chapterKey, ReadingSettingsState readingSettings) {
    final colors = Theme.of(context).colorScheme;
    final headingId = heading.firestoreDocId.isNotEmpty 
      ? heading.firestoreDocId 
      : heading.id?.toString() ?? '';
    
    // Get reading state to determine language and RTL support
    final readingState = ref.watch(readingNotifierProvider(widget.bookId));
    final bookLanguage = readingState.book?.languageCode ?? 'en';
    final isRTL = bookLanguage == 'ur' || bookLanguage == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    
    // Use the unique global key for this heading
    final uniqueKey = '${chapterKey}_$headingId';
    final headingKey = _headingKeys[uniqueKey];
    
    return Directionality(
      textDirection: textDirection,
      child: GestureDetector(
        onTap: readingSettings.focusModeEnabled ? () {
          // Request focus on this section
          _requestFocusOnSection(headingKey);
        } : null,
      child: Container(
      key: headingKey,
        margin: const EdgeInsets.only(bottom: 32),
      child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
            // Heading title with improved RTL support and Airbnb-style design
          if (heading.title != null && heading.title!.isNotEmpty) ...[
            Container(
              width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.08),
                      colors.primary.withValues(alpha: 0.04),
                    ],
                    begin: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                    end: isRTL ? Alignment.centerLeft : Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: colors.primary.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Directionality(
                  textDirection: textDirection,
              child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                      // REVERSED: For RTL put bookmark on RIGHT (opposite)
                      if (!isRTL) _buildBookmarkButton(context, ref, heading, chapterKey),
                      
                      // Title text - REVERSED alignment
                  Expanded(
                    child: Text(
                      heading.title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                            fontSize: isRTL ? 22 : 20,
                            letterSpacing: isRTL ? 0 : 0.2,
                            fontFamily: isRTL ? 'NotoNastaliqUrdu' : null,
                            height: isRTL ? 1.4 : 1.2,
                          ),
                          textAlign: isRTL ? TextAlign.left : TextAlign.right, // REVERSED: RTL uses left align, LTR uses right align
                          textDirection: textDirection,
                    ),
                  ),
                      
                      // REVERSED: For LTR put bookmark on LEFT (opposite)
                      if (isRTL) _buildBookmarkButton(context, ref, heading, chapterKey),
                ],
                  ),
              ),
            ),
              const SizedBox(height: 20),
          ],
          
            // Heading content with proper RTL support and enhanced typography
          if (heading.content != null && heading.content!.isNotEmpty) ...[
            Container(
              width: double.infinity,
                padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.02),
                      blurRadius: 6,
                    offset: const Offset(0, 2),
                      spreadRadius: 0,
                  ),
                ],
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Directionality(
                  textDirection: textDirection,
              child: SelectableText(
                    heading.content!.join('\n\n'),
                    style: _buildTextStyle(context, ref, isRTL, colors),
                    textAlign: isRTL ? TextAlign.left : TextAlign.right, // REVERSED: RTL uses left align, LTR uses right align
                    textDirection: textDirection,
                    contextMenuBuilder: (context, editableTextState) {
                      // Disable system context menu to prevent the crash
                      return const SizedBox.shrink();
                    },
                    onSelectionChanged: (selection, cause) {
                      // Handle text selection without system context menu
                      if (selection.isValid && !selection.isCollapsed) {
                        final selectedText = selection.textInside(heading.content!.join('\n\n'));
                        if (selectedText.isNotEmpty) {
                          // Show custom context menu or handle selection
                          _showCustomTextMenu(context, selectedText);
                        }
                      }
                    },
                ),
              ),
            ),
          ],
        ],
          ),
        ),
      ),
    );
  }

  /// Request focus on a specific section (for focus mode)
  void _requestFocusOnSection(GlobalKey? sectionKey) {
    // Focus mode functionality simplified - no external control needed
    // The overlay automatically manages focus areas
  }

  Widget _buildBookmarkButton(BuildContext context, WidgetRef ref, heading, String chapterKey) {
    final bookmarkService = ref.watch(simpleBookmarkServiceProvider);
    
    return FutureBuilder<bool>(
      future: bookmarkService.isBookmarked(widget.bookId, chapterKey, heading.id?.toString() ?? ''),
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;
        final colors = Theme.of(context).colorScheme;
        
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isBookmarked 
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBookmarked 
                ? colors.primary.withValues(alpha: 0.3)
                : colors.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              if (isBookmarked)
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
              HapticFeedback.lightImpact();
              bookmarkService.toggleBookmark(
                bookId: widget.bookId,
                chapterId: chapterKey,
                  chapterTitle: 'Chapter $chapterKey',
                headingId: heading.id?.toString() ?? '',
                headingTitle: heading.title ?? 'Untitled',
              );
            },
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    key: ValueKey(isBookmarked),
                    color: isBookmarked ? colors.primary : colors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyChapterPage(String chapterKey) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No content available for this chapter',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Show custom text menu for selected text without system context menu
  void _showCustomTextMenu(BuildContext context, String selectedText) {
    final colors = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected Text',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Selected text preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
              ),
              child: Text(
                selectedText.length > 100 ? '${selectedText.substring(0, 100)}...' : selectedText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            ListTile(
              leading: Icon(Icons.copy, color: colors.primary),
              title: Text('Copy', style: TextStyle(color: colors.onSurface)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: selectedText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text copied to clipboard')),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.share, color: colors.primary),
              title: Text('Share', style: TextStyle(color: colors.onSurface)),
              onTap: () {
                Navigator.pop(context);
                // You can integrate with share_plus package here
                // Share.share(selectedText);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon')),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.auto_awesome, color: colors.primary),
              title: Text('AI Word Meaning', style: TextStyle(color: colors.onSurface)),
              subtitle: Text('Get meaning, translation & examples', 
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showWordMeaningBottomSheet(context, selectedText);
              },
            ),
            
            // Add bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Show AI-powered word meaning bottom sheet
  void _showWordMeaningBottomSheet(BuildContext context, String selectedText) {
    final colors = Theme.of(context).colorScheme;
    final wordMeaningService = ref.read(aiWordMeaningServiceProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Word Meaning',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: colors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: FutureBuilder<WordMeaningResult>(
                future: wordMeaningService.getWordMeaning(selectedText),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildAirbnbLoadingState(colors);
                  }
                  
                  if (snapshot.hasError || snapshot.data?.hasError == true) {
                    return _buildAirbnbErrorState(colors, snapshot.data?.errorMessage);
                  }
                  
                  final result = snapshot.data!;
                  return _buildAirbnbWordMeaningContent(context, result, colors);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirbnbLoadingState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: colors.primary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing text...',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI is processing the meaning and context',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirbnbErrorState(ColorScheme colors, String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to get meaning',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Please try again with a different word or phrase',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try Again'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirbnbWordMeaningContent(BuildContext context, WordMeaningResult result, ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.08),
                  colors.primary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Word text
                Text(
                  result.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Language and part of speech tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildAirbnbTag(result.language, colors.primary, colors),
                    if (result.partOfSpeech.isNotEmpty)
                      _buildAirbnbTag(result.partOfSpeech, colors.secondary, colors),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Primary meaning section
          _buildAirbnbSection(
            context,
            colors,
            'Primary Meaning',
            Icons.lightbulb_outline_rounded,
            result.primaryMeaning,
          ),
          
          // Secondary meaning section
          if (result.secondaryMeaning.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildAirbnbSection(
              context,
              colors,
              'Detailed Explanation',
              Icons.description_outlined,
              result.secondaryMeaning,
            ),
          ],
          
          // Examples section
          if (result.examples.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAirbnbSectionHeader(context, colors, 'Examples', Icons.format_quote_rounded),
            const SizedBox(height: 12),
            ...result.examples.asMap().entries.map((entry) => 
              _buildAirbnbExampleCard(context, colors, entry.value, entry.key + 1)),
          ],
          
          // Etymology section
          if (result.etymology.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAirbnbSection(
              context,
              colors,
              'Etymology',
              Icons.history_edu_rounded,
              result.etymology,
            ),
          ],
          
          // Related words section
          if (result.relatedWords.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAirbnbSectionHeader(context, colors, 'Related Words', Icons.link_rounded),
            const SizedBox(height: 12),
            _buildAirbnbRelatedWords(colors, result.relatedWords),
          ],
          
          // Bottom spacing for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildAirbnbTag(String text, Color color, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildAirbnbSection(BuildContext context, ColorScheme colors, 
      String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAirbnbSectionHeader(context, colors, title, icon),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              height: 1.6,
              fontSize: 16,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAirbnbSectionHeader(BuildContext context, ColorScheme colors, 
      String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildAirbnbExampleCard(BuildContext context, ColorScheme colors, String example, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              example,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                height: 1.5,
                fontSize: 15,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirbnbRelatedWords(ColorScheme colors, List<String> words) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: words.map((word) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          word,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      )).toList(),
    );
  }

  TextStyle _buildTextStyle(BuildContext context, WidgetRef ref, bool isRTL, ColorScheme colors) {
    // Use reading-specific settings instead of global app settings
    final readingSettings = ref.watch(readingSettingsProvider);
    
    // Determine appropriate font family based on language and reading settings
    String? effectiveFontFamily;
    if (isRTL && readingSettings.fontFamily.isCustomFont) {
      // Use selected reading font for RTL languages
      effectiveFontFamily = readingSettings.fontFamily.fontFamily;
    } else if (isRTL) {
      // Fallback to default RTL font if no custom font selected
      effectiveFontFamily = 'NotoNastaliqUrdu';
    } else {
      // For LTR languages, use selected reading font or default
      effectiveFontFamily = readingSettings.fontFamily.isCustomFont 
        ? readingSettings.fontFamily.fontFamily 
        : null;
    }
    
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      height: readingSettings.lineSpacing,
      letterSpacing: isRTL ? readingSettings.letterSpacing : readingSettings.letterSpacing,
      fontSize: readingSettings.fontSize.size,
      color: colors.onSurface,
      fontFamily: effectiveFontFamily,
      wordSpacing: readingSettings.wordSpacing,
      fontWeight: readingSettings.fontWeight,
    ) ?? TextStyle(
      height: readingSettings.lineSpacing,
      letterSpacing: isRTL ? readingSettings.letterSpacing : readingSettings.letterSpacing,
      fontSize: readingSettings.fontSize.size,
      color: colors.onSurface,
      fontFamily: effectiveFontFamily,
      wordSpacing: readingSettings.wordSpacing,
      fontWeight: readingSettings.fontWeight,
    );
  }
} 