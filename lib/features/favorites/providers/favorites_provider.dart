import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/books/data/models/book_models.dart';

// Provider for the FavoritesNotifier
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Book>>((ref) {
  return FavoritesNotifier();
});

// Notifier class to manage favorites state
class FavoritesNotifier extends StateNotifier<List<Book>> {
  final _log = Logger('FavoritesNotifier');
  static const String _prefsKey = 'favorites';
  
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }
  
  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_prefsKey) ?? [];
      
      final loadedFavorites = favoritesJson.map((jsonStr) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
        final docId = jsonMap['firestoreDocId'] as String? ?? jsonMap['id']?.toString() ?? 'unknown';
        
        // Ensure thumbnail_url is properly set for the Book model
        if (jsonMap['thumbnailUrl'] != null && !jsonMap.containsKey('thumbnail_url')) {
          jsonMap['thumbnail_url'] = jsonMap['thumbnailUrl'];
        }
        
        _log.info('Loading favorite book: $docId with thumbnail: ${jsonMap['thumbnail_url']}');
        return Book.fromMap(docId, jsonMap);
      }).toList();
      
      state = loadedFavorites;
      _log.info('Loaded ${state.length} favorites from storage');
    } catch (e) {
      _log.severe('Error loading favorites: $e');
    }
  }
  
  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = state.map((book) {
        // Create a simplified version of the book for storage
        final Map<String, dynamic> simplifiedBook = {
          'firestoreDocId': book.firestoreDocId,
          'id': book.id,
          'title': book.title,
          'author': book.author,
          'thumbnail_url': book.thumbnailUrl, // Use the correct field name expected by Book.fromMap
          'description': book.description?.substring(0, 
                        book.description!.length > 100 ? 100 : book.description!.length),
          'defaultLanguage': book.defaultLanguage ?? 'N/A', // Add language for display
          'tags': book.tags ?? [], // Add tags for category display
        };
        
        return jsonEncode(simplifiedBook);
      }).toList();
      
      await prefs.setStringList(_prefsKey, favoritesJson);
      _log.info('Saved ${state.length} favorites to storage');
    } catch (e, stack) {
      _log.severe('Error saving favorites: $e', e, stack);
    }
  }
  
  // Add a book to favorites
  Future<void> addFavorite(Book book) async {
    if (!isFavorite(book.firestoreDocId)) {
      state = [...state, book];
      await _saveFavorites();
      _log.info('Added book ${book.firestoreDocId} to favorites');
    }
  }
  
  // Remove a book from favorites
  Future<void> removeFavorite(String bookId) async {
    if (isFavorite(bookId)) {
      state = state.where((book) => book.firestoreDocId != bookId).toList();
      await _saveFavorites();
      _log.info('Removed book $bookId from favorites');
    }
  }
  
  // Toggle a book's favorite status
  Future<void> toggleFavorite(Book book) async {
    if (isFavorite(book.firestoreDocId)) {
      await removeFavorite(book.firestoreDocId);
    } else {
      await addFavorite(book);
    }
  }
  
  // Check if a book is in favorites
  bool isFavorite(String bookId) {
    return state.any((book) => book.firestoreDocId == bookId);
  }
} 