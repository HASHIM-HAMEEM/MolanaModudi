import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/themes/app_color.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/books/presentation/providers/book_actions_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logging/logging.dart';

class BookActionBar extends ConsumerWidget {
  final String bookId;
  final Book book; // Required for toggleFavorite and share content
  final Color? iconColor;
  final Color? activeIconColor;
  final bool showOnlyFavorite; // Only show favorite button

  BookActionBar({
    super.key,
    required this.bookId,
    required this.book,
    this.iconColor, // Default will be themed
    this.activeIconColor, // Default will be AppColor.accent
    this.showOnlyFavorite = false, // Default shows all buttons
  });

  final _log = Logger('BookActionBar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsStateAsync = ref.watch(bookActionsProvider(bookId));
    final theme = Theme.of(context);

    final bool isFavorite = actionsStateAsync.when(
      data: (data) => data.isFavorite,
      loading: () => actionsStateAsync.asData?.value.isFavorite ?? false,
      error: (e, s) => actionsStateAsync.asData?.value.isFavorite ?? false,
    );

    final bool isPinned = actionsStateAsync.when(
      data: (data) => data.isPinned,
      loading: () => actionsStateAsync.asData?.value.isPinned ?? false,
      error: (e, s) => actionsStateAsync.asData?.value.isPinned ?? false,
    );

    final defaultIconColor = iconColor ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54);
    final currentActiveIconColor = activeIconColor ?? AppColor.accent;

    return Row(
      mainAxisSize: MainAxisSize.min, // To be used in AppBar actions or similar
      children: [
        // Favorite Button
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? currentActiveIconColor : defaultIconColor,
          ),
          onPressed: () async {
            await ref.read(bookActionsProvider(bookId).notifier).toggleFavorite(book);
          },
          tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
        ),
        // Show other buttons only if showOnlyFavorite is false
        if (!showOnlyFavorite) ...[
          // Pin Button
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: isPinned ? currentActiveIconColor : defaultIconColor,
            ),
            onPressed: () {
              ref.read(bookActionsProvider(bookId).notifier).togglePin();
            },
            tooltip: isPinned ? 'Remove from Saved Items' : 'Save for Quick Access',
          ),
          // Share Button
          IconButton(
            tooltip: 'Share this book',
            icon: Icon(Icons.share, color: defaultIconColor),
            onPressed: () async {
              try {
                HapticFeedback.mediumImpact();
                final String shareText = '''Check out "${book.title}" by ${book.author ?? 'Unknown Author'} on the Maulana Maududi app!\n\n${book.description != null ? '${book.description?.substring(0, book.description!.length > 100 ? 100 : book.description!.length)}...' : 'A great book to explore!'}

Download the app to read more.'''; // Simplified share text
                
                await Share.share(
                  shareText,
                  subject: 'Check out this book: ${book.title}'
                );
                _log.info('Shared book via native share sheet: ${book.title}');
              } catch (e) {
                _log.warning('Error sharing book: $e');
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Could not share this book')),
                   );
                }
              }
            },
          ),
        ],
      ],
    );
  }
} 