import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/themes/app_color.dart';
import '../../../../features/videos/presentation/providers/video_providers.dart';
import '../../../../features/videos/domain/entities/playlist_entity.dart';

class VideoLecturesSection extends ConsumerWidget {
  const VideoLecturesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    // Theme-aware colors
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : const Color(0xFF222222);
            
    final primaryGreen = isDark
        ? const Color(0xFF10B981) // Lighter green for dark mode
        : isSepia
            ? const Color(0xFF047857) // Darker green for sepia
            : const Color(0xFF059669); // Standard green for light
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Video Lectures',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/videos');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Playlists display
        SizedBox(
          height: 240,
          child: _buildPlaylistContent(context, playlistState, isDark, isSepia, textColor, primaryGreen),
        ),
      ],
    );
  }

  Widget _buildPlaylistContent(BuildContext context, VideoState<List<PlaylistEntity>> state, 
                              bool isDark, bool isSepia, Color textColor, Color primaryGreen) {
    // Loading state
    if (state.isLoading && !state.hasData) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: primaryGreen,
        )
      );
    }
    
    // Error state with no data
    if (state.hasError && !state.hasData) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColor.surfaceDark.withOpacity(0.5)
                      : isSepia 
                          ? AppColor.surfaceSepia.withOpacity(0.5)
                          : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.video_library_outlined, 
                  size: 32, 
                  color: isDark 
                      ? AppColor.textSecondaryDark 
                      : isSepia 
                          ? AppColor.textSecondarySepia 
                          : const Color(0xFF717171),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load videos',
                style: TextStyle(
                  color: isDark 
                      ? AppColor.textSecondaryDark 
                      : isSepia 
                          ? AppColor.textSecondarySepia 
                          : const Color(0xFF717171),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Empty state
    if (state.hasData && state.data!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColor.surfaceDark.withOpacity(0.5)
                      : isSepia 
                          ? AppColor.surfaceSepia.withOpacity(0.5)
                          : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.video_library_outlined, 
                  size: 32, 
                  color: isDark 
                      ? AppColor.textSecondaryDark 
                      : isSepia 
                          ? AppColor.textSecondarySepia 
                          : const Color(0xFF717171),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No videos available',
                style: TextStyle(
                  color: isDark 
                      ? AppColor.textSecondaryDark 
                      : isSepia 
                          ? AppColor.textSecondarySepia 
                          : const Color(0xFF717171),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Success state with data
    if (state.hasData && state.data!.isNotEmpty) {
      final playlists = state.data!;
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return Container(
            width: 200,
            margin: EdgeInsets.only(
              right: index == playlists.length - 1 ? 0 : 20,
            ),
            child: GestureDetector(
              onTap: () {
                context.go('/videos/playlist/${playlist.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail with shadow
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: playlist.thumbnailUrl != null && playlist.thumbnailUrl!.isNotEmpty
                              ? Image.network(
                                  playlist.thumbnailUrl!,
                                  height: 120,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      width: 200,
                                      color: isDark 
                                          ? AppColor.surfaceDark 
                                          : isSepia 
                                              ? AppColor.surfaceSepia 
                                              : const Color(0xFFF7F7F7),
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image_outlined, 
                                          color: isDark 
                                              ? AppColor.textSecondaryDark 
                                              : isSepia 
                                                  ? AppColor.textSecondarySepia 
                                                  : const Color(0xFF717171),
                                          size: 32,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  height: 120,
                                  width: 200,
                                  color: isDark 
                                      ? AppColor.surfaceDark 
                                      : isSepia 
                                          ? AppColor.surfaceSepia 
                                          : const Color(0xFFF7F7F7),
                                  child: Center(
                                    child: Icon(
                                      Icons.video_library_outlined, 
                                      color: isDark 
                                          ? AppColor.textSecondaryDark 
                                          : isSepia 
                                              ? AppColor.textSecondarySepia 
                                              : const Color(0xFF717171),
                                      size: 32,
                                    ),
                                  ),
                                ),
                        ),
                        // Play button overlay
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        // Video count
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${playlist.videoCount} videos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    playlist.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: textColor,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description if available
                  if (playlist.description?.isNotEmpty == true)
                    Text(
                      playlist.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark 
                            ? AppColor.textSecondaryDark 
                            : isSepia 
                                ? AppColor.textSecondarySepia 
                                : const Color(0xFF717171),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    
    return const SizedBox.shrink();
  }
} 