import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../providers/reading_state.dart';
import '../providers/reading_performance_provider.dart';

/// Highly optimized reading content widget with virtual scrolling and minimal rebuilds
class OptimizedReadingContent extends ConsumerStatefulWidget {
  final String bookId;
  final ReadingState readingState;

  const OptimizedReadingContent({
    super.key,
    required this.bookId,
    required this.readingState,
  });

  @override
  ConsumerState<OptimizedReadingContent> createState() => _OptimizedReadingContentState();
}

class _OptimizedReadingContentState extends ConsumerState<OptimizedReadingContent>
    with AutomaticKeepAliveClientMixin {
  final _log = Logger('OptimizedReadingContent');
  final PageController _pageController = PageController();
  final Map<int, Widget> _pageCache = {};
  
  // Performance metrics
  late final Stopwatch _renderStopwatch;
  int _totalRebuildCount = 0;
  int _visiblePageIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _renderStopwatch = Stopwatch()..start();
    _pageController.addListener(_onPageChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderStopwatch.stop();
      _log.info('Initial render completed in: ${_renderStopwatch.elapsedMilliseconds}ms');
    });
  }

  @override
  void didUpdateWidget(covariant OptimizedReadingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync page controller when currentChapter changes externally
    if (widget.readingState.currentChapter != oldWidget.readingState.currentChapter) {
      final newPage = widget.readingState.currentChapter;
      if (_pageController.hasClients && (_pageController.page?.round() ?? -1) != newPage) {
        _log.fine('Synchronizing PageView to new chapter: $newPage');
        _pageController.jumpToPage(newPage);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.hasClients) {
      final newPageIndex = _pageController.page?.round() ?? 0;
      if (newPageIndex != _visiblePageIndex) {
        _visiblePageIndex = newPageIndex;
        _log.fine('Page changed to: $_visiblePageIndex');
        
        // Preload adjacent pages for smooth navigation
        _preloadAdjacentPages(newPageIndex);
      }
    }
  }

  void _preloadAdjacentPages(int currentIndex) {
    final totalPages = widget.readingState.mainChapterKeys?.length ?? 0;
    
    // Preload next page
    if (currentIndex + 1 < totalPages && !_pageCache.containsKey(currentIndex + 1)) {
      _buildPageWidget(currentIndex + 1, preload: true);
    }
    
    // Preload previous page
    if (currentIndex - 1 >= 0 && !_pageCache.containsKey(currentIndex - 1)) {
      _buildPageWidget(currentIndex - 1, preload: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _totalRebuildCount++;
    
    if (_totalRebuildCount > 1) {
      _log.fine('Rebuild #$_totalRebuildCount');
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (widget.readingState.status == ReadingStatus.loading) {
      return _buildOptimizedLoadingState(colors);
    }

    if (widget.readingState.status == ReadingStatus.error) {
      return _buildOptimizedErrorState(colors, widget.readingState.errorMessage ?? 'Unknown error');
    }

    final mainChapterKeys = widget.readingState.mainChapterKeys ?? [];
    if (mainChapterKeys.isEmpty) {
      return _buildOptimizedEmptyState(colors);
    }

    return _VirtualPageView(
      controller: _pageController,
      itemCount: mainChapterKeys.length,
      itemBuilder: (context, pageIndex) => _buildPageWidget(pageIndex),
      cacheExtent: 2, // Cache 2 pages on each side for smooth scrolling
      onPageChanged: (index) {
        // Update reading provider with optimized navigation
        ref.read(readingPerformanceProvider(widget.bookId).notifier)
           .navigateToChapterOptimized(index);
      },
    );
  }

  Widget _buildPageWidget(int pageIndex, {bool preload = false}) {
    // Use cached page if available
    if (_pageCache.containsKey(pageIndex) && !preload) {
      return _pageCache[pageIndex]!;
    }

    final mainChapterKeys = widget.readingState.mainChapterKeys!;
    if (pageIndex >= mainChapterKeys.length) return const SizedBox.shrink();

    final chapterKey = mainChapterKeys[pageIndex];
    final chapterWidget = _OptimizedChapterPage(
      bookId: widget.bookId,
      chapterKey: chapterKey.toString(),
      chapterIndex: pageIndex,
      readingState: widget.readingState,
      isPreload: preload,
    );

    // Cache the widget for future use
    if (!preload) {
      _pageCache[pageIndex] = chapterWidget;
      
      // Limit cache size to prevent memory issues
      if (_pageCache.length > 5) {
        final oldestKey = _pageCache.keys.first;
        _pageCache.remove(oldestKey);
        _log.fine('Evicted cached page: $oldestKey');
      }
    }

    return chapterWidget;
  }

  Widget _buildOptimizedLoadingState(ColorScheme colors) {
    return _PerformantContainer(
      color: colors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OptimizedAnimatedIcon(
              icon: Icons.menu_book_rounded,
              color: colors.primary,
              size: 60,
            ),
            const SizedBox(height: 24),
            _OptimizedText(
              text: 'Loading content...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedErrorState(ColorScheme colors, String error) {
    return _PerformantContainer(
      color: colors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error, size: 56),
              const SizedBox(height: 32),
              _OptimizedText(
                text: 'Content Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 16),
              _OptimizedText(
                text: error,
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptimizedEmptyState(ColorScheme colors) {
    return _PerformantContainer(
      color: colors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined, 
              size: 64, 
              color: colors.onSurfaceVariant.withValues(alpha: 0.6)
            ),
            const SizedBox(height: 16),
            _OptimizedText(
              text: 'No content available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimized chapter page with minimal rebuilds
class _OptimizedChapterPage extends StatefulWidget {
  final String bookId;
  final String chapterKey;
  final int chapterIndex;
  final ReadingState readingState;
  final bool isPreload;

  const _OptimizedChapterPage({
    required this.bookId,
    required this.chapterKey,
    required this.chapterIndex,
    required this.readingState,
    this.isPreload = false,
  });

  @override
  State<_OptimizedChapterPage> createState() => _OptimizedChapterPageState();
}

class _OptimizedChapterPageState extends State<_OptimizedChapterPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<int, Widget> _sectionCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.isPreload) {
      // Return lightweight placeholder for preloaded pages
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Get chapter headings efficiently
    final allHeadings = widget.readingState.headings ?? [];
    final chapterHeadings = allHeadings.where((heading) => 
      heading.chapterId?.toString() == widget.chapterKey
    ).toList();

    if (chapterHeadings.isEmpty) {
      return _buildEmptyChapterPage(colors);
    }

    return _PerformantContainer(
      color: colors.surface,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        cacheExtent: 1500, // Increased cache for smooth scrolling
        slivers: [
          // Optimized chapter header
          SliverToBoxAdapter(
            child: _buildOptimizedChapterHeader(chapterHeadings, colors),
          ),
          
          // Virtual list for chapter content
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildOptimizedSection(index, chapterHeadings[index], colors),
              childCount: chapterHeadings.length,
            ),
          ),
          
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedChapterHeader(List<dynamic> chapterHeadings, ColorScheme colors) {
    final chapterTitle = chapterHeadings.isNotEmpty 
      ? chapterHeadings.first.title ?? 'Chapter ${widget.chapterIndex + 1}'
      : 'Chapter ${widget.chapterIndex + 1}';

    return _PerformantContainer(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.1),
            colors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Chapter indicator
          _PerformantContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _OptimizedText(
              text: 'Chapter ${widget.chapterIndex + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.onPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Chapter title
          _OptimizedText(
            text: chapterTitle,
            language: widget.readingState.book?.languageCode ?? 'en', // Get language from readingState
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedSection(int index, dynamic heading, ColorScheme colors) {
    // Cache sections for performance
    if (_sectionCache.containsKey(index)) {
      return _sectionCache[index]!;
    }

    final content = heading.content?.join('\n\n') ?? 'No content available.';
    final headingTitle = heading.title ?? '';
    
    // Get language from reading state for RTL support
    final bookLanguage = widget.readingState.book?.languageCode ?? 'en';
    final isRTL = bookLanguage == 'ur' || bookLanguage == 'ar';
    
    final section = _PerformantContainer(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.08),
          width: 1,
        ),
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
      ),
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
            // Optimized heading title with RTL support
          if (headingTitle.isNotEmpty) ...[
            _PerformantContainer(
                padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.06),
                      colors.primary.withValues(alpha: 0.03),
                    ],
                    begin: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                    end: isRTL ? Alignment.centerLeft : Alignment.centerRight,
                  ),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                ),
              ),
              child: _OptimizedText(
                text: headingTitle,
                  language: bookLanguage,
                style: TextStyle(
                    fontSize: isRTL ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface, 
                    height: isRTL ? 1.6 : 1.4,
                    letterSpacing: isRTL ? 0 : 0.2,
                ),
              ),
            ),
          ],
          
            // Optimized content with lazy rendering and RTL support
          Padding(
              padding: const EdgeInsets.all(24),
            child: _LazyText(
              content: content,
                language: bookLanguage,
              style: TextStyle(
                  fontSize: isRTL ? 20 : 16, // Larger font for Urdu readability
                  height: isRTL ? 2.2 : 1.8, // Increased line height for Urdu
                color: colors.onSurface,
                  letterSpacing: isRTL ? 0 : 0.3,
                  wordSpacing: isRTL ? 3 : 0, // Increased word spacing for Urdu
                ),
              ),
            ),
          ],
          ),
      ),
    );
    
    // Cache the section
    _sectionCache[index] = section;
    
    // Limit cache size
    if (_sectionCache.length > 10) {
      final oldestKey = _sectionCache.keys.first;
      _sectionCache.remove(oldestKey);
    }
    
    return section;
  }

  Widget _buildEmptyChapterPage(ColorScheme colors) {
    return _PerformantContainer(
      color: colors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined, 
              size: 64, 
              color: colors.onSurfaceVariant.withValues(alpha: 0.6)
            ),
            const SizedBox(height: 16),
            _OptimizedText(
              text: 'Chapter content not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Performance-optimized container with automatic repaint boundaries
class _PerformantContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;

  const _PerformantContainer({
    required this.child,
    this.color,
    this.margin,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: color,
        margin: margin,
        padding: padding,
        decoration: decoration,
        child: child,
      ),
    );
  }
}

/// Optimized text widget with automatic repaint boundaries
class _OptimizedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? language;

  const _OptimizedText({
    required this.text,
    this.style,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if text should be RTL based on language
    final isRTL = language == 'ur' || language == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = isRTL ? TextAlign.right : TextAlign.left;
    
    // Enhanced text style for Urdu/Arabic
    final enhancedStyle = style?.copyWith(
      fontFamily: isRTL ? 'NotoNastaliqUrdu' : style?.fontFamily,
      height: isRTL ? 2.2 : (style?.height ?? 1.6),
      letterSpacing: isRTL ? 0 : (style?.letterSpacing ?? 0.2),
      wordSpacing: isRTL ? 3 : 0,
      fontWeight: isRTL ? FontWeight.w400 : (style?.fontWeight ?? FontWeight.normal),
    ) ?? TextStyle(
      fontFamily: isRTL ? 'NotoNastaliqUrdu' : null,
      height: isRTL ? 2.2 : 1.6,
      letterSpacing: isRTL ? 0 : 0.2,
      wordSpacing: isRTL ? 3 : 0,
      fontWeight: isRTL ? FontWeight.w400 : FontWeight.normal,
    );
    
    return RepaintBoundary(
      child: Directionality(
        textDirection: textDirection,
      child: SelectableText(
        text,
          style: enhancedStyle,
          textAlign: textAlign,
          contextMenuBuilder: (context, editableTextState) {
            // Disable system context menu to prevent the crash
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// Lazy text rendering for large content
class _LazyText extends StatefulWidget {
  final String content;
  final TextStyle? style;
  final String? language;

  const _LazyText({
    required this.content,
    this.style,
    this.language,
  });

  @override
  State<_LazyText> createState() => _LazyTextState();
}

class _LazyTextState extends State<_LazyText> {
  bool _isExpanded = false;
  static const int _previewLength = 500;

  @override
  Widget build(BuildContext context) {
    // Determine if text should be RTL based on language
    final isRTL = widget.language == 'ur' || widget.language == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final textAlign = isRTL ? TextAlign.right : TextAlign.left;
    
    // Enhanced text style for Urdu/Arabic
    final enhancedStyle = widget.style?.copyWith(
      fontFamily: isRTL ? 'NotoNastaliqUrdu' : widget.style?.fontFamily,
      height: isRTL ? 2.2 : (widget.style?.height ?? 1.6),
      letterSpacing: isRTL ? 0 : (widget.style?.letterSpacing ?? 0.2),
      wordSpacing: isRTL ? 3 : 0,
    ) ?? TextStyle(
      fontFamily: isRTL ? 'NotoNastaliqUrdu' : null,
      height: isRTL ? 2.2 : 1.6,
      letterSpacing: isRTL ? 0 : 0.2,
      wordSpacing: isRTL ? 3 : 0,
      fontWeight: isRTL ? FontWeight.w400 : FontWeight.normal,
    );
    
    final shouldTruncate = widget.content.length > _previewLength && !_isExpanded;
    final displayText = shouldTruncate 
        ? '${widget.content.substring(0, _previewLength)}...'
        : widget.content;

    return Directionality(
      textDirection: textDirection,
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: SelectableText(
            displayText,
              style: enhancedStyle,
              textAlign: textAlign,
              contextMenuBuilder: (context, editableTextState) {
                // Disable system context menu to prevent the crash
                return const SizedBox.shrink();
              },
          ),
        ),
        if (shouldTruncate) ...[
          const SizedBox(height: 8),
            Align(
              alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
              child: TextButton(
            onPressed: () => setState(() => _isExpanded = true),
                child: Text(isRTL ? 'مزید پڑھیں' : 'Read more'),
              ),
          ),
        ],
      ],
      ),
    );
  }
}

/// Virtual page view for optimized rendering
class _VirtualPageView extends StatelessWidget {
  final PageController controller;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double cacheExtent;
  final ValueChanged<int>? onPageChanged;

  const _VirtualPageView({
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.cacheExtent = 0.0,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      onPageChanged: onPageChanged,
      allowImplicitScrolling: true, // For better performance on iOS
    );
  }
}

/// Optimized animated icon
class _OptimizedAnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _OptimizedAnimatedIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_OptimizedAnimatedIcon> createState() => _OptimizedAnimatedIconState();
}

class _OptimizedAnimatedIconState extends State<_OptimizedAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withValues(alpha: 0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(widget.size / 2),
          ),
          child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.5),
        ),
      ),
    );
  }
} 