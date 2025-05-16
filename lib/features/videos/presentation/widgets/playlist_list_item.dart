import 'package:flutter/material.dart';
import '../../domain/entities/playlist_entity.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Use cached image for performance

class PlaylistListItem extends StatelessWidget {
  final PlaylistEntity playlist;
  final VoidCallback onTap;

  const PlaylistListItem({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          children: [
            // Thumbnail with overlay
            Hero(
              tag: 'playlist-thumbnail-${playlist.id}', // Unique tag for Hero animation
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Playlist thumbnail
                  SizedBox(
                    height: 200, // Increased height for more impact
                    width: double.infinity,
                    child: playlist.thumbnailUrl != null && playlist.thumbnailUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: playlist.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                            child: Center(
                              child: Icon(
                                Icons.video_library_outlined,
                                size: 50,
                                color: theme.colorScheme.onSecondaryContainer.withOpacity(0.7),
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
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.video_library_outlined,
                              size: 50,
                              color: theme.colorScheme.onSecondaryContainer.withOpacity(0.7),
                            ),
                          ), 
                        ),
                  ),
                  
                  // Play overlay (more subtle)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
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
                        color: Colors.black.withOpacity(0.75),
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
            
            // Title and Description
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: theme.textTheme.titleLarge?.copyWith( // Larger title
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (playlist.description != null && playlist.description!.isNotEmpty)
                    Text(
                      playlist.description!,
                      style: theme.textTheme.bodyMedium?.copyWith( // Slightly larger body
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Align button to the right
                    children: [
                      // Removed the redundant video count text here as it's on the image
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        label: const Text('View Playlist'),
                        onPressed: onTap, // Use the main onTap callback
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12), // Consistent rounding
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}