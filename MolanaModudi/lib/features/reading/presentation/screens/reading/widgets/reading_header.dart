import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/reading_provider.dart';
import '../../../providers/reading_state.dart';
import '../../../widgets/chapters_bottom_sheet.dart';
// import '../../../widgets/reader_settings_bottom_sheet.dart'; // No longer needed here
import '../../../widgets/bookmarks_bottom_sheet.dart';

// Provider to control the visibility of the settings panel
final settingsPanelVisibilityProvider = StateProvider<bool>((_) => false);

/// Header widget for reading screen - extracted from monolithic ReadingScreen
class ReadingHeader extends ConsumerWidget {
  final String bookId;
  final VoidCallback onBackPressed;

  const ReadingHeader({
    super.key,
    required this.bookId,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingState = ref.watch(readingNotifierProvider(bookId));
    final colors = Theme.of(context).colorScheme;

    // Handle different states
    if (readingState.status == ReadingStatus.loading || 
        readingState.status == ReadingStatus.loadingMetadata ||
        readingState.status == ReadingStatus.loadingContent) {
      return _buildLoadingHeader(colors);
    }
    
    if (readingState.status == ReadingStatus.error) {
      return _buildErrorHeader(colors);
    }

    return _buildHeader(context, ref, readingState, colors);
  }

  Widget _buildLoadingHeader(ColorScheme colors) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface,
            colors.surface.withValues(alpha: 0.95),
            colors.surface.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorHeader(ColorScheme colors) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface,
            colors.surface.withValues(alpha: 0.95),
            colors.surface.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.error_outline, color: colors.error),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ReadingState readingState, ColorScheme colors) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface,
            colors.surface.withValues(alpha: 0.95),
            colors.surface.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Back button with enhanced design
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onBackPressed();
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Book title with enhanced typography
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readingState.bookTitle ?? 'Reading',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (readingState.mainChapterKeys != null && readingState.mainChapterKeys!.isNotEmpty)
                      Text(
                        'Chapter ${readingState.currentChapter + 1} of ${readingState.mainChapterKeys!.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            
              const SizedBox(width: 8),
              
              // Chapter navigation button
              Container(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.list_rounded, color: colors.primary),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showChaptersBottomSheet(context, ref, readingState);
                  },
                  tooltip: 'Chapters',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Bookmarks button
              Container(
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.secondary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.bookmark_rounded, color: colors.secondary),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showBookmarksBottomSheet(context, bookId);
                  },
                  tooltip: 'Bookmarks',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Settings button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showSettingsBottomSheet(context, ref);
                  },
                  icon: Icon(
                    Icons.settings_rounded,
                    color: colors.onSurface,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChaptersBottomSheet(BuildContext context, WidgetRef ref, ReadingState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChaptersBottomSheet(
        bookId: bookId,
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    print('[DEBUG] ReadingHeader: Showing settings panel via StateProvider'); // DEBUG LOG
    ref.read(settingsPanelVisibilityProvider.notifier).state = true;
  }

  void _showBookmarksBottomSheet(BuildContext context, String currentBookId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookmarksBottomSheet(
        bookId: currentBookId,
        onBookmarkSelected: (chapterId, headingId) {
          // TODO: Navigate to specific bookmark location
        },
      ),
    );
  }
} 