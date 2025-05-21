import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modudi/core/widgets/optimized_cached_image.dart';
import 'package:modudi/features/reading/presentation/providers/download_provider.dart';
import 'package:modudi/features/reading/data/models/bookmark_model.dart';
import 'package:modudi/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:modudi/core/themes/app_color.dart';
import 'package:modudi/routes/route_names.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
// import 'package:modudi/core/providers/books_providers.dart'; // Removed unused import
import 'package:modudi/features/favorites/providers/favorites_provider.dart';
import 'package:modudi/core/themes/font_utils.dart';
// import 'package:modudi/core/constants/app_assets.dart'; // Removed unused import
import 'package:modudi/core/utils/app_logger.dart';
import 'package:modudi/core/providers/providers.dart'; // For cacheServiceProvider
import 'package:modudi/core/cache/config/cache_constants.dart'; 
// Ensure these are present, if not, the diff will add them.
// If they were added by a previous attempt, this search block might need adjustment if it assumes they are not there.
import 'package:modudi/core/providers/books_providers.dart'; 
import 'package:modudi/features/reading/domain/entities/book_structure.dart'; 

// import 'package:modudi/features/reading/domain/entities/models.dart'; // Commented out missing file
// import 'package:modudi/features/books/presentation/widgets/book_card.dart'; // Commented out missing file
// import 'package:modudi/features/books/presentation/widgets/book_structure_widgets.dart'; // Commented out missing file

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId; // Assume bookId is passed to the screen

  const BookDetailScreen({required this.bookId, super.key});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

