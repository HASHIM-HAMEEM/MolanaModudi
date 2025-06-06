import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/providers.dart';
import '../../../../core/themes/maududi_theme.dart'; // For BookItemStyles & CardStyles
// import '../../../../core/models/book_model.dart'; // Import BookModel from core
import 'package:modudi/features/books/data/models/book_models.dart'; // Use new models

class BookListItem extends ConsumerWidget {
  final Book book; // Changed from BookModel to Book
  final VoidCallback? onTap;

  const BookListItem({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookItemStyles = EnhancedTheme.bookItemStyles(context);
    final cardStyles = EnhancedTheme.cardStyles(context);
    const double imageWidth = 64.0; // w-16 in reference
    const double imageHeight = 96.0; // h-24 in reference

    // Extract data from book model
    final title = book.title ?? 'Untitled'; // Added null check for title
    final author = book.author ?? 'Unknown Author'; // Use author field
    final coverImageUrl = book.thumbnailUrl ?? ''; // Changed from coverUrl to thumbnailUrl
    // Use tags list, display first one or fallback
    final category = book.tags?.isNotEmpty == true ? book.tags!.first : 'Misc'; // Changed from categories to tags
    // Use defaultLanguage field directly
    final language = book.defaultLanguage ?? 'N/A'; // Changed from language to defaultLanguage
    // Use publicationDate field
    final year = book.publicationDate ?? 'N/A'; // Changed from publishYear. Consider parsing for year only.
    const int progress = 0; // Placeholder - progress needs separate state or field

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0), // Match card radius
      child: DecoratedBox(
        decoration: cardStyles.elevated, // Use elevated card style
        child: Padding(
          padding: bookItemStyles.listItemPadding, // Use padding from theme
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: CachedNetworkImage(
                  cacheManager: ref.watch(defaultCacheManagerProvider).maybeWhen(
                    data: (manager) => manager,
                    orElse: () => null,
                  ),
                  imageUrl: coverImageUrl,
                  cacheKey: 'thumb_${book.firestoreDocId}',
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.error_outline, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              // Text Content & Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Author Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: bookItemStyles.titleStyle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                author,
                                style: bookItemStyles.authorStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4), // Reduced spacing
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80), // Limit chip width
                          child: Chip(
                            label: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            labelStyle: theme.chipTheme.labelStyle?.copyWith(
                              fontSize: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
                            backgroundColor: theme.chipTheme.backgroundColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    // Language & Year
                    Text(
                      '$language • $year', // Use language & year from BookModel
                      style: bookItemStyles.metadataStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Progress Bar (if progress > 0)
                    if (progress > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: LinearProgressIndicator(
                                value: progress / 100.0,
                                minHeight: 6.0,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.progressIndicatorTheme.color!),
                                backgroundColor: theme.progressIndicatorTheme.linearTrackColor,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Progress', style: bookItemStyles.metadataStyle),
                                Text(
                                  '$progress%',
                                  style: bookItemStyles.metadataStyle.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}