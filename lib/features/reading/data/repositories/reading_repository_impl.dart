import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import 'package:modudi/core/cache/models/cache_priority.dart';
import 'package:modudi/core/cache/models/cache_result.dart';
import 'package:modudi/core/providers/providers.dart';
import 'package:modudi/core/services/gemini_service.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'package:modudi/features/reading/data/models/bookmark_model.dart';
import 'package:modudi/features/reading/domain/entities/book_structure.dart'; // Added import
import 'package:shared_preferences/shared_preferences.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  final GeminiService geminiService;
  final FirebaseFirestore _firestore;
  final CacheService _cacheService;
  final _log = Logger('ReadingRepository');

  // Key prefix for storing bookmarks in shared_preferences
  static const String _bookmarkStorePrefix = 'bookmarks_';

  ReadingRepositoryImpl({
    required this.geminiService,
    required CacheService cacheService,
    FirebaseFirestore? firestore,
  })
   : _firestore = firestore ?? FirebaseFirestore.instance,
     _cacheService = cacheService;

  @override
  Future<Book> getBookData(String bookId) async {
    try {
      // STEP 1: Check if we have a complete book in memory cache first (ultra-fast)
      _log.info('Checking cache for book ID: $bookId');
      final cacheResult = await _cacheService.getCachedData<Map<String, dynamic>>(
        key: '${CacheConstants.bookKeyPrefix}$bookId',
        boxName: CacheConstants.booksBoxName,
      );
      
      // Create a variable to track if we need a background refresh
      bool needsBackgroundRefresh = false;
      
      // If book exists in cache, use it
      if (cacheResult.hasData) {
        _log.info('Book found in cache for ID: $bookId');
        final cachedBook = Book.fromMap(bookId, cacheResult.data!);
        
        // No need to mark as from cache as that parameter doesn't exist
        final bookWithCacheFlag = cachedBook;
        
        // Update book access priority to improve cache retention
        await _cacheService.updateBookPriority(bookId, CachePriorityLevel.high);
        
        // If the cached book has all necessary data, return it immediately
        if (bookWithCacheFlag.volumes != null && bookWithCacheFlag.volumes!.isNotEmpty) {
          _log.info('Returning complete book from cache: ${bookWithCacheFlag.title}');
          
          // Check if cache is stale and needs a background refresh
          // Only refresh if the cache entry is older than 24 hours
          if (cacheResult.metadata != null) {
            final cacheAge = DateTime.now().millisecondsSinceEpoch - 
                cacheResult.metadata!.timestamp;
            if (cacheAge > const Duration(hours: 24).inMilliseconds) {
              _log.info('Cache is stale (> 24h old), will refresh in background');
              needsBackgroundRefresh = true;
            } else {
              _log.info('Cache is fresh (< 24h old), no background refresh needed');
            }
          } else {
            // If we don't have metadata, assume we need a refresh
            needsBackgroundRefresh = true;
          }
          
          // Only trigger background refresh if necessary and AFTER returning cached data
          if (needsBackgroundRefresh) {
            // This doesn't block the UI as it schedules the work to happen later
            _refreshBookInBackground(bookId);
          }
          
          // Return cached data immediately, background refresh happens independently
          return bookWithCacheFlag;
        }
        
        _log.info('Cached book missing volumes/headings, will supplement with Firestore data');
      }
      
      // Check if device is online before attempting to access Firestore
      final isOnline = await _cacheService.isConnected();
      if (!isOnline) {
        _log.info('Device is offline, can only use cache data');
        if (cacheResult.hasData) {
          // Return whatever we have from cache even if incomplete
          return Book.fromMap(bookId, cacheResult.data!);
        } else {
          throw Exception('No cached data available for book ID: $bookId and device is offline');
        }
      }
      
      // STEP 2: Try Firestore (remote data source) - only if online
      _log.info('Querying Firestore for book ID: $bookId');
      DocumentSnapshot? docSnapshot;
      
      try {
        docSnapshot = await _firestore.collection('books').doc(bookId).get();
        
        if (!docSnapshot.exists) {
          _log.warning('No book found for ID: $bookId in Firestore');
          throw Exception('Book with ID $bookId not found in Firestore');
        }
        
        final data = docSnapshot.data();
        
        if (data == null) {
          _log.severe('Book document exists but data is null for ID: $bookId');
          throw Exception('Book data is null in Firestore');
        }
        
        // Cast Firestore data to the correct type
        // Since we know data from Firestore is a Map<String, dynamic>
        final Map<String, dynamic> bookData = data as Map<String, dynamic>;
        final bookFromFirestoreMetadata = Book.fromMap(bookId, bookData);

        // Try to load headings or chapters (volumes)
        try {
          _log.info('Loading volumes from Firestore for book ID: $bookId');
          final volumesSnapshot = await _firestore
              .collection('books')
              .doc(bookId)
              .collection('volumes')
              .orderBy('sequence')
              .get();

          final firestoreVolumes = volumesSnapshot.docs
              .map((doc) => Volume.fromMap(doc.id, doc.data()))
              .toList();

          // Cache each volume individually with a long TTL
          for (final volume in firestoreVolumes) {
            await _cacheService.cacheData(
              key: '${CacheConstants.volumeKeyPrefix}${bookId}_${volume.id}',
              data: volume.toMap(),
              boxName: CacheConstants.volumesBoxName,
              ttl: const Duration(days: 30),  // Keep for a month
            );
          }

          // Create the complete book with all data
          final completeBook = bookFromFirestoreMetadata.copyWith(
              volumes: firestoreVolumes,
              // Fresh from Firestore
              );

          // Cache the COMPLETE book data (including volumes) with a long TTL
          _log.info('Caching complete book data (with volumes) for book ID: $bookId');
          final bookDataMap = completeBook.toMap(); // Book.toMap() now correctly returns Map<String, dynamic>
          await _cacheService.cacheData(
            key: '${CacheConstants.bookKeyPrefix}$bookId',
            data: bookDataMap,
            boxName: CacheConstants.booksBoxName,
            ttl: const Duration(days: 90),  // Extend to 90 days for better offline experience
          );

          _log.info('Successfully loaded and cached complete book: ${completeBook.title} from Firestore');
          return completeBook;

        } catch (innerE, stackTrace) {
          _log.warning('Failed to load volumes/headings from Firestore for book ID: $bookId. Error: $innerE. Stack: $stackTrace');
          // If loading volumes failed, cache only the metadata as a fallback
          _log.info('Caching basic book data (metadata only) for book ID: $bookId due to volume load failure.');
          await _cacheService.cacheData(
            key: '${CacheConstants.bookKeyPrefix}$bookId',
            data: data,
            boxName: CacheConstants.booksBoxName,
            ttl: const Duration(days: 30),
          );
          // Return book with metadata only, marked as not from cache
          return bookFromFirestoreMetadata;
        }  
      } catch (firestoreError) {
        _log.severe('Firestore error: $firestoreError');
        
        // STEP 3: If Firestore fails but we have cache, return cache
        if (cacheResult.hasData) {
          _log.info('Firestore failed but returning cached book data as fallback');
          return Book.fromMap(bookId, cacheResult.data!);
        }
        
        // If all else fails, rethrow to trigger the fallback book creation
        rethrow;
      }
    } catch (e, stackTrace) {
      _log.severe('Error fetching book data for ID $bookId: $e');
      _log.severe('Stack trace: $stackTrace');
      
      // Return a fallback book object as last resort
      return Book(
        firestoreDocId: bookId,
        title: 'Error Loading Book',
        author: 'Unknown',
        thumbnailUrl: '',
        defaultLanguage: 'ur', // Set Urdu as default for consistency with app
        description: 'کتاب لوڈ کرنے میں خرابی آگئی۔ براہ کرم دوبارہ کوشش کریں۔',
        volumes: [],
        status: 'error',
      );
    }
  }

  // Helper method to refresh book data in background without blocking UI
  Future<void> _refreshBookInBackground(String bookId) async {
    // Ensuring this runs completely independently from the UI thread
    // by pushing it to the end of the event queue
    Future.microtask(() async {
      try {
        // Check network connectivity before attempting refresh
        final isConnected = await _cacheService.isConnected();
        if (!isConnected) {
          _log.info('Skipping background refresh for book $bookId: device is offline');
          return;
        }
        
        // Add a deliberate delay to ensure UI has time to render first
        // This prioritizes user experience over data freshness
        await Future.delayed(const Duration(seconds: 2));
        
        _log.info('Background refreshing book data for ID: $bookId');
        
        // Get fresh data from Firestore
        final docSnapshot = await _firestore.collection('books').doc(bookId).get();
        if (!docSnapshot.exists) {
          _log.warning('Book not found during background refresh: $bookId');
          return;
        }
        
        final data = docSnapshot.data();
        if (data == null) {
          _log.warning('Book data is null during background refresh: $bookId');
          return;
        }
        
        // Get volumes
        final volumesSnapshot = await _firestore
            .collection('books')
            .doc(bookId)
            .collection('volumes')
            .orderBy('sequence')
            .get();

        final firestoreVolumes = volumesSnapshot.docs
            .map((doc) => Volume.fromMap(doc.id, doc.data()))
            .toList();
        
        // Cache the updated book data
        final completeBook = Book.fromMap(bookId, data).copyWith(volumes: firestoreVolumes);
        await _cacheService.cacheData(
          key: '${CacheConstants.bookKeyPrefix}$bookId',
          data: completeBook.toMap(),
          boxName: CacheConstants.booksBoxName,
          ttl: const Duration(days: 30),
        );
        
        _log.info('Background refresh completed for book $bookId');
      } catch (e) {
        _log.warning('Background refresh failed for book $bookId: $e');
      }
    });
  }

  @override
  Future<List<Heading>> getBookHeadings(String bookId) async {
    try {
      // Convert bookId to integer for querying against book_id field
      final numericBookId = int.tryParse(bookId);
      if (numericBookId == null) {
        _log.warning('Invalid book ID format: $bookId');
        return [];
      }
      
      // Try to get from cache first, but use a proper cache-first approach
      final cacheKey = '${CacheConstants.bookKeyPrefix}${bookId}_headings';
      final cacheResult = await _cacheService.getCachedData<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.headingsBoxName,
      );
      
      // If we have valid cache data, use it and refresh in background if needed
      if (cacheResult.hasData && cacheResult.data != null && cacheResult.data!.isNotEmpty) {
        _log.info('Retrieved headings for book $bookId from cache');
        
        // Start background refresh if device is online
        _refreshHeadingsInBackground(bookId, numericBookId, cacheKey);
        
        // Convert the dynamic list back to headings
        return cacheResult.data!.map<Heading>((item) => 
          Heading.fromMap(item['id'].toString(), Map<String, dynamic>.from(item))
        ).toList();
      }
      
      // If no valid cache, check connectivity before trying network
      final isOnline = await _cacheService.isConnected();
      if (!isOnline) {
        _log.warning('Device is offline and no cached headings available for book $bookId');
        return []; // Return empty list when offline with no cache
      }
      
      // Network fetch since cache missed
      _log.info('Querying headings collection for book_id: $numericBookId');
      final headingsSnap = await _firestore
          .collection('headings')
          .where('book_id', isEqualTo: numericBookId)
          .orderBy('sequence', descending: false)
          .get();
      
      _log.info('Found ${headingsSnap.docs.length} headings for book ID: $bookId');
      
      if (headingsSnap.docs.isEmpty) {
        _log.warning('No headings found for book ID: $bookId');
        return [];
      }
      
      // Convert to list of maps for caching
      final headingsData = headingsSnap.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Cache the fetched data
      await _cacheService.cacheData(
        key: cacheKey,
        data: headingsData,
        boxName: CacheConstants.headingsBoxName,
        ttl: const Duration(days: 7),
      );
      
      // Convert the dynamic list to headings
      return headingsData.map<Heading>((item) => 
        Heading.fromMap(item['id'].toString(), Map<String, dynamic>.from(item))
      ).toList();
    } catch (e) {
      _log.severe('Error fetching book headings for bookId $bookId: $e');
      return []; // Return empty list instead of rethrowing to avoid app crashes
    }
  }
  
  // Helper method to refresh headings in background
  Future<void> _refreshHeadingsInBackground(String bookId, int numericBookId, String cacheKey) async {
    Future.delayed(Duration.zero, () async {
      try {
        final isConnected = await _cacheService.isConnected();
        if (!isConnected) return;
        
        _log.info('Background refreshing headings for book ID: $bookId');
        
        final headingsSnap = await _firestore
            .collection('headings')
            .where('book_id', isEqualTo: numericBookId)
            .orderBy('sequence', descending: false)
            .get();
        
        if (headingsSnap.docs.isEmpty) return;
        
        final headingsData = headingsSnap.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        
        // Update cache with fresh data
        await _cacheService.cacheData(
          key: cacheKey,
          data: headingsData,
          boxName: CacheConstants.headingsBoxName,
          ttl: const Duration(days: 7),
        );
        
        _log.info('Background refresh completed for headings of book $bookId');
      } catch (e) {
        _log.warning('Background refresh failed for headings of book $bookId: $e');
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> extractChaptersFromContent(
    String content, {
    String? bookType,
    String? bookTitle,
    bool isTableOfContents = false,
  }) async {
    try {
      _log.info('Extracting chapters using AI for ${bookTitle ?? "unknown book"}');
      final chapters = await geminiService.extractChapters(
        content,
        bookType: bookType,
        title: bookTitle,
        isTableOfContents: isTableOfContents,
      );
      _log.info('Extracted ${chapters.length} chapters');
      return chapters;
    } catch (e) {
      _log.severe('Error extracting chapters: $e');
      // Return empty list as fallback
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> explainDifficultWords(
    String text, {
    String? targetLanguage,
    String? difficulty,
  }) async {
    try {
      _log.info('Identifying and explaining difficult words');
      final explanations = await geminiService.explainDifficultWords(
        text,
        targetLanguage: targetLanguage,
        difficulty: difficulty,
      );
      _log.info('Explained ${explanations.length} words');
      
      // Convert list to map for easier lookup
      Map<String, dynamic> wordMap = {};
      for (var word in explanations) {
        if (word.containsKey('word') && word.containsKey('definition')) {
          wordMap[word['word']] = word['definition'];
        }
      }
      
      return wordMap;
    } catch (e) {
      _log.severe('Error explaining difficult words: $e');
      return {};
    }
  }
  
  @override
  Future<Map<String, dynamic>> getRecommendedReadingSettings(
    String textSample, {
    String? language,
  }) async {
    try {
      _log.info('Recommending reading settings for text');
      final lang = language ?? 'English'; // Default to English if not provided
      final settings = await geminiService.recommendReadingSettings(
        textSample,
        lang,
      );
      return settings;
    } catch (e) {
      _log.severe('Error recommending reading settings: $e');
      return {
        'fontType': 'Serif',
        'fontSize': 16.0,
        'lineSpacing': 1.5,
        'colorScheme': 'light',
        'explanation': 'Default settings. AI recommendation failed.'
      };
    }
  }
  
  @override
  Future<Map<String, dynamic>> generateBookSummary(
    String text, {
    String? bookTitle,
    String? author,
    String? language,
  }) async {
    try {
      _log.info('Generating summary for book: ${bookTitle ?? "Unknown title"}');
      final summary = await geminiService.generateBookSummary(
        bookTitle ?? 'Unknown Book',
        author ?? 'Unknown Author',
        excerpt: text,
        language: language,
      );
      return summary;
    } catch (e) {
      _log.severe('Error generating book summary: $e');
      return {
        'summary': 'Failed to generate summary.',
        'themes': [],
        'keyTakeaways': []
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getBookRecommendations(
    List<String> recentBooks, {
    String preferredGenre = '',
    List<String>? preferredAuthors,
    String? readerProfile,
  }) async {
    try {
      _log.info('Getting book recommendations based on: ${recentBooks.join(", ")}');
      return await geminiService.getBookRecommendations(
        recentBooks,
        preferredGenre: preferredGenre,
        preferredAuthors: preferredAuthors,
        readerProfile: readerProfile,
      );
    } catch (e) {
      _log.severe('Error getting book recommendations: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> translateText(
    String text,
    String targetLanguage, {
    bool preserveFormatting = true,
  }) async {
    try {
      _log.info('Translating text to $targetLanguage');
      final translated = await geminiService.translateText(
        text,
        targetLanguage,
        preserveFormatting: preserveFormatting,
      );
      return translated;
    } catch (e) {
      _log.severe('Error translating text: $e');
      return {
        'translated': 'Translation failed',
        'detectedLanguage': 'unknown'
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchWithinContent(
    String query,
    String bookContent,
  ) async {
    try {
      _log.info('Searching for: "$query" in book content');
      // Split content into paragraphs for searching
      final paragraphs = bookContent
          .split('\n\n')
          .where((p) => p.trim().length > 20) // Filter out short paragraphs
          .take(50) // Limit to 50 paragraphs to avoid token limits
          .toList();
      
      final results = await geminiService.semanticSearch(query, paragraphs);
      _log.info('Found ${results.length} relevant paragraphs');
      return results;
    } catch (e) {
      _log.severe('Error searching within content: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>> analyzeThemesAndConcepts(String text) async {
    try {
      _log.info('Analyzing themes and concepts in text');
      final analysis = await geminiService.analyzeThemesAndConcepts(text);
      return analysis;
    } catch (e) {
      _log.severe('Error analyzing themes and concepts: $e');
      return {
        'majorThemes': [],
        'concepts': [],
        'tone': 'Analysis failed',
        'style': 'Analysis failed',
      };
    }
  }
  
  @override
  Future<Map<String, dynamic>> generateTtsPrompt(
    String text, {
    String? voiceStyle,
    String? language,
  }) async {
    try {
      _log.info('Generating TTS prompt for text');
      final markers = await geminiService.generateSpeechMarkers(
        text,
        voiceStyle: voiceStyle,
        language: language,
      );
      return markers;
    } catch (e) {
      _log.severe('Error generating TTS prompt: $e');
      return {
        'ssml': text,
        'markedText': text,
        'emotion': 'neutral',
        'pace': 'medium',
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> suggestBookmarks(String text) async {
    try {
      _log.info('Suggesting bookmarks for text');
      final bookmarks = await geminiService.suggestBookmarks(text);
      _log.info('Suggested ${bookmarks.length} bookmarks');
      return bookmarks;
    } catch (e) {
      _log.severe('Error suggesting bookmarks: $e');
      return [];
    }
  }

  bool isValidHeadingData(Map<String, dynamic> data) {
    // Check if required fields exist and have correct types
    if (!data.containsKey('title') || data['title'] == null) {
      _log.warning('Heading missing title field or title is null');
      return false;
    }
    
    if (!data.containsKey('content')) {
      _log.warning('Heading missing content field');
      return false;
    }
    
    // Check content field type and handle accordingly
    if (data['content'] != null && data['content'] is! List && data['content'] is! String) {
      _log.warning('Heading content has invalid type: ${data['content'].runtimeType}');
      return false;
    }
    
    // Check if 'sequence' field exists and is a number (important for ordering)
    if (!data.containsKey('sequence') || data['sequence'] is! num) {
      _log.warning('Heading missing or invalid sequence field');
      // Not returning false, as it might still be displayable, but logging a warning.
    }

    // Check if 'book_id' field exists (important for linking)
    if (!data.containsKey('book_id')) {
      _log.warning('Heading missing book_id field');
      // Not returning false, as it might still be displayable if fetched by direct ID
    }
    return true;
  }
  
  @override
  Future<dynamic> getHeadingById(String headingId) async {
    try {
      _log.info('Fetching heading by ID: $headingId');
      final docSnap = await _firestore.collection('headings').doc(headingId).get();
      
      if (!docSnap.exists || docSnap.data() == null) {
        _log.warning('Heading not found for ID: $headingId');
        return null;
      }
      
      final data = docSnap.data()!;
      if (!isValidHeadingData(data)) {
        _log.warning('Invalid heading data for ID: $headingId');
        return null;
      }
      
      return Heading.fromMap(headingId, data);
    } catch (e, stackTrace) {
      _log.severe('Error fetching heading by ID: $e', e, stackTrace);
      return null; // Return null instead of throwing to avoid app crashes
    }
  }

  Future<Map<String, dynamic>> getHeadingContent(String headingId, {String? bookId}) async {
    try {
      final String cacheKey = '${CacheConstants.headingContentKeyPrefix}$headingId';
      
      final CacheResult<Map<String, dynamic>>? cacheResult = 
          await _cacheService.fetch<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.contentBoxName,
        networkFetch: () async {
          _log.info('Fetching content for heading ID: $headingId from Firestore.');
          final docSnap = await _firestore.collection('content').doc(headingId).get();

          if (!docSnap.exists || docSnap.data() == null) {
            _log.warning('Content not found for heading ID: $headingId in Firestore.');
            throw Exception('Content for heading $headingId not found in Firestore.');
          }
          
          return docSnap.data()!;
        },
        ttl: CacheConstants.bookCacheTtl, 
      );
    
      final Map<String, dynamic>? contentData = cacheResult?.data;

      if (contentData != null) {
        // Log if from cache or network based on CacheResultSource
        if (cacheResult?.source == CacheResultSource.cache) {
          _log.info('Retrieved content for heading $headingId from cache');
        } else if (cacheResult?.source == CacheResultSource.network) {
          _log.info('Retrieved content for heading $headingId from network (and cached)');
        }
        return contentData;
      } else {
        // This case implies cacheResult was null, or cacheResult.data was null.
        // _cacheService.fetch should ideally not return a null CacheResult if networkFetch succeeds.
        // If networkFetch throws, _cacheService.fetch should rethrow or return a CacheResult with an error.
        // For now, let's conform to CacheService.fetch expecting T or throwing.
        _log.warning('Failed to fetch content for heading $headingId. CacheResult or its data was null.');
        throw Exception('Failed to retrieve content for heading $headingId.');
      }

    } catch (e, stackTrace) {
      _log.severe('Error fetching heading content for headingId $headingId: $e', e, stackTrace);
      // Re-throw the original exception to allow higher-level error handling
      // or return a specific error structure if preferred by the app's architecture.
      rethrow; 
    }
  }
  
  @override
  Future<Map<String, dynamic>> getHeadingFullContent(String headingId, {String? bookId}) async {
    final rawContent = await getHeadingContent(headingId, bookId: bookId);
    // Add the headingId to the returned content for ease of access
    return {
      'id': headingId,
      ...rawContent,
    };
  }

  @override
  Future<List<String>> getDownloadedBookIds() async {
    try {
      return await _cacheService.getDownloadedBooks();
    } catch (e) {
      _log.warning('Error getting downloaded books: $e');
      return [];
    }
  }

  @override
  Stream<Map<String, double>> getDownloadProgressStream() {
    // Map the DownloadProgress events to the format expected by the UI
    return _cacheService.downloadProgressStream.map((progress) {
      return <String, double>{
        progress.bookId: progress.progressPercentage
      };
    });
  }

  @override
  Future<void> debugFirestoreStructure(String bookId) async {
    _log.info('Debug Firestore structure method called for book ID: $bookId');
    // Implementation simplified as we have moved to a cache-first approach
    try {
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      _log.info('Book document exists: ${bookDoc.exists}');
      
      final numericBookId = int.tryParse(bookId);
      if (numericBookId != null) {
        final headingsSnap = await _firestore
            .collection('headings')
            .where('book_id', isEqualTo: numericBookId)
            .limit(1)
            .get();
        _log.info('Found ${headingsSnap.docs.length} headings in top-level collection');
      }
    } catch (e) {
      _log.severe('Debug error: $e');
    }
  }

  @override
  Future<bool> downloadBookForOfflineReading(String bookId) async {
    try {
      _log.info('Starting to download book $bookId for offline reading');
      
      // Use the bulk download feature of CacheService
      await _cacheService.downloadBook(
        bookId: bookId,
        fetchBookData: () async {
          final docSnap = await _firestore.collection('books').doc(bookId).get();
          if (!docSnap.exists || docSnap.data() == null) {
            throw Exception('Book with ID $bookId not found in Firestore.');
          }
          return docSnap.data()!;
        },
        fetchHeadings: () async {
          final numericBookId = int.tryParse(bookId);
          if (numericBookId == null) {
            throw Exception('Invalid book ID format: $bookId');
          }
          
          final headingsSnap = await _firestore
              .collection('headings')
              .where('book_id', isEqualTo: numericBookId)
              .orderBy('sequence', descending: false)
              .get();
          
          return headingsSnap.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
        },
        fetchHeadingContent: (String headingId) async {
          final docSnap = await _firestore.collection('content').doc(headingId).get();
          if (!docSnap.exists || docSnap.data() == null) {
            throw Exception('Content for heading $headingId not found.');
          }
          return docSnap.data()!;
        },
      );
      
      return true;
    } catch (e) {
      _log.severe('Error downloading book $bookId: $e');
      return false;
    }
  }

  @override
  Future<bool> isBookAvailableOffline(String bookId) async {
    try {
      return await _cacheService.isBookDownloaded(bookId);
    } catch (e) {
      _log.warning('Error checking offline availability for book $bookId: $e');
      return false;
    }
  }

  // --- Bookmark Methods (Local Storage Implementation) ---

  Future<List<Bookmark>> _getLocalBookmarks(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? bookmarksJson = prefs.getString('$_bookmarkStorePrefix$bookId');
    if (bookmarksJson == null) {
      return [];
    }
    try {
      final List<dynamic> decodedJson = jsonDecode(bookmarksJson);
      return decodedJson.map((jsonItem) {
        // Manually reconstruct Bookmark from JSON, handling Timestamp
        return Bookmark(
          id: jsonItem['headingId'] as String, // Use headingId as id for local
          bookId: jsonItem['bookId'] as String,
          chapterId: jsonItem['chapterId'] as String,
          chapterTitle: jsonItem['chapterTitle'] as String,
          headingId: jsonItem['headingId'] as String,
          headingTitle: jsonItem['headingTitle'] as String,
          // Convert milliseconds_since_epoch (int) back to Timestamp
          timestamp: Timestamp.fromMillisecondsSinceEpoch(jsonItem['timestamp_epoch'] as int),
          textContentSnippet: jsonItem['textContentSnippet'] as String?,
        );
      }).toList();
    } catch (e) {
      _log.severe('Error decoding bookmarks for book $bookId from local storage: $e');
      return [];
    }
  }

  Future<void> _saveLocalBookmarks(String bookId, List<Bookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    // Sort by timestamp descending before saving, mimicking Firestore query
    bookmarks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final List<Map<String, dynamic>> encodableBookmarks = bookmarks.map((bookmark) {
      // Manually convert Bookmark to a JSON-encodable map
      return {
        'bookId': bookmark.bookId,
        'chapterId': bookmark.chapterId,
        'chapterTitle': bookmark.chapterTitle,
        'headingId': bookmark.headingId,
        'headingTitle': bookmark.headingTitle,
        // Convert Timestamp to milliseconds_since_epoch (int) for JSON
        'timestamp_epoch': bookmark.timestamp.millisecondsSinceEpoch,
        'textContentSnippet': bookmark.textContentSnippet,
      };
    }).toList();
    final String bookmarksJson = jsonEncode(encodableBookmarks);
    await prefs.setString('$_bookmarkStorePrefix$bookId', bookmarksJson);
  }

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    try {
      List<Bookmark> bookmarks = await _getLocalBookmarks(bookmark.bookId);
      // Remove if exists (to update)
      bookmarks.removeWhere((b) => b.headingId == bookmark.headingId);
      bookmarks.add(bookmark);
      await _saveLocalBookmarks(bookmark.bookId, bookmarks);
      _log.info('Local bookmark added/updated for book ${bookmark.bookId}, heading ${bookmark.headingId}');
    } catch (e) {
      _log.severe('Error adding local bookmark for book ${bookmark.bookId}, heading ${bookmark.headingId}: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeBookmark(String bookId, String bookmarkId) async {
    // bookmarkId here is expected to be the headingId
    try {
      List<Bookmark> bookmarks = await _getLocalBookmarks(bookId);
      bookmarks.removeWhere((b) => b.headingId == bookmarkId);
      await _saveLocalBookmarks(bookId, bookmarks);
      _log.info('Local bookmark removed for book $bookId, bookmark/heading $bookmarkId');
    } catch (e) {
      _log.severe('Error removing local bookmark for book $bookId, bookmark/heading $bookmarkId: $e');
      rethrow;
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks(String bookId) async {
    try {
      final bookmarks = await _getLocalBookmarks(bookId);
      _log.info('Fetched ${bookmarks.length} local bookmarks for book $bookId');
      return bookmarks; // Already sorted by _saveLocalBookmarks if needed, or sort here.
    } catch (e) {
      _log.severe('Error fetching local bookmarks for book $bookId: $e');
      return [];
    }
  }

  // --- Methods from BooksRepository ---

  @override
  Future<List<Book>> getBooks({String? category, int limit = 50, dynamic startAfter}) async {
    final cacheKey = category != null ? 'books_category_${category}_limit_${limit}_startAfter_${startAfter?.id ?? 'none'}' : 'all_books_limit_${limit}_startAfter_${startAfter?.id ?? 'none'}';
    try {
      final cacheResult = await _cacheService.fetch<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
        networkFetch: () async {
          _log.info('Fetching books from Firestore: category=$category, limit=$limit');
          Query query = _firestore.collection('books');
          if (category != null) {
            query = query.where('tags', arrayContains: category);
          }
          if (startAfter != null) {
            query = query.startAfterDocument(startAfter);
          }
          final querySnapshot = await query.limit(limit).get();
          return querySnapshot.docs.map((doc) => doc.data()).toList();
        },
        ttl: const Duration(hours: 1),
      );

      if (cacheResult?.data != null) {
        return cacheResult!.data!
            .map((data) => Book.fromMap(data['firestoreDocId'] ?? (data['id'] ?? FirebaseFirestore.instance.collection('dummy').doc().id), Map<String,dynamic>.from(data)))
            .toList();
      }
      return [];
    } catch (e) {
      _log.severe('Error getting books: $e');
      return [];
    }
  }

  @override
  Future<List<Book>> searchBooks(String query) async {
    final cacheKey = 'search_books_$query';
    try {
      final cacheResult = await _cacheService.fetch<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.searchBoxName, // Using a separate box for search results
        networkFetch: () async {
          _log.info('Searching books in Firestore for query: $query');
          final querySnapshot = await _firestore
              .collection('books')
              .orderBy('title')
              .startAt([query])
              .endAt(['$query\uf8ff'])
              .limit(20)
              .get();
          return querySnapshot.docs.map((doc) => doc.data()).toList();
        },
        ttl: const Duration(minutes: 10),
      );

      if (cacheResult?.data != null) {
        return cacheResult!.data!
            .map((data) => Book.fromMap(data['firestoreDocId'] ?? (data['id'] ?? FirebaseFirestore.instance.collection('dummy').doc().id), Map<String,dynamic>.from(data)))
            .toList();
      }
      return [];
    } catch (e) {
      _log.severe('Error searching books: $e');
      return [];
    }
  }

  @override
  Future<List<Book>> getFeaturedBooks({int limit = 10}) async {
    const cacheKey = 'featured_books';
    try {
      final cacheResult = await _cacheService.fetch<List<dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.booksBoxName,
        networkFetch: () async {
          _log.info('Fetching featured books from Firestore, limit=$limit');
          final querySnapshot = await _firestore
              .collection('books')
              .orderBy('title') // Consider a 'featured' flag or different ordering
              .limit(limit)
              .get();
          return querySnapshot.docs.map((doc) => doc.data()).toList();
        },
        ttl: const Duration(hours: 6),
      );

      if (cacheResult?.data != null) {
        return cacheResult!.data!
            .map((data) => Book.fromMap(data['firestoreDocId'] ?? (data['id'] ?? FirebaseFirestore.instance.collection('dummy').doc().id), Map<String,dynamic>.from(data)))
            .toList();
      }
      return [];
    } catch (e) {
      _log.severe('Error getting featured books: $e');
      return [];
    }
  }

  @override
  Future<Map<String, int>> getCategories() async {
    // TODO: Optimize this method as it iterates through all books.
    const cacheKey = 'book_categories';
    try {
      final cacheResult = await _cacheService.fetch<Map<String, dynamic>>(
        key: cacheKey,
        boxName: CacheConstants.categoriesBoxName, // Using a separate box for categories
        networkFetch: () async {
          _log.info('Fetching categories from Firestore');
          final querySnapshot = await _firestore.collection('books').get();
          final Map<String, int> categoryCounts = {};
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            final currentTags = data['tags'];
            if (currentTags is List) {
              for (var tag in currentTags) {
                final tagStr = tag.toString();
                categoryCounts[tagStr] = (categoryCounts[tagStr] ?? 0) + 1;
              }
            }
          }
          return categoryCounts;
        },
        ttl: const Duration(hours: 24),
      );

      return cacheResult?.data?.map((key, value) => MapEntry(key, value as int)) ?? {};
    } catch (e) {
      _log.severe('Error getting categories: $e');
      return {};
    }
  }

  @override
  Future<BookStructure> getBookStructure(String bookId) async {
    final String cacheKey = '${CacheConstants.bookStructureKeyPrefix}$bookId';
    _log.info('Attempting to fetch book structure for $bookId, cacheKey: $cacheKey');

    try {
      final cacheResult = await _cacheService.fetch<BookStructure>(
        key: cacheKey,
        boxName: CacheConstants.bookStructuresBoxName,
        networkFetch: () async {
          _log.info('Network fetch for book structure $bookId');
          List<Volume> volumes = [];
          List<Chapter> standaloneChapters = [];

          // Try fetching volumes first
          final volumesSnapshot = await _firestore
              .collection('books')
              .doc(bookId)
              .collection('volumes')
              .orderBy('sequence')
              .get();

          if (volumesSnapshot.docs.isNotEmpty) {
            _log.info('Found ${volumesSnapshot.docs.length} volumes for book $bookId.');
            for (var volDoc in volumesSnapshot.docs) {
              List<Chapter> chaptersInVolume = [];
              final chaptersSnapshot = await volDoc.reference
                  .collection('chapters')
                  .orderBy('sequence')
                  .get();
              
              _log.finer('Found ${chaptersSnapshot.docs.length} chapters for volume ${volDoc.id}.');
              for (var chapDoc in chaptersSnapshot.docs) {
                List<Heading> headingsInChapter = [];
                final headingsSnapshot = await chapDoc.reference
                    .collection('headings')
                    .orderBy('sequence')
                    .get();
                
                _log.finest('Found ${headingsSnapshot.docs.length} headings for chapter ${chapDoc.id}.');
                for (var headDoc in headingsSnapshot.docs) {
                  headingsInChapter.add(Heading.fromMap(headDoc.id, headDoc.data()));
                }
                chaptersInVolume.add(Chapter.fromMap(chapDoc.id, chapDoc.data()).copyWith(headings: headingsInChapter));
              }
              volumes.add(Volume.fromMap(volDoc.id, volDoc.data()).copyWith(chapters: chaptersInVolume));
            }
          } else {
            _log.info('No volumes found for book $bookId. Fetching standalone chapters.');
            // If no volumes, fetch standalone chapters
            final chaptersSnapshot = await _firestore
                .collection('books')
                .doc(bookId)
                .collection('chapters')
                .orderBy('sequence')
                .get();
            
            _log.info('Found ${chaptersSnapshot.docs.length} standalone chapters for book $bookId.');
            for (var chapDoc in chaptersSnapshot.docs) {
              List<Heading> headingsInChapter = [];
              final headingsSnapshot = await chapDoc.reference
                  .collection('headings')
                  .orderBy('sequence')
                  .get();

              _log.finer('Found ${headingsSnapshot.docs.length} headings for standalone chapter ${chapDoc.id}.');
              for (var headDoc in headingsSnapshot.docs) {
                headingsInChapter.add(Heading.fromMap(headDoc.id, headDoc.data()));
              }
              standaloneChapters.add(Chapter.fromMap(chapDoc.id, chapDoc.data()).copyWith(headings: headingsInChapter));
            }
          }
          return BookStructure(volumes: volumes, standaloneChapters: standaloneChapters);
        },
        ttl: CacheConstants.bookCacheTtl, // e.g., 30 days
        // Assuming BookStructure and its constituents (Volume, Chapter, Heading)
        // are Hive-adaptable or _cacheService.fetch can handle complex objects.
        // If not, a deserialize function would be needed here if networkFetch returned Map.
      );

      if (cacheResult?.data != null) {
        _log.info('Successfully fetched book structure for $bookId from ${cacheResult!.source}');
        return cacheResult.data!;
      } else {
        _log.warning('Book structure for $bookId is null after fetch attempt.');
        // This case should ideally be handled by _cacheService.fetch throwing an error
        // if networkFetch fails and no cache is available.
        throw Exception('Failed to load book structure for $bookId and no data was returned.');
      }
    } catch (e, stackTrace) {
      _log.severe('Error getting book structure for $bookId: $e', stackTrace);
      // Return an empty structure or rethrow, depending on desired error handling.
      // For now, rethrowing to make it clear to the provider that an error occurred.
      rethrow;
    }
  }
}

// Define the provider for ReadingRepository
// This will be replaced by consolidatedBookRepoProvider in books_providers.dart
// final readingRepositoryProvider = FutureProvider<ReadingRepository>((ref) async {
//   final geminiService = ref.watch(geminiServiceProvider);
//   // Await the CacheService from its FutureProvider
//   final cacheService = await ref.watch(cacheServiceProvider.future);
  
//   return ReadingRepositoryImpl(
//     geminiService: geminiService,
//     cacheService: cacheService,
//   );
// });