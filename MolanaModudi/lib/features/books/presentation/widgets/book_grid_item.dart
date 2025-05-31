import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/providers.dart'; // For core providers
// ignore: unused_import  // Ignore unused import removal
import 'package:modudi/features/books/data/models/book_models.dart'; // Use new models location

class BookGridItem extends ConsumerWidget {
  final Book book; // Changed from BookModel to Book
  final VoidCallback? onTap;

  const BookGridItem({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const double imageHeight = 110.0; // Further reduced from 120.0 to fix overflow issues

    // Extract data from book model
    final title = book.title ?? 'Untitled'; // Added null check for title
    final coverImageUrl = book.thumbnailUrl ?? ''; // Changed from coverUrl to thumbnailUrl
    // Use tags list, display first one or fallback
    final category = book.tags?.isNotEmpty == true ? book.tags!.first : 'Misc'; // Changed from categories to tags
    // Use defaultLanguage field directly
    final language = book.defaultLanguage ?? 'N/A'; // Changed from language to defaultLanguage
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 160), // Reduced from 180
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2.0, // Reduced from 4.0
          margin: const EdgeInsets.all(2.0), // Add small margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Reduced from 12.0
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Book cover image
                    CachedNetworkImage(
                      cacheManager: ref.watch(defaultCacheManagerProvider).maybeWhen(
                        data: (manager) => manager,
                        orElse: () => null,
                      ),
                      imageUrl: coverImageUrl,
                      cacheKey: 'thumb_${book.firestoreDocId}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        child: const Center(
                          child: SizedBox(
                            width: 20, // Reduced from 30
                            height: 20, // Reduced from 30
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        ),
                        child: Center(child: Icon(Icons.book, size: 40, color: theme.colorScheme.primary.withValues(alpha: 0.3))),
                      ),
                    ),
                    
                    // Title overlay at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                            stops: const [0.0, 0.9],
                          ),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.0, // Reduced from 12.0
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Book metadata - Simplified layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3.0), // Reduced from 4.0
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 8.0, // Reduced from 9.0
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    // Language and Year
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Language
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 9.0, // Reduced from 10.0
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 2.0),
                              Expanded(
                                child: Text(
                                  language,
                                  style: TextStyle(
                                    fontSize: 9.0, // Reduced from 10.0
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Year
                        if (book.publicationDate != null)
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 9.0,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 2.0),
                                Expanded(
                                  child: Text(
                                    book.publicationDate!, // Changed from publishYear.toString(). Consider parsing for year only.
                                    style: TextStyle(
                                      fontSize: 9.0,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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