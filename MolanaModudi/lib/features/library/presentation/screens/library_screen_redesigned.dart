import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';

import '../../../../routes/route_names.dart';
import '../widgets/book_grid_item.dart';
import '../widgets/book_list_item.dart';
import '../../../../core/themes/maududi_theme.dart';
import '../../../../core/themes/app_color.dart';
import '../../../books/presentation/providers/library_books_provider.dart';
import '../../../books/data/models/book_models.dart';
import '../../../books/data/models/library_state.dart';
import '../../../home/domain/services/book_categorization_service.dart';

final _log = Logger('LibraryScreenRedesigned');

// View modes for the library
enum LibraryViewMode { grid, list, carousel }

class LibraryScreenRedesigned extends ConsumerStatefulWidget {
  const LibraryScreenRedesigned({super.key});

  @override
  ConsumerState<LibraryScreenRedesigned> createState() => _LibraryScreenRedesignedState();
}

class _LibraryScreenRedesignedState extends ConsumerState<LibraryScreenRedesigned> 
    with SingleTickerProviderStateMixin {
  // View mode with carousel as default for a more visual experience
  LibraryViewMode _viewMode = LibraryViewMode.carousel;
  
  // Controllers
  final ScrollController _scrollController = ScrollController();
  
  // Animation controller for transitions
  late AnimationController _animationController;
  
  // State variables
  bool _isFilterExpanded = false;
  
  // Filter options
  String _selectedLanguage = 'all';
  String _selectedCategory = 'all';
  
  // Language options with code mapping for better display
  final Map<String, String> _languageMap = {
    'all': 'All Languages',
    'eng': 'English',
    'urd': 'Urdu',
    'ara': 'Arabic',
  };
  
  // Categories with icons for better visual representation
  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All Categories', 'icon': Icons.category},
    {'id': 'tafsir', 'name': 'Tafsir', 'icon': Icons.menu_book},
    {'id': 'islamic_law', 'name': 'Islamic Law', 'icon': Icons.balance},
    {'id': 'biography', 'name': 'Biography', 'icon': Icons.person},
    {'id': 'political_thought', 'name': 'Political Thought', 'icon': Icons.account_balance},
    {'id': 'aqeedah', 'name': 'Aqeedah', 'icon': Icons.lightbulb},
    {'id': 'spirituality', 'name': 'Spirituality', 'icon': Icons.spa},
    {'id': 'dawah', 'name': 'Dawah', 'icon': Icons.campaign},
    {'id': 'education', 'name': 'Education', 'icon': Icons.school},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers and listeners
    _scrollController.addListener(_onScroll);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Schedule initialization after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromRoute();
    });
  }
  
  void _initializeFromRoute() {
    final GoRouterState routerState = GoRouterState.of(context);
    final String? categoryParam = routerState.uri.queryParameters['category'];
    final String? languageParam = routerState.uri.queryParameters['language'];
    
    // Get category from route if provided
    final String? categoryFromRoute = GoRouterState.of(context).uri.queryParameters['category'];
    if (categoryFromRoute != null && categoryFromRoute.isNotEmpty) {
      _selectedCategory = categoryFromRoute;
      _log.info('Category selected from route: $_selectedCategory');
    }
    
    if (categoryParam != null && categoryParam.isNotEmpty) {
      final matchingCategory = _categories.firstWhere(
        (cat) => cat['id'] == categoryParam.toLowerCase(),
        orElse: () => _categories[0],
      );
      _selectedCategory = matchingCategory['id'];
    }
    
    if (languageParam != null && languageParam.isNotEmpty) {
      if (_languageMap.containsKey(languageParam.toLowerCase())) {
        _selectedLanguage = languageParam.toLowerCase();
      }
    }
    
    // Load books with selected filters
    _loadBooks();
  }
  
  // Get the category name for display in the app bar
  String _getCategoryDisplayName(String categoryId) {
    if (categoryId == 'all') return 'Library';
    
    // Convert 'tafsir' to 'tafseer' if needed for compatibility
    String normalizedCategoryId = categoryId;
    if (normalizedCategoryId == 'tafsir') {
      normalizedCategoryId = 'tafseer';
    }
    
    // Get category data from BookCategorizationService
    final categories = BookCategorizationService.getPredefinedCategories();
    final category = categories.firstWhere(
      (cat) => cat['id'] == normalizedCategoryId,
      orElse: () => {'name': 'Library'},
    );
    
    return category['name'] as String;
  }
  
  void _loadBooks() {
    // First load all books if we're filtering by category (except 'all')
    if (_selectedCategory != 'all') {
      // For category filtering, we'll load all books first and then filter them in the UI
      // This ensures we have books to show even if Firebase doesn't have specific category tags
      ref.read(libraryBooksProvider.notifier).loadBooks(
        languageCode: _selectedLanguage == 'all' ? null : _selectedLanguage,
        // Don't pass category to load all books
      );
    } else {
      // For 'all' category or language-only filtering, use the normal approach
      ref.read(libraryBooksProvider.notifier).loadBooks(
        languageCode: _selectedLanguage == 'all' ? null : _selectedLanguage,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
    }
  }
  
  void _onScroll() {
    // Load more books when reaching near the end of the list
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(libraryBooksProvider);
      if (state is LibraryStateData && !state.isLoadingMore && state.lastDocument != null) {
        ref.read(libraryBooksProvider.notifier).loadMoreBooks(
          languageCode: _selectedLanguage == 'all' ? null : _selectedLanguage,
          category: _selectedCategory == 'all' ? null : _selectedCategory,
        );
      }
    }
  }
  
  void _toggleFilterPanel() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
      if (_isFilterExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  void _selectCategory(String categoryId) {
    if (_selectedCategory == categoryId) return;
    
    setState(() {
      _selectedCategory = categoryId;
      _animationController.forward(from: 0.0);
    });
    
    _loadBooks();
  }
  
  void _selectLanguage(String languageCode) {
    if (_selectedLanguage == languageCode) return;
    
    setState(() {
      _selectedLanguage = languageCode;
      _animationController.forward(from: 0.0);
    });
    
    _loadBooks();
  }
  
  void _changeViewMode(LibraryViewMode mode) {
    if (_viewMode == mode) return;
    
    setState(() {
      _viewMode = mode;
      _animationController.forward(from: 0.0);
    });
  }
  
  // Navigate to book detail
  void _navigateToBookDetail(Book book) {
    context.goNamed(
      'libraryBookDetail',
      pathParameters: {'bookId': book.id.toString()},
    );
  }

  /// Navigate to unified search screen for library search
  void _navigateToLibrarySearch() {
    context.go('/search/library');
  }

  @override
  void dispose() {
    // Clean up resources
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Filter books based on search query and filters
  List<Book> _filterBooksForDisplay(List<Book> books) {
    // First apply search filter if there's a query
    List<Book> filteredBooks = books;
    
    // Apply category filtering in the UI if a specific category is selected
    if (_selectedCategory != 'all') {
      _log.info('Filtering books for category: $_selectedCategory');
      _log.info('Total books before filtering: ${filteredBooks.length}');
      
      // Get the category ID - convert 'tafsir' to 'tafseer' if needed for compatibility
      String categoryId = _selectedCategory;
      if (categoryId == 'tafsir') {
        categoryId = 'tafseer';
      }
      
      // Filter books using BookCategorizationService
      final List<Book> matchedBooks = [];
      
      for (final book in filteredBooks) {
        final bookCategory = BookCategorizationService.getCategoryForBook(book);
        if (bookCategory == categoryId) {
          matchedBooks.add(book);
          _log.info('Book "${book.title}" matched category $categoryId');
        }
      }
      
      // Use the matched books if we found any
      if (matchedBooks.isNotEmpty) {
        filteredBooks = matchedBooks;
        _log.info('Found ${matchedBooks.length} books for category $categoryId');
      } else {
        // If no books matched the category, show a message but keep some books visible
        _log.info('No books matched category $categoryId, showing all books as fallback');
        // We'll keep the original list but show a message in the UI
      }
      
      _log.info('Total books after filtering for $categoryId: ${filteredBooks.length}');
      
      // If no books match the category, add some fallback books to ensure something is displayed
      if (filteredBooks.isEmpty) {
        _log.info('No books matched category $_selectedCategory, adding fallback books');
        
        // Take 3-5 random books as fallbacks
        final allBooks = books;
        if (allBooks.isNotEmpty) {
          // Shuffle the books to get random ones
          final randomBooks = List<Book>.from(allBooks)..shuffle();
          // Take up to 5 books
          final fallbackBooks = randomBooks.take(5).toList();
          filteredBooks = fallbackBooks;
          _log.info('Added ${fallbackBooks.length} fallback books for $_selectedCategory');
        }
      }
    }
    
    return filteredBooks;
  }
  
  // Build the app bar with search functionality
  AppBar _buildAppBar(ThemeData theme) {
    // Determine if we're in dark mode
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    // Get appropriate colors based on theme
    final backgroundColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia 
            : AppColor.surface;
    
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;
    
    // Get the display title based on selected category
    final String displayTitle = _getCategoryDisplayName(_selectedCategory);
    
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true, // Center the title
      systemOverlayStyle: isDark 
          ? SystemUiOverlayStyle.light 
          : SystemUiOverlayStyle.dark,
      title: Text(
              displayTitle,
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: textColor,
              ),
            ),
      actions: [
        // Search icon button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _navigateToLibrarySearch,
          color: textColor,
          tooltip: 'Search your library',
        ),
      ],
    );
  }
  
  // No sort options sheet needed
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Consumer(builder: (context, ref, child) {
        final libraryState = ref.watch(libraryBooksProvider);
        
        return libraryState.maybeWhen(
          loading: () => _buildLoadingState(),
          error: (message) => _buildErrorState(message, theme),
          data: (books, lastUpdated, lastDoc, isLoadingMore, error) {
            // Filter books based on search query
            List<Book> filteredBooks = _filterBooksForDisplay(books);
            
            return _buildMainContent(filteredBooks, isLoadingMore, error, theme);
          },
          orElse: () => _buildLoadingState(), // Add the required orElse parameter
        );
      }),
      // No floating action button
    );
  }
  
  // Build main content based on selected view mode with perfect theme integration
  Widget _buildMainContent(List<Book> books, bool isLoadingMore, String? error, ThemeData theme) {
    // Filter books based on search query and selected filters
    final filteredBooks = _filterBooksForDisplay(books);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    // Show empty state if no books match filters
    if (filteredBooks.isEmpty && !isLoadingMore) {
      return _buildEmptyState(theme);
    }
    
    // Build content based on selected view mode
    return Column(
      children: [
        // View mode selector with enhanced styling and animations
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          decoration: BoxDecoration(
            color: isSepia
                ? AppColor.backgroundSepia.withValues(alpha: 0.3)
                : isDark
                    ? theme.colorScheme.surface.withValues(alpha: 0.3)
                    : theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: isSepia
                    ? AppColor.primarySepia.withValues(alpha: 0.1)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildViewModeButton(
                icon: Icons.grid_view_rounded,
                mode: LibraryViewMode.grid,
                tooltip: 'Grid',
                theme: theme,
              ),
              const SizedBox(width: 8.0),
              _buildViewModeButton(
                icon: Icons.view_list_rounded,
                mode: LibraryViewMode.list,
                tooltip: 'List',
                theme: theme,
              ),
              const SizedBox(width: 8.0),
              _buildViewModeButton(
                icon: Icons.view_carousel_rounded,
                mode: LibraryViewMode.carousel,
                tooltip: 'Carousel',
                theme: theme,
              ),
            ],
          ),
        ),
        
        // Content based on view mode with smooth transitions
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _viewMode == LibraryViewMode.grid
                ? _buildGridView(filteredBooks, isLoadingMore, error)
                : _viewMode == LibraryViewMode.list
                    ? _buildListView(filteredBooks, isLoadingMore, error)
                    : _buildCarouselView(filteredBooks, isLoadingMore, error),
          ),
        ),
      ],
    );
  }
  
  // Build a view mode button with perfect theme integration
  Widget _buildViewModeButton({
    required IconData icon,
    required LibraryViewMode mode,
    required String tooltip,
    required ThemeData theme,
  }) {
    final isSelected = _viewMode == mode;
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    // Use CardStyles from theme extensions for consistent styling
    final cardStyles = EnhancedTheme.cardStyles(context);
    
    // Theme-specific colors
    final primaryColor = isSepia ? AppColor.primarySepia : theme.colorScheme.primary;
    final surfaceColor = isSepia ? AppColor.surfaceSepia : theme.colorScheme.surface;
    final textColor = isSepia ? AppColor.textPrimarySepia : theme.colorScheme.onSurface;
    
    // Container decoration based on selection state and theme
    final decoration = isSelected
        ? BoxDecoration(
            color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.7 : 0.8),
              width: 1.5,
            ),
          )
        : BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          );
    
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 800),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _changeViewMode(mode),
            borderRadius: BorderRadius.circular(12),
            splashColor: primaryColor.withValues(alpha: 0.1),
            highlightColor: primaryColor.withValues(alpha: 0.05),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 12, 
                vertical: isSelected ? 9 : 8,
              ),
              decoration: decoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with theme-aware coloring
                  Icon(
                    icon,
                    color: isSelected 
                        ? primaryColor
                        : textColor.withValues(alpha: isDark ? 0.8 : 0.65),
                    size: isSelected ? 20 : 18,
                  ),
                  // Animated width for text appearance/disappearance
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: isSelected
                        ? Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                tooltip,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build the grid view with perfect theme integration and animations
  Widget _buildGridView(List<Book> books, bool isLoadingMore, String? error) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        controller: _scrollController, // Keep the scroll controller for pagination
        padding: const EdgeInsets.only(top: 20.0, bottom: 28.0),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Adjusted for better book cover proportions
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 20.0,
        ),
        itemCount: books.length + (isLoadingMore ? 1 : 0), // Add loading indicator if loading more
        itemBuilder: (context, index) {
          // Show loading indicator at the end when loading more
          if (index == books.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isSepia 
                        ? AppColor.primarySepia 
                        : theme.colorScheme.primary,
                    backgroundColor: isDark 
                        ? Colors.grey[800] 
                        : isSepia 
                            ? AppColor.backgroundSepia.withValues(alpha: 0.2)
                            : Colors.grey[200],
                  ),
                ),
              ),
            );
          }
          
          final book = books[index];
          // Calculate staggered animation delay based on position
          final delay = Duration(milliseconds: 30 * (index % 4) + 50 * (index ~/ 2));
          
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 2,
            duration: const Duration(milliseconds: 350),
            child: ScaleAnimation(
              scale: 0.94,
              child: FadeInAnimation(
                child: BookGridItem(
                  book: book,
                  onTap: () => _navigateToBookDetail(book),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // List view of books
  Widget _buildListView(List<Book> books, bool isLoadingMore, String? error) {
    return AnimationLimiter(
      child: ListView.builder(
        key: const PageStorageKey('list_view'),
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: books.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the end when loading more
          if (index == books.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final book = books[index];
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: BookListItem(
                    book: book,
                    onTap: () => _navigateToBookDetail(book),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Carousel view of books
  Widget _buildCarouselView(List<Book> books, bool isLoadingMore, String? error) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recently viewed section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recently Viewed',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.take(5).length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => context.goNamed(
                    RouteNames.bookDetailItem,
                    pathParameters: {'bookId': book.id.toString()},
                  ),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book cover
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: book.thumbnailUrl ?? '',
                              fit: BoxFit.cover,
                              width: 120,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Book title
                        Text(
                          book.title ?? 'Untitled',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Book author
                        Text(
                          book.author ?? 'Unknown Author',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // All books section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'All Books',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: AnimationLimiter(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (screenWidth / 180).floor().clamp(2, 4),
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: books.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == books.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final book = books[index];
                
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  columnCount: (screenWidth / 180).floor().clamp(2, 4),
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: BookGridItem(
                        book: book,
                        onTap: () => context.goNamed(
                          RouteNames.bookDetailItem,
                          pathParameters: {'bookId': book.id.toString()},
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  // Empty state when no books match the filters
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: AnimationLimiter(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              Icon(
                Icons.menu_book,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No books in your library',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Add books to your library to see them here',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
                ElevatedButton.icon(
                onPressed: () => ref.read(libraryBooksProvider.notifier).refreshBooks(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading state with shimmer effect
  Widget _buildLoadingState() {
    return AnimationLimiter(
      child: Column(
        children: [
          // Filter panel placeholder
          Container(
            height: 60,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          
          // Book grid placeholders
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 10, // Show 10 shimmer items
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  columnCount: 2,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildShimmerItem(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Shimmer loading effect for book items
  Widget _buildShimmerItem() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 16,
              width: double.infinity,
              color: isDark ? Colors.grey[700] : Colors.grey[350],
            ),
          ),
          const SizedBox(height: 8),
          // Author placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 12,
              width: 100,
              color: isDark ? Colors.grey[700] : Colors.grey[350],
            ),
          ),
        ],
      ),
    );
  }
  
  // Error state
  Widget _buildErrorState(String message, ThemeData theme) {
    return Center(
      child: AnimationLimiter(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Unable to load your library',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(libraryBooksProvider.notifier).refreshBooks(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Filter panel with language and category options
  Widget _buildFilterPanel(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? 120 : 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with view mode toggles and filter button
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // View mode toggles
                  ToggleButtons(
                    onPressed: (index) {
                      _changeViewMode(LibraryViewMode.values[index]);
                    },
                    isSelected: [
                      _viewMode == LibraryViewMode.grid,
                      _viewMode == LibraryViewMode.list,
                      _viewMode == LibraryViewMode.carousel,
                    ],
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minHeight: 36, minWidth: 40),
                    children: const [
                      Icon(Icons.grid_view, size: 20),
                      Icon(Icons.view_list, size: 20),
                      Icon(Icons.view_carousel, size: 20),
                    ],
                  ),
                  const Spacer(),
                  // Filter button
                  TextButton.icon(
                    onPressed: _toggleFilterPanel,
                    icon: Icon(
                      _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                      size: 20,
                    ),
                    label: Text(_isFilterExpanded ? 'Hide Filters' : 'Show Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded filter options
          if (_isFilterExpanded)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    // Language filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Language', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            underline: Container(
                              height: 1,
                              color: theme.colorScheme.primary,
                            ),
                            onChanged: (value) {
                              if (value != null) _selectLanguage(value);
                            },
                            items: _languageMap.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Category filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            underline: Container(
                              height: 1,
                              color: theme.colorScheme.primary,
                            ),
                            onChanged: (value) {
                              if (value != null) _selectCategory(value);
                            },
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category['id'],
                                child: Row(
                                  children: [
                                    Icon(category['icon'], size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        category['name'],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
