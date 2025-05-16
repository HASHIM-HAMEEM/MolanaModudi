import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../domain/entities/video_entity.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import '../widgets/video_list_item.dart'; // For helper functions like formatVideoDuration etc.

class VideoPlayerScreen extends StatefulWidget {
  final VideoEntity video;
  // final List<VideoEntity>? currentPlaylist; // For potential 'Up Next' feature

  const VideoPlayerScreen({
    super.key,
    required this.video,
    // this.currentPlaylist,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final Logger _logger = Logger('VideoPlayerScreen');
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        // privacyEnhanced: true, // Commenting out for now, may not exist or be named differently
      ),
    );

    _controller.listen((event) { // event is YoutubePlayerValue
      if (!mounted) return; // Check mounted state first

      // Simplify readiness check: if not unknown, it's initialized.
      final bool isPlayerConsideredReady = event.playerState != PlayerState.unknown;
                                         
      if (isPlayerConsideredReady && !_isPlayerReady) {
        if (mounted) setState(() => _isPlayerReady = true);
        _logger.info('YouTube Player is ready for video: ${widget.video.title} with state: ${event.playerState}');
      }
      if (event.playerState == PlayerState.ended) {
        _logger.info('Video finished: ${widget.video.title}');
      }
      if (event.hasError) {
        _logger.severe('YouTube Player Error: ${event.error}');
      }
    });
    
    _controller.setFullScreenListener((isFullScreen) {
      _logger.info('Fullscreen change: $isFullScreen');
      if (isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        // It's common for SystemChrome.setPreferredOrientations to take a bit to apply.
        // Delaying the rebuild slightly can help ensure the layout is correct.
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {}); // Force rebuild to adjust layout if necessary
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    // Ensure orientation is reset if screen is disposed while in landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _launchInYouTube(String videoId) async {
    final Uri youtubeUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(youtubeUrl)) {
      await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication);
    } else {
      _logger.severe('Could not launch YouTube URL: $youtubeUrl');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open in YouTube.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.video.title, style: const TextStyle(fontSize: 18)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded), // Close icon for a player screen
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close Player',
          ),
          elevation: 1, // Subtle elevation
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _isPlayerReady
                    ? YoutubePlayer(controller: _controller)
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.video.channelTitle ?? 'Unknown Channel',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            formatViewCount(widget.video.viewCount), // Called directly
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4), // Spacer
                          Text('•', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 4), // Spacer
                          Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            formatPublishedDate(widget.video.publishedAt), // Called directly
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      if (widget.video.description != null && widget.video.description!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.video.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                          label: const Text('Open in YouTube App'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            textStyle: theme.textTheme.labelLarge,
                            // backgroundColor: theme.colorScheme.secondary, // Optional: if you want distinct color
                            // foregroundColor: theme.colorScheme.onSecondary, // Optional: if you want distinct color
                          ),
                          onPressed: () => _launchInYouTube(widget.video.id),
                        ),
                      ),
                      const SizedBox(height: 16), // Extra spacing at the bottom
                      // TODO: Implement 'Up Next' or related videos section if currentPlaylist is available
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}