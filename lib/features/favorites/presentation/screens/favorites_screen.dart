import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:modudi/features/favorites/providers/favorites_provider.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/library/presentation/widgets/book_grid_item.dart'; // Using the enhanced BookGridItem
import 'package:go_router/go_router.dart';
import 'package:modudi/core/themes/app_color.dart';

class FavoritesScreen extends ConsumerWidget {
  FavoritesScreen({super.key});
  
  final _log = Logger('FavoritesScreen');
  
  // Helper method to scale font sizes based on settings
  double _scaleFontSize(double baseSize, WidgetRef ref) {
    final settingsState = ref.read(settingsProvider);
    final fontSizeMultiplier = settingsState.fontSize.size / 14.0; // Use 14.0 as the base font size
    return baseSize * fontSizeMultiplier;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings provider to react to font size changes
    ref.watch(settingsProvider); // Watch to rebuild on changes
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme, ref),
      body: favorites.isEmpty
          ? _buildEmptyState(context, ref)
          : _buildFavoritesGrid(context, favorites, ref),
    );
  }
  
  // Build an elegant app bar with perfect theme integration
  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    // Theme-specific colors
    final backgroundColor = isSepia 
        ? AppColor.surfaceSepia 
        : theme.scaffoldBackgroundColor;
    
    final titleColor = isSepia 
        ? AppColor.textPrimarySepia 
        : theme.colorScheme.onSurface;
    
    final borderColor = isSepia
        ? AppColor.primarySepia.withOpacity(0.15)
        : isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05);
    
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      centerTitle: false,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: backgroundColor,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: backgroundColor,
            ),
      title: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(
          fontSize: _scaleFontSize(20, ref),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: titleColor,
          height: 1.2,
        ),
        child: const Text('Favorites'),
      ),
      // No actions needed
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          height: 1.0,
          color: borderColor,
        ),
      ),
    );
  }
  
  // Build the favorites grid with animations and long-press functionality
  Widget _buildFavoritesGrid(BuildContext context, List<Book> favorites, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.only(top: 20.0, bottom: 28.0),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65, // Adjusted for better book cover proportions
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 20.0,
          ),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final Book book = favorites[index];
            
            // Debug log to check thumbnail URL
            _log.info('Book: ${book.title}, Thumbnail URL: ${book.thumbnailUrl}');
            
            return AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: 2,
              duration: const Duration(milliseconds: 350),
              child: ScaleAnimation(
                scale: 0.94,
                child: FadeInAnimation(
                  child: GestureDetector(
                    onLongPress: () => _showRemoveDialog(context, book, ref),
                    child: BookGridItem(
                      book: book,
                      onTap: () {
                        _log.info('Opening book detail: ${book.firestoreDocId}');
                        // Navigate to book detail page
                        context.go('/books/${book.firestoreDocId}');
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Show dialog to confirm removing a book from favorites
  void _showRemoveDialog(BuildContext context, Book book, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    final primaryColor = isSepia ? AppColor.primarySepia : theme.colorScheme.primary;
    final backgroundColor = isSepia ? AppColor.surfaceSepia : theme.colorScheme.surface;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Remove from Favorites?',
          style: TextStyle(
            color: isSepia ? AppColor.textPrimarySepia : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Do you want to remove "${book.title}" from your favorites?',
          style: TextStyle(
            color: isSepia 
                ? AppColor.textSecondarySepia 
                : theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: primaryColor.withOpacity(0.8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).removeFavorite(book.firestoreDocId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${book.title} removed from favorites'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: primaryColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    // Theme-specific colors
    final primaryColor = isSepia ? AppColor.primarySepia : theme.colorScheme.primary;
    final textColor = isSepia ? AppColor.textPrimarySepia : theme.colorScheme.onSurface;
    final secondaryTextColor = isSepia 
        ? AppColor.textSecondarySepia 
        : theme.colorScheme.onSurface.withOpacity(0.7);
    
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSepia
              ? AppColor.surfaceSepia.withOpacity(0.5)
              : isDark
                  ? theme.colorScheme.surface.withOpacity(0.3)
                  : theme.colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSepia
                ? AppColor.primarySepia.withOpacity(0.1)
                : isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
          ),
        ),
        margin: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_outlined,
              size: 80,
              color: primaryColor.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Text(
              "No Favorites Yet",
              style: TextStyle(
                fontSize: _scaleFontSize(24, ref),
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Books you mark as favorite will appear here for quick access",
              style: TextStyle(
                fontSize: _scaleFontSize(16, ref),
                color: secondaryTextColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/library'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text(
                "Browse Library",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}