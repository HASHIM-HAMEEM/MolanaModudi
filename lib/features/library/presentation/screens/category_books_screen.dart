import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:logging/logging.dart';
import '../../../../core/themes/app_color.dart';
import '../../../../routes/route_names.dart';
import '../../../books/presentation/providers/library_books_provider.dart';
import '../../../books/data/models/book_models.dart';
import '../../../books/data/models/library_state.dart';
import '../widgets/book_grid_item.dart';
import '../../../home/domain/services/book_categorization_service.dart';

/// A screen that displays books for a specific category
class CategoryBooksScreen extends ConsumerStatefulWidget {
  final String categoryId;
  
  const CategoryBooksScreen({
    super.key,
    required this.categoryId,
  });

  @override
  ConsumerState<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends ConsumerState<CategoryBooksScreen> {
  final ScrollController _scrollController = ScrollController();
  final _log = Logger('CategoryBooksScreen');
  late String _categoryId;
  late String _categoryName;
  
  // Helper method to scale font sizes based on settings
  double _scaleFontSize(double baseSize) {
    final settingsState = ref.read(settingsProvider);
    final fontSizeMultiplier = settingsState.fontSize.size / 14.0; // Use 14.0 as the base font size
    return baseSize * fontSizeMultiplier;
  }
  
  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
    
    // Convert 'tafsir' to 'tafseer' if needed for compatibility
    if (_categoryId == 'tafsir') {
      _categoryId = 'tafseer';
    }
    
    // Get the category name for display
    _categoryName = _getCategoryDisplayName(_categoryId);
    
    _scrollController.addListener(_onScroll);
    
    // Load books when the screen initializes
    Future.microtask(() => _loadBooks());
  }
  
  // Get the category name for display in the app bar
  String _getCategoryDisplayName(String categoryId) {
    // Hardcoded category mapping for now
    final Map<String, String> categoryNames = {
      'tafsir': 'Tafsir Books',
      'islamic_law_social': 'Law & Society Books',
      'biography': 'Biography Books',
      'political_thought': 'Political Thought Books',
    };
    
    return categoryNames[categoryId] ?? 'Category Books';
  }
  
  void _loadBooks() {
    // Log that we're loading books for this category
    _log.info('Loading books for category: ${widget.categoryId}');
    
    // Load all books instead of filtering by category in the query
    // We'll filter them in the UI after loading
    ref.read(libraryBooksProvider.notifier).loadBooks();
  }
  
