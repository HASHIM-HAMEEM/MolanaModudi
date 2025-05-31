import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/themes/app_color.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/themes/font_utils.dart';
import '../../../reading/presentation/providers/live_reading_progress_provider.dart';
import '../../../reading/presentation/providers/unified_reading_progress_provider.dart';
import '../../../reading/presentation/screens/reading_tab_screen.dart';
import 'package:modudi/core/l10n/app_localizations_wrapper.dart';

/// Continue Reading Card widget for the homepage
/// Reuses the same design and functionality from the reading tab screen
class ContinueReadingCard extends ConsumerStatefulWidget {
  const ContinueReadingCard({super.key});

  @override
  ConsumerState<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends ConsumerState<ContinueReadingCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start animation when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final recentBooksAsyncValue = ref.watch(unifiedRecentBooksProvider);
    
    return recentBooksAsyncValue.when(
      loading: () => const SizedBox.shrink(), // Don't show loading on homepage
      error: (err, stack) => const SizedBox.shrink(), // Don't show errors on homepage
      data: (recentBooks) {
        // Only show if there are recent books
        if (recentBooks.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Show the most recent book
        return _buildContinueReadingSection(recentBooks.first, l10n);
      },
    );
  }

  Widget _buildContinueReadingSection(RecentBook book, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;
    
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  l10n.readingTabContinueReading,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              
              // Continue reading card (same design as reading tab)
              _buildContinueReadingCard(book),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueReadingCard(RecentBook book) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final cardBackgroundColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia 
            : AppColor.surface;
    
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;
    
    final secondaryTextColor = isDark 
        ? AppColor.textSecondaryDark 
        : isSepia 
            ? AppColor.textSecondarySepia 
            : AppColor.textSecondary;
    
    final accentColor = isDark 
        ? AppColor.accentDark 
        : isSepia 
            ? AppColor.accentSepia 
            : AppColor.accent;
    
    final progressBackgroundColor = isDark 
        ? AppColor.progressBackgroundDark 
        : isSepia 
            ? AppColor.primarySepia.withValues(alpha: 0.1) 
            : AppColor.progressBackground;
    
    final liveProgress = ref.watch(liveReadingProgressProvider(book.id));
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go('/read/${book.id}');
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : isSepia
                      ? AppColor.primarySepia.withValues(alpha: 0.1)
                      : theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: book.coverUrl ?? '',
                height: 200,
                width: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => ShimmerPlaceholder(
                  child: Container(
                  height: 200,
                  width: 120,
                  color: accentColor.withValues(alpha: 0.1),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  width: 120,
                  color: accentColor.withValues(alpha: 0.1),
                  child: Icon(Icons.book, size: 40, color: accentColor),
                ),
              ),
            ),
            
            // Book details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      book.author ?? 'Unknown Author',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Progress bar and details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(liveProgress * 100).toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: liveProgress,
                            backgroundColor: progressBackgroundColor,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            minHeight: 6,
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Continue reading button
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context.go('/read/${book.id}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Continue Reading'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 