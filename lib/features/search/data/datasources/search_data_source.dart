import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/repositories/books_repository.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../biography/domain/repositories/biography_repository.dart';
import '../../../videos/presentation/providers/video_provider.dart';
import '../../domain/entities/search_result_entity.dart';
import '../models/search_result_model.dart';

/// Data source for search functionality
abstract class SearchDataSource {
  /// Search across all content types
  Future<List<SearchResultModel>> search(
    String query, {
    List<SearchResultType>? types,
  });

  /// Get recent searches
  Future<List<String>> getRecentSearches();

  /// Save a search query to recent searches
  Future<void> saveRecentSearch(String query);

  /// Clear all recent searches
  Future<void> clearRecentSearches();
}

/// Implementation of SearchDataSource that searches across books and videos
class SearchDataSourceImpl implements SearchDataSource {
  final SharedPreferences _prefs;
  
  // Repositories from other features
  final BooksRepository _bookRepository;
  final VideoProvider _videoRepository;
  final BiographyRepository _biographyRepository;
  final GeminiService? _geminiService;

  static const _recentSearchesKey = 'recent_searches';
  static const _maxRecentSearches = 10;

  SearchDataSourceImpl({
    required SharedPreferences prefs,
    required BooksRepository bookRepository,
    required VideoProvider videoRepository,
    required BiographyRepository biographyRepository,
    GeminiService? geminiService,
  })  : _prefs = prefs,
        _bookRepository = bookRepository,
        _videoRepository = videoRepository,
        _biographyRepository = biographyRepository,
        _geminiService = geminiService;

  @override
  Future<List<SearchResultModel>> search(
    String query, {
    List<SearchResultType>? types,
  }) async {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final results = <SearchResultModel>[];
    final searchTypes = types ?? SearchResultType.values;

    // Search books if included in types
    if (searchTypes.contains(SearchResultType.book) || 
        searchTypes.contains(SearchResultType.chapter)) {
      try {
        final bookResults = await _searchBooks(normalizedQuery);
        results.addAll(bookResults);
      } catch (e) {
        debugPrint('Error searching books: $e');
      }
    }

    // Search videos if included in types
    if (searchTypes.contains(SearchResultType.video)) {
      try {
        final videoResults = await _searchVideos(normalizedQuery);
        results.addAll(videoResults);
      } catch (e) {
        debugPrint('Error searching videos: $e');
      }
    }

    // Search biography if included in types
    if (searchTypes.contains(SearchResultType.biography)) {
      try {
        final biographyResults = await _searchBiography(normalizedQuery);
        results.addAll(biographyResults);
      } catch (e) {
        debugPrint('Error searching biography: $e');
      }
    }
    
    // Enhance search results with Gemini if available
    if (_geminiService != null && results.isNotEmpty) {
      try {
        final enhancedResults = await _enhanceSearchResultsWithGemini(normalizedQuery, results);
        return enhancedResults;
      } catch (e) {
        debugPrint('Error enhancing search results with Gemini: $e');
      }
    }

    return results;
  }
  
  /// Use Gemini to enhance search results by reranking them based on semantic relevance
  Future<List<SearchResultModel>> _enhanceSearchResultsWithGemini(
    String query,
    List<SearchResultModel> results,
  ) async {
    if (_geminiService == null || results.isEmpty) {
      return results;
    }
    
    try {
      // Extract text content from each result for semantic comparison
      final paragraphs = results.map((result) {
        return '${result.title}. ${result.description}';
      }).toList();
      
      // Use Gemini's semantic search to find the most relevant paragraphs
      final rankedParagraphs = await _geminiService.semanticSearch(query, paragraphs);
      
      if (rankedParagraphs.isEmpty) {
        return results; // Return original results if semantic search fails
      }
      
      // Create a map to track the ranking of each result
      final resultRanking = <String, int>{};
      
      // Process the ranked paragraphs to determine result order
      for (int i = 0; i < rankedParagraphs.length; i++) {
        // Find which result this ranked paragraph corresponds to
        final rankedText = rankedParagraphs[i];
        for (int j = 0; j < results.length; j++) {
          final result = results[j];
          final resultText = '${result.title}. ${result.description}';
          
          // If this is the matching result, record its ranking
          if (resultText == rankedText) {
            resultRanking[result.id] = i;
            break;
          }
        }
      }
      
      // Sort the results based on their ranking
      final sortedResults = List<SearchResultModel>.from(results);
      sortedResults.sort((a, b) {
        final rankA = resultRanking[a.id] ?? results.length;
        final rankB = resultRanking[b.id] ?? results.length;
        return rankA.compareTo(rankB);
      });
      
      return sortedResults;
    } catch (e) {
      debugPrint('Error in _enhanceSearchResultsWithGemini: $e');
      return results; // Return original results if enhancement fails
    }
  }

