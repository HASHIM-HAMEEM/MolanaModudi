import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/simple_bookmark_service.dart';
import '../../data/models/bookmark_model.dart';

/// Bottom sheet widget for displaying and managing bookmarks
class BookmarksBottomSheet extends ConsumerStatefulWidget {
  final String bookId;
  final Function(String chapterId, String? headingId)? onBookmarkSelected;

  const BookmarksBottomSheet({
    super.key,
    required this.bookId,
    this.onBookmarkSelected,
  });

  @override
  ConsumerState<BookmarksBottomSheet> createState() => _BookmarksBottomSheetState();
}

class _BookmarksBottomSheetState extends ConsumerState<BookmarksBottomSheet> {
  final SimpleBookmarkService _bookmarkService = SimpleBookmarkService();
  List<SimpleBookmark>? _bookmarks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _bookmarkService.getBookmarksForBook(widget.bookId);
      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookmarks = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBookmark(SimpleBookmark bookmark) async {
    try {
      await _bookmarkService.removeBookmark(bookmark.id);
      await _loadBookmarks(); // Refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing bookmark: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.bookmark_rounded, color: colors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your Bookmarks',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (_bookmarks != null && _bookmarks!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_bookmarks!.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading 
              ? _buildLoadingState(colors)
              : _bookmarks == null || _bookmarks!.isEmpty
                ? _buildEmptyState(colors)
                : _buildBookmarksList(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading bookmarks...',
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookmarks yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start bookmarking chapters and sections you want to revisit later.',
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList(ColorScheme colors) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _bookmarks!.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: colors.outline.withValues(alpha: 0.2),
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        final bookmark = _bookmarks![index];
        return _buildBookmarkItem(bookmark, colors);
      },
    );
  }

  Widget _buildBookmarkItem(SimpleBookmark bookmark, ColorScheme colors) {
    final isSubChapter = bookmark.isSubChapter;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSubChapter 
              ? colors.secondaryContainer
              : colors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSubChapter 
              ? Icons.bookmark_outline_rounded
              : Icons.bookmark_rounded,
            color: isSubChapter 
              ? colors.onSecondaryContainer
              : colors.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          bookmark.displayName,
          style: GoogleFonts.notoNastaliqUrdu(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              bookmark.chapterTitle,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimestamp(bookmark.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigate button
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onBookmarkSelected?.call(
                  bookmark.chapterId,
                  bookmark.headingId,
                );
              },
              icon: Icon(
                Icons.play_arrow_rounded,
                color: colors.primary,
                size: 24,
              ),
              tooltip: 'Go to bookmark',
            ),
            // Delete button
            IconButton(
              onPressed: () => _showDeleteConfirmation(bookmark),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.error,
                size: 20,
              ),
              tooltip: 'Delete bookmark',
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          widget.onBookmarkSelected?.call(
            bookmark.chapterId,
            bookmark.headingId,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(SimpleBookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark?'),
        content: Text('Are you sure you want to delete "${bookmark.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBookmark(bookmark);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 