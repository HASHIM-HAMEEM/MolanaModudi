import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/providers.dart';
import '../../domain/entities/video_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago; // For relative time formatting
// Keep if still used, or remove if not.
import 'package:url_launcher/url_launcher.dart';

// Helper function to format video duration from ISO 8601
String formatVideoDuration(String? isoDuration) {
  if (isoDuration == null || isoDuration.isEmpty) {
    return '--:--';
  }
  try {
    final duration = Duration(seconds: _parseIso8601Duration(isoDuration));
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  } catch (e) {
    // Log error or handle appropriately
    return '--:--'; // Fallback for parsing errors
  }
}

// Helper function to parse ISO 8601 duration (simplified version)
int _parseIso8601Duration(String isoDuration) {
  if (!isoDuration.startsWith('PT')) {
    throw const FormatException('Invalid ISO 8601 duration format');
  }
  final RegExp regExp = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
  final match = regExp.firstMatch(isoDuration);
  if (match == null) {
    return 0;
  }
  final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
  final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
  return (hours * 3600) + (minutes * 60) + seconds;
}

// Helper function to format view count
String formatViewCount(String? viewCountStr) {
  if (viewCountStr == null) return 'N/A views';
  final count = int.tryParse(viewCountStr);
  if (count == null) return 'N/A views';

  if (count < 1000) {
    return '$count views';
  } else if (count < 1000000) {
    return '${(count / 1000).toStringAsFixed(1)}K views';
  } else if (count < 1000000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M views';
  } else {
    return '${(count / 1000000000).toStringAsFixed(1)}B views';
  }
}

// Helper function to format published date
String formatPublishedDate(String? dateStr) {
  if (dateStr == null) return 'Unknown date';
  try {
    final dateTime = DateTime.parse(dateStr);
    return timeago.format(dateTime);
  } catch (e) {
    return 'Unknown date'; // Fallback for parsing errors
  }
}

class VideoListItem extends ConsumerWidget {
  final VideoEntity video;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formattedDuration = formatVideoDuration(video.duration);
    final formattedViewCount = formatViewCount(video.viewCount);
    final formattedPublishedAt = formatPublishedDate(video.publishedAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with duration
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(
                    width: 120, // Standard YouTube thumbnail aspect ratio (16:9)
                    height: (120 * 9) / 16, // Calculate height for 16:9 aspect ratio
                    child: CachedNetworkImage(
                      cacheManager: ref.watch(defaultCacheManagerProvider).maybeWhen(
                        data: (manager) => manager,
                        orElse: () => null,
                      ),
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 30,
                            color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.errorContainer,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 30,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (formattedDuration.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(4.0),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Video details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3, // Improve line spacing
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (video.channelTitle != null && video.channelTitle!.isNotEmpty)
                    Text(
                      video.channelTitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (formattedViewCount.isNotEmpty)
                        Text(
                          formattedViewCount,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      if (formattedViewCount.isNotEmpty && formattedPublishedAt.isNotEmpty)
                        Text(
                          ' • ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      if (formattedPublishedAt.isNotEmpty)
                        Text(
                          formattedPublishedAt,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // More options icon
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20), // Larger tap target
                onTap: () {
                  // Show options menu
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder( // Rounded top corners
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              video.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2, // Allow title to wrap
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.play_circle_outline_rounded),
                            title: const Text('Play video'),
                            onTap: () {
                              Navigator.pop(context);
                              onTap();
                            },
                          ),
                          if (video.youtubeUrl.isNotEmpty) // Check if youtubeUrl is available
                            ListTile(
                              leading: const Icon(Icons.open_in_new_rounded),
                              title: const Text('Open in YouTube'),
                              onTap: () async {
                                Navigator.pop(context);
                                final url = Uri.parse(video.youtubeUrl);
                                try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not launch YouTube')), 
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: Could not open YouTube - $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ListTile(
                            leading: const Icon(Icons.share_outlined),
                            title: const Text('Share'),
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Implement sharing functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sharing is not implemented yet')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0), // Increase padding for touch target
                  child: Icon(Icons.more_vert, size: 20), 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}