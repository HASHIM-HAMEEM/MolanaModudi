import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import '../../../../core/providers/providers.dart';

/// Service for preloading book thumbnail images to improve scrolling performance
class ThumbnailPreloaderService {
  static final _log = Logger('ThumbnailPreloaderService');
  
  /// Preload thumbnails for a list of books
  static Future<void> preloadThumbnails(
    List<Book> books, 
    WidgetRef ref, {
    int maxConcurrent = 3,
  }) async {
    if (books.isEmpty) return;
    
    _log.info('Starting to preload ${books.length} book thumbnails');
    
    final cacheManager = await ref.read(defaultCacheManagerProvider.future);
    final validBooks = books
        .where((book) => book.thumbnailUrl != null && book.thumbnailUrl!.isNotEmpty)
        .take(10) // Only preload first 10 to avoid memory issues
        .toList();
    
    if (validBooks.isEmpty) {
      _log.info('No valid thumbnails to preload');
      return;
    }
    
    // Split into batches to avoid overwhelming the network
    final batches = <List<Book>>[];
    for (int i = 0; i < validBooks.length; i += maxConcurrent) {
      batches.add(validBooks.skip(i).take(maxConcurrent).toList());
    }
    
    int preloadedCount = 0;
    for (final batch in batches) {
      final futures = batch.map((book) => _preloadSingleThumbnail(
        book.thumbnailUrl!,
        book.firestoreDocId,
        cacheManager,
      ));
      
      try {
        await Future.wait(futures);
        preloadedCount += batch.length;
        _log.fine('Preloaded batch of ${batch.length} thumbnails');
      } catch (e) {
        _log.warning('Error preloading thumbnail batch: $e');
      }
      
      // Small delay between batches to avoid overwhelming the cache
      if (batches.indexOf(batch) < batches.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    _log.info('Completed preloading $preloadedCount thumbnails');
  }
  
  /// Preload a single thumbnail
  static Future<void> _preloadSingleThumbnail(
    String imageUrl,
    String bookId,
    DefaultCacheManager cacheManager,
  ) async {
    try {
      final cacheKey = 'optimized_thumb_${bookId}_140x185';
      
      // Check if already cached
      final fileInfo = await cacheManager.getFileFromCache(cacheKey);
      if (fileInfo != null) {
        return; // Already cached
      }
      
      // Download and cache
      await cacheManager.downloadFile(imageUrl, key: cacheKey);
      _log.fine('Preloaded thumbnail for book: $bookId');
    } catch (e) {
      _log.fine('Failed to preload thumbnail for book $bookId: $e');
    }
  }
  
  /// Preload images that are likely to be seen next (based on scroll position)
  static Future<void> preloadNextImages(
    List<Book> allBooks,
    int currentStartIndex,
    WidgetRef ref, {
    int preloadCount = 5,
  }) async {
    final startIndex = (currentStartIndex + 1).clamp(0, allBooks.length);
    final endIndex = (startIndex + preloadCount).clamp(0, allBooks.length);
    
    if (startIndex >= allBooks.length) return;
    
    final nextBooks = allBooks.sublist(startIndex, endIndex);
    await preloadThumbnails(nextBooks, ref, maxConcurrent: 2);
  }
  
  /// Clear preloaded thumbnails (useful for memory management)
  static Future<void> clearPreloadedThumbnails(WidgetRef ref) async {
    try {
      final cacheManager = await ref.read(defaultCacheManagerProvider.future);
      await cacheManager.emptyCache();
      _log.info('Cleared preloaded thumbnails cache');
    } catch (e) {
      _log.warning('Error clearing preloaded thumbnails: $e');
    }
  }
}

/// Provider for thumbnail preloader service
final thumbnailPreloaderServiceProvider = Provider<ThumbnailPreloaderService>((ref) {
  return ThumbnailPreloaderService();
}); 