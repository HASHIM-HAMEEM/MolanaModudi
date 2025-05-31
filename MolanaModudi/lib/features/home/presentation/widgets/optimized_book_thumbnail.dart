import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/providers.dart';

/// Optimized book thumbnail widget with better caching and performance
class OptimizedBookThumbnail extends ConsumerWidget {
  final String imageUrl;
  final String bookId;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const OptimizedBookThumbnail({
    super.key,
    required this.imageUrl,
    required this.bookId,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        cacheManager: ref.watch(defaultCacheManagerProvider).maybeWhen(
          data: (manager) => manager,
          orElse: () => null,
        ),
        imageUrl: imageUrl,
        cacheKey: 'optimized_thumb_${bookId}_${width.toInt()}x${height.toInt()}',
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: borderRadius,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child: const Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 32,
            ),
          ),
        ),
        // Performance optimizations
        memCacheWidth: (width * MediaQuery.of(context).devicePixelRatio).toInt(),
        memCacheHeight: (height * MediaQuery.of(context).devicePixelRatio).toInt(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }
} 