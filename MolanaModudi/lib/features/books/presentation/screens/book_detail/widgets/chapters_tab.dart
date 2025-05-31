import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../routes/route_names.dart';
import '../../../../data/models/book_models.dart';
import '../../../../../../core/extensions/string_extensions.dart';

/// Hierarchical chapters tab with expandable headings
class ChaptersTab extends ConsumerStatefulWidget {
  final Book book;

  const ChaptersTab({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<ChaptersTab> createState() => _ChaptersTabState();
}

class _ChaptersTabState extends ConsumerState<ChaptersTab>
    with TickerProviderStateMixin {
  late Map<String, AnimationController> _animationControllers;
  late Map<String, Animation<double>> _rotationAnimations;
  late Map<String, Animation<double>> _expandAnimations;
  final Set<String> _expandedChapters = {};
  
  // Get the font family name for Urdu content
  String get _urduFontFamily => 'JameelNooriNastaleeqRegular';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = {};
    _rotationAnimations = {};
    _expandAnimations = {};

    final chapters = _getChaptersWithHeadings();
    for (int i = 0; i < chapters.length; i++) {
      final key = 'chapter_$i';
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _animationControllers[key] = controller;
      _rotationAnimations[key] = Tween<double>(
        begin: 0.0,
        end: 0.5,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      _expandAnimations[key] = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<ChapterWithHeadings> _getChaptersWithHeadings() {
    final List<ChapterWithHeadings> chaptersWithHeadings = [];

    if (widget.book.volumes?.isNotEmpty == true) {
      // Extract from volumes/chapters structure
      for (final volume in widget.book.volumes!) {
        if (volume.chapters?.isNotEmpty == true) {
          for (final chapter in volume.chapters!) {
            if (chapter.headings?.isNotEmpty == true) {
              chaptersWithHeadings.add(ChapterWithHeadings(
                chapter: chapter,
                headings: chapter.headings!,
              ));
            }
          }
        }
      }
    } else if (widget.book.headings?.isNotEmpty == true) {
      // Group headings by chapterId if no volume structure
      final Map<int?, List<Heading>> groupedHeadings = {};
      for (final heading in widget.book.headings!) {
        final chapterId = heading.chapterId ?? 0;
        (groupedHeadings[chapterId] ??= []).add(heading);
      }

      groupedHeadings.forEach((chapterId, headings) {
        headings.sort((a, b) => a.sequence.compareTo(b.sequence));
        chaptersWithHeadings.add(ChapterWithHeadings(
          chapter: Chapter(
            id: chapterId ?? 0,
            title: 'Chapter ${chapterId ?? 1}',
            headings: headings,
          ),
          headings: headings,
        ));
      });
    }

    return chaptersWithHeadings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chapters = _getChaptersWithHeadings();
    final String language = widget.book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;

    if (chapters.isEmpty) {
      return _buildEmptyState(theme);
    }

    return CustomScrollView(
      slivers: [
        // Simple header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Table of Contents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // Expandable chapters list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildChapterTile(
              chapters[index],
              index,
              theme,
            ),
            childCount: chapters.length,
          ),
        ),

        // Bottom padding for floating bottom bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No chapters available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Content structure is loading',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterTile(ChapterWithHeadings chapterData, int chapterIndex, ThemeData theme) {
    final key = 'chapter_$chapterIndex';
    final chapter = chapterData.chapter;
    final headings = chapterData.headings;
    final String language = widget.book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Chapter header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleChapter(key),
              onLongPress: () => _navigateToChapter(chapter),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Chapter number
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${chapterIndex + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Chapter title with navigation button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chapter.title ?? 'Chapter ${chapterIndex + 1}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                    fontFamily: isRTL ? _urduFontFamily : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Small navigation icon
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _navigateToChapter(chapter),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (chapter.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              chapter.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${headings.length} headings',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Animated expand icon
                    AnimatedBuilder(
                      animation: _rotationAnimations[key]!,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimations[key]!.value * 3.14159,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable headings list
          AnimatedBuilder(
            animation: _expandAnimations[key]!,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _expandAnimations[key]!.value,
                  child: child,
                ),
              );
            },
            child: _buildHeadingsList(headings, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadingsList(List<Heading> headings, ThemeData theme) {
    final String language = widget.book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: headings.asMap().entries.map((entry) {
          final index = entry.key;
          final heading = entry.value;
          final isLast = index == headings.length - 1;

          return _buildHeadingTile(heading, index + 1, theme, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildHeadingTile(Heading heading, int headingIndex, ThemeData theme, bool isLast) {
    final String language = widget.book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToHeading(heading),
        borderRadius: BorderRadius.only(
          bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
          ),
          child: Row(
            children: [
              // Heading number
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    headingIndex.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Heading title
              Expanded(
                child: Text(
                  heading.title ?? 'Heading ${headingIndex}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    fontFamily: isRTL ? _urduFontFamily : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Small arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleChapter(String key) {
    setState(() {
      if (_expandedChapters.contains(key)) {
        _expandedChapters.remove(key);
        _animationControllers[key]?.reverse();
      } else {
        _expandedChapters.add(key);
        _animationControllers[key]?.forward();
      }
    });
  }

  void _navigateToHeading(Heading heading) {
    // Navigate to reading screen with the specific heading parameters
    final chapterId = heading.chapterId?.toString() ?? heading.id.toString();
    final headingId = heading.firestoreDocId.isNotEmpty ? heading.firestoreDocId : heading.id.toString();
    
    // Construct URL with query parameters for direct heading navigation including unique timestamp
    final uri = Uri(
      path: '/read/${widget.book.id}',
      queryParameters: {
        'chapterId': chapterId,
        'headingId': headingId,
        'ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    
    context.go(uri.toString());
  }

  void _navigateToChapter(Chapter chapter) {
    // Navigate to reading screen with the specific chapter parameters
    final chapterId = chapter.id.toString();
    
    // Construct URL with query parameters for direct chapter navigation including unique timestamp
    final uri = Uri(
      path: '/read/${widget.book.id}',
      queryParameters: {
        'chapterId': chapterId,
        'ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    
    context.go(uri.toString());
  }
}

/// Helper class to group chapters with their headings
class ChapterWithHeadings {
  final Chapter chapter;
  final List<Heading> headings;

  ChapterWithHeadings({
    required this.chapter,
    required this.headings,
  });
} 