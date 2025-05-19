import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../routes/route_names.dart';
import '../widgets/book_grid_item.dart';
import '../widgets/book_list_item.dart';
import 'package:modudi/features/books/presentation/providers/library_books_provider.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/books/data/models/library_state.dart';

// View modes for the library
enum LibraryViewMode { grid, list }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // View mode with grid as default
  LibraryViewMode _viewMode = LibraryViewMode.grid;
  
  // Controllers
  final ScrollController _scrollController = ScrollController();
  
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
    {'id': 'hadith', 'name': 'Hadith', 'icon': Icons.history_edu},
    {'id': 'fiqh', 'name': 'Fiqh', 'icon': Icons.balance},
    {'id': 'seerah', 'name': 'Seerah', 'icon': Icons.person},
    {'id': 'aqeedah', 'name': 'Aqeedah', 'icon': Icons.lightbulb},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooks();
    });
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more books when scrolling to the bottom
      ref.read(libraryBooksProvider.notifier).loadMoreBooks(
        languageCode: _selectedLanguage == 'all' ? null : _selectedLanguage,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
    }
  }

  void _loadBooks() {
    ref.read(libraryBooksProvider.notifier).loadBooks(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      languageCode: _selectedLanguage == 'all' ? null : _selectedLanguage,
    );
  }

  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
    
    _loadBooks();
  }

  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    
    _loadBooks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the library books provider
    final libraryBooksAsync = ref.watch(libraryBooksProvider);
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Center the title
        title: Text(
          'Library',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(libraryBooksProvider),
          ),
          IconButton(
            icon: Icon(_viewMode == LibraryViewMode.grid ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == LibraryViewMode.grid 
                    ? LibraryViewMode.list 
                    : LibraryViewMode.grid;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Language and category filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedLanguage,
                    items: _languageMap.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectLanguage(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'] as String,
                        child: Text(category['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectCategory(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Books list/grid
          Expanded(
            child: libraryBooksAsync.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => Center(child: Text('Error: $message')),
              data: (books, _, __, isLoadingMore, error) {
                if (books.isEmpty) {
                  return const Center(child: Text('No books found'));
                }
                
                return _viewMode == LibraryViewMode.grid
                  ? _buildGridView(books, isLoadingMore)
                  : _buildListView(books, isLoadingMore);
              },
              orElse: () => const Center(child: Text('Something went wrong')),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGridView(List<Book> books, bool isLoadingMore) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 160).floor().clamp(2, 4);
    final itemWidth = screenWidth / crossAxisCount;
    final double itemHeight = 240;
    final childAspectRatio = itemWidth / itemHeight;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
      ),
      itemCount: books.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == books.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final book = books[index];
        return BookGridItem(
          book: book,
          onTap: () => context.goNamed(
            RouteNames.bookDetailItem,
            pathParameters: {'bookId': book.firestoreDocId}
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Book> books, bool isLoadingMore) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: books.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        if (index == books.length) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ));
        }
        final book = books[index];
        return BookListItem(
          book: book,
          onTap: () => context.goNamed(
            RouteNames.bookDetailItem,
            pathParameters: {'bookId': book.firestoreDocId}
          ),
        );
      },
    );
  }


} 