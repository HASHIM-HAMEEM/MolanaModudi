import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/playlist_entity.dart';
import '../widgets/playlist_list_item.dart';
import '../providers/video_provider.dart';
import 'package:logging/logging.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final Logger _logger = Logger('VideosScreen');
  final VideoProvider _videoProvider = VideoProvider();
  
  late Future<List<PlaylistEntity>> _playlistsFuture;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }
  
  void _loadPlaylists() {
    setState(() {
      _isLoading = true;
      _playlistsFuture = _videoProvider.getPlaylists();
    });
  }
  
  Future<void> _refreshPlaylists() async {
    _logger.info('Refreshing playlists');
    setState(() {
      _videoProvider.clearCache();
      _loadPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Lectures'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPlaylists,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPlaylists,
        child: FutureBuilder<List<PlaylistEntity>>(
          future: _playlistsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
                        'Failed to load playlists',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshPlaylists,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final playlists = snapshot.data ?? [];
            
            if (playlists.isEmpty) {
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
                      'No playlists found',
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
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: PlaylistListItem(
                    playlist: playlist,
                    onTap: () {
                      _logger.info('Navigating to playlist: ${playlist.id}');
                      context.go('/videos/${playlist.id}');
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 