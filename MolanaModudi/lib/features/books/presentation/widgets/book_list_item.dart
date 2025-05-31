import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/providers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:modudi/core/themes/maududi_theme.dart'; // For BookItemStyles & CardStyles
// import '../../../../core/models/book_model.dart'; // Import BookModel from core
import 'package:modudi/features/books/data/models/book_models.dart'; // Use new models location
import 'package:shimmer/shimmer.dart'; // User would need to add this package
import 'package:modudi/features/books/presentation/providers/book_actions_provider.dart'; // Added

class BookListItem extends ConsumerWidget {
  final Book book; // Changed from BookModel to Book
  final VoidCallback? onTap;
  final bool showFavoriteIcon;
  final bool showPinIcon;

  const BookListItem({
    super.key,
    required this.book,
    this.onTap,
    this.showFavoriteIcon = false,
    this.showPinIcon = false,
  });

  // Enhanced helper method to check if image is cached with disk cache check
  Future<bool> _isImageCached(CacheManager cacheManager, String imageUrl) async {
    if (imageUrl.isEmpty) return false;
    try {
      // Check disk cache
      final fileInfo = await cacheManager.getFileFromCache(imageUrl);
      return fileInfo != null && fileInfo.file.existsSync();
    } catch (e) {
      return false;
    }
  }

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
    // Progress is handled by liveReadingProgressProvider if shown elsewhere
    // const int progress = 0; // Placeholder - progress needs separate state or field

    // Watch book actions state if icons are shown
    final bookActionsState = ref.watch(bookActionsProvider(book.id.toString())); 

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
              // Book Cover - Optimized to avoid shimmer for cached images
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: ref.watch(defaultCacheManagerProvider).when(
                  data: (cacheManagerInstance) => FutureBuilder<bool>(
                    future: _isImageCached(cacheManagerInstance, coverImageUrl),
                    builder: (context, snapshot) {
                      final bool isCached = snapshot.data ?? false;
                      
                      return CachedNetworkImage(
                  imageUrl: coverImageUrl,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                        cacheManager: cacheManagerInstance,
                        placeholder: isCached 
                          ? null // No placeholder for cached images - load instantly
                          : (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                  width: imageWidth, 
                                  height: imageHeight, 
                                  color: Colors.white
                              ),
                          ),
                        errorWidget: (context, url, error) => Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.book_outlined,
                            size: 32,
                            color: theme.iconTheme.color?.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                            width: imageWidth, 
                            height: imageHeight, 
                            color: Colors.white
                        ),
                    ),
                  error: (err, stack) => Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.book_outlined,
                      size: 32,
                      color: theme.iconTheme.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              // Text Content & Icons
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
                        // Action Icons (Favorite/Pin)
                        if (showFavoriteIcon || showPinIcon)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showFavoriteIcon && bookActionsState.hasValue)
                                IconButton(
                                  icon: Icon(
                                    bookActionsState.value!.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: bookActionsState.value!.isFavorite ? Colors.red : theme.iconTheme.color?.withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: bookActionsState.value!.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                                  onPressed: () => ref.read(bookActionsProvider(book.id.toString()).notifier).toggleFavorite(book),
                                ),
                              if (showPinIcon && showFavoriteIcon && bookActionsState.hasValue) const SizedBox(width: 4),
                              if (showPinIcon && bookActionsState.hasValue)
                                IconButton(
                                  icon: Icon(
                                    bookActionsState.value!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                    color: bookActionsState.value!.isPinned ? Theme.of(context).colorScheme.secondary : theme.iconTheme.color?.withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: bookActionsState.value!.isPinned ? 'Remove from Saved Items' : 'Save for Quick Access',
                                  onPressed: () => ref.read(bookActionsProvider(book.id.toString()).notifier).togglePin(),
                                ),
                               if (showPinIcon || showFavoriteIcon) const SizedBox(width: 4), // Ensure chip is spaced if icons present
                            ],
                          ),
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
                    // if (progress > 0)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 8.0),
                    //     child: Column(
                    //       children: [
                    //         ClipRRect(
                    //           borderRadius: BorderRadius.circular(4.0),
                    //           child: LinearProgressIndicator(
                    //             value: progress / 100.0,
                    //             minHeight: 6.0,
                    //             valueColor: AlwaysStoppedAnimation<Color>(theme.progressIndicatorTheme.color!),
                    //             backgroundColor: theme.progressIndicatorTheme.linearTrackColor,
                    //           ),
                    //         ),
                    //         const SizedBox(height: 4.0),
                    //         Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Text('Progress', style: bookItemStyles.metadataStyle),
                    //             Text(
                    //               '$progress%',
                    //               style: bookItemStyles.metadataStyle.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     ),
                    //   ),
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