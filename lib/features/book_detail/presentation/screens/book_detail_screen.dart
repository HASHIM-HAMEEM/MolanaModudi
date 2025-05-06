import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Needed for images
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:logging/logging.dart'; // Import Logging
import '../../../../core/themes/maududi_theme.dart'; // For CardStyles
import 'package:go_router/go_router.dart'; // Import GoRouter
import '../../../../routes/route_names.dart'; // Import RouteNames
import 'package:modudi/models/book_models.dart'; // Use new models
// Import domain entity
// import '../../domain/entities/book_detail_entity.dart';
// Import provider and state
// import '../providers/book_detail_provider.dart';
// import '../providers/book_detail_state.dart';
// Import favorites provider
import '../../../../features/favorites/providers/favorites_provider.dart';
// Import BookEntity for creating favorite books
import '../../../../features/home/domain/entities/book_entity.dart';
import 'package:modudi/features/reading/presentation/providers/reading_state.dart'; // Import AiFeatureStatus

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId; // Assume bookId is passed to the screen

  const BookDetailScreen({required this.bookId, super.key});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDescriptionExpanded = false;
  final _log = Logger('BookDetailScreen');

  // Local state variables
  Book? _book;
  List<Heading> _headings = [];
  bool _isLoading = true;
  String? _errorMessage;
  // Add state for AI insights if fetched separately
  // Map<String, dynamic>? _aiInsights;
  // bool _isAiLoading = false;

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
          _headings = headingsList;
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
    final isFavorite = favorites.any((favBook) => favBook.id == widget.bookId);

    // Handle loading and error states based on local state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    } else if (_errorMessage != null || _book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading book details',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Book data could not be loaded.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  // Use the local reload method
                  onPressed: _loadBookDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        ),
      );
    } else {
      // Success state - build the UI with real data from _book and _headings
      final book = _book!;

      return Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: Text(book.title ?? 'Book Detail'),
                pinned: true,
                floating: true,
                snap: false,
                forceElevated: innerBoxIsScrolled,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go(RouteNames.home);
                    }
                  },
                ),
                actions: [
                  // Favorite button using local _book data
                  IconButton(
                    icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                    tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                    onPressed: () {
                      // Pass the BookModel directly
                      ref.read(favoritesProvider.notifier).toggleFavorite(book);
                    },
                  ),
                  IconButton(icon: const Icon(Icons.share_outlined), onPressed: () { /* TODO: Share */ }),
                ],
                expandedHeight: 260.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeaderContent(context, book), // Pass BookModel
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(kTextTabBarHeight),
                  child: Material(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: theme.colorScheme.primary,
                      indicatorWeight: 2.5,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Chapters'),
                        Tab(text: 'Bookmarks'),
                        Tab(text: 'AI Insights'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, book), // Pass BookModel
              _buildChaptersTab(context, _headings), // Pass List<HeadingModel>
              _buildBookmarksTab(context, book), // Pass BookModel
              _buildAiInsightsTab(context), // Pass necessary data if needed
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, book), // Pass BookModel
      );
    }
  }

  // Updated Header Content to use BookModel
  Widget _buildHeaderContent(BuildContext context, Book book) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    // Determine dynamic image height (e.g., 30-35% of screen height)
    final double imageHeight = screenHeight * 0.3; // Adjust multiplier as needed

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image (optional fade)
        CachedNetworkImage(
          imageUrl: book.thumbnailUrl ?? '', // Changed from coverUrl
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => Container(color: theme.primaryColorDark),
        ),
        // Overlay content
        SafeArea(
          bottom: false, // Prevent double padding with AppBar bottom
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title ?? 'Untitled', // Changed from BookModel field, added null check
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.author ?? 'Unknown Author', // Use BookModel field
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              // Display Rating and Language/Format
              Row(
                children: [
                  if (book.defaultLanguage != null)
                    Text(
                      book.defaultLanguage!,
                      style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  // Add more info like format if available
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (book.defaultLanguage != null) Chip(label: Text(book.defaultLanguage!), padding: EdgeInsets.zero),
                  if (book.publicationDate != null) Chip(label: Text(book.publicationDate!.toString()), padding: EdgeInsets.zero),
                  if (book.tags != null && book.tags!.isNotEmpty) Chip(label: Text(book.tags!.join(', ')), padding: EdgeInsets.zero),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Update Overview Tab to use BookModel
  Widget _buildOverviewTab(BuildContext context, Book book) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          // Expandable description
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.description ?? 'No description available.', // Use BookModel field
                maxLines: _isDescriptionExpanded ? null : 5,
                overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if ((book.description?.length ?? 0) > 150) // Show toggle if text is long
                TextButton(
                  onPressed: () {
                    setState(() { _isDescriptionExpanded = !_isDescriptionExpanded; });
                  },
                  child: Text(_isDescriptionExpanded ? 'Show Less' : 'Show More'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Details', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          // Use _buildDetailRow helper
          if (book.author != null) _buildDetailRow(context, Icons.person_outline, 'Author', book.author!),
          if (book.publisher != null) _buildDetailRow(context, Icons.business_outlined, 'Publisher', book.publisher!),
          if (book.publicationDate != null) _buildDetailRow(context, Icons.calendar_today_outlined, 'Published', book.publicationDate!.toString()),
          if (book.defaultLanguage != null) _buildDetailRow(context, Icons.language_outlined, 'Language', book.defaultLanguage!),
          if (book.tags != null && book.tags!.isNotEmpty) 
            _buildDetailRow(context, Icons.category_outlined, 'Tags', book.tags!.join(', ')),
          if (book.isbn != null) _buildDetailRow(context, Icons.qr_code_outlined, 'ISBN', book.isbn!),
          // ... other details from BookModel ...
        ],
      ),
    );
  }

  // Helper for detail rows
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Update Chapters Tab to use List<HeadingModel>
  Widget _buildChaptersTab(BuildContext context, List<Heading> headings) {
    if (headings.isEmpty) {
      return const Center(child: Text('No chapter information available.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: headings.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final heading = headings[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'), // Use index for chapter number
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          title: Text(heading.title ?? 'Untitled Heading'),
          onTap: () {
            // Navigate to ReadingScreen, passing bookId and potentially chapter info
            // Use the correct route name: readingBook
            context.goNamed(
              RouteNames.readingBook, 
              pathParameters: {'bookId': widget.bookId},
              queryParameters: {'chapterId': heading.id, 'sequence': heading.sequence.toString()}
            );
          },
        );
      },
    );
  }

  // Update Bookmarks Tab to potentially use BookModel
  Widget _buildBookmarksTab(BuildContext context, Book book) {
    // TODO: Implement bookmark fetching and display logic
    // This might involve another Firestore query or local storage
    return const Center(child: Text('Bookmarks will appear here.'));
  }

  // Update AI Insights Tab
  Widget _buildAiInsightsTab(BuildContext context) {
    // Check AI feature status from provider (if implemented)
    // final aiStatus = ref.watch(bookDetailNotifierProvider(widget.bookId)).aiFeatureStatus;
    // final aiData = ref.watch(bookDetailNotifierProvider(widget.bookId)).aiInsights;
    final bool _isAiLoading = false; // Replace with actual state
    final Map<String, dynamic>? _aiInsights = null; // Replace with actual state
    
    if (_isAiLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_aiInsights == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Generate AI Insights?'),
            ElevatedButton(
              onPressed: () { /* TODO: Trigger AI fetch */ }, 
              child: const Text('Generate')
            )
          ],
        )
      );
    }

    // Display fetched AI insights
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_aiInsights['summary'] != null) ...[
            Text('AI Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_aiInsights['summary']!),
            const SizedBox(height: 16),
          ],
          if (_aiInsights['themes'] != null && (_aiInsights['themes'] as List).isNotEmpty) ...[
            Text('Key Themes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (_aiInsights['themes'] as List).map((theme) => Chip(label: Text(theme))).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // ... Display other AI insights ...
        ],
      ),
    );
  }
  
  // Update Bottom Bar to use BookModel
  Widget _buildBottomBar(BuildContext context, Book book) {
    // ... existing UI code ...
    // Update to use fields from BookModel for actions like 'Read'
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          )
        ], // Use direct shadow or theme equivalent
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Add to Library/Download button (optional)
          OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download'), // Or 'Add to Library'
            onPressed: () { /* TODO: Implement download/add logic */ },
          ),
          // Read button
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('Read'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              // Navigate to ReadingScreen, passing the bookId
              // Use the correct route name: readingBook
              context.goNamed(
                RouteNames.readingBook, 
                pathParameters: {'bookId': book.firestoreDocId} // Use firestoreDocId (String)
              );
            },
          ),
        ],
      ),
    );
  }
}