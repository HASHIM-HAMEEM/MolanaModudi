import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import 'package:modudi/core/cache/models/cache_metadata.dart';
import 'package:modudi/core/cache/models/cache_priority.dart';
import 'package:modudi/core/cache/models/cache_result.dart';
import 'package:modudi/core/cache/utils/cache_utils.dart';
import 'package:modudi/core/providers/providers.dart';
import 'package:modudi/core/services/gemini_service.dart';
import 'package:modudi/core/utils/firestore_retry_helper.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'package:modudi/features/reading/data/models/bookmark_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modudi/core/cache/managers/image_cache_manager.dart';
import 'package:modudi/core/network/network_info.dart';

// ignore_for_file: unused_import

// Helper class to hold fetched book structure
class BookStructure {
  final List<Volume> volumes;
  final List<Chapter> standaloneChapters;

  BookStructure({required this.volumes, required this.standaloneChapters});
}

class ReadingRepositoryImpl implements ReadingRepository {
  final GeminiService geminiService;
  final FirebaseFirestore _firestore;
  final CacheService _cacheService;
  final _log = Logger('ReadingRepository');

  // Key prefix for storing bookmarks in shared_preferences
  // ignore: unused_field -- reserved for future local bookmark storage
  static const String _bookmarkStorePrefix = 'bookmarks_';

  // Coalesce simultaneous heading fetches per book
  final Map<String, Future<List<Heading>>> _inFlightHeadingFetches = {};

  ReadingRepositoryImpl({
    required this.geminiService,
    required CacheService cacheService,
    FirebaseFirestore? firestore,
  })
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheService = cacheService;

  // Helper method to fetch the full book structure from Firestore
  Future<BookStructure> _fetchBookStructure(String bookId) async {
    _log.info('Fetching book structure for ID: $bookId');
    final List<Volume> volumes = [];
    final List<Chapter> standaloneChapters = [];

    try {
      // 1. Fetch volumes for this book with retry logic
      final volumesQuery = await FirestoreRetryHelper.executeWithRetry(
        () => _firestore
            .collection('volumes')
            .where('book_id', isEqualTo: int.tryParse(bookId)) 
            .orderBy('sequence')
            .get(),
        'Fetch volumes for book $bookId',
      );

      _log.info('Found ${volumesQuery.docs.length} volumes for book $bookId');

      for (final volDoc in volumesQuery.docs) {
        final volData = volDoc.data();
        final volume = Volume.fromMap( (volData..['firestoreDocId'] = volDoc.id) );
        
        // 2. For each volume, fetch its chapters with retry logic
        final chaptersQuery = await FirestoreRetryHelper.executeWithRetry(
          () => _firestore
              .collection('chapters')
              .where('volume_id', isEqualTo: volume.id) 
              .orderBy('sequence')
              .get(),
          'Fetch chapters for volume ${volume.id}',
        );
      
        final List<Chapter> volumeChapters = [];
        for (final chapDoc in chaptersQuery.docs) {
          final chapData = chapDoc.data();
          // CORRECTED Chapter.fromMap call
          final chapter = Chapter.fromMap( (chapData..['firestoreDocId'] = chapDoc.id) );

          // 3. For each chapter, fetch its headings with retry logic
          final headingsQuery = await FirestoreRetryHelper.executeWithRetry(
            () => _firestore
                .collection('headings')
                .where('chapter_id', isEqualTo: chapter.id)
                .orderBy('sequence')
                .get(),
            'Fetch headings for chapter ${chapter.id}',
          );
        
          // CORRECTED Heading.fromMap call
          chapter.headings = headingsQuery.docs
              .map((hDoc) => Heading.fromMap( (hDoc.data()..['firestoreDocId'] = hDoc.id) ))
              .toList();
          volumeChapters.add(chapter);
        }
        volume.chapters = volumeChapters;
        volumes.add(volume);
      }

      // 4. If no volumes found, check for standalone chapters
      if (volumes.isEmpty) {
        _log.info('No volumes found for $bookId, checking for standalone chapters.');
        final standaloneChaptersQuery = await FirestoreRetryHelper.executeWithRetry(
          () => _firestore
              .collection('chapters')
              .where('book_id', isEqualTo: int.tryParse(bookId))
              .orderBy('sequence')
              .get(),
          'Fetch standalone chapters for book $bookId',
        );

        for (final chapDoc in standaloneChaptersQuery.docs) {
          final chapData = chapDoc.data();
          // CORRECTED Chapter.fromMap call
          final chapter = Chapter.fromMap( (chapData..['firestoreDocId'] = chapDoc.id) );

          final headingsQuery = await FirestoreRetryHelper.executeWithRetry(
            () => _firestore
                .collection('headings')
                .where('chapter_id', isEqualTo: chapter.id)
                .orderBy('sequence')
                .get(),
            'Fetch headings for standalone chapter ${chapter.id}',
          );
          // CORRECTED Heading.fromMap call
          chapter.headings = headingsQuery.docs
              .map((hDoc) => Heading.fromMap( (hDoc.data()..['firestoreDocId'] = hDoc.id) ))
              .toList();
          standaloneChapters.add(chapter);
        }
        _log.info('Found ${standaloneChapters.length} standalone chapters for book $bookId');
          }
      return BookStructure(volumes: volumes, standaloneChapters: standaloneChapters);
    } catch (e, stackTrace) {
      _log.severe('Error fetching book structure for $bookId: $e', stackTrace);
      return BookStructure(volumes: [], standaloneChapters: []);
      }
  }