  void _onScroll() {
    // Load more books when reaching near the end of the list
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final libraryState = ref.read(libraryBooksProvider);
      
      if (libraryState is LibraryStateData && 
          !libraryState.isLoadingMore && 
          libraryState.lastDocument != null) {
        _log.info('Loading more books for category: $_categoryId');
        ref.read(libraryBooksProvider.notifier).loadMoreBooks();
      }
    }
  }
  
  void _navigateToBookDetail(Book book) {
    final String bookId = book.id?.toString() ?? '';
    context.pushNamed(
      RouteNames.bookDetail,
      pathParameters: {'id': bookId},
    );
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Filter books to show only those in the selected category
  List<Book> _filterBooksByCategory(List<Book> books) {
    final List<Book> matchedBooks = [];
    
    // For debugging
    _log.info('Filtering ${books.length} books for category: ${widget.categoryId}');
    
    // For the Law & Society category, we need to check for both old categories
    if (widget.categoryId == 'islamic_law_social') {
      // First pass: check if any books are already categorized as islamic_law or social_cultural
      for (final book in books) {
        final bookCategory = BookCategorizationService.getCategoryForBook(book);
        if (bookCategory == 'islamic_law' || bookCategory == 'social_cultural' || bookCategory == 'islamic_law_social') {
          matchedBooks.add(book);
        }
      }
    } else {
      // For other categories, use the standard approach
      for (final book in books) {
        final bookCategory = BookCategorizationService.getCategoryForBook(book);
        if (bookCategory == widget.categoryId) {
          matchedBooks.add(book);
        }
      }
    }
    
    // If we don't have enough books, use keyword matching as a fallback
    if (matchedBooks.length < 5) {
      for (final book in books) {
        // Skip books we've already added
        if (matchedBooks.contains(book)) continue;
        
        final String bookTitle = book.title?.toLowerCase() ?? '';
        bool shouldAdd = false;
        
        if (widget.categoryId == 'islamic_law_social') {
          // Check for law-related keywords
          final bool isLawRelated = bookTitle.contains('قانون') || // law
                                  bookTitle.contains('شریعت') || // shariah
                                  bookTitle.contains('فقہ') || // fiqh
                                  bookTitle.contains('حلال') || // halal
                                  bookTitle.contains('حرام') || // haram
                                  bookTitle.contains('معاشیات') || // economics
                                  bookTitle.contains('معاشی') || // economic
                                  bookTitle.contains('نظام') || // system
                                  bookTitle.contains('اسلامی نظام'); // Islamic system
          // Check for social-related keywords
          final bool isSocialRelated = bookTitle.contains('معاشرت') || // society
                                     bookTitle.contains('ثقافت') || // culture
                                     bookTitle.contains('سماجی') || // social
                                     bookTitle.contains('عورت') || // woman
                                     bookTitle.contains('خواتین') || // women
                                     bookTitle.contains('پردہ') || // purdah/veil
                                     bookTitle.contains('قادیانی') || // qadiani
                                     bookTitle.contains('مسئلہ') || // issue/problem
                                     bookTitle.contains('معاشرتی'); // societal
          
          shouldAdd = isLawRelated || isSocialRelated;
        } else if (widget.categoryId == 'tafsir' || widget.categoryId == 'tafseer') {
          shouldAdd = bookTitle.contains('قرآن') || // Quran
                     bookTitle.contains('تفسیر') || // tafsir
                     bookTitle.contains('آیات') || // ayat/verses
                     bookTitle.contains('سورہ') || // surah
                     bookTitle.contains('اصطلاح'); // terminology
        } else if (widget.categoryId == 'biography') {
          shouldAdd = bookTitle.contains('سیرت') || // seerah/biography
                     bookTitle.contains('حیات') || // life
                     bookTitle.contains('تاریخ') || // history
                     bookTitle.contains('مسلمانوں') || // Muslims
                     bookTitle.contains('شہادت') || // martyrdom
                     bookTitle.contains('امام'); // imam
        } else if (widget.categoryId == 'political_thought') {
          shouldAdd = bookTitle.contains('سیاسی') || // political
                     bookTitle.contains('حکومت') || // government
                     bookTitle.contains('ریاست') || // state
                     bookTitle.contains('دستور') || // constitution
                     bookTitle.contains('جماعت') || // jamaat/group
                     bookTitle.contains('جہاد') || // jihad
                     bookTitle.contains('دعوت') || // dawah
                     bookTitle.contains('اسلامی ریاست'); // Islamic state
        }
        
        if (shouldAdd) {
          matchedBooks.add(book);
        }
      }
      
      _log.info('After keyword matching: found ${matchedBooks.length} books');
    }
    
    // If we still don't have enough books, add some based on a broader match
    if (matchedBooks.length < 3 && books.isNotEmpty) {
      _log.info('Not enough books found, adding some more based on broader criteria');
      
      // Take the first few books that aren't already in matchedBooks
      final additionalNeeded = 5 - matchedBooks.length;
      int added = 0;
      
      for (final book in books) {
        if (!matchedBooks.contains(book)) {
          matchedBooks.add(book);
          added++;
          
          if (added >= additionalNeeded) break;
        }
      }
    }
    
    return matchedBooks;
  }
  
  // Build the app bar with the category name
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
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
    
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      systemOverlayStyle: isDark 
          ? SystemUiOverlayStyle.light 
          : SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '$_categoryName Books',
        style: theme.textTheme.titleLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: _scaleFontSize(22), // Apply font scaling
        ),
      ),
    );
  }
  
  // Build the grid view of books
  Widget _buildGridView(List<Book> books, bool isLoadingMore) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        // Show loading indicators at the end if loading more
        if (isLoadingMore && index >= books.length) {
          return _buildShimmerItem();
        }
        
        // Otherwise show book items
        if (index < books.length) {
          final book = books[index];
          
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 2,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: BookGridItem(
                  book: book,
                  onTap: () => _navigateToBookDetail(book),
                ),
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  // Build shimmer loading effect for grid items
  Widget _buildShimmerItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover placeholder
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
          ),
          
          // Title placeholder
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 100,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build empty state when no books are found
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No books found in this category',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: _scaleFontSize(18), // Apply font scaling
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new additions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build loading state
  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Show 6 shimmer items while loading
      itemBuilder: (_, __) => _buildShimmerItem(),
    );
  }
  
  // Build error state
  Widget _buildErrorState(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading books',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontSize: _scaleFontSize(18), // Apply font scaling
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadBooks,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Consumer(
        builder: (context, ref, child) {
          final libraryState = ref.watch(libraryBooksProvider);
          
          if (libraryState is LibraryLoading) {
            return _buildLoadingState();
          } else if (libraryState is LibraryStateError) {
            return _buildErrorState(libraryState.message, theme);
          } else if (libraryState is LibraryStateData) {
            final books = _filterBooksByCategory(libraryState.books);
            _log.info('Found ${books.length} books for category ${widget.categoryId}');
            
            if (books.isEmpty && !libraryState.isLoadingMore) {
              // If no books and not currently loading more, show empty state
              return _buildEmptyState(theme);
            }
            
            return _buildGridView(books, libraryState.isLoadingMore);
          }
          
          // Fallback for any other state
          return _buildEmptyState(theme);
        },
      ),
    );
  }
}
