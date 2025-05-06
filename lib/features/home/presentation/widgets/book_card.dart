import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/themes/maududi_theme.dart'; // For BookItemStyles

class BookCard extends StatelessWidget {
  final String title;
  final String category;
  final String coverImageUrl;
  final VoidCallback? onTap; // Optional callback for tap event

  const BookCard({
    super.key,
    required this.title,
    required this.category,
    required this.coverImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookItemStyles = EnhancedTheme.bookItemStyles(context); // Use theme extension
    const double cardWidth = 120.0; // Consistent width like reference (w-32)
    const double imageHeight = 150.0; // Reduced height to prevent overflow

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: 220, // Fixed height to match the parent container
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Image with Favorite Icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: coverImageUrl,
                    placeholder: (context, url) => Container(
                      width: cardWidth,
                      height: imageHeight,
                      color: theme.colorScheme.surfaceVariant,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: cardWidth,
                      height: imageHeight,
                      color: theme.colorScheme.surfaceVariant,
                      child: const Icon(Icons.error),
                    ),
                    width: cardWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                  ),
                ),
                // Favorite Icon Placeholder
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border, // Placeholder, replace with Heart icon if needed
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0), // Reduced spacing below image

            // Book Title
            Flexible(
              child: Text(
                title,
                style: bookItemStyles.titleStyle, // Use style from theme extension
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2.0), // Reduced spacing between title and category

            // Book Category
            Text(
              category,
              style: bookItemStyles.categoryStyle, // Use style from theme extension
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 