import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../providers/reading_provider.dart';
import '../../../providers/reading_state.dart';
import '../../../../data/services/simple_bookmark_service.dart';
import '../../../../../books/data/models/book_models.dart';
// Removed unused imports - bottom sheet functionality moved to ReadingHeader

/// Controls widget for reading screen - extracted from monolithic ReadingScreen
class ReadingControls extends ConsumerWidget {
  final String bookId;

  const ReadingControls({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingState = ref.watch(readingNotifierProvider(bookId));
    final colors = Theme.of(context).colorScheme;

    // Return empty container to hide the navigation controls
      return const SizedBox.shrink();
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, ReadingState readingState) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            colors.surface,
            colors.surface.withValues(alpha: 0.95),
            colors.surface.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                context,
                Icons.chevron_left_rounded,
                'Previous',
                _canNavigateToPrevious(readingState),
                () => _navigateToPreviousChapter(ref, readingState),
              ),
              _buildControlButton(
                context,
                Icons.chevron_right_rounded,
                'Next',
                _canNavigateToNext(readingState),
                () => _navigateToNextChapter(ref, readingState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String label,
    bool enabled,
    VoidCallback? onPressed,
  ) {
    final colors = Theme.of(context).colorScheme;
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Navigation helper methods
  bool _canNavigateToPrevious(ReadingState readingState) {
    return readingState.mainChapterKeys != null && 
           readingState.currentChapter > 0;
  }

  bool _canNavigateToNext(ReadingState readingState) {
    return readingState.mainChapterKeys != null && 
           readingState.currentChapter < (readingState.mainChapterKeys!.length - 1);
  }

  // Navigation methods
  void _navigateToPreviousChapter(WidgetRef ref, ReadingState readingState) {
    HapticFeedback.lightImpact();
    if (_canNavigateToPrevious(readingState)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readingNotifierProvider(bookId).notifier)
           .goToChapter(readingState.mainChapterKeys![readingState.currentChapter - 1]);
      });
    }
  }

  void _navigateToNextChapter(WidgetRef ref, ReadingState readingState) {
    HapticFeedback.lightImpact();
    if (_canNavigateToNext(readingState)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readingNotifierProvider(bookId).notifier)
           .goToChapter(readingState.mainChapterKeys![readingState.currentChapter + 1]);
      });
    }
  }

  // Bottom sheet methods have been removed to eliminate duplicate functionality
  // Chapter and bookmark navigation is handled by ReadingHeader widget

  // Bookmark methods
  IconData _getCurrentBookmarkIcon(ReadingState readingState) {
    return _isCurrentChapterBookmarked(readingState) 
      ? Icons.bookmark_rounded 
      : Icons.bookmark_outline_rounded;
  }

  bool _isCurrentChapterBookmarked(ReadingState readingState) {
    if (readingState.mainChapterKeys == null || readingState.mainChapterKeys!.isEmpty) {
      return false;
    }
    
    final currentChapterKey = readingState.mainChapterKeys![readingState.currentChapter];
    return readingState.bookmarks.any((bookmark) => 
      bookmark.chapterId?.toString() == currentChapterKey.toString()
    );
  }

  Future<void> _toggleCurrentBookmark(WidgetRef ref, ReadingState readingState, BuildContext context) async {
    HapticFeedback.lightImpact();
    
    try {
      if (readingState.mainChapterKeys == null || readingState.mainChapterKeys!.isEmpty) {
        _showSnackBar(context, 'No chapters available to bookmark', isError: true);
        return;
      }

      final currentChapterKey = readingState.mainChapterKeys![readingState.currentChapter];
      final currentChapterTitle = _getCurrentChapterTitle(readingState);
      
      final bookmarkService = SimpleBookmarkService();
      final wasAdded = await bookmarkService.toggleBookmark(
        bookId: bookId,
        chapterId: currentChapterKey.toString(),
        chapterTitle: currentChapterTitle,
      );

      _showSnackBar(
        context, 
        wasAdded ? 'Chapter bookmarked!' : 'Bookmark removed',
        isError: false,
      );

      // Refresh the reading state to update bookmark status
      ref.refresh(readingNotifierProvider(bookId));
      
    } catch (e) {
      _showSnackBar(context, 'Error updating bookmark: $e', isError: true);
    }
  }

  String _getCurrentChapterTitle(ReadingState readingState) {
    if (readingState.headings != null && readingState.headings!.isNotEmpty) {
      final currentChapterKey = readingState.mainChapterKeys![readingState.currentChapter];
      
      // Find the chapter heading, return null if not found
      Heading? chapterHeading;
      try {
        chapterHeading = readingState.headings!.firstWhere(
          (heading) => heading.chapterId?.toString() == currentChapterKey.toString(),
        );
      } catch (e) {
        // No matching heading found
        chapterHeading = null;
      }
      
      if (chapterHeading?.title != null) {
        return chapterHeading!.title!;
      }
    }
    
    return 'Chapter ${readingState.currentChapter + 1}';
  }

  // Share methods
  Future<void> _shareCurrentContent(ReadingState readingState, BuildContext context) async {
    HapticFeedback.lightImpact();
    
    try {
      final chapterTitle = _getCurrentChapterTitle(readingState);
      final bookTitle = readingState.bookTitle ?? 'Islamic Book';
      
      // Get current chapter content
      String shareContent = '$chapterTitle\n\nFrom: $bookTitle\n\n';
      
      if (readingState.headings != null && readingState.mainChapterKeys != null) {
        final currentChapterKey = readingState.mainChapterKeys![readingState.currentChapter];
        final chapterHeadings = readingState.headings!.where((heading) => 
          heading.chapterId?.toString() == currentChapterKey.toString()
        ).toList();
        
        if (chapterHeadings.isNotEmpty) {
          // Add first paragraph or summary
          final firstHeading = chapterHeadings.first;
          if (firstHeading.content != null && firstHeading.content!.isNotEmpty) {
            String preview = firstHeading.content!.first;
            if (preview.length > 200) {
              preview = '${preview.substring(0, 197)}...';
            }
            shareContent += preview;
          }
        }
      }
      
      shareContent += '\n\nShared from Modudi Islamic Reading App';
      
      try {
        await Share.share(shareContent);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing: $e')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing share content: $e')),
        );
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
} 