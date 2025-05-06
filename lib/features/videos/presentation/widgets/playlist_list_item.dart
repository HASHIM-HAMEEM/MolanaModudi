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
      elevation: 3,
      margin: EdgeInsets.zero, // Use padding in the parent ListView
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias, // Clip the image to the card shape
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with overlay
            Stack(
              children: [
                // Playlist thumbnail
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: playlist.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: playlist.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.video_library_outlined,
                              size: 50,
                              color: theme.colorScheme.primary,
                            ),
                          ), 
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.video_library_outlined,
                              size: 50,
                              color: theme.colorScheme.primary,
                            ),
                          ), 
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.video_library_outlined,
                            size: 50,
                            color: theme.colorScheme.primary,
                          ),
                        ), 
                      ),
                ),
                
                // Playlist count overlay
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${playlist.videoCount} videos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Play overlay
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Title and Description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (playlist.description != null && playlist.description!.isNotEmpty)
                    Text(
                      playlist.description!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.video_library, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${playlist.videoCount} videos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: theme.colorScheme.primary,
                            )
                          ],
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