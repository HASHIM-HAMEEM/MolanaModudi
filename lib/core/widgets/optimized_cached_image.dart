import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// An optimized cached image widget that wraps CachedNetworkImage with better
/// caching settings and error handling for the Modudi app.
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholderBuilder;
  final Widget? placeholderWidget;
  final Widget Function(BuildContext, String, dynamic)? errorBuilder;
  final Duration cacheDuration;
  final bool useOldImageOnUrlChange;
  final String? cacheKey;
  
  static final Logger _log = Logger('OptimizedCachedImage');
  
  /// Creates an optimized cached image with improved caching settings.
  ///
  /// [imageUrl] The URL of the image to load
  /// [width] Optional width constraint for the image
  /// [height] Optional height constraint for the image
  /// [fit] How the image should be fitted to its container
  /// [placeholderBuilder] Function to build a widget while loading (higher priority)
  /// [placeholderWidget] Static widget to show while loading (used if builder is null)
  /// [errorBuilder] Function to build a widget on error
  /// [cacheDuration] Duration to keep the image in cache (defaults to 90 days)
  /// [useOldImageOnUrlChange] Whether to show old image while new one loads when URL changes (improves perceived performance)
  /// [cacheKey] Optional unique key for caching this image (useful for same URL different content scenarios)
  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    this.placeholderWidget,
    this.errorBuilder,
    this.cacheDuration = const Duration(days: 90), // Extended from default 30 days
    this.useOldImageOnUrlChange = true, // Better UX during URL changes
    this.cacheKey,
  });

  @override
  Widget build(BuildContext context) {
    // If the URL is empty, show the error widget
    if (imageUrl.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: _buildErrorWidget(context, imageUrl, 'Empty URL'),
      );
    }
    
    // Create a unique cache key if not provided, using the URL
    final uniqueCacheKey = cacheKey ?? imageUrl;
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheKey: uniqueCacheKey,
      // Much larger max cache size for better offline experience
      maxWidthDiskCache: 1500, // Increased from standard 800
      maxHeightDiskCache: 1500, // Increased from standard 800
      // Use memory cache aggressively
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      placeholderFadeInDuration: const Duration(milliseconds: 300),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      // Custom placeholder implementation
      placeholder: (context, url) => _buildPlaceholder(context, url),
      // Custom error widget implementation
      errorWidget: (context, url, error) {
        _log.warning('Error loading image: $url, error: $error');
        return _buildErrorWidget(context, url, error);
      },
    );
  }
  
  /// Builds a placeholder widget based on provided builder or widget
  Widget _buildPlaceholder(BuildContext context, String url) {
    // If a builder is provided, use it
    if (placeholderBuilder != null) {
      return placeholderBuilder!(context, url);
    }
    
    // If a static widget is provided, use it
    if (placeholderWidget != null) {
      return placeholderWidget!;
    }
    
    // Fallback placeholder
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
  
  /// Builds an error widget based on provided builder or defaults
  Widget _buildErrorWidget(BuildContext context, String url, dynamic error) {
    // If a builder is provided, use it
    if (errorBuilder != null) {
      return errorBuilder!(context, url, error);
    }
    
    // Fallback error widget
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
