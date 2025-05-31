import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import '../../data/providers/home_data_providers.dart';

/// Cached featured books provider with optimized caching behavior
/// This provider prevents unnecessary re-fetching when returning to home screen
class CachedFeaturedBooksNotifier extends AsyncNotifier<List<Book>> {
  static final _log = Logger('CachedFeaturedBooksNotifier');
  static const int _defaultPerPage = 20;
  
  // Static cache to persist across provider disposal/recreation
  static List<Book>? _cachedBooks;
  static DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 10);
  
  @override
  Future<List<Book>> build() async {
    return _fetchFeaturedBooks();
  }
  
  Future<List<Book>> _fetchFeaturedBooks() async {
    // Check if we have valid cached data
    if (_cachedBooks != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration) {
      _log.info('Using cached featured books (${_cachedBooks!.length} items)');
      return _cachedBooks!;
    }
    
    try {
      _log.info('Fetching featured books from repository');
      final repository = ref.watch(homeRepositoryProvider);
      final books = await repository.getFeaturedBooks(perPage: _defaultPerPage);
      
      // Update cache
      _cachedBooks = books;
      _lastFetchTime = DateTime.now();
      
      _log.info('Cached ${books.length} featured books');
      return books;
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch featured books', e, stackTrace);
      
      // Return cached data if available, even if stale
      if (_cachedBooks != null) {
        _log.info('Returning stale cached data due to fetch error');
        return _cachedBooks!;
      }
      
      rethrow;
    }
  }
  
  /// Force refresh the featured books
  Future<void> refresh() async {
    _log.info('Force refreshing featured books');
    _cachedBooks = null;
    _lastFetchTime = null;
    
    state = const AsyncValue.loading();
    try {
      final books = await _fetchFeaturedBooks();
      state = AsyncValue.data(books);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  /// Clear the cache manually
  static void clearCache() {
    _log.info('Clearing featured books cache');
    _cachedBooks = null;
    _lastFetchTime = null;
  }
  
  /// Check if cache is still valid
  static bool get isCacheValid {
    return _cachedBooks != null && 
           _lastFetchTime != null && 
           DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }
}

/// Provider for cached featured books
final cachedFeaturedBooksProvider = AsyncNotifierProvider<CachedFeaturedBooksNotifier, List<Book>>(
  () => CachedFeaturedBooksNotifier(),
);

/// Legacy provider for backwards compatibility
final optimizedFeaturedBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  return ref.watch(cachedFeaturedBooksProvider);
}); 