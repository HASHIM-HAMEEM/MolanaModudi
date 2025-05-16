import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VideoTile extends StatelessWidget {
  final String title;
  final String thumbnailUrl;
  final String duration;
  final String source;
  final VoidCallback? onTap;

  const VideoTile({
    super.key,
    required this.title,
    required this.thumbnailUrl,
    required this.duration,
    this.source = 'YouTube', // Default source
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const double thumbnailWidth = 96.0; // w-24 in reference
    const double thumbnailHeight = 64.0; // h-16 in reference

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail with Play Icon and Duration
            SizedBox(
              width: thumbnailWidth,
              height: thumbnailHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      width: thumbnailWidth,
                      height: thumbnailHeight,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.error_outline, size: 24),
                      ),
                    ),
                  ),
                  // Play Icon Overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  ),
                  // Duration Badge
                  Positioned(
                    bottom: 4.0,
                    right: 4.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: Text(
                        duration,
                        style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            // Video Title and Source
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontSize: 14), // Slightly smaller title
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    source,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
