import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:modudi/core/themes/maududi_theme.dart'; // For BookItemStyles & CardStyles
// import '../../../../core/models/book_model.dart'; // Import BookModel from core
import 'package:modudi/features/books/data/models/book_models.dart'; // Use new models location

class BookListItem extends StatelessWidget {
  final Book book; // Changed from BookModel to Book
  final VoidCallback? onTap;

  const BookListItem({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  imageUrl: coverImageUrl,
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
                    // Title & Category Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title, // Use title from BookModel
                                style: bookItemStyles.titleStyle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                author, // Use author from BookModel
                                style: bookItemStyles.authorStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(category), // Use category from BookModel
                          labelStyle: theme.chipTheme.labelStyle?.copyWith(fontSize: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          backgroundColor: theme.chipTheme.backgroundColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
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