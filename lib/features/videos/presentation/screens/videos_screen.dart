import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/playlist_entity.dart';
import '../widgets/playlist_list_item.dart';
import '../providers/video_provider.dart';
import 'package:logging/logging.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
        title: const Text('Video Playlists'), // Updated title
        centerTitle: true, // Center title for a modern look
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded), // Modern back icon
          onPressed: () => context.go('/home'),
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _refreshPlaylists, // Disable during load
            tooltip: 'Refresh Playlists',
          ),
        ],
        elevation: 0, // Flat AppBar for a cleaner look, relying on body's scroll for shadow
        backgroundColor: theme.scaffoldBackgroundColor, // Blend AppBar with body
        foregroundColor: theme.colorScheme.onSurface, // Ensure icons and text are visible
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPlaylists,
        color: theme.colorScheme.primary, // Match refresh indicator with primary color
        child: FutureBuilder<List<PlaylistEntity>>(
          future: _playlistsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive()); // Adaptive indicator
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64, // Larger icon
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Oops! Something Went Wrong',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We couldn\'t load the playlists. Please check your connection and try again.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      //Removed snapshot.error.toString() for a cleaner user message
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _refreshPlaylists,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final playlists = snapshot.data ?? [];
            
            if (playlists.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off_outlined, // Corrected icon
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Playlists Found',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'It seems there are no video playlists available at the moment. Pull down to refresh.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Using AnimationLimiter for staggered animations
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0), // Increased spacing
                          child: PlaylistListItem(
                            playlist: playlist,
                            onTap: () {
                              _logger.info('Navigating to playlist: ${playlist.id}');
                              context.go('/videos/${playlist.id}');
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}