// Delegate for handling the tab bar in the SliverPersistentHeader
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).primaryColor, // Match the header color
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _log = Logger('BookDetailScreen');
  
  // Helper method to scale font sizes based on settings
  double _scaleFontSize(double baseSize) {
    return FontUtils.getScaledFontSize(baseSize, ref);
  }

  // Local state variables for UI that isn't directly tied to FutureProvider states
  bool _isBookPinned = false; // State for pinned status, managed locally
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _checkBookPinnedStatus(); // Check pinned status on init

    // Trigger initial fetch for book details and structure by reading the providers.
    ref.read(bookProvider(widget.bookId));
    ref.read(bookStructureProvider(widget.bookId));

    // _startBackgroundPrefetching will be called from the build method
    // once bookProvider has data.
  }
  
  // Status tracking for content prefetching
  bool _isPrefetchingContent = false;
  double _prefetchProgress = 0.0;
  
  // Method to check if the book is pinned
  Future<void> _checkBookPinnedStatus() async {
    if (!mounted) return;
    try {
      final cacheService = await ref.read(cacheServiceProvider.future);
      final bookCacheKey = CacheConstants.bookKeyPrefix + widget.bookId;
      final isPinned = await cacheService.isItemPinned(bookCacheKey);
      if (mounted) {
        setState(() {
          _isBookPinned = isPinned;
        });
      }
    } catch (e) {
      _log.warning('Error checking pinned status for book ${widget.bookId}: $e');
      if (mounted) {
        setState(() {
          _isBookPinned = false; // Assume not pinned on error
        });
      }
    }
  }

  // Method to toggle the pinned status of the book
  Future<void> _togglePinStatus() async {
    // Get the book data from the provider
    final bookAsync = ref.read(bookProvider(widget.bookId));
    final book = bookAsync.asData?.value;

    if (book == null) {
      _log.warning('Cannot toggle pin status: Book details not loaded.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book details not available. Please try again.')),
      );
      return;
    }

    if (!mounted) return;

    final cacheService = await ref.read(cacheServiceProvider.future);
    final bookCacheKey = CacheConstants.bookKeyPrefix + widget.bookId;
    // Assuming books are primarily stored in a general 'books' box or similar
    // This might need to be derived from where ReadingRepositoryImpl caches the full book object
    // Based on MEMORY[93983ea3-14c4-40f4-9efc-cb2ae399f787], the book is cached with bookKeyPrefix.
    // The boxName used by ReadingRepositoryImpl.getBookData when caching the full book needs to be consistent here.
    // Let's assume CacheConstants.booksBoxName is the correct box for full book objects.
    const String boxName = CacheConstants.booksBoxName; 

    try {
      if (_isBookPinned) {
        await cacheService.unpinItem(bookCacheKey, boxName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from Offline Saved Items.')),
          );
        }
      } else {
        // Before pinning, ensure the full book data is actually in the persistent cache.
        // The ReadingRepositoryImpl.getBookData is responsible for caching the entire Book object.
        // We assume that if _loadBookDetails was successful, the book *should* be in cache.
        // A more robust check could involve verifying existence via cacheService.getCachedData, 
        // but for now, we'll rely on prior caching by _loadBookDetails.
        await cacheService.pinItem(bookCacheKey, boxName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved for Offline Access.')),
          );
        }
      }
      // Refresh the pinned status after the operation
      await _checkBookPinnedStatus();
    } catch (e, stackTrace) {
      _log.severe('Error toggling pin status for book ${widget.bookId}: $e', stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating offline status: ${e.toString()}')),
        );
      }
      // Optionally, re-check status to ensure UI consistency even on error
      await _checkBookPinnedStatus(); 
    }
  }

  // _loadBookDetails method is removed.

  // AI Insights functionality will be implemented in future updates

  // Improved prefetching method that works with optimized caching
  Future<void> _startBackgroundPrefetching(Book book) async { // Accepts Book object
    if (_isPrefetchingContent) return;
    
    if (!mounted) return; // Ensure widget is still in tree
    setState(() {
      _isPrefetchingContent = true;
      _prefetchProgress = 0.0;
    });
    
    try {
      // Get cache service and repository
      final cacheService = await ref.read(cacheServiceProvider.future);
      final readingRepo = await ref.read(consolidatedBookRepoProvider.future);
      
      final bookId = book.firestoreDocId;
      final imageUrls = <String>[];
      
      if (book.thumbnailUrl != null && book.thumbnailUrl!.isNotEmpty) {
        imageUrls.add(book.thumbnailUrl!);
      }
      if (book.audioUrl != null && book.audioUrl!.isNotEmpty) {
        imageUrls.add(book.audioUrl!);
      }
      
      await cacheService.prefetchBookContent(
        bookId: bookId,
        fetchBookData: () async {
          // Per instructions, direct Firestore call for book data is reluctantly kept for now.
          // This is a known point for future refactoring to use a repository raw data method.
          _log.warning("Prefetch fetchBookData: Using direct Firestore call. This should be refactored.");
          final bookDoc = await FirebaseFirestore.instance.collection('books').doc(bookId).get();
          return bookDoc.data() ?? {};
        },
        fetchHeadings: () async {
          _log.info("Prefetch fetchHeadings: Using readingRepo.getBookStructure and extracting headings.");
          final structure = await readingRepo.getBookStructure(bookId);
          List<Map<String, dynamic>> allRawHeadings = [];
          for (var vol in structure.volumes) {
            for (var chap in vol.chapters ?? []) {
              // Assuming Heading model has a toMap() method
              allRawHeadings.addAll(chap.headings?.map((h) => h.toMap()).toList() ?? []);
            }
          }
          for (var chap in structure.standaloneChapters) {
             allRawHeadings.addAll(chap.headings?.map((h) => h.toMap()).toList() ?? []);
          }
          return allRawHeadings;
        },
        fetchHeadingContent: (String headingId) async {
          _log.info("Prefetch fetchHeadingContent: Using readingRepo.getHeadingFullContent for $headingId");
          return await readingRepo.getHeadingFullContent(headingId);
        },
        imageUrls: imageUrls,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _prefetchProgress = progress;
            });
          }
        },
      );
      
      _log.info('Successfully prefetched all content for book ${book.title}');
    } catch (e, stackTrace) {
      _log.severe('Error prefetching book content for ${book.firestoreDocId}: $e', stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isPrefetchingContent = false;
          _prefetchProgress = 1.0;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsyncValue = ref.watch(bookProvider(widget.bookId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return bookAsyncValue.when(
      data: (book) {
        // Book data is available
        // Trigger prefetching if conditions are met
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isPrefetchingContent) {
            _startBackgroundPrefetching(book);
          }
        });
        
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          systemOverlayStyle: isDark 
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
              ),
          title: Text(
            book.title ?? 'Book Detail', 
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600,
              fontSize: _scaleFontSize(22),
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          leading: BackButton(
            color: Colors.white,
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
            // Offline availability indicator/download button with progress
            Consumer(builder: (context, ref, child) {
              final downloadProgressAsyncValue = ref.watch(downloadProgressStreamProvider);
              final isOfflineAsyncValue = ref.watch(isBookAvailableOfflineProvider(widget.bookId));
              
              return downloadProgressAsyncValue.when(
                data: (progressMap) {
                  // Check if this book has an active download
                  final bookProgress = progressMap[widget.bookId];
                  
                  if (bookProgress != null && bookProgress < 100) {
                    // Show circular progress indicator if downloading
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: bookProgress / 100,
                            strokeWidth: 2,
                            color: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.3),
                          ),
                          Text(
                            "${bookProgress.toInt()}%",
                            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Check offline availability if not currently downloading
                  return isOfflineAsyncValue.when(
                    data: (isAvailableOffline) {
                      return IconButton(
                        tooltip: isAvailableOffline ? 'Available offline' : 'Download for offline',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(
                            isAvailableOffline ? Icons.offline_pin : Icons.download,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () async {
                          if (isAvailableOffline) {
                            // Already downloaded, show toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('This book is already available offline'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } else {
                            // Start download
                            HapticFeedback.mediumImpact();
                            final logger = AppLogger.getLogger('BookDetailScreen');
                            logger.info('Starting download of book: ${widget.bookId}');
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading book for offline reading...'),
                                backgroundColor: primaryColor,
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            
                            // Start the download using AsyncValue pattern
                            final result = await ref.read(readingRepositoryProvider).when(
                              data: (repository) async {
                                return await repository.downloadBookForOfflineReading(widget.bookId);
                              },
                              loading: () => Future.value(false),
                              error: (error, stack) {
                                logger.severe('Error accessing repository for download', error, stack);
                                return Future.value(false);
                              },
                            );
                            
                            if (mounted && result == false) {
                              // Only show error message as success will be evident from the UI change
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to download book'),
                                  backgroundColor: AppColor.accent, // Corrected class name
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                    loading: () => IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      onPressed: null,
                    ),
                    error: (_, __) => IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Icon(Icons.error_outline, color: Colors.white, size: 20),
                      ),
                      onPressed: null,
                    ),
                  );
                },
                loading: () => IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  onPressed: null,
                ),
                error: (_, __) => IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(Icons.error_outline, color: Colors.white, size: 20),
                  ),
                  onPressed: null,
                ),
              );
            }),
            // Share button
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
                  // Add haptic feedback like in profile screen
                  HapticFeedback.mediumImpact();
                  
                  // Get book details for sharing
                  final book = _book;
                  if (book == null) return;
                  
                  // Create sharing text
                  final String shareText = '''Check out "${book.title}" by ${book.author ?? 'Unknown Author'} on the Maulana Maududi app!

${book.description != null ? '${book.description?.substring(0, book.description!.length > 100 ? 100 : book.description!.length)}...' : 'A great book to explore!'}

${book.additionalFields['rating'] != null ? '${(book.additionalFields['rating'] as num?)?.toStringAsFixed(1) ?? '4.5'} (${book.additionalFields['rating_count'] ?? '276'})' : ''}

Download the app to read more.''';
                  
                  // Use native share sheet with the proper API for our version
                  try {
                    // Use the Share API that matches our import
                    await Share.share(
                      shareText,
                      subject: 'Check out this book: ${book.title}'
                    );
                    
                    _log.info('Shared book via native share sheet: ${book.title}');
                  } catch (e) {
                    // Fallback to clipboard if native sharing fails
                    _log.warning('Native sharing failed, using clipboard fallback: $e');
                    await Clipboard.setData(ClipboardData(text: shareText));
                    
                    // Show snackbar for clipboard fallback
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Book details copied to clipboard for sharing!'),
                          backgroundColor: primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  }
                  
                  _log.info('Shared book: ${book.title}');
                } catch (e) {
                  _log.warning('Error sharing book: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Could not share this book'),
                        backgroundColor: AppColor.accent, // Corrected class name
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
            ),
            // Favorite button
            Consumer(builder: (context, ref, child) {
              return _buildFavoriteButton(book); // Pass book
            }),
            // Pin button
            IconButton(
              icon: Icon(
                _isBookPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isBookPinned ? AppColor.accent : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
              ),
              onPressed: _togglePinStatus, // No longer rely on _isLoading
              tooltip: _isBookPinned ? 'Remove from Offline Saved Items' : 'Save for Offline Access',
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              // Collapsible Header with Book Details
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.22,
                floating: false,
                pinned: false, // Header fully disappears when scrolled
                snap: false,
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 16
                    ),
                    child: _buildMinimalHeaderContent(context, book),
                  ),
                ),
              ),
              
              // Sticky Tab Bar
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.6),
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    labelStyle: GoogleFonts.inter(
                      fontSize: _scaleFontSize(14),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: _scaleFontSize(14),
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
                pinned: true, // Tabs remain at top when scrolling
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(book),
              _buildChaptersTab(),
              _buildBookmarksTab(),
              _buildAiInsightsTab(),
            ],
          ),
        ),
        // Enhanced bottom bar with heart button and "Start Reading" button - MORE COMPACT
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.05, 
            right: MediaQuery.of(context).size.width * 0.05, 
            top: 12, // Reduced vertical padding
            bottom: MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom + 6  // Reduced bottom padding
                : 12, // Reduced bottom padding
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
              // Heart/Favorite button - MORE COMPACT
              Consumer(builder: (context, ref, child) {
                return _buildFavoriteButton(book); // Pass book
              }),
              
              SizedBox(width: MediaQuery.of(context).size.width * 0.03), // Reduced spacing
              
              // Start Reading button - MORE COMPACT
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
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), // Reduced from 18
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Reduced from 14
                    ),
                    elevation: 2, // Reduced from 3
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.menu_book, size: 20), // Reduced from 22
                  label: Text(
                    'Start Reading',
                    style: GoogleFonts.inter(
                      fontSize: 16, // Reduced from 17
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Minimalist header content with thumbnail and title side-by-side
  Widget _buildMinimalHeaderContent(BuildContext context, Book book) {
    // Get theme-specific colors for this method
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
            
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Enhanced Animated Book Cover
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 8 * (1 - value)), // Slight float-in effect
                child: Opacity(
                  opacity: value,
                  child: Container(
                    // Improved proportions
                    width: screenWidth * 0.28,
                    height: screenWidth * 0.40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'book-cover-${book.firestoreDocId}',
                      child: Material(
                        elevation: 0, // Removed extra elevation
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: book.thumbnailUrl != null && book.thumbnailUrl!.isNotEmpty
                          ? OptimizedCachedImage(
                              imageUrl: book.thumbnailUrl!,
                              fit: BoxFit.cover,
                              cacheKey: 'book_thumbnail_${book.id}',
                              placeholderBuilder: (context, url) => Container(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorBuilder: (context, url, error) => Container(
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image_rounded, 
                                          size: 36, 
                                          color: Colors.white.withOpacity(0.8)),
                                      const SizedBox(height: 8),
                                      Text('Image not found',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.menu_book_rounded, 
                                        size: 40, 
                                        color: Colors.white.withOpacity(0.8)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No Cover',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 20),
          
          // Enhanced Book Details with improved styling
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - value), 0), // Slide in from right
                        child: child!,
                      ),
                    );
                  },
                  child: Text(
                    book.title ?? 'Unknown Title',
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: _scaleFontSize(20),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                
                if (book.author != null && book.author!.isNotEmpty) ...[  
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: Text(
                      'by ${book.author!}',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: _scaleFontSize(14),
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.85),
                        fontStyle: FontStyle.italic,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
                
                // Add tags if available
                if (book.tags != null && book.tags!.isNotEmpty) ...[  
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: book.tags!.length > 3 ? 3 : book.tags!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: Text(
                              book.tags![index],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (book.type != null && book.type!.isNotEmpty) ...[  
                  // Show book type if no tags
                  const SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      book.type!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Enhanced Overview Tab with modern design
  Widget _buildOverviewTab(Book book) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: 24
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description section
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface, // Use theme surface color
              borderRadius: BorderRadius.circular(12), // Adjusted radius
              border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1), // Subtle border
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.03), // More subtle shadow
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20), // Adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: colorScheme.primary,
                        size: 22
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Description',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20, // Matched reference style
                        fontWeight: FontWeight.w600, // Matched reference style
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Adjusted spacing
                Text(
                  book.description ?? 'No description available.',
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 17,
                    height: 1.8,
                    color: colorScheme.onSurfaceVariant, // Theme consistent color
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Book details section
          if (book.author != null || book.publisher != null ||
              book.publicationDate != null || book.defaultLanguage != null ||
              book.additionalFields['page_count'] != null) ...[
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface, // Use theme surface color
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1), // Subtle border
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.03), // More subtle shadow
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
                      Icon(Icons.info_outline,
                        color: colorScheme.secondary, size: 22), // Use theme secondary color
                      const SizedBox(width: 10),
                      Text(
                        'Book Details',
                        style: GoogleFonts.playfairDisplay( // Consistent section title style
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (book.author != null) _buildDetailRow('Author', book.author!),
                  if (book.publisher != null) _buildDetailRow('Publisher', book.publisher!),
                  if (book.additionalFields['page_count'] != null) _buildDetailRow('Pages', '${book.additionalFields['page_count']}'),
                  // Removed publication date and language as requested
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // Reduced bottom padding for tighter list
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Padding for text content
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100, // Keep consistent label width
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500, // Adjusted weight
                      fontSize: 14, // Adjusted size
                      color: colorScheme.onSurfaceVariant, // Theme consistent color
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: colorScheme.onSurface, // Theme consistent color
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: theme.dividerColor.withOpacity(0.7)), // Subtle divider
        ],
      ),
    );
  }

  // Update Chapters Tab to use bookStructureProvider
  Widget _buildChaptersTab() {
    final structureAsyncValue = ref.watch(bookStructureProvider(widget.bookId));
    
    return structureAsyncValue.when(
      data: (structure) {
        final List<Volume> volumes = structure.volumes;
        final List<Chapter> standaloneChapters = structure.standaloneChapters;

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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
        
        return const Center(child: Text('No data available.')); // More informative
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        AppLogger.getLogger('BookDetailScreen').severe('Failed to load chapters structure', err, stack);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Could not load chapters',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Error: ${err.toString()}', // Display error message
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Navigate to a chapter for reading
  void _navigateToChapter(Chapter chapter) {
    if (widget.bookId.isNotEmpty && chapter.id != null) {
      // Navigate to reading screen with chapter information using query parameters
      // Ensure all parameters are converted to strings
      final uri = Uri(path: '/read/${widget.bookId}', queryParameters: {
        'chapterId': chapter.id.toString(),
      });
      context.go(uri.toString());
      _log.info('Navigating to chapter: ${chapter.title}, ID: ${chapter.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this chapter. Missing required information.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigate to a specific heading within a chapter
  void _navigateToHeading(Chapter chapter, Heading heading) {
    if (widget.bookId.isNotEmpty && chapter.id != null && heading.id != null) {
      // Navigate to reading screen with heading information using query parameters
      // Ensure all parameters are converted to strings
      final uri = Uri(path: '/read/${widget.bookId}', queryParameters: {
        'chapterId': chapter.id.toString(),
        'headingId': heading.id.toString(),
      });
      context.go(uri.toString());
      _log.info('Navigating to heading: ${heading.title}, ID: ${heading.id}, in chapter: ${chapter.title}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this section. Missing required information.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildChapterCard(int index, Chapter chapter) {
    final hasHeadings = chapter.headings != null && chapter.headings!.isNotEmpty;
    final PageStorageKey expansionTileKey = PageStorageKey<String>('chapter_${chapter.id}');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12), // Slightly reduced margin
      elevation: 1.0, // Subtle elevation
      color: colorScheme.surface, // Use theme surface color
      shadowColor: theme.shadowColor.withOpacity(0.05), // Subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 1), // Consistent border style
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent), // Remove default divider in ExpansionTile
          child: InkWell(
            onTap: hasHeadings ? null : () => _navigateToChapter(chapter),
            child: ExpansionTile(
              key: expansionTileKey,
              backgroundColor: colorScheme.surface, // Theme consistent
              collapsedBackgroundColor: colorScheme.surface, // Theme consistent
              iconColor: colorScheme.primary,
              collapsedIconColor: colorScheme.onSurfaceVariant,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjusted padding
              title: Text(
                chapter.title ?? 'Untitled Chapter',
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface, // Theme consistent
                ),
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl,
              ),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                foregroundColor: colorScheme.primary,
                child: Text(
                  index.toString(),
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 0), // Adjusted padding
              children: hasHeadings
                  ? chapter.headings!
                      .map((heading) => _buildHeadingItem(0, heading, chapter))
                      .toList()
                  : [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        child: Text(
                          'No sub-topics in this chapter.',
                          style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
              onExpansionChanged: (isExpanded) {
                if (isExpanded && !hasHeadings) {
                  _navigateToChapter(chapter);
                }
              },
          ),
        ),
      ),
      )
    );
    
  }

  Widget _buildHeadingItem(int index, Heading heading, Chapter chapter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent, // Ensure it blends with ExpansionTile
      child: InkWell(
        onTap: () {
          // Navigate to the heading using the navigation method
          _navigateToHeading(chapter, heading);
        },
        borderRadius: BorderRadius.circular(8), // Smaller radius for inner items
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Adjusted padding
          child: Row(
            children: [
              Expanded(
                child: Text(
                  heading.title ?? 'Untitled Heading',
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant, // Theme consistent
                  ),
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.rtl,
                ),
              ),
              Icon(Icons.chevron_right, color: theme.dividerColor.withOpacity(0.8)), // Subtle icon color
            ],
          ),
        ),
      ),
    );
  }
  
  // _loadBookStructure method is now removed.
  
  // Update Bookmarks Tab to use AsyncValue pattern
  Widget _buildBookmarksTab() {
    final logger = AppLogger.getLogger('BookDetailScreen');
    // Use AsyncValue pattern to safely access the repository
    final repoAsyncValue = ref.watch(readingRepositoryProvider);
    
    return repoAsyncValue.when<Widget>(
      data: (repository) {
        return FutureBuilder<List<Bookmark>>(
          future: repository.getBookmarks(widget.bookId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              logger.severe('Error loading bookmarks: ${snapshot.error}', snapshot.error, snapshot.stackTrace);
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
                    context.goNamed(
                      RouteNames.readingBook, 
                      pathParameters: {'bookId': widget.bookId},
                      queryParameters: {
                        'chapterId': bookmark.chapterId,
                        'headingId': bookmark.headingId,
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        logger.severe('Error accessing reading repository', error, stack);
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Repository error',
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
      },
    );
  }

  // Update AI Insights Tab
  Widget _buildAiInsightsTab() {
    return Center(
      child: Text('AI Insights Coming Soon'),
    );
  }

  // Helper method to build favorite button with dynamic icon and action
  Widget _buildFavoriteButton() {
    // Watch the list of favorite books for reactive updates
    final favoriteBooksList = ref.watch(favoritesProvider);
    // Determine if the current book is a favorite
    final bool isFavorite = _book != null 
        ? favoriteBooksList.any((favBook) => favBook.firestoreDocId == _book!.firestoreDocId) 
        : false;

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? AppColor.accent : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black54),
      ),
      onPressed: () async {
        if (_book != null) {
          // Use the correct provider and its notifier to toggle favorite status
          await ref.read(favoritesProvider.notifier).toggleFavorite(_book!);
          // UI will update via ref.watch on favoritesProvider
        }
      },
      tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
    );
  }
}
