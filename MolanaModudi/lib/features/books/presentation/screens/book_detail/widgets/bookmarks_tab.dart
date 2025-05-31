import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/book_models.dart';
import '../../../../../reading/data/models/bookmark_model.dart';
import '../../../../../reading/data/services/simple_bookmark_service.dart';
import '../../../../../../routes/route_names.dart';
import '../../../../../../core/extensions/string_extensions.dart';

/// Provider for SimpleBookmarkService
final simpleBookmarkServiceProvider = Provider((ref) => SimpleBookmarkService());

/// Bookmarks tab showing user's saved bookmarks for this book
class BookmarksTab extends ConsumerWidget {
  final Book book;

  const BookmarksTab({
    super.key,
    required this.book,
  });

  // Get the font family name for Urdu content
  String get _urduFontFamily => 'JameelNooriNastaleeqRegular';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookmarkService = ref.watch(simpleBookmarkServiceProvider);
    final String language = book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;

    return FutureBuilder<List<SimpleBookmark>>(
      future: bookmarkService.getBookmarksForBook(book.id.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(colorScheme, snapshot.error.toString());
        }

        final bookmarks = snapshot.data ?? [];
        
        if (bookmarks.isEmpty) {
          return _buildEmptyState(colorScheme);
        }

        return _buildBookmarksList(bookmarks, theme, ref);
      },
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, String error) {
    return SingleChildScrollView(
      child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading bookmarks',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
                ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start reading to add bookmarks',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the bookmark icon while reading to save important passages',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksList(List<SimpleBookmark> bookmarks, ThemeData theme, WidgetRef ref) {
    final String language = book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bookmark.headingTitle ?? bookmark.chapterTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        fontFamily: isRTL ? _urduFontFamily : null,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _deleteBookmark(ref, bookmark);
                      } else if (value == 'navigate') {
                        _navigateToBookmark(context, bookmark);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'navigate',
                        child: ListTile(
                          leading: Icon(Icons.navigation),
                          title: Text('Go to'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(bookmark.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.menu_book,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bookmark.chapterTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: isRTL ? _urduFontFamily : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _navigateToBookmark(context, bookmark),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Continue Reading',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _deleteBookmark(WidgetRef ref, SimpleBookmark bookmark) async {
    try {
      final bookmarkService = ref.read(simpleBookmarkServiceProvider);
      await bookmarkService.removeBookmark(bookmark.id);
      
      // Trigger a rebuild by invalidating the provider
      ref.invalidate(simpleBookmarkServiceProvider);
    } catch (e) {
      // Handle error - could show a snackbar
    }
  }

  void _navigateToBookmark(BuildContext context, SimpleBookmark bookmark) {
    final bookId = bookmark.bookId;
    final chapterId = bookmark.chapterId;
    final headingId = bookmark.headingId;

    // Build the reading route with query parameters
    String route = RouteNames.readingWithId(bookId);
    
    if (chapterId.isNotEmpty) {
      route += '?chapterId=$chapterId';
      
      if (headingId != null && headingId.isNotEmpty) {
        route += '&headingId=$headingId';
      }
    }

    context.go(route);
  }
} 