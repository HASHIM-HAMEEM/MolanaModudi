import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../widgets/video_list_item.dart';
import '../providers/video_providers.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> with WidgetsBindingObserver {
  final Logger _logger = Logger('PlaylistDetailScreen');
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }



  void _scrollListener() {
    if (_scrollController.offset >= 400) {
      if (!_showScrollToTopButton) {
        setState(() => _showScrollToTopButton = true);
      }
    } else if (_showScrollToTopButton) {
      setState(() => _showScrollToTopButton = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistAsync = ref.watch(playlistProvider(widget.playlistId));
    final videosState = ref.watch(playlistVideosNotifierProvider(widget.playlistId));

    return Scaffold(
      appBar: _buildAppBar(context, theme),
      body: _buildBody(context, theme, playlistAsync, videosState),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              tooltip: 'Scroll to top',
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: const Text('Playlist Details'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.go('/videos'),
        tooltip: 'Back to Videos',
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Refresh'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share Playlist'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      foregroundColor: theme.colorScheme.onSurface,
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _logger.info('Refreshing playlist and videos');
        ref.read(playlistVideosNotifierProvider(widget.playlistId).notifier).refresh();
        ref.invalidate(playlistProvider(widget.playlistId));
        break;
      case 'share':
        // Implement playlist sharing if needed
        _logger.info('Share playlist action triggered');
        break;
    }
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AsyncValue<PlaylistEntity?> playlistAsync,
    VideoState<List<VideoEntity>> videosState,
  ) {
    return playlistAsync.when(
      loading: () => _buildLoadingIndicator(theme),
      error: (error, stackTrace) => _buildErrorState(context, theme, error.toString()),
      data: (playlist) {
        if (playlist == null) {
          return _buildNotFoundState(context, theme);
        }
        return _buildPlaylistContent(context, theme, playlist, videosState);
      },
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: 16),
          Text(
            'Loading playlist...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Playlist',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(playlistProvider(widget.playlistId));
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go('/videos'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_remove,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'Playlist Not Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The requested playlist could not be found or may have been removed.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/videos'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Videos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistContent(
    BuildContext context,
    ThemeData theme,
    PlaylistEntity playlist,
    VideoState<List<VideoEntity>> videosState,
  ) {
    final videosToShow = videosState.data;
    final isLoading = videosState.isLoading;
    final hasError = videosState.hasError;
    final error = videosState.error;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(playlistVideosNotifierProvider(widget.playlistId).notifier).refresh();
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Playlist Header
          _buildPlaylistHeader(theme, playlist, videosState),
          
          // Videos List
          if (isLoading && (videosToShow?.isEmpty ?? true))
            _buildLoadingSliver(theme)
          else if (hasError && (videosToShow?.isEmpty ?? true))
            _buildErrorSliver(context, theme, error ?? 'Unknown error')
          else if (videosToShow?.isEmpty ?? true)
            _buildEmptySliver(theme)
          else
            _buildVideosList(context, theme, videosToShow!),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader(ThemeData theme, PlaylistEntity playlist, VideoState<List<VideoEntity>> videosState) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 90,
                    child: playlist.thumbnailUrl?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: playlist.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHigh,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.errorContainer,
                              child: Icon(
                                Icons.broken_image,
                                color: theme.colorScheme.onErrorContainer,
                                size: 32,
                              ),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.playlist_play,
                              color: theme.colorScheme.onSurface,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.video_library,
                            size: 16,
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${videosState.totalCount} videos',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                          if (videosState.isRefreshing) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (playlist.description?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                playlist.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildLoadingSliver(ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            Text(
              'Loading videos...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver(BuildContext context, ThemeData theme, String error) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Videos',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(playlistVideosNotifierProvider(widget.playlistId).notifier).retry();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySliver(ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Videos',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This playlist doesn\'t contain any videos.',
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

  Widget _buildVideosList(BuildContext context, ThemeData theme, List<VideoEntity> videos) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverAnimatedList(
        initialItemCount: videos.length,
        itemBuilder: (context, index, animation) {
          if (index >= videos.length) return const SizedBox.shrink();
          
          final video = videos[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: VideoListItem(
                    video: video,
                    onTap: () {
                      _logger.info('Playing video: ${video.id}');
                      context.go('/videos/player', extra: {
                        'video': video,
                        'playlistId': widget.playlistId,
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}