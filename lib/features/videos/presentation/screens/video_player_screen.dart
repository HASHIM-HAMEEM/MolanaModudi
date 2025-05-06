import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../domain/entities/video_entity.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoEntity video;
  
  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final Logger _logger = Logger('VideoPlayerScreen');
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  bool _isVideoLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  void _initializePlayer() {
    try {
      // Extract video ID from YouTube URL or use the direct ID
      String videoId = widget.video.id;
      
      // Try to extract from URL if it's a YouTube URL
      if (widget.video.youtubeUrl.contains('youtube.com/watch') || 
          widget.video.youtubeUrl.contains('youtu.be/')) {
        try {
          final uri = Uri.parse(widget.video.youtubeUrl);
          if (uri.host == 'youtu.be') {
            videoId = uri.pathSegments.first;
          } else if (uri.host.contains('youtube.com')) {
            videoId = uri.queryParameters['v'] ?? videoId;
          }
        } catch (e) {
          _logger.warning('Error extracting YouTube ID from URL: ${widget.video.youtubeUrl}');
        }
      }
      
      _logger.info('Initializing YouTube player with video ID: $videoId');
      
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      );
      
      _controller.setFullScreenListener((isFullScreen) {
        setState(() {
          _isFullScreen = isFullScreen;
        });
      });
      
      // Listen to controller events for loading status
      _controller.listen((event) {
        final ps = event.playerState;
        if (ps == PlayerState.playing || ps == PlayerState.paused) {
          if (mounted) {
            setState(() {
              _isVideoLoading = false;
            });
          }
        }
      });
      
      // Set a timeout to check if the player is still loading after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isVideoLoading) {
          setState(() {
            _isVideoLoading = false;
          });
        }
      });
      
      // Set orientation to allow both portrait and landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Start playback automatically
      _controller.playVideo();
      
    } catch (e, stackTrace) {
      _logger.severe('Error initializing YouTube player: $e', e, stackTrace);
      setState(() {
        _errorMessage = 'Failed to initialize video player: $e';
        _isVideoLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _logger.info('Disposing VideoPlayerScreen');
    
    // Safe cleanup of controller
    try {
      _controller.close();
    } catch (e) {
      _logger.warning('Error disposing YouTube controller: $e');
    }
    
    // Reset to portrait mode when leaving
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (e) {
      _logger.warning('Error resetting orientation: $e');
    }
    
    super.dispose();
  }
  
  // Open video in external YouTube app
  Future<void> _openInYouTube() async {
    try {
      final url = Uri.parse(widget.video.youtubeUrl);
      final canLaunch = await canLaunchUrl(url);
      
      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open YouTube app')),
          );
        }
      }
    } catch (e) {
      _logger.warning('Error launching YouTube: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube app')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.video.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: _openInYouTube,
              tooltip: 'Open in YouTube',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error playing video', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openInYouTube,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in YouTube App'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: _isFullScreen 
        ? null 
        : AppBar(
            title: Text(widget.video.title, 
              style: const TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_browser),
                onPressed: _openInYouTube,
                tooltip: 'Open in YouTube',
              ),
            ],
          ),
      body: Column(
        children: [
          // Player
          _isVideoLoading
            ? const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
          
          // Open in YouTube button - always visible right below the player
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _openInYouTube,
              icon: const Icon(Icons.ondemand_video),
              label: const Text('Open in YouTube App'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Video info - only shown when not fullscreen
          if (!_isFullScreen)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (widget.video.channelTitle != null)
                      Text(
                        widget.video.channelTitle!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    
                    if (widget.video.viewCount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.video.viewCount!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    
                    const Divider(height: 24),
                    
                    if (widget.video.description != null && widget.video.description!.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.video.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 