  @override
  Future<CacheResult<Book>> getBookData(String bookId) async {
    final String cacheKey = '${CacheConstants.bookKeyPrefix}$bookId';
    _log.info('Getting book data for ID: $bookId using CacheService.fetch');

    final CacheResult<Map<String, dynamic>> cacheResult = await _cacheService.fetch<Map<String, dynamic>>(
      key: cacheKey,
      boxName: CacheConstants.booksBoxName,
      networkFetch: () async {
        _log.info('Network fetch triggered for book ID: $bookId');
        
        return await FirestoreRetryHelper.executeWithRetry(
          () async {
            final docSnapshot = await _firestore.collection('books').doc(bookId).get();
            if (!docSnapshot.exists || docSnapshot.data() == null) {
              _log.warning('No book found for ID: $bookId in Firestore during network fetch.');
              throw Exception('Book with ID $bookId not found in Firestore');
            }
            final data = docSnapshot.data()!;
            data['firestoreDocId'] = docSnapshot.id;
            return data;
          },
          'Fetch book data for $bookId',
        );
      },
      ttl: const Duration(days: 90),
    );
        
    if (cacheResult.data != null) {
      _log.info('Book data received for $bookId with map status: ${cacheResult.status}');
      Book book = Book.fromMap(bookId, cacheResult.data!); 

      bool hasStructure = (book.volumes != null && book.volumes!.isNotEmpty) ||
                          (book.headings != null && book.headings!.isNotEmpty && (book.volumes == null || book.volumes!.isEmpty));

      if (hasStructure) {
        _log.info('Complete book structure found for ${book.title} with map status: ${cacheResult.status}.');
        if (cacheResult.status == CacheStatus.fresh) {
          return CacheResult.fresh(book, metadata: cacheResult.metadata);
        } else if (cacheResult.status == CacheStatus.stale) {
          return CacheResult.stale(book, metadata: cacheResult.metadata, error: cacheResult.error);
        } else {
          _log.warning('Book $bookId has full structure, but map status is ${cacheResult.status}. Returning as stale with error.');
          return CacheResult.stale(book, metadata: cacheResult.metadata, error: cacheResult.error ?? Exception('Data with full structure has unexpected status: ${cacheResult.status}'));
        }
      } else {
        _log.info('Book for $bookId is missing full structure. Current status: ${cacheResult.status}. Fetching structure separately.');
        final isOnline = await _cacheService.isConnected();
        if (!isOnline) {
          _log.warning('Device is offline. Returning partial book data for $bookId as structure cannot be fetched.');
          return CacheResult.stale(book, metadata: cacheResult.metadata, error: 'Offline and book structure is missing from cache.');
        }

        try {
          _log.info('Fetching full structure for book ID: $bookId from Firestore.');
          final BookStructure structure = await _fetchBookStructure(bookId);

          List<Heading>? collectedHeadings;
          if (structure.standaloneChapters.isNotEmpty) {
            collectedHeadings = structure.standaloneChapters
                .expand((chapter) => chapter.headings ?? <Heading>[])
              .toList();
            if (collectedHeadings.isEmpty) collectedHeadings = null;
          }

          book = book.copyWith(
            volumes: structure.volumes.isNotEmpty ? structure.volumes : null,
            headings: collectedHeadings,
          );

          _log.info('Caching complete book data (with structure) for book ID: $bookId');
          await _cacheService.cacheData(
            key: cacheKey,
            data: book.toMap(), // Cache the complete book map
            boxName: CacheConstants.booksBoxName,
            ttl: const Duration(days: 90),
          );

          final newMetadata = CacheMetadata(
            originalKey: cacheKey,
            boxName: CacheConstants.booksBoxName,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            ttlMillis: const Duration(days: 90).inMilliseconds,
            source: 'network', // Explicitly set source as network after fetching structure
          );
          return CacheResult.fresh(book, metadata: newMetadata);

    } catch (e, stackTrace) {
          _log.severe('Error fetching book structure for $bookId: $e', e, stackTrace);
          return CacheResult.fromError(e, previousData: book, previousMetadata: cacheResult.metadata);
        }
      }
    } else {
      _log.warning('Initial fetch for book $bookId returned no data. Status: ${cacheResult.status}, Error: ${cacheResult.error}');
      if (cacheResult.status == CacheStatus.missing) {
        return CacheResult.missing(error: cacheResult.error);
      } else {
        return CacheResult.fromError(
          cacheResult.error ?? Exception('Book data not found and no specific error provided for $bookId'),
          previousMetadata: cacheResult.metadata,
        );
      }
    }
  }

