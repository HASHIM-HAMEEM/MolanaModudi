import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/themes/app_color.dart';
import 'package:modudi/features/books/data/models/book_models.dart';

class BookGridItem extends StatefulWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookGridItem({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  State<BookGridItem> createState() => _BookGridItemState();
}

class _BookGridItemState extends State<BookGridItem> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsScroll();
    });
  }

  void _checkIfNeedsScroll() {
    if (!mounted) return;
    
    setState(() {
      _needsScroll = _scrollController.position.maxScrollExtent > 0;
    });
    
    if (_needsScroll) {
      _startScrolling();
    }
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (!mounted || !_needsScroll) return;
      
      final maxExtent = _scrollController.position.maxScrollExtent;
      final currentPos = _scrollController.offset;
      
      if (currentPos < maxExtent) {
        _scrollController.animateTo(
          maxExtent,
          duration: Duration(milliseconds: 1500 + maxExtent.toInt() * 20),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 1500 + maxExtent.toInt() * 20),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    // Extract data from book model
    final title = widget.book.title ?? 'Untitled';
    final author = widget.book.author ?? 'Unknown';
    final coverImageUrl = widget.book.thumbnailUrl ?? '';
    
    // Card dimensions - match the aspect ratio in the image
    final cardWidth = 160.0;
    final cardHeight = 240.0;
    final titleHeight = 60.0;
    
    // Use app's default colors from theme
    final cardBackgroundColor = isDark 
        ? theme.cardColor
        : isSepia 
            ? AppColor.surfaceSepia
            : theme.cardColor;
    
    final titleBackgroundColor = isDark
        ? theme.cardColor
        : isSepia
            ? AppColor.surfaceSepia
            : theme.cardColor;
    
    final titleTextColor = isDark
        ? theme.colorScheme.onSurface
        : isSepia
            ? AppColor.textPrimarySepia
            : theme.colorScheme.onSurface;
    
    final authorTextColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.7)
        : isSepia
            ? AppColor.textSecondarySepia
            : theme.colorScheme.onSurface.withOpacity(0.7);
    
    return Hero(
      tag: 'book-${widget.book.firestoreDocId}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : isSepia
                          ? AppColor.primarySepia.withOpacity(0.1)
                          : theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Book cover image - takes most of the card
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: coverImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      fadeInDuration: const Duration(milliseconds: 300),
                      fadeOutDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) => Container(
                        color: isDark 
                            ? theme.colorScheme.surface
                            : isSepia 
                                ? AppColor.backgroundSepia
                                : theme.colorScheme.surface,
                        child: Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 48.0,
                            color: isDark
                                ? theme.colorScheme.onSurface.withOpacity(0.3)
                                : isSepia
                                    ? AppColor.textSecondarySepia.withOpacity(0.3)
                                    : theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark 
                            ? theme.colorScheme.surface
                            : isSepia 
                                ? AppColor.backgroundSepia
                                : theme.colorScheme.surface,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48.0,
                            color: isDark
                                ? theme.colorScheme.onSurface.withOpacity(0.3)
                                : isSepia
                                    ? AppColor.textSecondarySepia.withOpacity(0.3)
                                    : theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Title bar at bottom
                Container(
                  height: titleHeight,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: titleBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scrolling title for long text
                      SizedBox(
                        height: 30,
                        width: double.infinity,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: titleTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                      
                      // Author name
                      Text(
                        author,
                        style: TextStyle(
                          color: authorTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}