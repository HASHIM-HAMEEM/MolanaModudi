import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/search_result_entity.dart';
import '../models/search_result_model.dart';
import 'search_data_source.dart';

// For handling Future.delayed in tests
import 'dart:async';

/// Mock implementation of SearchDataSource for testing
class MockSearchDataSource implements SearchDataSource {
  final SharedPreferences _prefs;
  static const _recentSearchesKey = 'recent_searches';
  static const _maxRecentSearches = 10;

  MockSearchDataSource({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<List<SearchResultModel>> search(
    String query, {
    List<SearchResultType>? types,
  }) async {
    // Add logging for debugging
    debugPrint('MockSearchDataSource: Searching for "$query"');
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final results = <SearchResultModel>[];
    final searchTypes = types ?? SearchResultType.values;

    // Add mock book results
    if (searchTypes.contains(SearchResultType.book)) {
      results.addAll(_getMockBookResults(normalizedQuery));
    }

    // Add mock chapter results
    if (searchTypes.contains(SearchResultType.chapter)) {
      results.addAll(_getMockChapterResults(normalizedQuery));
    }

    // Add mock video results
    if (searchTypes.contains(SearchResultType.video)) {
      results.addAll(_getMockVideoResults(normalizedQuery));
    }

    // Add mock biography results
    if (searchTypes.contains(SearchResultType.biography)) {
      results.addAll(_getMockBiographyResults(normalizedQuery));
    }

    return results;
  }

  List<SearchResultModel> _getMockBookResults(String query) {
    final mockBooks = [
      {
        'id': 'book1',
        'title': 'Towards Understanding the Quran',
        'author': 'Maulana Maududi',
        'description': 'A comprehensive tafsir of the Quran by Maulana Maududi.',
        'coverUrl': 'https://example.com/book1.jpg',
        'totalChapters': 30,
      },
      {
        'id': 'book2',
        'title': 'The Islamic Way of Life',
        'author': 'Maulana Maududi',
        'description': 'An introduction to the Islamic way of life and its principles.',
        'coverUrl': 'https://example.com/book2.jpg',
        'totalChapters': 12,
      },
      {
        'id': 'book3',
        'title': 'Let Us Be Muslims',
        'author': 'Maulana Maududi',
        'description': 'A call to Muslims to live according to Islamic principles.',
        'coverUrl': 'https://example.com/book3.jpg',
        'totalChapters': 8,
      },
    ];

    return mockBooks
        .where((book) =>
            (book['title'] as String).toLowerCase().contains(query) ||
            (book['author'] as String).toLowerCase().contains(query) ||
            (book['description'] as String).toLowerCase().contains(query))
        .map((book) => SearchResultModel.fromBook(book))
        .toList();
  }

  List<SearchResultModel> _getMockChapterResults(String query) {
    // Using properly typed maps
    final List<Map<String, dynamic>> mockChapters = [
      {
        'bookId': 'book1',
        'bookTitle': 'Towards Understanding the Quran',
        'chapters': [
          {
            'id': 'chapter1',
            'title': 'Introduction to Surah Al-Fatiha',
            'chapterNumber': 1,
            'content': 'This is the first chapter of the Quran, known as Al-Fatiha (The Opening).',
          },
          {
            'id': 'chapter2',
            'title': 'Surah Al-Baqarah: Part 1',
            'chapterNumber': 2,
            'content': 'This chapter discusses the fundamentals of faith and Islamic principles.',
          },
        ],
      },
      {
        'bookId': 'book2',
        'bookTitle': 'The Islamic Way of Life',
        'chapters': [
          {
            'id': 'chapter1',
            'title': 'The Islamic Concept of Life',
            'chapterNumber': 1,
            'content': 'This chapter explains the Islamic worldview and concept of life.',
          },
          {
            'id': 'chapter2',
            'title': 'The Islamic System of Worship',
            'chapterNumber': 2,
            'content': 'This chapter discusses the Islamic system of worship and its significance.',
          },
        ],
      },
    ];

    final results = <SearchResultModel>[];

    for (final book in mockChapters) {
      for (final Map<String, dynamic> chapter in (book['chapters'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        if (chapter['title'].toLowerCase().contains(query) ||
            chapter['content'].toLowerCase().contains(query)) {
          // Create a preview from the content where the query appears
          String preview = '';
          final content = (chapter['content'] as String).toLowerCase();
          if (content.contains(query)) {
            final queryIndex = content.indexOf(query);
            final startIndex = queryIndex - 20 < 0 ? 0 : queryIndex - 20;
            final endIndex = queryIndex + 20 > content.length
                ? content.length
                : queryIndex + 20;
            preview = '...${content.substring(startIndex, endIndex)}...';
          }

          final chapterWithPreview = <String, dynamic>{
            ...chapter,
            'preview': preview,
          };

          results.add(SearchResultModel.fromChapter(
            chapterWithPreview,
            book['bookId'] as String,
            book['bookTitle'] as String,
          ));
        }
      }
    }

    return results;
  }

  List<SearchResultModel> _getMockVideoResults(String query) {
    final mockVideos = [
      {
        'id': 'video1',
        'title': 'Introduction to Maulana Maududi',
        'description': 'A brief introduction to the life and works of Maulana Maududi.',
        'thumbnailUrl': 'https://example.com/video1.jpg',
        'duration': '10:30',
        'playlistId': 'playlist1',
        'playlistName': 'Biography Series',
      },
      {
        'id': 'video2',
        'title': 'Understanding Islamic Economics',
        'description': 'Maulana Maududi explains the principles of Islamic economics.',
        'thumbnailUrl': 'https://example.com/video2.jpg',
        'duration': '15:45',
        'playlistId': 'playlist2',
        'playlistName': 'Islamic Economics',
      },
      {
        'id': 'video3',
        'title': 'The Concept of Jihad in Islam',
        'description': 'Maulana Maududi clarifies the concept of Jihad in Islam.',
        'thumbnailUrl': 'https://example.com/video3.jpg',
        'duration': '20:15',
        'playlistId': 'playlist3',
        'playlistName': 'Islamic Concepts',
      },
    ];

    return mockVideos
        .where((video) =>
            (video['title'] as String).toLowerCase().contains(query) ||
            (video['description'] as String).toLowerCase().contains(query))
        .map((video) => SearchResultModel.fromVideo(video))
        .toList();
  }

  List<SearchResultModel> _getMockBiographyResults(String query) {
    final mockBiographyEvents = [
      {
        'id': 'bio1',
        'title': 'Birth of Maulana Maududi',
        'date': 'September 25, 1903',
        'description': 'Maulana Maududi was born in Aurangabad, India.',
      },
      {
        'id': 'bio2',
        'title': 'Founding of Jamaat-e-Islami',
        'date': 'August 26, 1941',
        'description': 'Maulana Maududi founded the Jamaat-e-Islami, an Islamic revivalist party.',
      },
      {
        'id': 'bio3',
        'title': 'Death of Maulana Maududi',
        'date': 'September 22, 1979',
        'description': 'Maulana Maududi passed away in Buffalo, New York, USA.',
      },
    ];

    return mockBiographyEvents
        .where((event) =>
            (event['title'] as String).toLowerCase().contains(query) ||
            (event['date'] as String).toLowerCase().contains(query) ||
            (event['description'] as String).toLowerCase().contains(query))
        .map((event) => SearchResultModel.fromBiographyEvent(event))
        .toList();
  }

  @override
  Future<List<String>> getRecentSearches() async {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    debugPrint('MockSearchDataSource: Saving recent search "$query"');
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