  @override
  Future<List<Heading>> getBookHeadings(String bookId) async {
    // Deduplicate concurrent requests
    if (_inFlightHeadingFetches.containsKey(bookId)) return _inFlightHeadingFetches[bookId]!;

    final completer = Completer<List<Heading>>();
    _inFlightHeadingFetches[bookId] = completer.future;

    () async {
      try {
        // 1. Try memory/Hive cache
        final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
          key: '${CacheConstants.headingKeyPrefix}$bookId',
          boxName: CacheConstants.headingsBoxName,
        );

        if (cacheResult.hasData && cacheResult.data != null) {
          final cached = (cacheResult.data!).map((e) => Heading.fromMap(Map<String, dynamic>.from(e))).toList();
          completer.complete(cached);

          // If stale (>7d) refresh in background
          bool stale = true;
          if (cacheResult.metadata != null) {
            final age = DateTime.now().millisecondsSinceEpoch - cacheResult.metadata!.timestamp;
            stale = age > CacheConstants.defaultCacheTtl.inMilliseconds;
          }
          if (stale) {
            _refreshHeadingsInBackground(bookId);
          }
          return;
        }

        // 2. Get book data to check its structure first
        final bookResult = await getBookData(bookId);
        final book = bookResult.data;
        List<Heading> allHeadings = [];

        if (book != null && book.volumes != null && book.volumes!.isNotEmpty) {
          // Book has volumes structure - extract headings from volumes/chapters
          _log.info('Book $bookId has ${book.volumes!.length} volumes, extracting headings from structure');
          
          for (final volume in book.volumes!) {
            if (volume.chapters != null) {
              for (final chapter in volume.chapters!) {
                if (chapter.headings != null) {
                  allHeadings.addAll(chapter.headings!);
                }
              }
            }
          }
        } else {
          // Fallback: Try direct headings collection (correct structure)
          _log.info('Book $bookId has no volume structure, trying direct headings collection');
          
        QuerySnapshot<Map<String, dynamic>>? snap;
        try {
          // Query the top-level headings collection with book_id filter (try cache first)
          snap = await FirestoreRetryHelper.executeWithRetry(
            () => _firestore
                .collection('headings')
                .where('book_id', isEqualTo: int.tryParse(bookId) ?? bookId)
                .orderBy('sequence')
                .get(const GetOptions(source: Source.cache)),
            'Fetch headings from cache for book $bookId',
          );
        } catch (_) {
          // cache miss or error
        }

        if (snap == null || snap.docs.isEmpty) {
          // Fallback to server with retry logic
          snap = await FirestoreRetryHelper.executeWithRetry(
            () => _firestore
                .collection('headings')
                .where('book_id', isEqualTo: int.tryParse(bookId) ?? bookId)
                .orderBy('sequence')
                .get(const GetOptions(source: Source.server)),
            'Fetch headings from server for book $bookId',
          );
        }

          allHeadings = snap?.docs
              .map((d) => Heading.fromMap( (d.data()..['firestoreDocId'] = d.id) ))
            .toList() ?? [];
        }

        _log.info('Found ${allHeadings.length} total headings for book $bookId');

        // Cache list as list of maps
        final listMap = allHeadings.map((h) => h.toMap()..['firestoreDocId']=h.firestoreDocId).toList();
        await _cacheService.cacheData(
          key: '${CacheConstants.headingKeyPrefix}$bookId',
          data: listMap,
          boxName: CacheConstants.headingsBoxName,
          ttl: CacheConstants.defaultCacheTtl,
        );

        completer.complete(allHeadings);
      } catch (e, st) {
        _log.severe('Failed to get headings for $bookId: $e', e, st);
        completer.completeError(e, st);
      } finally {
        _inFlightHeadingFetches.remove(bookId);
      }
    }();

