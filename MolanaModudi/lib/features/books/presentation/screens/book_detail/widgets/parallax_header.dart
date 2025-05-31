import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/widgets/optimized_cached_image.dart';
import '../../../../data/models/book_models.dart';

/// Optimized ParallaxHeader extracted from monolithic BookDetailScreen
class ParallaxHeader extends StatelessWidget {
  final Book book;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;

  const ParallaxHeader({
    super.key,
    required this.book,
    required this.onFavoriteToggle,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate optimal header height using mathematical approach
    // Minimum height for content + responsive scaling
    final isCompactScreen = screenSize.width < 375;
    final isTablet = screenSize.width > 600;
    
    // Base height calculations for Airbnb-style larger thumbnails
    final minHeaderHeight = 160.0; // Increased minimum for larger thumbnails
    final maxHeaderHeight = screenSize.height * 0.30; // Increased to 30% for larger content
    
    // Enhanced responsive header height for prominent thumbnails
    final baseHeight = isCompactScreen 
        ? screenSize.height * 0.22  // Increased from 18% to 22%
        : isTablet 
            ? screenSize.height * 0.25  // Increased from 20% to 25%
            : screenSize.height * 0.28; // Increased from 22% to 28%
    
    final expandedHeight = baseHeight.clamp(minHeaderHeight, maxHeaderHeight);
    
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: false,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Theme-aware gradient background - memoized for performance
            _ThemeGradientBackground(),
            
            // Content with responsive layout
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactScreen ? 12.0 : 16.0,
                  vertical: isCompactScreen ? 8.0 : 12.0,
                ),
                child: _MinimalistHeaderContent(
                  book: book,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Memoized gradient background for performance
class _ThemeGradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getThemeGradientColors(context),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  List<Color> _getThemeGradientColors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Check if it's sepia theme by looking at primary color
    final isSepia = (colorScheme.primary.r * 255).round() == 139 && (colorScheme.primary.g * 255).round() == 69; // Brown check
    
    if (isSepia) {
      // Sepia theme - warm brown tones
      return [
        const Color(0xFFD2B48C).withValues(alpha: 0.9), // Tan
        const Color(0xFFDEB887).withValues(alpha: 0.8), // Burlywood
        const Color(0xFFF5E6D3).withValues(alpha: 0.7), // Light sepia
        const Color(0xFFFFF8DC).withValues(alpha: 0.5), // Cornsilk
      ];
    } else if (brightness == Brightness.dark) {
      // Dark theme - sophisticated dark with subtle green hints
      return [
        const Color(0xFF263238).withValues(alpha: 0.9), // Blue grey 800
        const Color(0xFF37474F).withValues(alpha: 0.8), // Blue grey 700
        const Color(0xFF455A64).withValues(alpha: 0.7), // Blue grey 600
        const Color(0xFF546E7A).withValues(alpha: 0.5), // Blue grey 500
      ];
    } else {
      // Light theme - clean modern blues/greys matching app theme
      final primary = colorScheme.primary;
      return [
        primary.withValues(alpha: 0.8),
        primary.withValues(alpha: 0.6),
        primary.withValues(alpha: 0.4),
        primary.withValues(alpha: 0.2),
      ];
    }
  }
}

/// Minimalist header content with clean design
class _MinimalistHeaderContent extends StatefulWidget {
  final Book book;

  const _MinimalistHeaderContent({
    required this.book,
  });

