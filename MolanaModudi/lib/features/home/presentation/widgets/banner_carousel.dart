import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/themes/app_color.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../reading/presentation/providers/live_reading_progress_provider.dart';
import '../../../reading/presentation/providers/unified_reading_progress_provider.dart';
import '../../../reading/presentation/screens/reading_tab_screen.dart';
import 'package:modudi/core/l10n/app_localizations_wrapper.dart';

/// Banner Carousel widget for the homepage
/// Shows welcome banner and continue reading banner as slides
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start animation when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final recentBooksAsyncValue = ref.watch(unifiedRecentBooksProvider);
    
    return recentBooksAsyncValue.when(
      loading: () => _buildWelcomeBanner(l10n), // Show only welcome while loading
      error: (err, stack) => _buildWelcomeBanner(l10n), // Show only welcome on error
      data: (recentBooks) {
        // If no recent books, show only welcome banner
        if (recentBooks.isEmpty) {
          return _buildWelcomeBanner(l10n);
        }
        
        // If there are recent books, show carousel with both banners
        return _buildCarousel(recentBooks.first, l10n);
      },
    );
  }

  Widget _buildWelcomeBanner(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    // Theme-aware banner background colors
    final bannerColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia // Use light cream surface instead of brown primary
            : Colors.white; // Light background for light theme
            
    // Green title color matching app UI - theme-aware
    final titleColor = isDark 
        ? const Color(0xFF10B981) // Lighter green for dark mode
        : isSepia 
            ? AppColor.textPrimarySepia // Use dark brown text on light cream background
            : const Color(0xFF059669); // Standard green for light theme
            
    final subtitleColor = isDark 
        ? AppColor.textSecondaryDark 
        : isSepia 
            ? AppColor.textSecondarySepia // Use proper sepia secondary text color
            : const Color(0xFF717171); // Dark subtitle for light theme
            
    final iconBgColor = isDark 
        ? AppColor.textPrimaryDark.withOpacity(0.15) 
        : isSepia 
            ? AppColor.textPrimarySepia.withOpacity(0.15) // Use dark brown for icon background
            : const Color(0xFF059669).withOpacity(0.08); // Light green background for light theme
            
    final iconColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia // Use dark brown for icon color
            : const Color(0xFF059669); // Green icon for light theme
    
    return FadeTransition(
      opacity: _animationController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 135, // Further increased height to show full text
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Adjusted padding
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? null : Border.all( // Add border for light theme
              color: isSepia 
                  ? AppColor.textPrimarySepia.withOpacity(0.3) // Use dark brown for sepia border
                  : const Color(0xFF059669).withOpacity(0.12),
              width: 1,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.homeScreenWelcomeTitle,
                      style: TextStyle(
                        fontSize: 19, // Keep same font size as requested
                        fontWeight: FontWeight.w600,
                        color: titleColor, // Green color
                        letterSpacing: -0.5,
                        height: 1.4, // Better line height for text wrapping
                      ),
                      maxLines: 2, // Allow 2 lines for full text
                      overflow: TextOverflow.visible, // Changed from ellipsis to visible
                      softWrap: true, // Ensure proper text wrapping
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.homeScreenWelcomeSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: 1.3, // Better line height
                      ),
                      maxLines: 1, // Reduced to 1 line to give more space to title
                      overflow: TextOverflow.ellipsis,
                      softWrap: true, // Ensure proper text wrapping
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.person_outline, 
                    color: iconColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(RecentBook recentBook, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    // Theme-aware banner background colors
    final bannerColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia // Use light cream surface instead of brown primary
            : Colors.white; // Light background for light theme
            
    // Green title color matching app UI - theme-aware
    final titleColor = isDark 
        ? const Color(0xFF10B981) // Lighter green for dark mode
        : isSepia 
            ? AppColor.textPrimarySepia // Use dark brown text on light cream background
            : const Color(0xFF059669); // Standard green for light theme
            
    final subtitleColor = isDark 
        ? AppColor.textSecondaryDark 
        : isSepia 
            ? AppColor.textSecondarySepia // Use proper sepia secondary text color
            : const Color(0xFF717171); // Dark subtitle for light theme
            
    final iconBgColor = isDark 
        ? AppColor.textPrimaryDark.withOpacity(0.15) 
        : isSepia 
            ? AppColor.textPrimarySepia.withOpacity(0.15) // Use dark brown for icon background
            : const Color(0xFF059669).withOpacity(0.08); // Light green background for light theme
            
    final iconColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia // Use dark brown for icon color
            : const Color(0xFF059669); // Green icon for light theme
            
    final cardColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia 
            : Colors.white;
            
    final cardTextColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : const Color(0xFF222222);
            
    final cardSubtitleColor = isDark 
        ? AppColor.textSecondaryDark 
        : isSepia 
            ? AppColor.textSecondarySepia 
            : const Color(0xFF717171);
    
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          SizedBox(
            height: 135, // Further increased height to show full text
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Welcome Banner (First slide)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Adjusted padding
                    decoration: BoxDecoration(
                      color: bannerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? null : Border.all( // Add border for light theme
                        color: isSepia 
                            ? AppColor.textPrimarySepia.withOpacity(0.3) // Use dark brown for sepia border
                            : const Color(0xFF059669).withOpacity(0.12),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.homeScreenWelcomeTitle,
                                style: TextStyle(
                                  fontSize: 19, // Keep same font size as requested
                                  fontWeight: FontWeight.w600,
                                  color: titleColor, // Green color
                                  letterSpacing: -0.5,
                                  height: 1.4, // Better line height for text wrapping
                                ),
                                maxLines: 2, // Allow 2 lines for full text
                                overflow: TextOverflow.visible, // Changed from ellipsis to visible
                                softWrap: true, // Ensure proper text wrapping
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.homeScreenWelcomeSubtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                  height: 1.3, // Better line height
                                ),
                                maxLines: 1, // Reduced to 1 line to give more space to title
                                overflow: TextOverflow.ellipsis,
                                softWrap: true, // Ensure proper text wrapping
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person_outline, 
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Continue Reading Banner (Second slide)
                _buildContinueReadingBanner(recentBook, cardColor, cardTextColor, cardSubtitleColor, isDark),
              ],
            ),
          ),
          
          // Page indicator dots
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(0, isDark, isSepia),
              const SizedBox(width: 12),
              _buildDot(1, isDark, isSepia),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, bool isDark, bool isSepia) {
    final activeColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.primarySepia 
            : const Color(0xFF222222);
            
    final inactiveColor = isDark 
        ? AppColor.textSecondaryDark.withOpacity(0.3) 
        : isSepia 
            ? AppColor.textSecondarySepia.withOpacity(0.3) 
            : const Color(0xFFE5E5E5);
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: _currentPage == index ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentPage == index ? activeColor : inactiveColor,
        ),
      ),
    );
  }

  Widget _buildContinueReadingBanner(RecentBook book, Color cardColor, Color cardTextColor, Color cardSubtitleColor, bool isDark) {
    final liveProgress = ref.watch(liveReadingProgressProvider(book.id));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('/read/${book.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(22), // Matched padding to prevent overflow
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Book cover thumbnail
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: book.coverUrl ?? '',
                    height: 52, // Reduced height
                    width: 40, // Reduced width
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ShimmerPlaceholder(
                      child: Container(
                        height: 52,
                        width: 40,
                        color: isDark 
                            ? AppColor.surfaceDark 
                            : const Color(0xFFF7F7F7),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 52,
                      width: 40,
                      color: isDark 
                          ? AppColor.surfaceDark 
                          : const Color(0xFFF7F7F7),
                      child: Icon(
                        Icons.book_outlined,
                        size: 20, // Reduced icon size
                        color: isDark 
                            ? AppColor.textSecondaryDark 
                            : const Color(0xFF717171),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12), // Reduced spacing
              
              // Book details and progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue Reading',
                      style: TextStyle(
                        fontSize: 14, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: cardTextColor,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 12, // Reduced font size
                        color: cardSubtitleColor,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // Reduced spacing
                    
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3, // Reduced height
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? AppColor.dividerDark 
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: liveProgress ?? 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? const Color(0xFF10B981) 
                                      : const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Reduced spacing
                        Text(
                          '${((liveProgress ?? 0.0) * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10, // Reduced font size
                            fontWeight: FontWeight.w500,
                            color: cardSubtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12), // Reduced spacing
              
              // Continue reading icon
              Container(
                width: 36, // Reduced size
                height: 36,
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColor.surfaceDark.withOpacity(0.5) 
                      : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: isDark 
                        ? AppColor.textPrimaryDark 
                        : const Color(0xFF222222),
                    size: 18, // Reduced icon size
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 