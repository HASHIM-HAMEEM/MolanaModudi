import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/books/data/models/book_models.dart';

/// A dedicated service for caching book data using Hive
class BookCacheService {
  static const String _booksBoxName = 'books_cache';
  static const String _volumesBoxName = 'volumes_cache';
  static const String _chaptersBoxName = 'chapters_cache';
  static const String _headingsBoxName = 'headings_cache';
  static const String _contentBoxName = 'content_cache';
  
  final _log = Logger('BookCacheService');
  
  // Helper method to safely get or create a Hive box
  Future<Box<String>> getBoxSafe(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<String>(boxName);
      } else {
        return await Hive.openBox<String>(boxName);
      }
    } catch (e) {
      _log.warning('Error opening box $boxName: $e');
      // Try to delete and recreate the box if there was an error
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<String>(boxName);
      } catch (e) {
        _log.severe('Failed to recreate box $boxName: $e');
        throw Exception('Could not open Hive box: $boxName');
      }
    }
  }
  
  // Cache a complete book structure
  Future<void> cacheBook(Book book) async {
    try {
      final box = await getBoxSafe(_booksBoxName);
      final bookJson = _bookToJson(book);
      await box.put(book.firestoreDocId, jsonEncode(bookJson));
      _log.info('Cached book: ${book.title} (${book.firestoreDocId})');
    } catch (e) {
      _log.severe('Error caching book: $e');
    }
  }
  
  // Get a cached book
  Future<Book?> getCachedBook(String bookId) async {
    try {
      final box = await getBoxSafe(_booksBoxName);
      final bookJsonString = box.get(bookId);
      if (bookJsonString != null) {
        final bookJson = jsonDecode(bookJsonString) as Map<String, dynamic>;
        return _bookFromJson(bookId, bookJson);
      }
      return null;
    } catch (e) {
      _log.severe('Error getting cached book: $e');
      return null;
    }
  }
  
  // Cache a volume
  Future<void> cacheVolume(String bookId, Volume volume) async {
    try {
      final box = await getBoxSafe(_volumesBoxName);
      final key = '${bookId}_${volume.firestoreDocId}';
      final volumeJson = _volumeToJson(volume);
      await box.put(key, jsonEncode(volumeJson));
      _log.info('Cached volume: ${volume.title} ($key)');
    } catch (e) {
      _log.severe('Error caching volume: $e');
    }
  }
  
  // Get a cached volume
  Future<Volume?> getCachedVolume(String bookId, String volumeId) async {
    try {
      final box = await getBoxSafe(_volumesBoxName);
      final key = '${bookId}_$volumeId';
      final volumeJsonString = box.get(key);
      if (volumeJsonString != null) {
        final volumeJson = jsonDecode(volumeJsonString) as Map<String, dynamic>;
        return _volumeFromJson(volumeId, volumeJson);
      }
      return null;
    } catch (e) {
      _log.severe('Error getting cached volume: $e');
      return null;
    }
  }
  
  // Cache a chapter
  Future<void> cacheChapter(String bookId, String volumeId, Chapter chapter) async {
    try {
      final box = await getBoxSafe(_chaptersBoxName);
      final key = '${bookId}_${volumeId}_${chapter.firestoreDocId}';
      final chapterJson = _chapterToJson(chapter);
      await box.put(key, jsonEncode(chapterJson));
      _log.info('Cached chapter: ${chapter.title} ($key)');
    } catch (e) {
      _log.severe('Error caching chapter: $e');
    }
  }
  
  // Get a cached chapter
  Future<Chapter?> getCachedChapter(String bookId, String volumeId, String chapterId) async {
    try {
      final box = await getBoxSafe(_chaptersBoxName);
      final key = '${bookId}_${volumeId}_$chapterId';
      final chapterJsonString = box.get(key);
      if (chapterJsonString != null) {
        final chapterJson = jsonDecode(chapterJsonString) as Map<String, dynamic>;
        return _chapterFromJson(chapterId, chapterJson);
      }
      return null;
    } catch (e) {
      _log.severe('Error getting cached chapter: $e');
      return null;
    }
  }
  
  // Cache a heading
  Future<void> cacheHeading(String bookId, String volumeId, String chapterId, Heading heading) async {
    try {
      final box = await getBoxSafe(_headingsBoxName);
      final key = '${bookId}_${volumeId}_${chapterId}_${heading.firestoreDocId}';
      final headingJson = _headingToJson(heading);
      await box.put(key, jsonEncode(headingJson));
      _log.info('Cached heading: ${heading.title} ($key)');
    } catch (e) {
      _log.severe('Error caching heading: $e');
    }
  }
  
  // Get a cached heading
  Future<Heading?> getCachedHeading(String bookId, String volumeId, String chapterId, String headingId) async {
    try {
      final box = await getBoxSafe(_headingsBoxName);
      final key = '${bookId}_${volumeId}_${chapterId}_$headingId';
      final headingJsonString = box.get(key);
      if (headingJsonString != null) {
        final headingJson = jsonDecode(headingJsonString) as Map<String, dynamic>;
        return _headingFromJson(headingId, headingJson);
      }
      return null;
    } catch (e) {
      _log.severe('Error getting cached heading: $e');
      return null;
    }
  }
  
  // Cache content for a heading
  Future<void> cacheContent(String bookId, String headingId, List<String> content) async {
    try {
      final box = await getBoxSafe(_contentBoxName);
      final key = '${bookId}_$headingId';
      await box.put(key, jsonEncode(content));
      _log.info('Cached content for heading: $headingId');
    } catch (e) {
      _log.severe('Error caching content: $e');
    }
  }
  
  // Get cached content for a heading
  Future<List<String>?> getCachedContent(String bookId, String headingId) async {
    try {
      final box = await getBoxSafe(_contentBoxName);
      final key = '${bookId}_$headingId';
      final contentString = box.get(key);
      if (contentString != null) {
        final contentList = jsonDecode(contentString) as List;
        return contentList.cast<String>();
      }
      return null;
    } catch (e) {
      _log.severe('Error getting cached content: $e');
      return null;
    }
  }
  
  // Clear all caches
  Future<void> clearAllCaches() async {
    try {
      _log.info('Clearing all book caches');
      final boxNames = [
        _booksBoxName,
        _volumesBoxName,
        _chaptersBoxName,
        _headingsBoxName,
        _contentBoxName,
      ];
      
      for (final boxName in boxNames) {
        if (Hive.isBoxOpen(boxName)) {
          final box = await getBoxSafe(boxName);
          await box.clear();
        }
      }
      
      _log.info('All book caches cleared');
    } catch (e) {
      _log.severe('Error clearing caches: $e');
    }
  }
  
  // Helper methods for serialization
  Map<String, dynamic> _bookToJson(Book book) {
    return {
      'id': book.id,
      'unicode': book.unicode,
      'title': book.title,
      'author': book.author,
      'publisher': book.publisher,
      'publication_date': book.publicationDate,
      'description': book.description,
      'audio_url': book.audioUrl,
      'thumbnail_url': book.thumbnailUrl,
      'version': book.version,
      'link': book.link,
      'isbn': book.isbn,
      'tags': book.tags,
      'default_language': book.defaultLanguage,
      'status': book.status,
      'sequence': book.sequence,
      'is_featured': book.isFeatured,
      'created_at': book.createdAt,
      'updated_at': book.updatedAt,
      'languages': book.languages,
      'book_translations': book.bookTranslations,
      // Don't include headings and volumes arrays to avoid deep nesting
      // They are cached separately
    };
  }
  
  Book _bookFromJson(String docId, Map<String, dynamic> json) {
    return Book(
      firestoreDocId: docId,
      id: json['id'],
      unicode: json['unicode'],
      title: json['title'],
      author: json['author'],
      publisher: json['publisher'],
      publicationDate: json['publication_date'],
      description: json['description'],
      audioUrl: json['audio_url'],
      thumbnailUrl: json['thumbnail_url'],
      version: json['version'],
      link: json['link'],
      isbn: json['isbn'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      defaultLanguage: json['default_language'],
      status: json['status'],
      sequence: json['sequence'],
      isFeatured: json['is_featured'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      languages: json['languages'],
      bookTranslations: json['book_translations'],
      isFromCache: true, // Mark as from cache
    );
  }
  
  Map<String, dynamic> _volumeToJson(Volume volume) {
    return {
      'id': volume.id,
      'book_id': volume.bookId,
      'title': volume.title,
      'sequence': volume.sequence,
      'status': volume.status,
      'created_at': volume.createdAt,
      'updated_at': volume.updatedAt,
      // Don't include chapters array to avoid deep nesting
      // Chapters are cached separately
    };
  }
  
  Volume _volumeFromJson(String docId, Map<String, dynamic> json) {
    return Volume(
      firestoreDocId: docId,
      id: json['id'],
      bookId: json['book_id'],
      title: json['title'],
      sequence: json['sequence'] ?? 0,
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      // Chapters will be loaded separately
      chapters: [],
    );
  }
  
  Map<String, dynamic> _chapterToJson(Chapter chapter) {
    return {
      'id': chapter.id,
      'volume_id': chapter.volumeId,
      'book_id': chapter.bookId,
      'title': chapter.title,
      'sequence': chapter.sequence,
      'status': chapter.status,
      'created_at': chapter.createdAt,
      'updated_at': chapter.updatedAt,
      // Don't include headings array to avoid deep nesting
      // Headings are cached separately
    };
  }
  
  Chapter _chapterFromJson(String docId, Map<String, dynamic> json) {
    return Chapter(
      firestoreDocId: docId,
      id: json['id'],
      volumeId: json['volume_id'],
      bookId: json['book_id'],
      title: json['title'],
      sequence: json['sequence'] ?? 0,
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      // Content will be loaded separately if needed
      content: json['content'] != null ? List<String>.from(json['content']) : null,
    );
  }
  
  Map<String, dynamic> _headingToJson(Heading heading) {
    return {
      'id': heading.id,
      'chapter_id': heading.chapterId,
      'volume_id': heading.volumeId,
      'book_id': heading.bookId,
      'title': heading.title,
      'sequence': heading.sequence,
      'status': heading.status,
      'created_at': heading.createdAt,
      'updated_at': heading.updatedAt,
      'audio_id': heading.audioId,
      'tags': heading.tags,
      // Content is cached separately for efficiency
    };
  }
  
  Heading _headingFromJson(String docId, Map<String, dynamic> json) {
    return Heading(
      firestoreDocId: docId,
      id: json['id'],
      chapterId: json['chapter_id'],
      volumeId: json['volume_id'],
      bookId: json['book_id'],
      title: json['title'],
      sequence: json['sequence'] ?? 0,
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      audioId: json['audio_id'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      // Content will be loaded separately
      content: [],
    );
  }
}