  @override
  State<_MinimalistHeaderContent> createState() => _MinimalistHeaderContentState();
}

class _MinimalistHeaderContentState extends State<_MinimalistHeaderContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutExpo),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutExpo));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Enhanced mathematical calculation for premium layout
    final isCompactScreen = screenWidth < 375;
    final isTablet = screenWidth > 600;
    
    // Premium spacing and proportions
    final horizontalPadding = isCompactScreen ? 20.0 : 24.0;
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final contentSpacing = isCompactScreen ? 18.0 : 22.0;
    
    // Airbnb-style prominent cover sizing for visual impact
    final coverWidthRatio = isCompactScreen ? 0.38 : (isTablet ? 0.32 : 0.42); // Significantly increased
    final coverWidth = availableWidth * coverWidthRatio;
    
    // Larger book proportions for Airbnb-style prominence
    final maxCoverHeight = screenHeight * 0.20; // Increased from 0.16
    final calculatedHeight = coverWidth * 1.45; // Slightly adjusted ratio
    final coverHeight = calculatedHeight > maxCoverHeight ? maxCoverHeight : calculatedHeight;
    final finalCoverWidth = coverHeight > calculatedHeight ? coverWidth : coverHeight / 1.45;
    
    // Text area calculations
    final textAreaWidth = availableWidth - finalCoverWidth - contentSpacing;
    
    // Premium typography scaling
    final titleFontSize = isCompactScreen ? 20.0 : (isTablet ? 28.0 : 24.0);
    final authorFontSize = isCompactScreen ? 14.0 : (isTablet ? 18.0 : 16.0);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Airbnb-style book cover with clean shadows
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16), // Slightly more rounded for Airbnb style
                  boxShadow: [
                    // Airbnb-style shadow - cleaner and more subtle
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: _CleanBookCover(
                  book: widget.book,
                  width: finalCoverWidth,
                  height: coverHeight,
                ),
              ),

              SizedBox(width: contentSpacing),

              // Enhanced book info with premium typography
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium title with enhanced styling
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        widget.book.title ?? 'Unknown Title',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                          letterSpacing: -0.5,
                        ),
                        maxLines: isCompactScreen ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Enhanced author styling
                    if (widget.book.author != null && widget.book.author!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          'by ${widget.book.author!}',
                          style: GoogleFonts.inter(
                            fontSize: authorFontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.3,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Premium tags with enhanced spacing
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      child: _BookTags(
                        book: widget.book,
                        maxWidth: textAreaWidth,
                        isCompact: isCompactScreen,
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

/// Clean book cover design
class _CleanBookCover extends StatelessWidget {
  final Book book;
  final double width;
  final double height;

  const _CleanBookCover({
    required this.book,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'book-cover-${book.id}',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: book.thumbnailUrl != null && book.thumbnailUrl!.isNotEmpty
            ? OptimizedCachedImage(
                imageUrl: book.thumbnailUrl!,
                fit: BoxFit.cover,
                cacheKey: 'book_thumbnail_${book.id}',
                placeholderBuilder: (context, url) => _CoverPlaceholder(),
                errorBuilder: (context, url, error) => _CoverError(),
              )
            : _CoverPlaceholder(),
        ),
      ),
    );
  }
}

/// Reusable cover placeholder
class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[200]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 40, color: Colors.white),
          SizedBox(height: 8),
          Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Reusable cover error widget
class _CoverError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[200]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
          SizedBox(height: 8),
          Text('No Cover', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Optimized book tags widget using Firebase tags
class _BookTags extends StatelessWidget {
  final Book book;
  final double? maxWidth;
  final bool isCompact;

  const _BookTags({
    required this.book,
    this.maxWidth,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tags = _getBookTags();
    
    if (tags.isEmpty) return const SizedBox.shrink();
    
    // Responsive tag limits and spacing
    final maxTags = isCompact ? 3 : 4;
    final tagSpacing = isCompact ? 4.0 : 6.0;
    final runSpacing = isCompact ? 4.0 : 6.0;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: Wrap(
        spacing: tagSpacing,
        runSpacing: runSpacing,
        children: tags.take(maxTags).map((tag) => _CleanTag(
          tag,
          isCompact: isCompact,
        )).toList(),
      ),
    );
  }

  List<String> _getBookTags() {
    final tags = <String>[];
    
    // Primary tags from Firebase tags field
    if (book.tags != null && book.tags!.isNotEmpty) {
      tags.addAll(book.tags!);
    }
    
    // Additional tags from additionalFields
    if (book.additionalFields['tags'] != null) {
      if (book.additionalFields['tags'] is List) {
        tags.addAll((book.additionalFields['tags'] as List).cast<String>());
      } else if (book.additionalFields['tags'] is String) {
        tags.addAll(book.additionalFields['tags'].toString().split(',').map((e) => e.trim()));
      }
    }
    
    // Fallback to type and language if no tags
    if (tags.isEmpty) {
      if (book.type != null && book.type!.isNotEmpty) {
        tags.add(book.type!);
      }
      if (book.defaultLanguage != null && book.defaultLanguage!.isNotEmpty) {
        tags.add(book.defaultLanguage!);
      }
    }
    
    return tags.where((tag) => tag.isNotEmpty).toSet().toList();
  }
}

/// Clean tag widget
class _CleanTag extends StatelessWidget {
  final String text;
  final bool isCompact;

  const _CleanTag(this.text, {this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    // Responsive tag styling
    final horizontalPadding = isCompact ? 8.0 : 10.0;
    final verticalPadding = isCompact ? 3.0 : 4.0;
    final fontSize = isCompact ? 10.0 : 11.0;
    final borderRadius = isCompact ? 10.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
} 