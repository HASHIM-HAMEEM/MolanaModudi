import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_color.dart';
import '../../../../../routes/route_names.dart';
import '../../../data/models/book_models.dart';
import 'widgets/parallax_header.dart';
import 'widgets/book_overview_tab.dart';
import 'widgets/chapters_tab.dart';
import 'widgets/bookmarks_tab.dart';
import 'widgets/ai_insights_tab.dart';
import 'providers/book_detail_provider.dart';
import '../../../../reading/presentation/providers/unified_reading_progress_provider.dart';

/// Clean, focused BookDetailPage - no business logic, pure presentation
class BookDetailPage extends ConsumerStatefulWidget {
  final String bookId;
  final String? source;

  const BookDetailPage({
    super.key,
    required this.bookId,
    this.source,
  });

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage>
    with SingleTickerProviderStateMixin {
  final _log = Logger('BookDetailPage');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _log.info('BookDetailPage initialized for bookId: ${widget.bookId}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else if (GoRouter.of(context).canPop()) {
        GoRouter.of(context).pop();
      } else {
        GoRouter.of(context).go(RouteNames.home);
      }
    } catch (e) {
      _log.warning('Back navigation error: $e');
      GoRouter.of(context).go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookDetailAsync = ref.watch(bookDetailProvider(widget.bookId));

    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        appBar: bookDetailAsync.maybeWhen(
          data: (bookDetail) => _buildSimpleAppBar(bookDetail.book),
          orElse: () => _buildSimpleAppBar(null),
        ),
        body: bookDetailAsync.when(
          loading: () => _buildLoadingState(theme),
          error: (error, stackTrace) => _buildErrorState(error.toString(), theme),
          data: (bookDetail) => _buildMainContent(bookDetail, theme),
        ),
        bottomNavigationBar: bookDetailAsync.maybeWhen(
          data: (bookDetail) => _buildFloatingBottomBar(bookDetail),
          orElse: () => null,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar(Book? book) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleBackNavigation,
                  borderRadius: BorderRadius.circular(12),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: book != null 
                      ? () => ref.read(bookDetailProvider(widget.bookId).notifier).shareBook()
                      : null,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BookDetailState bookDetail, ThemeData theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Parallax Header
        ParallaxHeader(
          book: bookDetail.book,
          onFavoriteToggle: () => ref.read(bookDetailProvider(widget.bookId).notifier).toggleFavorite(),
          isFavorite: bookDetail.isFavorite,
        ),
        
        // Modern Tab Bar
        _buildModernTabBar(),
        
        // Tab Content - Flexible height to prevent scrolling issues
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBookOverviewTab(bookDetail.book),
              _buildChaptersTab(),
              _buildBookmarksTab(),
              _buildAiInsightsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Temporary placeholder widgets - TODO: Extract to separate files
  Widget _buildModernTabBar() {
    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        height: 60, // Fixed height to prevent overflow
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: _AirbnbStyleIndicator(theme),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                _buildAirbnbTab('Overview', Icons.home_outlined),
                _buildAirbnbTab('Chapters', Icons.menu_book_outlined),
                _buildAirbnbTab('Bookmarks', Icons.bookmark_outline),
                _buildAirbnbTab('Insights', Icons.lightbulb_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAirbnbTab(String text, IconData icon) {
    return SizedBox(
      height: 52, // Fixed height
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookOverviewTab(Book book) {
    return BookOverviewTab(book: book);
  }

  Widget _buildChaptersTab() {
    final bookDetailAsync = ref.watch(bookDetailProvider(widget.bookId));
    return bookDetailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (bookDetail) => ChaptersTab(book: bookDetail.book),
    );
  }

  Widget _buildBookmarksTab() {
    final bookDetailAsync = ref.watch(bookDetailProvider(widget.bookId));
    return bookDetailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (bookDetail) => BookmarksTab(book: bookDetail.book),
    );
  }

  Widget _buildAiInsightsTab() {
    final bookDetailAsync = ref.watch(bookDetailProvider(widget.bookId));
    return bookDetailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (bookDetail) => AiInsightsTab(book: bookDetail.book),
    );
  }

  Widget _buildFloatingBottomBar(BookDetailState bookDetail) {
    final theme = Theme.of(context);
    
    // Watch the unified recent books to check if this book has been read before
    final recentBooksAsync = ref.watch(unifiedRecentBooksProvider);
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Favorite Button
          IconButton(
            onPressed: () => ref.read(bookDetailProvider(widget.bookId).notifier).toggleFavorite(),
            icon: Icon(
              bookDetail.isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: bookDetail.isFavorite 
                ? Colors.red 
                : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            tooltip: bookDetail.isFavorite ? 'Remove from favorites' : 'Add to favorites',
            padding: const EdgeInsets.all(8),
          ),
          
          const SizedBox(width: 4),
          
          // Main Reading Button - Updated to show "Start Reading" or "Continue Reading"
          Expanded(
            child: recentBooksAsync.when(
              loading: () => ElevatedButton(
                onPressed: () {
                  GoRouter.of(context).go(RouteNames.readingWithId(bookDetail.book.id.toString()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Start Reading',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              error: (error, stack) => ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go(RouteNames.readingWithId(bookDetail.book.id.toString()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                  'Start Reading',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              ),
              data: (recentBooks) {
                // Check if this book has been read before
                final hasBeenRead = recentBooks.any((book) => book.id == widget.bookId);
                final buttonText = hasBeenRead ? 'Continue Reading' : 'Start Reading';
                
                return ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).go(RouteNames.readingWithId(bookDetail.book.id.toString()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withValues(alpha: 0.1),
            AppColor.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading masterpiece...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 56),
              const SizedBox(height: 32),
              const Text('Oops! Something went wrong'),
              const SizedBox(height: 16),
              Text(error),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(bookDetailProvider(widget.bookId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean Airbnb-style tab indicator
class _AirbnbStyleIndicator extends Decoration {
  final ThemeData theme;

  const _AirbnbStyleIndicator(this.theme);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _AirbnbStylePainter(theme, onChanged);
  }
}

class _AirbnbStylePainter extends BoxPainter {
  final ThemeData theme;
  
  _AirbnbStylePainter(this.theme, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    
    // Create rounded rectangle with Airbnb-style rounded corners
    final RRect rrect = RRect.fromRectAndRadius(
      rect.deflate(2), // Small margin for clean look
      const Radius.circular(12), // Softer, more Airbnb-like radius
    );
    
    // Airbnb-style solid color with subtle gradient
    final paint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;
    
    // Very subtle shadow for depth (Airbnb style)
    final shadowPaint = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    // Draw subtle shadow
    canvas.drawRRect(rrect.shift(const Offset(0, 1)), shadowPaint);
    
    // Draw main indicator
    canvas.drawRRect(rrect, paint);
  }
} 