import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark_model.dart';

class SimpleBookmarkService {
  static const String _bookmarksKey = 'simple_bookmarks';

  // Get all bookmarks
  Future<List<SimpleBookmark>> getAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
    
    return bookmarksJson
        .map((json) => SimpleBookmark.fromJson(jsonDecode(json)))
        .toList();
  }

  // Get bookmarks for a specific book
  Future<List<SimpleBookmark>> getBookmarksForBook(String bookId) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks.where((bookmark) => bookmark.bookId == bookId).toList();
  }

  // Add a bookmark
  Future<void> addBookmark(SimpleBookmark bookmark) async {
    final allBookmarks = await getAllBookmarks();
    
    // Remove existing bookmark with same key (if any)
    allBookmarks.removeWhere((b) => b.uniqueKey == bookmark.uniqueKey);
    
    // Add new bookmark
    allBookmarks.add(bookmark);
    
    // Save to preferences
    await _saveBookmarks(allBookmarks);
  }

  // Remove a bookmark
  Future<void> removeBookmark(String bookmarkId) async {
    final allBookmarks = await getAllBookmarks();
    allBookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    await _saveBookmarks(allBookmarks);
  }

  // Check if a chapter/heading is bookmarked
  Future<bool> isBookmarked(String bookId, String chapterId, [String? headingId]) async {
    final allBookmarks = await getAllBookmarks();
    final uniqueKey = headingId != null 
        ? '${bookId}_${chapterId}_$headingId'
        : '${bookId}_$chapterId';
        
    return allBookmarks.any((bookmark) => bookmark.uniqueKey == uniqueKey);
  }

  // Toggle bookmark (add if not exists, remove if exists)
  Future<bool> toggleBookmark({
    required String bookId,
    required String chapterId,
    required String chapterTitle,
    String? headingId,
    String? headingTitle,
  }) async {
    final uniqueKey = headingId != null 
        ? '${bookId}_${chapterId}_$headingId'
        : '${bookId}_$chapterId';

    final allBookmarks = await getAllBookmarks();
    final existingIndex = allBookmarks.indexWhere((b) => b.uniqueKey == uniqueKey);

    if (existingIndex != -1) {
      // Remove existing bookmark
      allBookmarks.removeAt(existingIndex);
      await _saveBookmarks(allBookmarks);
      return false; // Bookmark removed
    } else {
      // Add new bookmark
      final newBookmark = SimpleBookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: bookId,
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        headingId: headingId,
        headingTitle: headingTitle,
        timestamp: DateTime.now(),
      );
      
      allBookmarks.add(newBookmark);
      await _saveBookmarks(allBookmarks);
      return true; // Bookmark added
    }
  }

  // Clear all bookmarks for a book
  Future<void> clearBookmarksForBook(String bookId) async {
    final allBookmarks = await getAllBookmarks();
    allBookmarks.removeWhere((bookmark) => bookmark.bookId == bookId);
    await _saveBookmarks(allBookmarks);
  }

  // Private method to save bookmarks
  Future<void> _saveBookmarks(List<SimpleBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = bookmarks
        .map((bookmark) => jsonEncode(bookmark.toJson()))
        .toList();
    
    await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }
} 