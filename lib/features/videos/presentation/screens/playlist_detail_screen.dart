import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../widgets/video_list_item.dart';
import '../providers/video_provider.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import 'video_player_screen.dart'; 

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final Logger _logger = Logger('PlaylistDetailScreen');
  final VideoProvider _videoProvider = VideoProvider();
  
  late Future<PlaylistEntity?> _playlistFuture;
  late Future<List<VideoEntity>> _videosFuture;
  bool _isLoadingPlaylist = true;
  bool _isLoadingVideos = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    setState(() {
      _isLoadingPlaylist = true;
      _isLoadingVideos = true;
    });
    _playlistFuture = _videoProvider.getPlaylist(widget.playlistId).whenComplete(() {
      if (mounted) setState(() => _isLoadingPlaylist = false);
    });
    _videosFuture = _videoProvider.getPlaylistVideos(widget.playlistId).whenComplete(() {
      if (mounted) setState(() => _isLoadingVideos = false);
    });
  }
  
  Future<void> _refreshData() async {
    _logger.info('Refreshing playlist details and videos for ID: ${widget.playlistId}');
    setState(() {
      _videoProvider.clearCache(); // Consider more granular caching if needed
      _loadData();
    });
  }
  
  Future<void> _openVideoPlayer(BuildContext context, VideoEntity video, List<VideoEntity> currentPlaylistVideos) async {
    // API connection test removed for brevity, can be added back if essential
    _logger.info("Opening in-app player for video: ${video.title}");
    // Potentially pass the current list of videos to the player for next/prev functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(video: video /*, currentPlaylist: currentPlaylistVideos */),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // No AppBar here, it's part of CustomScrollView
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250.0, // Height of the expanded app bar
              floating: false,
              pinned: true, // Keeps the app bar visible when scrolling up
              stretch: true,
              backgroundColor: theme.scaffoldBackgroundColor, // Or a specific color
              foregroundColor: theme.colorScheme.onSurface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.go('/videos'),
                tooltip: 'Back to Playlists',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: (_isLoadingPlaylist && _isLoadingVideos) ? null : _refreshData,
                  tooltip: 'Refresh',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
                title: FutureBuilder<PlaylistEntity?>(
                  future: _playlistFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && _isLoadingPlaylist) {
                      return const Text('Loading...', style: TextStyle(fontSize: 16));
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return const Text('Playlist Details', style: TextStyle(fontSize: 16));
                    }
                    // Text will scale down and move with the AppBar
                    return Text(
                      snapshot.data!.title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0, // Adjust size as needed
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                background: FutureBuilder<PlaylistEntity?>(
                  future: _playlistFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null || snapshot.data!.thumbnailUrl == null || snapshot.data!.thumbnailUrl!.isEmpty) {
                      return Container(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.video_library_outlined,
                            size: 80,
                            color: theme.colorScheme.onSecondaryContainer.withOpacity(0.5),
                          ),
                        ),
                      );
                    }
                    return Hero(
                      tag: 'playlist-thumbnail-${widget.playlistId}',
                      child: CachedNetworkImage(
                        imageUrl: snapshot.data!.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: theme.colorScheme.secondaryContainer.withOpacity(0.3)),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.errorContainer,
                          child: Icon(Icons.broken_image_outlined, size: 50, color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    );
                  },
                ),
                stretchModes: const [StretchMode.zoomBackground], 
              ),
            ),

            // Playlist Description Section (Optional, can be part of SliverList or separate SliverToBoxAdapter)
            FutureBuilder<PlaylistEntity?>(
              future: _playlistFuture,
              builder: (context, playlistSnapshot) {
                if (playlistSnapshot.connectionState == ConnectionState.waiting && _isLoadingPlaylist) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink()); // Show nothing while loading
                }
                if (playlistSnapshot.hasData && playlistSnapshot.data != null && playlistSnapshot.data!.description != null && playlistSnapshot.data!.description!.isNotEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About this playlist',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            playlistSnapshot.data!.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                          ),
                          const Divider(height: 24),
                        ],
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink()); // No description or error
              },
            ),

            // Video List Header (Optional)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
                child: Text(
                  'Videos in this playlist',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Video List
            FutureBuilder<List<VideoEntity>>(
              future: _videosFuture,
              builder: (context, videoSnapshot) {
                if (videoSnapshot.connectionState == ConnectionState.waiting && _isLoadingVideos) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                
                if (videoSnapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                            const SizedBox(height: 20),
                            Text('Failed to Load Videos', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(
                              'We couldn\'t fetch the videos for this playlist. Please try refreshing.', 
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                final videos = videoSnapshot.data ?? [];
                if (videos.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                            const SizedBox(height: 20),
                            Text('No Videos Here', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(
                              'This playlist doesn\'t have any videos yet. Pull down to refresh if you think this is an error.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return AnimationLimiter(
                  child: SliverList(delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = videos[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0), // Spacing for VideoListItem
                              child: VideoListItem(
                                video: video,
                                onTap: () => _openVideoPlayer(context, video, videos),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: videos.length,
                  )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}