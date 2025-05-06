import 'package:flutter/material.dart';
import '../../domain/entities/video_entity.dart';
import 'video_tile.dart';

// Placeholder data model
class _PlaceholderVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String duration;

  _PlaceholderVideo(this.id, this.title, this.thumbnailUrl, this.duration);
}

class VideoList extends StatelessWidget {
  final String title;
  final List<dynamic> videos; // Accept both VideoEntity and _PlaceholderVideo
  final VoidCallback? onViewAll;

  const VideoList({
    super.key,
    required this.title,
    required this.videos,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Sample data matching the reference
    final sampleVideos = [
      _PlaceholderVideo('1', "Understanding Islamic Society", "https://via.placeholder.com/150x90/047857/FFFFFF?text=Vid1", "12:45"),
      _PlaceholderVideo('2', "Principles of Islamic State", "https://via.placeholder.com/150x90/059669/FFFFFF?text=Vid2", "18:23"),
    ];

    // Use sample data for now
    final displayVideos = videos.isEmpty ? sampleVideos : videos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with "View All" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: textTheme.titleLarge),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12.0), // Spacing below header

        // Videos list
        ...List.generate(
          displayVideos.length,
          (index) {
            final video = displayVideos[index];
            
            // Handle both VideoEntity and _PlaceholderVideo
            String title, thumbnailUrl, duration;
            
            if (video is VideoEntity) {
              title = video.title;
              thumbnailUrl = video.thumbnailUrl ?? 'https://via.placeholder.com/150x90/047857/FFFFFF?text=Video';
              duration = video.duration ?? 'Unknown';
            } else if (video is _PlaceholderVideo) {
              title = video.title;
              thumbnailUrl = video.thumbnailUrl;
              duration = video.duration;
            } else {
              // Fallback
              title = "Unknown Video";
              thumbnailUrl = 'https://via.placeholder.com/150x90/047857/FFFFFF?text=Unknown';
              duration = 'Unknown';
            }
            
            return Padding(
              padding: EdgeInsets.only(bottom: index < displayVideos.length - 1 ? 12.0 : 0),
              child: VideoTile(
                title: title,
                thumbnailUrl: thumbnailUrl,
                duration: duration,
                onTap: () {
                  // TODO: Implement navigation to video player screen
                  print('Tapped on video: $title');
                },
              ),
            );
          },
        ),
      ],
    );
  }
} 