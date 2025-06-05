import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../domain/entities/video_entity.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:share_plus/share_plus.dart';

/// Screen for playing YouTube videos with enhanced UI and controls
class VideoPlayerScreen extends ConsumerStatefulWidget {
  final VideoEntity video;
  final String? playlistId;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    this.playlistId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isFullScreen = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid YouTube URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'ar',
        showLiveFullscreenButton: true,
      ),
    );

    _controller.addListener(_playerListener);
  }

  void _playerListener() {
    if (_controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
      });
    }

    if (_controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _controller.value.isFullScreen;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_playerListener);
    _controller.dispose();
    // Reset orientation when leaving video player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
      overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Allow all orientations when exiting fullscreen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, 
          overlays: SystemUiOverlay.values);
      },
      onEnterFullScreen: () {
        // Allow landscape orientations for fullscreen video
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: colorScheme.primary,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              widget.video.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          // Handle video end - could navigate to next video in playlist
          _handleVideoEnd();
        },
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _isFullScreen ? null : AppBar(
          title: Text(
            widget.video.title,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share_outlined),
                    title: Text('Share'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'youtube',
                  child: ListTile(
                    leading: Icon(Icons.smart_display_outlined),
                    title: Text('Open in YouTube'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: _isFullScreen,
          child: Column(
            children: [
              // Video Player
              player,
            
            // Video Information and Controls
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Text(
                      widget.video.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Video Metadata
                    if (widget.video.channelTitle != null ||
                        widget.video.publishedAt != null ||
                        widget.video.viewCount != null) ...[
                      Wrap(
                        spacing: 16,
                        children: [
                          if (widget.video.channelTitle != null)
                            _buildMetadataChip(
                              Icons.person,
                              widget.video.channelTitle!,
                              colorScheme,
                            ),
                          if (widget.video.duration != null)
                            _buildMetadataChip(
                              Icons.access_time,
                              widget.video.duration!,
                              colorScheme,
                            ),
                          if (widget.video.viewCount != null)
                            _buildMetadataChip(
                              Icons.visibility,
                              '${widget.video.viewCount} views',
                              colorScheme,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Action Buttons
                    _buildActionButtons(colorScheme),
                    const SizedBox(height: 16),
                    
                    // Video Description
                    if (widget.video.description != null &&
                        widget.video.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildExpandableDescription(theme, colorScheme),
                    ],
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

  Widget _buildMetadataChip(IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Share Button - Compact design
        _buildCompactActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: _shareVideo,
          colorScheme: colorScheme,
          isPrimary: false,
        ),
        const SizedBox(width: 16),
        
        // Open in YouTube Button - Compact design
        _buildCompactActionButton(
          icon: Icons.smart_display_outlined,
          label: 'YouTube',
          onPressed: _openInYouTube,
          colorScheme: colorScheme,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary 
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary 
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isPrimary 
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Future<void> _openInYouTube() async {
    try {
      final uri = Uri.parse(widget.video.youtubeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open YouTube'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening YouTube: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareVideo() async {
    try {
      await Share.share(
        '${widget.video.title}\n\n${widget.video.youtubeUrl}',
        subject: widget.video.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExpandableDescription(ThemeData theme, ColorScheme colorScheme) {
    final description = widget.video.description!;
    final isLongDescription = description.length > 150;
    final displayText = _isDescriptionExpanded || !isLongDescription
        ? description
        : '${description.substring(0, 150)}...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (isLongDescription) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded ? 'Show less' : 'Show more',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareVideo();
        break;
      case 'youtube':
        _openInYouTube();
        break;
    }
  }

  void _handleVideoEnd() {
    // Could implement auto-play next video in playlist
    if (widget.playlistId != null) {
      // Load next video from playlist
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video ended. Next video functionality coming soon!'),
        ),
      );
    }
  }
}