import 'package:flutter/material.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../widgets/video_list_item.dart';
import '../providers/video_provider.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import 'video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    _playlistFuture = _videoProvider.getPlaylist(widget.playlistId);
    _videosFuture = _videoProvider.getPlaylistVideos(widget.playlistId);
  }
  
  Future<void> _refreshData() async {
    setState(() {
      _videoProvider.clearCache();
      _loadData();
    });
  }
  
  void _openVideoPlayer(BuildContext context, VideoEntity video) async {
    try {
      // Test the YouTube API connection first
      final result = await _videoProvider.testApiConnection();
      
      if (!result) {
        // API connection failed, show a more detailed error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot connect to YouTube API. Please try using the external YouTube app.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      _logger.warning('Error testing YouTube API: $e');
    }
  
    // First offer choice of how to view the video
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                video.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              enabled: false,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_circle_outlined),
              title: const Text('Play in-app (experimental)'),
              subtitle: const Text('Opens the video player within this app'),
              onTap: () {
                Navigator.of(context).pop();
                // Use MaterialPageRoute for better stability
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(video: video),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Open in YouTube app'),
              subtitle: const Text('Opens in the YouTube app for better playback (recommended)'),
              onTap: () async {
                Navigator.of(context).pop();
                final url = Uri.parse(video.youtubeUrl);
                try {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open YouTube')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<PlaylistEntity?>(
          future: _playlistFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading playlist...');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Playlist');
            }
            return Text(
              snapshot.data!.title,
              style: const TextStyle(fontSize: 20),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/videos'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            // Playlist Info Card
            FutureBuilder<PlaylistEntity?>(
              future: _playlistFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load playlist',
                            style: theme.textTheme.titleMedium,
                          ),
                          if (snapshot.hasError)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                snapshot.error.toString(),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                
                final playlist = snapshot.data!;
                return Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Playlist header with thumbnail
                      Stack(
                        children: [
                          SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: playlist.thumbnailUrl != null && playlist.thumbnailUrl!.isNotEmpty
                              ? Image.network(
                                  playlist.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: theme.colorScheme.primaryContainer,
                                      child: Center(
                                        child: Icon(
                                          Icons.video_library,
                                          size: 48,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: theme.colorScheme.primaryContainer,
                                  child: Center(
                                    child: Icon(
                                      Icons.video_library,
                                      size: 48,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                          ),
                          // Video count
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.video_library,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${playlist.videoCount} videos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Playlist details
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (playlist.description != null && 
                                playlist.description!.isNotEmpty)
                              Text(
                                playlist.description!,
                                style: theme.textTheme.bodyMedium,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Video List
            Expanded(
              child: FutureBuilder<List<VideoEntity>>(
                future: _videosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load videos',
                            style: theme.textTheme.titleMedium,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              snapshot.error.toString(),
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _refreshData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No videos found in this playlist',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pull down to refresh',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final videos = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: videos.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return VideoListItem(
                        video: video,
                        onTap: () => _openVideoPlayer(context, video),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 