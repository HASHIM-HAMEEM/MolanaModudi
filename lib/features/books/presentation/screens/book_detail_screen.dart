import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/themes/maududi_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/routes/route_names.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/core/utils/app_logger.dart';
import '../providers/book_detail_provider.dart';
import '../providers/book_detail_state.dart';
import 'package:modudi/features/favorites/providers/favorites_provider.dart';
import 'package:modudi/features/home/domain/entities/book_entity.dart';
import 'package:modudi/features/reading/presentation/providers/reading_state.dart';
import 'package:modudi/features/reading/data/models/bookmark_model.dart';
import 'package:modudi/features/reading/data/repositories/reading_repository_impl.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId; // Assume bookId is passed to the screen

  const BookDetailScreen({required this.bookId, super.key});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _log = Logger('BookDetailScreen');
  @override
  Future<bool> didPop() async {
    // When back is pressed, check if we can pop normally
    if (context.canPop()) {
      return true; // Allow default pop behavior
    } else {
      // If no route to pop, navigate to fallback route
      context.go(_fallbackRoute);
      return false; // Prevent default pop behavior
    }
  }

  // Local state variables
  Book? _book;
  bool _isLoading = true;
  String? _errorMessage;
  final String _fallbackRoute = RouteNames.home; // Use named route constant from route_names.dart

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookDetails(); // Fetch data on init
  }

  // Fetch book details and headings from Firestore
  Future<void> _loadBookDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _log.info('Loading details for book ID: ${widget.bookId}');

    try {
      final firestore = FirebaseFirestore.instance;
      final bookDocRef = firestore.collection('books').doc(widget.bookId);
      
      // Fetch book and headings concurrently
      final results = await Future.wait([
        bookDocRef.get(),
        bookDocRef.collection('headings').orderBy('sequence').get(),
      ]);

      final bookDocSnap = results[0] as DocumentSnapshot;
      final headingsSnapshot = results[1] as QuerySnapshot;

      if (!bookDocSnap.exists) {
        throw Exception('Book not found');
      }

      final bookData = Book.fromMap(
        bookDocSnap.id,
        bookDocSnap.data() as Map<String, dynamic>,
      );

      final headingsList = headingsSnapshot.docs.map((doc) {
        return Heading.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      _log.info('Loaded book: ${bookData.title} with ${headingsList.length} headings.');

      if (mounted) {
        setState(() {
          _book = bookData;
          _isLoading = false;
        });
        // Optional: Trigger AI insights fetch here if needed
        // _loadAiInsights(); 
      }

    } catch (e, stackTrace) {
      _log.severe('Error loading book details: $e', e, stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Placeholder for fetching AI insights
  // Future<void> _loadAiInsights() async {
  //   if (_book == null || !mounted) return;
  //   setState(() { _isAiLoading = true; });
  //   try {
  //     // Replace with your actual AI fetching logic using a provider or service
  //     // final insights = await ref.read(aiInsightsProvider(_book!.id).future);
  //     await Future.delayed(Duration(seconds: 1)); // Simulate network call
  //     final insights = { 'summary': 'This is an AI generated summary...', 'themes': ['Faith', 'Community'] };
  //     if (mounted) setState(() { _aiInsights = insights; });
  //   } catch (e) {
  //     _log.warning('Failed to load AI insights: $e');
  //   } finally {
  //      if (mounted) setState(() { _isAiLoading = false; });
  //   }
  // }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Watch favorites provider
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.any((favBook) => favBook.firestoreDocId == widget.bookId);
    
    AppLogger.logUserAction('BookDetail', 'check_favorite_status', 
      details: {'bookId': widget.bookId, 'isFavorite': isFavorite});

    // Handle loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: const Text('Loading...'),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              _log.info('Navigating back from book detail loading state');
              try {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.home);
                }
              } catch (e) {
                _log.warning('Error during back navigation: $e');
                context.go(RouteNames.home);
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading book details...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: colorScheme.background,
      );
    } 
    // Handle error state
    else if (_errorMessage != null || _book == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: const Text('Error'),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              _log.info('Navigating back from book detail error state');
              try {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.home);
                }
              } catch (e) {
                _log.warning('Error during back navigation: $e');
                context.go(RouteNames.home);
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline, 
                    size: 48, 
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Error Loading Book Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Book data could not be loaded.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadBookDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          )
        ),
        backgroundColor: colorScheme.background,
      );
    } 
    // Success state
    else {
      final book = _book!;
      final statusBarHeight = MediaQuery.of(context).padding.top;
      final screenWidth = MediaQuery.of(context).size.width;
      final isTablet = screenWidth > 600;
      
      // Calculate responsive book cover dimensions
      final coverWidth = isTablet ? 140.0 : 110.0;
      final coverHeight = isTablet ? 200.0 : 160.0;

      return Scaffold(
        // Use transparent AppBar to allow custom header to show through
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.2),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  _log.info('Navigating back from book detail');
                  try {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteNames.home);
                    }
                  } catch (e) {
                    _log.warning('Error during back navigation: $e');
                    context.go(RouteNames.home);
                  }
                },
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Book header section with book image and title
            Container(
              padding: EdgeInsets.only(
                top: statusBarHeight + 16, // Adjust for status bar
                bottom: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover image with enhanced shadow and animation
                  Hero(
                    tag: 'book-${widget.bookId}',
                    child: Container(
                      width: coverWidth,
                      height: coverHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: book.thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.book, color: Colors.grey, size: 50),
                          ),
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Book details with improved typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title ?? 'Untitled Book',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (book.author != null)
                          Text(
                            'by ${book.author}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isTablet ? 17 : 15,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (book.tags != null && book.tags!.isNotEmpty) 
                          SizedBox(
                            height: 32,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: book.tags!.map((tag) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar with improved design
            Material(
              color: Theme.of(context).colorScheme.primary,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                    child: TabBar(
                      controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Chapters'),
                        Tab(text: 'Bookmarks'),
                        Tab(text: 'AI Insights'),
                      ],
                    ),
                  ),
                ),
            
            // Tab content
            Expanded(
              child: TabBarView(
            controller: _tabController,
            children: [
                  _buildOverviewTab(book),
                  _buildChaptersTab(),
                  _buildBookmarksTab(),
                  _buildAiInsightsTab(),
            ],
          ),
        ),
          ],
        ),
        // Bottom bar with heart button and "Start Reading" button
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 20, 
            right: 20, 
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom 
                : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Heart/Favorite button (red circle with outline)
              GestureDetector(
                onTap: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(book);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFavorite ? Colors.red.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(
                      color: isFavorite ? Colors.red : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 26,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Start Reading button (themed button with book icon)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed(
                      RouteNames.readingBook, 
                      pathParameters: {'bookId': book.firestoreDocId}
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.menu_book, size: 20),
                  label: const Text(
                    'Start Reading',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFFAF0E6), // Off-white background for the main content area
      );
    }
  }

  // Updated Header Content to use BookModel
  Widget _buildHeaderContent(BuildContext context, Book book) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            // Book cover image
            SizedBox(
              width: 140,
              child: AspectRatio(
                aspectRatio: 3/4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: book.thumbnailUrl ?? '',
          fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.book, color: Colors.grey),
                    ),
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Book info
            Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    book.title ?? 'Untitled',
                    style: const TextStyle(
                  color: Colors.white,
                      fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
                  if (book.author != null) ...[
                    const SizedBox(height: 4),
              Text(
                      'by ${book.author}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (book.tags != null && book.tags!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                      spacing: 4,
                runSpacing: 4,
                      children: book.tags!.map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ]
            ],
          ),
        ),
      ],
        ),
      ),
    );
  }

  // Update Overview Tab to use BookModel
  Widget _buildOverviewTab(Book book) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description section with beautiful styling
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, 
                      color: Color(0xFFB07A2B), size: 22),
                    const SizedBox(width: 10),
              Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                ),
            ],
          ),
                const SizedBox(height: 16),
                Text(
                  book.description ?? 'No description available.',
                  style: TextStyle(
                    fontSize: 15, 
                    height: 1.6, 
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Book details section
          if (book.author != null || book.publisher != null || 
              book.publicationDate != null || book.defaultLanguage != null) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, 
                        color: Color(0xFFB07A2B), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Book Details',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (book.author != null) _buildDetailRow('Author', book.author!),
                  if (book.publisher != null) _buildDetailRow('Publisher', book.publisher!),
                  if (book.publicationDate != null) _buildDetailRow('Published', book.publicationDate!),
                  if (book.defaultLanguage != null) _buildDetailRow('Language', book.defaultLanguage!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper for detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update Chapters Tab to use List<HeadingModel>
  Widget _buildChaptersTab() {
    return FutureBuilder<List<dynamic>>(
      future: _loadBookStructure(widget.bookId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          AppLogger.getLogger('BookDetail').severe('Failed to load chapters', snapshot.error);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Could not load chapters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasData) {
          final List<Volume> volumes = snapshot.data![0];
          final List<Chapter> standaloneChapters = snapshot.data![1];
          
          if (volumes.isEmpty && standaloneChapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No chapters found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This book is presented as a single reading',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Volumes section
              if (volumes.isNotEmpty) ...[
                // If we have multiple volumes, show volume structure
                for (int volumeIndex = 0; volumeIndex < volumes.length; volumeIndex++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0), // Add space below each volume section
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Volume header - Polished
                        Material(
                          elevation: 1.0, // Subtle elevation
                          borderRadius: BorderRadius.circular(8.0),
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            leading: Icon(
                              Icons.library_books_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              'Volume ${volumeIndex + 1}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                            subtitle: Text(
                              volumes[volumeIndex].title ?? 'Untitled Volume',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Space between volume header and its chapters
                        
                        // Chapters in this volume
                        if (volumes[volumeIndex].chapters != null && 
                            volumes[volumeIndex].chapters!.isNotEmpty) ...[
                          for (int chapterIndex = 0; 
                               chapterIndex < volumes[volumeIndex].chapters!.length; 
                               chapterIndex++)
                            _buildChapterCard(
                              chapterIndex + 1,
                              volumes[volumeIndex].chapters![chapterIndex],
                            ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No chapters in this volume',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
              ],
              
              // Standalone chapters (if no volumes)
              if (standaloneChapters.isNotEmpty) ...[
                if (volumes.isEmpty) // Only show this header if we don't have volumes
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Chapters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  
                for (int chapterIndex = 0; 
                     chapterIndex < standaloneChapters.length; 
                     chapterIndex++)
                  _buildChapterCard(
                    chapterIndex + 1,
                    standaloneChapters[chapterIndex],
                  ),
              ],
            ],
          );
        }
        
        return const Center(child: Text('No data available'));
      },
    );
  }
  
  Widget _buildChapterCard(int index, Chapter chapter) {
    final hasHeadings = chapter.headings != null && chapter.headings!.isNotEmpty;
    // Create a GlobalKey for the ExpansionTile to control its state
    final GlobalKey expansionTileKey = GlobalKey(); 

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Chapter title row
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(
                chapter.title ?? 'Chapter $index',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: chapter.description != null && chapter.description!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        chapter.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : null,
              trailing: hasHeadings
                  ? null // Remove trailing icon if ExpansionTile is present
                  : Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
          onTap: () {
                if (hasHeadings) {
                  // If has headings, the user should tap the ExpansionTile's chevron to expand/collapse.
                  // Tapping the main ListTile for a chapter with headings currently does not toggle expansion directly.
                  // This was simplified to avoid needing an ExpansionTileController for now.
                  // See previous comments if direct ListTile tap-to-toggle is desired.
                  _log.info("Chapter card (with headings) tapped. User should use chevron to see headings.");
                } else {
                  // If no headings, navigate to reading screen with chapter context
                  AppLogger.logUserAction('BookDetail', 'open_chapter',
                    details: {'chapterId': chapter.firestoreDocId, 'title': chapter.title});
                  
            context.goNamed(
              RouteNames.readingBook, 
              pathParameters: {'bookId': widget.bookId},
                    queryParameters: {'chapterId': chapter.firestoreDocId},
                  );
                }
              }
            ),
          ),
          
          // Headings (if any)
          if (hasHeadings)
            ExpansionTile(
              key: expansionTileKey, // Assign the key
              title: Text(
                '${chapter.headings!.length} Section${chapter.headings!.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Theme.of(context).cardColor,
              collapsedBackgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              childrenPadding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
              tilePadding: const EdgeInsets.symmetric(horizontal: 24.0),
              iconColor: Theme.of(context).colorScheme.primary,
              collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
              children: [
                for (int headingIndex = 0; 
                     headingIndex < chapter.headings!.length; 
                     headingIndex++)
                  _buildHeadingItem(
                    headingIndex + 1, 
                    chapter.headings![headingIndex], 
                    chapter,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Widget for displaying a heading item in a chapter
  Widget _buildHeadingItem(int index, Heading heading, Chapter chapter) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 16, top: 8, bottom: 8), // Adjusted padding
      leading: Container(
        width: 28, // Slightly smaller than chapter index
        height: 28, // Slightly smaller
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          border: Border.all( // Optional: add a subtle border
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            width: 1,
          )
        ),
        child: Center(
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 13, // Slightly smaller font
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600, // Bolder for a small number
            ),
          ),
        ),
      ),
      title: Text(
        heading.title ?? 'Section $index',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface, // Standard text color
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Theme.of(context).colorScheme.primary, // Consistent with chapter navigation icon color
      ),
      onTap: () {
        AppLogger.logUserAction('BookDetail', 'open_heading', 
          details: {'headingId': heading.firestoreDocId, 'title': heading.title});
        // Navigate to reading screen with heading context
        context.goNamed(
          RouteNames.readingBook,
          pathParameters: {'bookId': widget.bookId},
          queryParameters: {
            'chapterId': chapter.firestoreDocId,
            'headingId': heading.firestoreDocId
          },
        );
      },
    );
  }

  // Helper to fetch book structure (volumes and chapters)
  Future<List<dynamic>> _loadBookStructure(String bookId) async {
    final log = AppLogger.getLogger('BookDetailScreen');
    log.info('Loading book structure for ID: $bookId');
    
    try {
      final firestore = FirebaseFirestore.instance;
      final bookDocRef = firestore.collection('books').doc(bookId);
      
      // Debug the structure
      await bookDocRef.get().then((doc) {
        if (doc.exists) {
          log.info('Book document exists: ${doc.data()?.keys.toString()}');
        } else {
          log.info('Book document does not exist');
        }
      });
      
      // 1. First fetch volumes for this book
      log.info('Fetching volumes for book: $bookId');
      final volumesQuery = await firestore.collection('volumes')
          .where('book_id', isEqualTo: int.tryParse(bookId))
          .orderBy('sequence')
          .get();
          
      log.info('Found ${volumesQuery.docs.length} volumes for book $bookId');
      
      // Map volumes to our model
      final volumes = volumesQuery.docs.map((doc) {
        final data = doc.data();
        log.info('Volume data: ${doc.id}, title: ${data['title'] ?? 'unknown'}');
        return Volume.fromMap(doc.id, data);
      }).toList();
      
      // 2. If no volumes found, check if there are standalone chapters
      final List<Chapter> standaloneChapters = [];
      if (volumes.isEmpty) {
        log.info('No volumes found, checking for standalone chapters');
        final chaptersQuery = await firestore.collection('chapters')
            .where('book_id', isEqualTo: int.tryParse(bookId))
            .orderBy('sequence')
            .get();
        
        standaloneChapters.addAll(chaptersQuery.docs.map((doc) {
          final data = doc.data();
          log.info('Standalone chapter: ${doc.id}, title: ${data['title'] ?? 'unknown'}');
          return Chapter.fromMap(doc.id, data);
        }));
        
        log.info('Found ${standaloneChapters.length} standalone chapters');
      }
      
      // 3. For each volume, fetch its chapters
      await Future.wait(volumes.map((volume) async {
        try {
          // First try regular path - chapters directly under volumes
          final volumeChapters = await firestore.collection('chapters')
              .where('volume_id', isEqualTo: volume.id)
              .orderBy('sequence')
              .get();
          
          // Map chapters to our model
          volume.chapters = volumeChapters.docs.map((doc) {
            final data = doc.data();
            log.info('Chapter in volume ${volume.title}: ${doc.id}, title: ${data['title'] ?? 'unknown'}');
            return Chapter.fromMap(doc.id, data);
          }).toList();
          
          log.info('Found ${volume.chapters?.length ?? 0} chapters for volume ${volume.title}');
          
          // 4. For each chapter in this volume, fetch headings (where the actual content lives)
          if (volume.chapters != null) {
            await Future.wait(volume.chapters!.map((chapter) async {
              try {
                final headingsQuery = await firestore.collection('headings')
                    .where('chapter_id', isEqualTo: chapter.id)
                    .orderBy('sequence')
                    .get();
                    
                chapter.headings = headingsQuery.docs.map((doc) {
                  final data = doc.data();
                  return Heading.fromMap(doc.id, data);
                }).toList();
                
                log.info('Found ${chapter.headings?.length ?? 0} headings for chapter ${chapter.title}');
              } catch (e) {
                log.warning('Error fetching headings for chapter ${chapter.id}: $e');
              }
            }));
          }
        } catch (e) {
          log.warning('Error fetching chapters for volume ${volume.id}: $e');
        }
      }));
      
      // 5. For standalone chapters, fetch their headings too
      if (standaloneChapters.isNotEmpty) {
        await Future.wait(standaloneChapters.map((chapter) async {
          try {
            final headingsQuery = await firestore.collection('headings')
                .where('chapter_id', isEqualTo: chapter.id)
                .orderBy('sequence')
                .get();
                
            chapter.headings = headingsQuery.docs.map((doc) {
              final data = doc.data();
              return Heading.fromMap(doc.id, data);
            }).toList();
            
            log.info('Found ${chapter.headings?.length ?? 0} headings for standalone chapter ${chapter.title}');
          } catch (e) {
            log.warning('Error fetching headings for standalone chapter ${chapter.id}: $e');
          }
        }));
      }
      
      return [volumes, standaloneChapters];
    } catch (e, stackTrace) {
      log.severe('Error loading book structure', e, stackTrace);
      rethrow;
    }
  }
  
  // Update Bookmarks Tab to potentially use BookModel
  Widget _buildBookmarksTab() {
    // Use FutureBuilder to fetch bookmarks
    return FutureBuilder<List<Bookmark>>(
      future: ref.read(readingRepositoryProvider).getBookmarks(widget.bookId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          _log.severe('Error loading bookmarks: ${snapshot.error}', snapshot.error, snapshot.stackTrace);
      return Center(
        child: Column(
              mainAxisSize: MainAxisSize.min,
          children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Could not load bookmarks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
      child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
        children: [
                Icon(Icons.bookmark_border, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
                Text(
                  'No bookmarks yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
            const SizedBox(height: 8),
                Text(
                  'You can add bookmarks while reading.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
        ],
      ),
    );
  }
  
        final bookmarks = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: bookmarks.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return ListTile(
              leading: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary),
              title: Text(
                bookmark.headingTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  if (bookmark.chapterTitle.isNotEmpty)
                    Text('Chapter: ${bookmark.chapterTitle}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (bookmark.textContentSnippet != null && bookmark.textContentSnippet!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        bookmark.textContentSnippet!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to the bookmarked location
                // This requires knowing the chapterId and headingId
              context.goNamed(
                RouteNames.readingBook, 
                  pathParameters: {'bookId': widget.bookId},
                  queryParameters: {
                    'chapterId': bookmark.chapterId, // Ensure Bookmark model has chapterId
                    'headingId': bookmark.headingId, // Ensure Bookmark model has headingId
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Update AI Insights Tab
  Widget _buildAiInsightsTab() {
    return const Center(
      child: Text('AI Insights coming soon'),
    );
  }
}