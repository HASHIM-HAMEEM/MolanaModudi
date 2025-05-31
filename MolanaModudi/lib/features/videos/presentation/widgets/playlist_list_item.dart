import 'package:flutter/material.dart';
import '../../domain/entities/playlist_entity.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Use cached image for performance
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/providers.dart';

class PlaylistListItem extends ConsumerWidget {
  final PlaylistEntity playlist;
  final VoidCallback onTap;

  const PlaylistListItem({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4, // Slightly more pronounced shadow
      margin: EdgeInsets.zero, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Softer corners
      ),
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0), // Match card's border radius for ripple
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Prevent overflow by allowing column to shrink
          children: [
            // Thumbnail with overlay
            Hero(
              tag: 'playlist-thumbnail-${playlist.id}', // Unique tag for Hero animation
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Playlist thumbnail
                  SizedBox(
                    height: 140, // Reduced height to prevent overflow
                    width: double.infinity,
                    child: playlist.thumbnailUrl != null && playlist.thumbnailUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: playlist.thumbnailUrl!,
                          fit: BoxFit.cover,
                          cacheManager: ref.watch(defaultCacheManagerProvider).maybeWhen(
                            data: (manager) => manager,
                            orElse: () => null,
                          ),
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                            child: Center(
                              child: Icon(
                                Icons.video_library_outlined,
                                size: 50,
                                color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                              ),
                            ), 
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.errorContainer,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 50,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ), 
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                          child: Center(
                            child: Icon(
                              Icons.video_library_outlined,
                              size: 50,
                              color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                            ),
                          ), 
                        ),
                  ),
                  
                  // Play overlay (more subtle)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48, // Slightly larger play icon
                    ),
                  ),

                  // Playlist count overlay (top right for better visibility)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.playlist_play_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${playlist.videoCount} videos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Title and Description - Completely restructured to prevent overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0), // Minimal padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title only - simplified
                  Text(
                    playlist.title,
                    style: theme.textTheme.titleSmall?.copyWith( // Even smaller title
                      fontWeight: FontWeight.w600,
                      height: 1.1, // Very tight line height
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Small spacing
                  const SizedBox(height: 6),
                  // Simple action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Video count
                      Text(
                        '${playlist.videoCount} videos',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      // Simple play button
                      Material(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Play',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}