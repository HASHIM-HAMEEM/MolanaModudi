import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/route_names.dart'; // Import RouteNames
import 'package:modudi/core/l10n/app_localizations_wrapper.dart'; // Import AppLocalizations
import '../../../../core/themes/app_color.dart'; // Import AppColor from themes
import '../widgets/optimized_book_thumbnail.dart';
import '../providers/cached_featured_books_provider.dart';
import '../services/thumbnail_preloader_service.dart';
import '../widgets/banner_carousel.dart';
import '../providers/home_state.dart';
// Import specific providers from home_notifier to avoid conflicts
import '../providers/home_notifier.dart' as home_notifier;
// Import our new BooksGrid component
import '../widgets/category_grid.dart'; // Import our new CategoryGrid component
import '../widgets/video_lectures_section.dart'; // Import our new widget
// Import VideosScreen
// import '../widgets/recent_article_card.dart'; // FIXME: File missing
// import '../widgets/section_header.dart'; // FIXME: File missing
// import '../widgets/video_lecture_card.dart'; // FIXME: File missing
// import '../widgets/welcome_banner.dart'; // FIXME: File missing
import '../../../../core/utils/app_logger.dart'; // Import AppLogger

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key = const ValueKey('home_screen')});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Track if we've already loaded data to prevent excessive reloads
  static bool _hasLoadedHomeData = false;
  
  @override
  void initState() {
    super.initState();
    
    // Optimized: Only trigger loading if providers aren't already loaded
      Future.microtask(() {
      // Check if individual providers have data before triggering load
      final featuredBooksState = ref.read(home_notifier.featuredBooksProvider(20));
      final categoriesState = ref.read(home_notifier.categoriesProvider);
      final videosState = ref.read(home_notifier.videoLecturesProvider(10));
      
      // Only load if all providers are in initial state or error
      final needsLoading = featuredBooksState.hasValue == false || 
                          categoriesState.hasValue == false || 
                          videosState.hasValue == false;
      
      if (needsLoading && !_hasLoadedHomeData) {
        ref.read(home_notifier.homeNotifierProvider.notifier).loadHomeData();
        _hasLoadedHomeData = true;
      }
      });
  }

  /// Navigate to unified search screen for global search
  void _navigateToGlobalSearch() {
    context.go('/search/global');
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(home_notifier.homeNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    // Theme-aware colors
    final backgroundColor = isDark 
        ? AppColor.backgroundDark 
        : isSepia 
            ? AppColor.backgroundSepia 
            : const Color(0xFFFAFAFA);
            
    final appBarColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia 
            : Colors.white;
            
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : const Color(0xFF222222);
            
    final searchIconColor = isDark
        ? const Color(0xFF10B981) // Lighter green for dark mode
        : isSepia
            ? const Color(0xFF047857) // Darker green for sepia
            : const Color(0xFF059669); // Standard green for light
            
    final searchBgColor = isDark
        ? searchIconColor.withOpacity(0.15)
        : isSepia
            ? searchIconColor.withOpacity(0.12)
            : searchIconColor.withOpacity(0.08);
            
    final searchBorderColor = isDark
        ? searchIconColor.withOpacity(0.2)
        : isSepia
            ? searchIconColor.withOpacity(0.15)
            : searchIconColor.withOpacity(0.12);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.menu, color: textColor),
          onPressed: () {
            // Placeholder for drawer functionality
            // Scaffold.of(context).openDrawer(); 
            AppLogger.logUserAction("HomeScreen", "Menu button tapped");
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.homeScreenAppBarTitle, 
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textColor,
            letterSpacing: -0.5,
          )
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: searchBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: searchBorderColor,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search, 
                color: searchIconColor,
                size: 20,
              ),
            ),
            onPressed: _navigateToGlobalSearch,
            tooltip: 'Search books, chapters, and videos',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(context, homeState),
      // FIXME: BottomNavBar is undefined due to missing import
      // bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    // Theme-aware colors
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : const Color(0xFF222222);
            
    final primaryGreen = isDark
        ? const Color(0xFF10B981) // Lighter green for dark mode
        : isSepia
            ? const Color(0xFF047857) // Darker green for sepia
            : const Color(0xFF059669); // Standard green for light
    
    switch (state.status) {
      case HomeStatus.loading:
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: primaryGreen,
          )
        );
      
      case HomeStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColor.surfaceDark.withOpacity(0.5)
                        : isSepia 
                            ? AppColor.surfaceSepia.withOpacity(0.5)
                            : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.error_outline, 
                    color: isDark 
                        ? AppColor.textSecondaryDark 
                        : isSepia 
                            ? AppColor.textSecondarySepia 
                            : const Color(0xFF717171),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.homeScreenFailedToLoadContent,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? AppLocalizations.of(context)!.homeScreenUnknownError,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark 
                        ? AppColor.textSecondaryDark 
                        : isSepia 
                            ? AppColor.textSecondarySepia 
                            : const Color(0xFF717171),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(home_notifier.homeNotifierProvider.notifier).loadHomeData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.homeScreenRetryButton,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      
      case HomeStatus.success:
      case HomeStatus.initial:
        return RefreshIndicator(
          onRefresh: () async {
            // Clear the cache and refresh data
            await ref.read(cachedFeaturedBooksProvider.notifier).refresh();
            // Also refresh other home data
            await ref.read(home_notifier.homeNotifierProvider.notifier).loadHomeData(forceRefresh: true);
          },
          color: primaryGreen,
          child: SingleChildScrollView(
            key: const PageStorageKey('homeScreenScrollable'),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16), // Reduced top spacing
                
                // Banner Carousel (Welcome + Continue Reading)
                const BannerCarousel(),
                
                const SizedBox(height: 36), // Slightly reduced spacing
                
                // Featured Books with "View All" header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.homeScreenFeaturedBooksTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(RouteNames.library);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.homeScreenViewAllButton,
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16), // Consistent spacing
                
                // Use optimized featured books with better caching
                Consumer(
                  builder: (context, ref, child) {
                    final featuredBooksAsync = ref.watch(cachedFeaturedBooksProvider);
                    
                    return featuredBooksAsync.when(
                      loading: () => SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryGreen,
                          )
                        ),
                      ),
                      error: (err, stack) => SizedBox(
                        height: 300,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? AppColor.surfaceDark.withOpacity(0.5)
                                        : isSepia 
                                            ? AppColor.surfaceSepia.withOpacity(0.5)
                                            : const Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.error_outline, 
                                    color: isDark 
                                        ? AppColor.textSecondaryDark 
                                        : isSepia 
                                            ? AppColor.textSecondarySepia 
                                            : const Color(0xFF717171),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.homeScreenErrorLoadingFeaturedBooks,
                                  style: TextStyle(
                                    color: isDark 
                                        ? AppColor.textSecondaryDark 
                                        : isSepia 
                                            ? AppColor.textSecondarySepia 
                                            : const Color(0xFF717171),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    ref.read(cachedFeaturedBooksProvider.notifier).refresh();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    backgroundColor: primaryGreen.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.homeScreenRetryButton,
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      data: (books) {
                        if (books.isEmpty) {
                          return SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.homeScreenNoFeaturedBooks,
                                style: TextStyle(
                                  color: isDark 
                                      ? AppColor.textSecondaryDark 
                                      : isSepia 
                                          ? AppColor.textSecondarySepia 
                                          : const Color(0xFF717171),
                                  fontSize: 14,
                                ),
                              )
                            ),
                          );
                        }
                        
                        // Preload thumbnails in the background
                        Future.microtask(() {
                          ThumbnailPreloaderService.preloadThumbnails(books, ref);
                        });
                        
                        return SizedBox(
                          height: 300,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return Container(
                                width: 160,
                                margin: EdgeInsets.only(
                                  right: index == books.length - 1 ? 0 : 20,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    // Log the book click using AppLogger
                                    AppLogger.logUserAction('HomeScreen', 'book_clicked', 
                                      details: {'bookId': book.firestoreDocId, 'title': book.title});
                                    
                                    // Use bookDetailItem route that shows BookDetailScreen instead of firebase-book route
                                    context.goNamed(
                                      RouteNames.bookDetailItem,
                                      pathParameters: {'bookId': book.firestoreDocId}
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Book Cover
                                      Container(
                                        height: 220,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: isDark ? [] : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: book.thumbnailUrl != null && book.thumbnailUrl!.isNotEmpty
                                              ? OptimizedBookThumbnail(
                                                  imageUrl: book.thumbnailUrl!,
                                                  bookId: book.firestoreDocId,
                                                  width: 160,
                                                  height: 220,
                                                  borderRadius: BorderRadius.circular(16),
                                                )
                                              : Container(
                                                  decoration: BoxDecoration(
                                                    color: isDark 
                                                        ? AppColor.surfaceDark 
                                                        : isSepia 
                                                            ? AppColor.surfaceSepia 
                                                            : const Color(0xFFF7F7F7),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.book_outlined, 
                                                      color: isDark 
                                                          ? AppColor.textSecondaryDark 
                                                          : isSepia 
                                                              ? AppColor.textSecondarySepia 
                                                              : const Color(0xFF717171),
                                                      size: 32,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Book Title
                                      Text(
                                        book.title ?? AppLocalizations.of(context)!.homeScreenUntitledBook,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: textColor,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 44), // Consistent spacing
                
                // Categories with our new CategoryGrid component
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Header with View All button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.homeScreenCategoriesTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to categories screen
                              context.go(RouteNames.library);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.homeScreenViewAllButton,
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                    decorationColor: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16), // Consistent spacing
                      
                      // Category grid with dynamic data
                      CategoryGrid(
                        categories: state.categories,
                        showTitle: false, // We already have a title above
                        onCategoryTap: (categoryId) {
                          // Navigate to category books
                          AppLogger.logUserAction('HomeScreen', 'category_tapped', 
                            details: {'categoryId': categoryId});
                            
                          // Navigate to category books screen
                          context.pushNamed(
                            RouteNames.categoryBooks,
                            pathParameters: {'categoryId': categoryId},
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 44), // Consistent spacing
                
                // Video Lectures section - using custom widget
                const VideoLecturesSection(),
                
                const SizedBox(height: 20), // Reduced spacing between video and biography from 32px to 20px
                
                // Biography Section with proper header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Biography Section Header
                      Text(
                        'About Maulana Maududi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Biography Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? AppColor.surfaceDark 
                              : isSepia 
                                  ? AppColor.surfaceSepia 
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryGreen.withOpacity(0.08),
                            width: 1,
                          ),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Abul A'la Maududi was an influential Islamic scholar, theologian, and political thinker who founded the Jamaat-e-Islami.",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark 
                                    ? AppColor.textSecondaryDark 
                                    : isSepia 
                                        ? AppColor.textSecondarySepia 
                                        : const Color(0xFF717171),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                // Navigate to biography screen
                                context.go(RouteNames.biography);
                              },
                              child: Text(
                                'Read Full Biography',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 44), // Consistent spacing
                
                // Recent Articles - modernized with card UI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppLocalizations.of(context)!.homeScreenRecentArticlesTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Consistent spacing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? AppColor.surfaceDark 
                          : isSepia 
                              ? AppColor.surfaceSepia 
                              : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryGreen.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Islamic State: Principles and Structure',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "An analysis of Maududi's political thought and his vision for governance.",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark 
                                ? AppColor.textSecondaryDark 
                                : isSepia 
                                    ? AppColor.textSecondarySepia 
                                    : const Color(0xFF717171),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '7 min read',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? AppColor.textSecondaryDark 
                                    : isSepia 
                                        ? AppColor.textSecondarySepia 
                                        : const Color(0xFF717171),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                // Read article
                              },
                              child: Text(
                                'Read Now',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  decorationColor: primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 60), // Final bottom spacing
              ],
            ),
          ),
        );
    }
  }
}
