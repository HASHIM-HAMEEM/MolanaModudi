import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/route_names.dart'; // Import RouteNames

// import '../../../../core/constants/app_palette.dart'; // FIXME: File missing
// import '../../../../generated/assets.gen.dart'; // FIXME: File missing or build_runner not run
// import '../../../settings/presentation/provider/theme_provider.dart'; // FIXME: File missing
import '../providers/home_notifier.dart';
import '../providers/home_state.dart';
// Import our new BooksGrid component
import '../widgets/category_grid.dart'; // Import our new CategoryGrid component
import '../widgets/video_lectures_section.dart'; // Import our new widget
// Import VideosScreen
// import '../widgets/recent_article_card.dart'; // FIXME: File missing
// import '../widgets/section_header.dart'; // FIXME: File missing
// import '../widgets/video_lecture_card.dart'; // FIXME: File missing
// import '../widgets/welcome_banner.dart'; // FIXME: File missing
import '../../../../core/providers/books_providers.dart'; // Import books providers
import '../../../../core/utils/app_logger.dart'; // Import AppLogger

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearchActive = false;
  final TextEditingController _searchQueryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Fetch data when the screen initializes
    Future.microtask(() => ref.read(homeNotifierProvider.notifier).loadHomeData());
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToSearchScreen(String query) {
    if (query.trim().isEmpty) return;
    // Ensure search is deactivated when navigating away
    // and text field is cleared for next time.
    setState(() {
      _isSearchActive = false;
    });
    final encodedQuery = Uri.encodeComponent(query.trim());
    // Using goNamed for clarity with query parameters
    context.goNamed(RouteNames.search, queryParameters: {'q': encodedQuery});
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);
    // FIXME: themeNotifierProvider is undefined due to missing import
    // final isDarkMode = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // Temporary fallback

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857), // emerald-700
        foregroundColor: Colors.white,
        leading: _isSearchActive
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearchActive = false;
                    _searchQueryController.clear();
                    _searchFocusNode.unfocus(); // Explicitly unfocus
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  // Placeholder for drawer functionality
                  // Scaffold.of(context).openDrawer(); 
                  AppLogger.logUserAction("HomeScreen", "Menu button tapped");
                },
              ),
        title: _isSearchActive
            ? TextField(
                controller: _searchQueryController,
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search books, videos...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onSubmitted: _navigateToSearchScreen,
              )
            : const Text('Maulana Maududi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: _isSearchActive
            ? [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchQueryController.clear();
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearchActive = true;
                      // Focus will be handled by autofocus: true on TextField
                      // and explicitly if needed after build if autofocus is tricky
                      // WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
                    });
                  },
                ),
              ],
      ),
      body: _buildBody(context, homeState),
      // FIXME: BottomNavBar is undefined due to missing import
      // bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    switch (state.status) {
      case HomeStatus.loading:
        return const Center(child: CircularProgressIndicator());
      
      case HomeStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load content',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(state.errorMessage ?? 'Unknown error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(homeNotifierProvider.notifier).loadHomeData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      
      case HomeStatus.success:
      case HomeStatus.initial:
        return RefreshIndicator(
          onRefresh: () => ref.read(homeNotifierProvider.notifier).loadHomeData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner (matching React example)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669), // emerald-600
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Welcome to Maulana Maududi's Works",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Explore the comprehensive collection",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Featured Books with "View All" header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Books',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go(RouteNames.library);
                          },
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  color: const Color(0xFF047857), // emerald-700
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Color(0xFF047857), // emerald-700
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Use BooksGrid with Firebase data
                  Consumer(
                    builder: (context, ref, child) {
                      final featuredBooksAsync = ref.watch(featuredBooksProvider);
                      
                      return featuredBooksAsync.when(
                        loading: () => const SizedBox(
                          height: 260,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => SizedBox(
                          height: 260,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(height: 8),
                                Text('Error loading featured books'),
                                TextButton(
                                  onPressed: () => ref.refresh(featuredBooksProvider),
                                  child: const Text('Retry'),
                                )
                              ],
                            ),
                          ),
                        ),
                        data: (books) {
                          if (books.isEmpty) {
                            return const SizedBox(
                              height: 260,
                              child: Center(child: Text('No featured books available')),
                            );
                          }
                          
                          return SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                return Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 16),
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
                                        AspectRatio(
                                          aspectRatio: 3/4,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: book.thumbnailUrl != null && book.thumbnailUrl!.isNotEmpty
                                                  ? Image.network(
                                                      book.thumbnailUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const Center(
                                                        child: Icon(Icons.broken_image, color: Colors.grey),
                                                      ),
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                                      },
                                                    )
                                                  : const Center(
                                                      child: Icon(Icons.book, color: Colors.grey),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          book.title ?? 'Untitled',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        // Author (if available)
                                        if (book.author != null)
                                          Text(
                                            book.author!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
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
                  
                  const SizedBox(height: 24),
                  
                  // Categories with our new CategoryGrid component
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Header with View All button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Categories',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to categories screen
                                context.go(RouteNames.library);
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'View All',
                                    style: TextStyle(
                                      color: const Color(0xFF047857), // emerald-700
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: Color(0xFF047857), // emerald-700
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
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
                  const SizedBox(height: 24),
                  
                  // Video Lectures section - using custom widget
                  const VideoLecturesSection(),
                  
                  // Further reduce the gap between Video Lectures and Biography section
                  const SizedBox(height: 8),
                  
                  // Biography Card - styled like the React example
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Maulana Maududi',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Abul A'la Maududi was an influential Islamic scholar, theologian, and political thinker who founded the Jamaat-e-Islami.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Read Full Biography',
                                  style: TextStyle(
                                    color: const Color(0xFF047857), // emerald-700
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: const Color(0xFF047857), // emerald-700
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Articles - modernized with card UI
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Recent Articles',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'The Islamic State: Principles and Structure',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "An analysis of Maududi's political thought and his vision for governance.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '7 min read',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
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
                                    color: const Color(0xFF047857), // emerald-700
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Removed 'Browse All Books' banner as requested
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
    }
  }
}
