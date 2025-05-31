import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../cache/cache_service.dart';
import '../cache/config/cache_constants.dart';
import '../../features/books/data/models/book_models.dart';
import '../../features/videos/domain/entities/video_entity.dart';
import '../../features/videos/domain/entities/playlist_entity.dart';

/// Enum for search contexts
enum SearchContext {
  global, // Home page - searches books, chapters, videos
  library, // Library page - searches only books
}

/// Enum for search result types
enum UnifiedSearchResultType {
  book,
  chapter,
  video,
}

/// Unified search result entity
class UnifiedSearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final UnifiedSearchResultType type;
  final String? parentId; // For chapters, this is the book ID
  final Map<String, dynamic>? metadata;

  const UnifiedSearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.type,
    this.parentId,
    this.metadata,
  });

  /// Get route path for navigation
  String getRoutePath() {
    switch (type) {
      case UnifiedSearchResultType.book:
        return '/read/$id';
      case UnifiedSearchResultType.chapter:
        return '/read/$parentId?heading=$id';
      case UnifiedSearchResultType.video:
        final playlistId = metadata?['playlistId'];
        return '/videos/playlist/$playlistId?video=$id';
    }
  }

  /// Get display icon
  String get iconName {
    switch (type) {
      case UnifiedSearchResultType.book:
        return 'menu_book';
      case UnifiedSearchResultType.chapter:
        return 'bookmark';
      case UnifiedSearchResultType.video:
        return 'play_circle';
    }
  }
}

/// Search results container
class SearchResults {
  final List<UnifiedSearchResult> books;
  final List<UnifiedSearchResult> chapters;
  final List<UnifiedSearchResult> videos;
  final int totalCount;
  final String query;
  final SearchContext context;

  const SearchResults({
    required this.books,
    required this.chapters,
    required this.videos,
    required this.totalCount,
    required this.query,
    required this.context,
  });

  /// Get all results as a flat list
  List<UnifiedSearchResult> get allResults => [...books, ...chapters, ...videos];

  /// Get results by type
  List<UnifiedSearchResult> getResultsByType(UnifiedSearchResultType type) {
    switch (type) {
      case UnifiedSearchResultType.book:
        return books;
      case UnifiedSearchResultType.chapter:
        return chapters;
      case UnifiedSearchResultType.video:
        return videos;
    }
  }

  /// Check if has results
  bool get hasResults => totalCount > 0;

  /// Get type counts
  Map<UnifiedSearchResultType, int> get typeCounts => {
    UnifiedSearchResultType.book: books.length,
    UnifiedSearchResultType.chapter: chapters.length,
    UnifiedSearchResultType.video: videos.length,
  };
}

/// Unified Search Service - Single source of truth for all search functionality
class UnifiedSearchService {
  static final UnifiedSearchService _instance = UnifiedSearchService._internal();
  factory UnifiedSearchService() => _instance;
  UnifiedSearchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _log = Logger('UnifiedSearchService');
  
  CacheService? _cacheService;
  Timer? _debounceTimer;
  
  // Recent searches storage
  final Map<SearchContext, List<String>> _recentSearches = {
    SearchContext.global: [],
    SearchContext.library: [],
  };

  /// Initialize the service
  Future<void> initialize(CacheService cacheService) async {
    _cacheService = cacheService;
    await _loadRecentSearches();
  }

  /// Main search method with context awareness
  Future<SearchResults> search({
    required String query,
    required SearchContext context,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return SearchResults(
        books: [],
        chapters: [],
        videos: [],
        totalCount: 0,
        query: query,
        context: context,
      );
    }

    final normalizedQuery = query.trim().toLowerCase();
    _log.info('Searching for "$normalizedQuery" in context: $context');

    try {
      // Add to recent searches
      await _addToRecentSearches(normalizedQuery, context);

      // Search based on context
      switch (context) {
        case SearchContext.global:
          return await _performGlobalSearch(normalizedQuery, limit);
        case SearchContext.library:
          return await _performLibrarySearch(normalizedQuery, limit);
      }
    } catch (e, stackTrace) {
      _log.severe('Search error for "$query": $e', e, stackTrace);
      return SearchResults(
        books: [],
        chapters: [],
        videos: [],
        totalCount: 0,
        query: query,
        context: context,
      );
    }
  }

  /// Global search (Home page) - Books, Chapters, Videos
  Future<SearchResults> _performGlobalSearch(String query, int limit) async {
    final futures = <Future<List<UnifiedSearchResult>>>[];

    // Search books (title only)
    futures.add(_searchBooks(query, limit ~/ 3));
    
    // Search chapters (title only)
    futures.add(_searchChapters(query, limit ~/ 3));
    
    // Search videos (title only)
    futures.add(_searchVideos(query, limit ~/ 3));

    final results = await Future.wait(futures);
    
    return SearchResults(
      books: results[0],
      chapters: results[1],
      videos: results[2],
      totalCount: results[0].length + results[1].length + results[2].length,
      query: query,
      context: SearchContext.global,
    );
  }

  /// Library search (Library page) - Books only
  Future<SearchResults> _performLibrarySearch(String query, int limit) async {
    final books = await _searchBooks(query, limit);
    
    return SearchResults(
      books: books,
      chapters: [],
      videos: [],
      totalCount: books.length,
      query: query,
      context: SearchContext.library,
    );
  }

