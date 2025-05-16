import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/routes/route_names.dart'; // Import RouteNames
import '../widgets/book_grid_item.dart'; // Import grid item
import '../widgets/book_list_item.dart'; // Import list item
// Import the library provider
import '../providers/library_books_provider.dart';
// Import the actual BookEntity
import 'package:modudi/features/books/data/models/book_models.dart'; // Use new models location
import '../../data/models/library_state.dart'; // Import updated LibraryState

// Placeholder for view modes
enum LibraryViewMode { grid, list }

// Format filter options - Keep if relevant for Firestore data, otherwise remove/adapt
// enum FormatFilter { all, pdfOnly } 

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final LibraryViewMode _viewMode = LibraryViewMode.grid;
  // FormatFilter _formatFilter = FormatFilter.all; // Remove or adapt if not used with Firestore fields
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  
  String? _selectedLanguage;
  // Consider if languages list should be dynamic or fetched
  final List<String> _languages = ['All', 'English', 'Urdu', 'Arabic']; 
  
  String? _selectedCategory;
  // Categories might come from Firestore or be predefined as here
  final List<Map<String, String>> _categories = [
    {'id': 'All', 'name': 'All'}, 
    {'id': 'tafsir', 'name': 'Tafsir'}, 
    // ... other categories
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialRouteParamsAndLoad();
    });
  }

  void _checkInitialRouteParamsAndLoad() {
    final GoRouterState routerState = GoRouterState.of(context);
    final String? categoryParam = routerState.uri.queryParameters['category'];
    final String? languageParam = routerState.uri.queryParameters['language'];

    bool needsLoad = false;
    if (categoryParam != null && categoryParam.isNotEmpty) {
      final matchingCategory = _categories.firstWhere(
        (cat) => cat['id'] == categoryParam || cat['name'] == categoryParam,
        orElse: () => {'id': 'All', 'name': 'All'}
      );
      if (_selectedCategory != matchingCategory['id']!) {
        _selectedCategory = matchingCategory['id']!;
        needsLoad = true;
      }
    }
    if (languageParam != null && languageParam.isNotEmpty) {
      if (_selectedLanguage != languageParam) {
        _selectedLanguage = languageParam;
        needsLoad = true;
      }
    }
    // Initial load or load if params changed filters
    ref.read(libraryBooksProvider.notifier).loadBooks(
      languageCode: (_selectedLanguage == null || _selectedLanguage == 'All') 
          ? null 
          : _mapLanguageToCode(_selectedLanguage!),
      category: (_selectedCategory == null || _selectedCategory == 'All') 
          ? null 
          : _selectedCategory,
    );
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Check if current state is LibraryStateData and not already loading more
      final state = ref.read(libraryBooksProvider);
      if (state is LibraryStateData && !state.isLoadingMore && state.lastDocument != null) {
         ref.read(libraryBooksProvider.notifier).loadMoreBooks(
           languageCode: _selectedLanguage == 'All' ? null : _mapLanguageToCode(_selectedLanguage!),
           category: _selectedCategory == 'All' ? null : _selectedCategory,
         );
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    // Debounce search or implement as user types
    // For now, direct filtering based on current local list (can be slow for large datasets from Firestore)
    // Consider server-side search for better performance with Firestore
    setState(() {
      _searchQuery = _searchController.text;
    });
  }
  
  void _startSearch() {
    setState(() { _isSearching = true; });
  }
  
  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }
  
  // void _toggleFormatFilter() { // Remove or adapt if not used
  //   setState(() {
  //     _formatFilter = _formatFilter == FormatFilter.all ? 
  //                    FormatFilter.pdfOnly : FormatFilter.all;
  //   });
  //   _applyFiltersAndReload(); 
  // }
  
  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
    _applyFiltersAndReload();
  }

  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    _applyFiltersAndReload();
  }

  void _applyFiltersAndReload(){
    ref.read(libraryBooksProvider.notifier).loadBooks(
      languageCode: _selectedLanguage == 'All' ? null : _mapLanguageToCode(_selectedLanguage!),
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );
  }

  // Filter logic now primarily for client-side search on already fetched data
  // Main filtering (language, category) is done by Firestore query in the notifier
  List<Book> _filterBooksForDisplay(List<Book> allBooks) {
    List<Book> filteredList = allBooks;
    
    // Client-side search query filtering
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((book) => 
        book.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false ||
        (book.author?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    // Client-side format filter (if kept and 'format' field exists in BookModel)
    // if (_formatFilter == FormatFilter.pdfOnly) {
    //   filteredList = filteredList.where((book) => 
    //     book.format?.any((f) => f.toLowerCase() == 'pdf') ?? false
    //   ).toList();
    // }
    
    // Filter by language
    if (_selectedLanguage != null && _selectedLanguage != 'All') {
      filteredList = filteredList.where((book) => book.defaultLanguage?.toLowerCase() == _selectedLanguage!.toLowerCase()).toList();
    }

    // Filter by category
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filteredList = filteredList.where((book) => book.tags?.any((t) => t.toLowerCase() == _selectedCategory!.toLowerCase()) ?? false).toList();
    }

    return filteredList;
  }
  
  String _mapLanguageToCode(String language) {
    // ... (keep existing mapLanguageToCode)
    switch (language) {
      case 'English': return 'eng';
      case 'Urdu': return 'urd';
      case 'Arabic': return 'ara';
      default: return language.toLowerCase(); // Or handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final libraryState = ref.watch(libraryBooksProvider);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          if (_isSearching) // Search bar UI (keep as is or adapt)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                 // ... same search bar setup ...
              ),
            ),
          
          // Filter Bar Implementation (adapt as needed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              children: [
                // ... Language filter DropdownButton ... (update onChanged to call _selectLanguage)
                 DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: (String? newValue) {
                    if (newValue != null) _selectLanguage(newValue);
                  },
                  items: _languages.map<DropdownMenuItem<String>>((String value) {
                     return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                  }).toList(),
                ),
                // ... Other filters like PDF toggle (remove or adapt) ...
              ],
            ),
          ),
          
          // Category list - this will now use BookModel
          libraryState.maybeWhen(
            data: (books, _, __, ___, ____) => _buildCategoryList(books, theme),
            loading: () => const SizedBox.shrink(), // Or a shimmer for categories
            orElse: () => const SizedBox.shrink(),
          ),
          
          // Content Area
          Expanded(
            child: libraryState.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              data: (books, _, lastDoc, isLoadingMore, loadMoreError) {
                final booksToDisplay = _filterBooksForDisplay(books);
                if (booksToDisplay.isEmpty && !isLoadingMore) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ... Empty state UI ...
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          onPressed: () => _applyFiltersAndReload(),
                        ),
                      ],
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
                        !isLoadingMore && lastDoc != null) {
                          ref.read(libraryBooksProvider.notifier).loadMoreBooks(
                            languageCode: _selectedLanguage == 'All' ? null : _mapLanguageToCode(_selectedLanguage!),
                            category: _selectedCategory == 'All' ? null : _selectedCategory,
                          );
                    }
                    return false;
                  },
                  child: _viewMode == LibraryViewMode.grid
                      ? _buildGridView(booksToDisplay, isLoadingMore, loadMoreError)
                      : _buildListView(booksToDisplay, isLoadingMore, loadMoreError),
                );
              },
              error: (message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading library: $message'),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      onPressed: () => _applyFiltersAndReload(),
                    ),
                  ],
                ),
              ),
              orElse: () => const Center(child: Text('Something went wrong.')), // Should not happen with sealed class
            ),
          ),
        ],
      ),
    );
  }
  
  List<Book> _convertDynamicToBookList(List<dynamic> dynamicList) {
    return dynamicList.whereType<Book>().toList();
  }

  Widget _buildCategoryList(List<Book> allBooks, ThemeData theme) {
    // ... (update to use List<BookModel> and book.categories)
    // int _getCategoryCount(List<BookModel> books, String categoryId)
    // ...
    return Container(
      // ... same container setup ...
      height: 44,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: ListView.builder(
        // ... same ListView setup ...
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final categoryId = category['id']!;
          final categoryName = category['name']!;
          final count = allBooks.where((book) => 
            categoryId == 'All' || (book.tags?.any((c) => c.toLowerCase() == categoryId.toLowerCase()) ?? false)
          ).length;
          final isSelected = _selectedCategory == categoryId;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: InkWell(
              onTap: () => _selectCategory(categoryId),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min, // Important for horizontal list
                   children: [
                    // Optional Icon
                    if (categoryId != 'All')
                      Icon(
                        _getCategoryIcon(categoryId), // Ensure this function exists and returns IconData
                        size: 16,
                        color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.primary,
                      ),
                    if (categoryId != 'All')
                      const SizedBox(width: 4),
                    // Category Name Text Widget
                    Text(
                      categoryName, 
                      style: TextStyle(
                        color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface,
                        fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Count Badge Container Widget
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? theme.colorScheme.onPrimary.withOpacity(0.2) 
                          : theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(), 
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected 
                            ? theme.colorScheme.onPrimary 
                            : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                   ],
                 ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Add back the missing helper method
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) { // Ensure case-insensitivity
      case 'tafsir':
        return Icons.auto_stories;
      case 'islamic_law': // Assuming category ID
        return Icons.balance;
      case 'biography':
        return Icons.person;
      case 'political_thought': // Assuming category ID
        return Icons.lightbulb;
      case 'islamic_studies': // Assuming category ID
        return Icons.school;
      case 'general':
        return Icons.menu_book;
      default:
        return Icons.category; // Default icon
    }
  }
  
  // ... _buildAppBar remain similar ...
  // Update _buildGridView and _buildListView to accept List<BookModel>
  // and potentially isLoadingMore, loadMoreError for UI cues

  Widget _buildGridView(List<Book> books, bool isLoadingMore, String? loadMoreError) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 160).floor().clamp(2, 4);
    final itemWidth = screenWidth / crossAxisCount;
    final double itemHeight = 240; // Adjusted for potentially more info
    final childAspectRatio = itemWidth / itemHeight;

    return GridView.builder(
      controller: _scrollController, // Attach scroll controller for pagination
      padding: const EdgeInsets.all(12.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
      ),
      itemCount: books.length + (isLoadingMore || loadMoreError != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == books.length) {
          if (loadMoreError != null) {
            return Center(child: Text('Error: $loadMoreError'));
          }
          return const Center(child: CircularProgressIndicator());
        }
        final book = books[index];
        return BookGridItem(
          book: book, // Ensure BookGridItem accepts BookModel
          onTap: () => context.goNamed(
            RouteNames.bookDetailItem, // Ensure this route name is correct
            pathParameters: {'bookId': book.id.toString()}
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Book> books, bool isLoadingMore, String? loadMoreError) {
    return ListView.separated(
      controller: _scrollController, // Attach scroll controller for pagination
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: books.length + (isLoadingMore || loadMoreError != null ? 1 : 0),
      separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        if (index == books.length) {
          if (loadMoreError != null) {
            return Center(child: Text('Error: $loadMoreError'));
          }
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }
        final book = books[index];
        return BookListItem(
          book: book, // Ensure BookListItem accepts BookModel
          onTap: () => context.goNamed(
            RouteNames.bookDetailItem, // Ensure this route name is correct
            pathParameters: {'bookId': book.id.toString()}
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        automaticallyImplyLeading: false,
        title: const Text("Search Books"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _stopSearch,
          ),
        ],
      );
    }
    
    return AppBar(
      title: _isSearching ? null : const Text('Library'),
      centerTitle: true,
      actions: _isSearching
        ? null // Hide actions when searching
        : [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search Library',
              onPressed: _startSearch,
            ),
            // Add refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Library',
              onPressed: () {
                ref.read(libraryBooksProvider.notifier).refreshBooks();
              },
            ),
          ],
      bottom: _isSearching ? null : PreferredSize( // Hide filters when searching initially
        preferredSize: const Size.fromHeight(0), // Adjust if filter bar is part of AppBar
        child: Container(),
      ),
      // Add back button if searching to allow canceling search
      leading: _isSearching ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _stopSearch) : null,
    );
  }
} 