    return completer.future;
  }

  void _refreshHeadingsInBackground(String bookId) {
    unawaited(() async {
      try {
        _log.info('Background refresh headings for $bookId');
        await getBookHeadings(bookId); // This will re-enter but dedup due _inFlightHeadingFetches
      } catch (_) {}
    }());
  }

  // ---------------- Stub implementations for remaining repository methods ----------------

  @override
  Future<List<Map<String, dynamic>>> extractChaptersFromContent(String content,
      {String? bookType, String? bookTitle, bool isTableOfContents = false}) async {
    _log.warning('extractChaptersFromContent not yet implemented fully – returning empty list');
    return [];
  }

  @override
  Future<Map<String, dynamic>> explainDifficultWords(String text,
      {String? targetLanguage, String? difficulty}) async {
    _log.warning('explainDifficultWords not yet implemented – returning empty map');
    return {};
  }

  @override
  Future<Map<String, dynamic>> getRecommendedReadingSettings(String textSample,
      {String? language}) async {
    return {
      'fontType': 'Serif',
      'fontSize': 16.0,
      'lineSpacing': 1.5,
      'colorScheme': 'light',
      'explanation': 'Default settings placeholder',
    };
  }

  @override
  Future<Map<String, dynamic>> generateBookSummary(String text,
      {String? bookTitle, String? author, String? language}) async {
    return {
      'summary': 'Summary unavailable',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getBookRecommendations(List<String> recentBooks,
      {String preferredGenre = '', List<String>? preferredAuthors, String? readerProfile}) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> translateText(String text, String targetLanguage,
      {bool preserveFormatting = true}) async {
    return {'translated': text};
  }

  @override
  Future<List<Map<String, dynamic>>> searchWithinContent(String query, String bookContent) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> analyzeThemesAndConcepts(String text) async => {};

  @override
  Future<Map<String, dynamic>> generateTtsPrompt(String text,
      {String? voiceStyle, String? language}) async => {
        'ssml': text,
      };

  @override
  Future<List<Map<String, dynamic>>> suggestBookmarks(String text) async => [];

  @override
  Future<dynamic> getHeadingById(String headingId) async => null;

  @override
  Future<void> addBookmark(SimpleBookmark bookmark) async {
    try {
      _log.info('Adding bookmark locally: ${bookmark.id} for book ${bookmark.bookId}');

      // Get existing bookmarks
      final existingBookmarks = await getBookmarks(bookmark.bookId);

      // Check if bookmark already exists
      final existingIndex = existingBookmarks.indexWhere((b) => 
        b.chapterId == bookmark.chapterId && b.headingId == bookmark.headingId);
      
      List<SimpleBookmark> updatedBookmarks;
      if (existingIndex != -1) {
        // Update existing bookmark
        updatedBookmarks = [...existingBookmarks];
        updatedBookmarks[existingIndex] = bookmark;
        _log.info('Updated existing bookmark: ${bookmark.id}');
        } else {
        // Add new bookmark
        updatedBookmarks = [...existingBookmarks, bookmark];
        _log.info('Added new bookmark: ${bookmark.id}');
      }

      // Save to local cache
      await _cacheService.saveBookmarks(bookmark.bookId, 
          updatedBookmarks.map((b) => b.toJson()).toList());
      
      // Also save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      final bookmarkKey = '$_bookmarkStorePrefix${bookmark.bookId}';
      final bookmarkJsonList = updatedBookmarks.map((b) => jsonEncode(b.toJson())).toList();
      await prefs.setStringList(bookmarkKey, bookmarkJsonList);
      
      _log.info('Successfully saved ${updatedBookmarks.length} bookmarks locally for book ${bookmark.bookId}');
    } catch (e, stackTrace) {
      _log.severe('Error adding bookmark locally: ${bookmark.id}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> removeBookmark(String bookId, String bookmarkId) async {
    try {
      _log.info('Removing bookmark locally: $bookmarkId for book $bookId');
      
      // Get existing bookmarks
      final existingBookmarks = await getBookmarks(bookId);
      
      // Remove the bookmark
      final updatedBookmarks = existingBookmarks.where((b) => b.id != bookmarkId).toList();
      
      // Save to local cache
      await _cacheService.saveBookmarks(bookId, 
          updatedBookmarks.map((b) => b.toJson()).toList());
      
      // Also save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      final bookmarkKey = '$_bookmarkStorePrefix$bookId';
      if (updatedBookmarks.isEmpty) {
        await prefs.remove(bookmarkKey);
      } else {
        final bookmarkJsonList = updatedBookmarks.map((b) => jsonEncode(b.toJson())).toList();
        await prefs.setStringList(bookmarkKey, bookmarkJsonList);
      }
      
      _log.info('Successfully removed bookmark: $bookmarkId. Remaining: ${updatedBookmarks.length}');
    } catch (e, stackTrace) {
      _log.severe('Error removing bookmark: $bookmarkId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<SimpleBookmark>> getBookmarks(String bookId) async {
    try {
      _log.info('Loading bookmarks locally for book: $bookId');
      
      // Try cache first (fastest)
      final cachedBookmarks = await _cacheService.getBookmarks(bookId);
      if (cachedBookmarks != null && cachedBookmarks.isNotEmpty) {
        _log.info('Found ${cachedBookmarks.length} cached bookmarks for book $bookId');
        return cachedBookmarks.map((json) => SimpleBookmark.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bookmarkKey = '$_bookmarkStorePrefix$bookId';
      final bookmarkJsonList = prefs.getStringList(bookmarkKey) ?? [];
      
      if (bookmarkJsonList.isNotEmpty) {
        final bookmarks = bookmarkJsonList
            .map((jsonStr) => SimpleBookmark.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>))
            .toList();
        
        // Cache the results for faster access
        await _cacheService.saveBookmarks(bookId, 
            bookmarks.map((b) => b.toJson()).toList());
        
        _log.info('Loaded ${bookmarks.length} bookmarks from SharedPreferences for book $bookId');
        return bookmarks;
      }
      
      _log.info('No bookmarks found for book $bookId');
      return [];
    } catch (e, stackTrace) {
      _log.severe('Error loading bookmarks for book $bookId', e, stackTrace);
      // Return empty list on error instead of rethrowing
      return [];
    }
  }

  // Helper method to clear all bookmarks for a book
  Future<void> clearAllBookmarks(String bookId) async {
    try {
      _log.info('Clearing all bookmarks for book: $bookId');
      
      // Clear from cache
      await _cacheService.saveBookmarks(bookId, []);
      
      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bookmarkKey = '$_bookmarkStorePrefix$bookId';
      await prefs.remove(bookmarkKey);
      
      _log.info('Successfully cleared all bookmarks for book $bookId');
    } catch (e, stackTrace) {
      _log.severe('Error clearing bookmarks for book $bookId', e, stackTrace);
      rethrow;
    }
  }

  // Helper method to get bookmark count for a book
  Future<int> getBookmarkCount(String bookId) async {
    try {
      final bookmarks = await getBookmarks(bookId);
      return bookmarks.length;
    } catch (e) {
      _log.warning('Error getting bookmark count for book $bookId: $e');
      return 0;
    }
  }

  // Helper method to check if a specific heading is bookmarked
  Future<bool> isHeadingBookmarked(String bookId, String chapterId, String headingId) async {
    try {
      final bookmarks = await getBookmarks(bookId);
      return bookmarks.any((b) => 
        b.chapterId == chapterId && b.headingId == headingId);
    } catch (e) {
      _log.warning('Error checking if heading is bookmarked: $e');
      return false;
    }
  }

  @override
  Future<void> debugFirestoreStructure(String bookId) async {}
}