  /// Search books by title only
  Future<List<UnifiedSearchResult>> _searchBooks(String query, int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(limit)
          .get();

      final results = <UnifiedSearchResult>[];
      
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final book = Book.fromMap(doc.id, data);
          
          results.add(UnifiedSearchResult(
            id: book.firestoreDocId,
            title: book.title ?? 'Untitled',
            subtitle: book.author,
            description: book.description,
            imageUrl: book.thumbnailUrl,
            type: UnifiedSearchResultType.book,
            metadata: {
              'author': book.author,
              'language': book.defaultLanguage,
              'publicationDate': book.publicationDate,
            },
          ));
        } catch (e) {
          _log.warning('Error parsing book result: $e');
        }
      }

      _log.info('Found ${results.length} books for query "$query"');
      return results;
    } catch (e) {
      _log.severe('Error searching books: $e');
      return [];
    }
  }

  /// Search chapters by title only
  Future<List<UnifiedSearchResult>> _searchChapters(String query, int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('headings')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(limit)
          .get();

      final results = <UnifiedSearchResult>[];
      
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final title = data['title'] as String? ?? 'Untitled';
          final bookId = data['bookId'] as String?;
          
          if (bookId != null) {
            results.add(UnifiedSearchResult(
              id: doc.id,
              title: title,
              subtitle: 'Chapter',
              description: null, // Not searching content
              imageUrl: null,
              type: UnifiedSearchResultType.chapter,
              parentId: bookId,
              metadata: {
                'bookId': bookId,
                'chapterId': data['chapterId'],
              },
            ));
          }
        } catch (e) {
          _log.warning('Error parsing chapter result: $e');
        }
      }

      _log.info('Found ${results.length} chapters for query "$query"');
      return results;
    } catch (e) {
      _log.severe('Error searching chapters: $e');
      return [];
    }
  }

  /// Search videos by title only
  Future<List<UnifiedSearchResult>> _searchVideos(String query, int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('videos')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(limit)
          .get();

      final results = <UnifiedSearchResult>[];
      
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final title = data['title'] as String? ?? 'Untitled';
          
          results.add(UnifiedSearchResult(
            id: doc.id,
            title: title,
            subtitle: data['duration'] as String?,
            description: data['description'] as String?,
            imageUrl: data['thumbnailUrl'] as String?,
            type: UnifiedSearchResultType.video,
            metadata: {
              'playlistId': data['playlistId'],
              'youtubeUrl': data['youtubeUrl'],
              'duration': data['duration'],
              'channelTitle': data['channelTitle'],
            },
          ));
        } catch (e) {
          _log.warning('Error parsing video result: $e');
        }
      }

      _log.info('Found ${results.length} videos for query "$query"');
      return results;
    } catch (e) {
      _log.severe('Error searching videos: $e');
      return [];
    }
  }

  /// Get recent searches for context
  List<String> getRecentSearches(SearchContext context) {
    return List.from(_recentSearches[context] ?? []);
  }

  /// Clear recent searches for context
  Future<void> clearRecentSearches(SearchContext context) async {
    _recentSearches[context]?.clear();
    await _saveRecentSearches();
  }

  /// Add to recent searches
  Future<void> _addToRecentSearches(String query, SearchContext context) async {
    final searches = _recentSearches[context] ??= [];
    
    // Remove if already exists
    searches.remove(query);
    
    // Add to beginning
    searches.insert(0, query);
    
    // Keep only last 10
    if (searches.length > 10) {
      searches.removeRange(10, searches.length);
    }
    
    await _saveRecentSearches();
  }

  /// Load recent searches from cache
  Future<void> _loadRecentSearches() async {
    if (_cacheService == null) return;
    
    try {
      for (final context in SearchContext.values) {
        final cacheKey = 'recent_searches_${context.name}';
        final result = await _cacheService!.getCachedData<List<dynamic>>(
          key: cacheKey,
          boxName: 'search_cache',
        );
        
        if (result.hasData && result.data != null) {
          _recentSearches[context] = result.data!.cast<String>();
        }
      }
    } catch (e) {
      _log.warning('Error loading recent searches: $e');
    }
  }

  /// Save recent searches to cache
  Future<void> _saveRecentSearches() async {
    if (_cacheService == null) return;
    
    try {
      for (final context in SearchContext.values) {
        final cacheKey = 'recent_searches_${context.name}';
        await _cacheService!.cacheData(
          key: cacheKey,
          data: _recentSearches[context] ?? [],
          boxName: 'search_cache',
          ttl: const Duration(days: 30),
        );
      }
    } catch (e) {
      _log.warning('Error saving recent searches: $e');
    }
  }

  /// Get search suggestions based on partial query
  Future<List<String>> getSearchSuggestions({
    required String partialQuery,
    required SearchContext context,
    int limit = 5,
  }) async {
    if (partialQuery.trim().isEmpty) {
      return getRecentSearches(context).take(limit).toList();
    }

    final suggestions = <String>{};
    final query = partialQuery.toLowerCase();

    try {
      // Get suggestions from books
      final bookSnapshot = await _firestore
          .collection('books')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(limit)
          .get();

      for (final doc in bookSnapshot.docs) {
        final title = doc.data()['title'] as String?;
        if (title != null) {
          suggestions.add(title);
        }
      }

      // Add relevant recent searches
      final recentSearches = getRecentSearches(context);
      for (final recent in recentSearches) {
        if (recent.toLowerCase().contains(query)) {
          suggestions.add(recent);
        }
      }

    } catch (e) {
      _log.warning('Error getting search suggestions: $e');
    }

    return suggestions.take(limit).toList();
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Global instance
final unifiedSearchService = UnifiedSearchService(); 