  /// Search through books and their chapters
  Future<List<SearchResultModel>> _searchBooks(String query) async {
    final results = <SearchResultModel>[];
    
    try {
      // Get all books
      final books = await _bookRepository.getBooks();
      
      // If repository returns null or empty, return empty results
      if (books.isEmpty) {
        return results;
      }
      
      // Search book titles and descriptions
      for (final book in books) {
        final bookTitle = (book.title ?? '').toLowerCase();
        final bookDescription = book.description?.toLowerCase() ?? '';
        final bookAuthor = book.author?.toLowerCase() ?? '';
        
        if (bookTitle.contains(query) || 
            bookDescription.contains(query) ||
            bookAuthor.contains(query)) {
          results.add(SearchResultModel.fromBook({
            'id': book.firestoreDocId,
            'title': book.title ?? 'Untitled',
            'description': book.description ?? '',
            'author': book.author ?? '',
            'coverUrl': book.thumbnailUrl ?? '',
          }));
        }
        
        // Get headings (chapters) for the book
        try {
          final headings = await _bookRepository.getBookHeadings(book.firestoreDocId);
          
          for (final heading in headings) {
            final headingTitle = (heading.title ?? '').toLowerCase();
            // Handle content as a list of strings
            final headingContent = heading.content?.join(' ').toLowerCase() ?? '';
            
            if (headingTitle.contains(query) || headingContent.contains(query)) {
              // Create a preview from the content where the query appears
              String preview = '';
              if (headingContent.contains(query)) {
                try {
                  final queryIndex = headingContent.indexOf(query);
                  final startIndex = queryIndex - 50 < 0 ? 0 : queryIndex - 50;
                  final endIndex = queryIndex + 50 > headingContent.length 
                      ? headingContent.length 
                      : queryIndex + 50;
                  preview = '...${headingContent.substring(startIndex, endIndex)}...';
                } catch (e) {
                  // Fallback if there's any issue with substring
                  preview = 'Content contains "$query"';
                }
              }
              
              results.add(SearchResultModel.fromChapter(
                {
                  'id': heading.firestoreDocId,
                  'title': heading.title ?? 'Untitled',
                  'content': heading.content,
                  'preview': preview,
                }, 
                book.firestoreDocId,
                book.title ?? 'Untitled',
              ));
            }
          }
        } catch (e) {
          debugPrint('Error fetching headings for book ${book.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _searchBooks: $e');
    }
    
    return results;
  }

  /// Search through videos
  Future<List<SearchResultModel>> _searchVideos(String query) async {
    final results = <SearchResultModel>[];
    
    try {
      // Get all playlists
      final playlists = await _videoRepository.getPlaylists();
      
      // If repository returns null or empty, return empty results
      if (playlists.isEmpty) {
        return results;
      }
      
      // Search through each playlist
      for (final playlist in playlists) {
        try {
          // Get videos for this playlist
          final videos = await _videoRepository.getPlaylistVideos(playlist.id);
          
          // Search video titles and descriptions
          for (final video in videos) {
            final videoTitle = video.title.toLowerCase();
            final videoDescription = video.description?.toLowerCase() ?? '';
            
            if (videoTitle.contains(query) || videoDescription.contains(query)) {
              results.add(SearchResultModel.fromVideo({
                'id': video.id,
                'title': video.title,
                'description': video.description ?? '',
                'thumbnailUrl': video.thumbnailUrl,
                'youtubeUrl': video.youtubeUrl,
                'playlistId': playlist.id,
                'playlistTitle': playlist.title,
              }));
            }
          }
        } catch (e) {
          debugPrint('Error fetching videos for playlist ${playlist.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in _searchVideos: $e');
    }
    
    return results;
  }

  /// Search through biography events
  Future<List<SearchResultModel>> _searchBiography(String query) async {
    final results = <SearchResultModel>[];
    
    try {
      // Get all biography events
      final events = await _biographyRepository.getBiographyEvents();
      
      // If repository returns empty, return empty results
      if (events.isEmpty) {
        return results;
      }
      
      // Search event titles and descriptions
      for (final event in events) {
        final eventTitle = event.title.toLowerCase();
        final eventDescription = event.description.toLowerCase();
        final eventDate = event.date.toLowerCase();
        
        if (eventTitle.contains(query) || 
            eventDescription.contains(query) ||
            eventDate.contains(query)) {
          results.add(SearchResultModel.fromBiographyEvent({
            'id': 'biography_${events.indexOf(event)}',
            'title': event.title,
            'date': event.date,
            'description': event.description,
          }));
        }
      }
    } catch (e) {
      debugPrint('Error in _searchBiography: $e');
    }
    
    return results;
  }

  @override
  Future<List<String>> getRecentSearches() async {
    final recentSearches = _prefs.getStringList(_recentSearchesKey) ?? [];
    return recentSearches;
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return;
    }

    final recentSearches = await getRecentSearches();
    
    // Remove the query if it already exists
    recentSearches.remove(normalizedQuery);
    
    // Add the query to the beginning of the list
    recentSearches.insert(0, normalizedQuery);
    
    // Limit the number of recent searches
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches.removeLast();
    }
    
    await _prefs.setStringList(_recentSearchesKey, recentSearches);
  }

  @override
  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }
}
