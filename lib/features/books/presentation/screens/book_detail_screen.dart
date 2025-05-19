import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/routes/route_names.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/core/utils/app_logger.dart';
import 'package:modudi/features/favorites/providers/favorites_provider.dart';
import 'package:modudi/features/reading/data/models/bookmark_model.dart';
import 'package:modudi/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // Watch favorites provider (keep as is for now, adapt if needed)
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.any((favBook) => favBook.firestoreDocId == widget.bookId);
    
    AppLogger.logUserAction('BookDetail', 'check_favorite_status', 
      details: {'bookId': widget.bookId, 'isFavorite': isFavorite});

    // Handle loading and error states based on local state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: const Text('Loading...'),
          foregroundColor: Colors.white,
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
                // Fallback to home if navigation fails
                context.go(RouteNames.home);
              }
            },
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          )
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
      );
    } else if (_errorMessage != null || _book == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: const Text('Error'),
          foregroundColor: Colors.white,
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
                // Fallback to home if navigation fails
                context.go(RouteNames.home);
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                const Text(
                  'Error loading book details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Book data could not be loaded.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  // Use the local reload method
                  onPressed: _loadBookDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
      );
    } else {
      // Success state - build the UI with real data from _book and _headings
      final book = _book!;

      return Scaffold(
        // Brown app bar with back and share buttons
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          title: Text(book.title ?? 'Book Detail', overflow: TextOverflow.ellipsis),
                leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
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
                // Fallback to home if navigation fails
                      context.go(RouteNames.home);
                    }
                  },
                ),
                actions: [
                  IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () async {
                try {
                  // Get book details for sharing
                  final book = _book;
                  if (book == null) return;
                  
                  // Create sharing text
                  final String shareText = '''Check out "${book.title}" by ${book.author ?? 'Unknown Author'} on the Maulana Maududi app!

${book.description != null ? '${book.description?.substring(0, book.description!.length > 100 ? 100 : book.description!.length)}...' : 'A great book to explore!'}

Download the app to read more.''';
                  
                  // Use platform channel to share text
                  await Clipboard.setData(ClipboardData(text: shareText));
                  
                  // Show snackbar for confirmation
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Book details copied to clipboard for sharing!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                  
                  _log.info('Shared book: ${book.title}');
                } catch (e) {
                  _log.warning('Error sharing book: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not share this book'))
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Book header section with book image and title - now more responsive
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05, 
                vertical: 20
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover image with responsive width
                  Hero(
                    tag: 'book-${widget.bookId}',
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.28, 
                      // Height is proportional, using aspect ratio
                      height: MediaQuery.of(context).size.width * 0.28 * 1.5, 
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
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
                  const SizedBox(width: 20),
                  // Book details - enhanced with better typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, // Align text vertically
                      children: [
                        Text(
                          book.title ?? 'Untitled Book',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.055,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        if (book.author != null)
                          Text(
                            'by ${book.author}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9), 
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (book.tags != null && book.tags!.isNotEmpty) 
                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            children: book.tags!.map((tag) => Container(
                              margin: const EdgeInsets.only(right: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white30,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar with improved design - more modern and responsive
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
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 15,
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
        // Enhanced bottom bar with heart button and "Start Reading" button
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.05, 
            right: MediaQuery.of(context).size.width * 0.05, 
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom + 8 
                : 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Heart/Favorite button (red circle with outline) - enhanced with animation
              GestureDetector(
                onTap: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(book);
                  // Add haptic feedback
                  HapticFeedback.mediumImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFavorite ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                    border: Border.all(
                      color: isFavorite ? Colors.red : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: isFavorite ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ] : [],
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: isFavorite ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              
              // Start Reading button (themed button with book icon) - enhanced design
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Add haptic feedback
                    HapticFeedback.mediumImpact();
                    context.goNamed(
                      RouteNames.readingBook, 
                      pathParameters: {'bookId': book.firestoreDocId}
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                  icon: const Icon(Icons.menu_book, size: 22),
                  label: Text(
                    'Start Reading',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

  // Enhanced Overview Tab with modern design
  Widget _buildOverviewTab(Book book) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: 24
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description section with beautiful styling
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined, 
                        color: Theme.of(context).colorScheme.primary,
                        size: 22
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Description',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  book.description ?? 'No description available.',
                  style: GoogleFonts.inter(
                    fontSize: 16, 
                    height: 1.7, 
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

  // Enhanced helper for detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, 
                fontSize: 15,
                color: Colors.grey.shade700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.grey.shade800,
                height: 1.5,
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
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Chapter title row with enhanced design
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  Colors.white,
                ],
                stops: const [0.0, 0.3],
              ),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 4,
                ),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      Theme.of(context).colorScheme.primary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(
                chapter.title ?? 'Chapter $index',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
              subtitle: chapter.description != null && chapter.description!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        chapter.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    )
                  : null,
              trailing: hasHeadings
                  ? null // Remove trailing icon if ExpansionTile is present
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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