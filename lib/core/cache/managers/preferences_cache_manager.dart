import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import '../utils/cache_logger.dart';
import '../utils/cache_utils.dart';

/// Manages caching for preferences, bookmarks, and other small data items
class PreferencesCacheManager {
  static final Logger _log = Logger('PreferencesCacheManager');
  
  // Key prefixes for different types of data
  static const String _bookmarksPrefix = 'bookmarks_';
  static const String _readingProgressPrefix = 'reading_progress_';
  static const String _preferencesPrefix = 'preferences_';
  static const String _metadataPrefix = 'metadata_';
  
  late final SharedPreferences _preferences;
  bool _initialized = false;

  /// Initialize the preferences cache manager
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _preferences = await SharedPreferences.getInstance();
      _initialized = true;
      CacheLogger.info('PreferencesCacheManager initialized successfully');
    } catch (e, stackTrace) {
      _log.severe('Error initializing PreferencesCacheManager', e, stackTrace);
      rethrow;
    }
  }

  /// Save a list of bookmarks for a book
  Future<bool> saveBookmarks(String bookId, List<dynamic> bookmarks) async {
    if (!_initialized) await initialize();
    
    try {
      final key = _bookmarksPrefix + bookId;
      final json = jsonEncode(bookmarks);
      
      // Save to preferences
      final result = await _preferences.setString(key, json);
      
      // Save metadata
      await _saveMetadata(key, CacheUtils.calculateStringSize(json));
      
      CacheLogger.info('Saved bookmarks for book: $bookId');
      return result;
    } catch (e, stackTrace) {
      _log.severe('Error saving bookmarks: $bookId', e, stackTrace);
      return false;
    }
  }

  /// Get bookmarks for a book
  Future<List<dynamic>?> getBookmarks(String bookId) async {
    if (!_initialized) await initialize();
    
    try {
      final key = _bookmarksPrefix + bookId;
      final json = _preferences.getString(key);
      
      if (json == null) {
        CacheLogger.logCacheMiss(key, 'bookmarks');
        return null;
      }
      
      // Update access metadata
      await _updateAccessMetadata(key);
      
      CacheLogger.logCacheHit(key, 'bookmarks');
      return jsonDecode(json) as List<dynamic>;
    } catch (e) {
      _log.warning('Error getting bookmarks: $bookId', e);
      return null;
    }
  }

  /// Save reading progress for a book
  Future<bool> saveReadingProgress(String bookId, Map<String, dynamic> progress) async {
    if (!_initialized) await initialize();
    
    try {
      final key = _readingProgressPrefix + bookId;
      final json = jsonEncode(progress);
      
      // Save to preferences
      final result = await _preferences.setString(key, json);
      
      // Save metadata
      await _saveMetadata(key, CacheUtils.calculateStringSize(json));
      
      CacheLogger.info('Saved reading progress for book: $bookId');
      return result;
    } catch (e, stackTrace) {
      _log.severe('Error saving reading progress: $bookId', e, stackTrace);
      return false;
    }
  }

  /// Get reading progress for a book
  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    if (!_initialized) await initialize();
    
    try {
      final key = _readingProgressPrefix + bookId;
      final json = _preferences.getString(key);
      
      if (json == null) {
        CacheLogger.logCacheMiss(key, 'reading_progress');
        return null;
      }
      
      // Update access metadata
      await _updateAccessMetadata(key);
      
      CacheLogger.logCacheHit(key, 'reading_progress');
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      _log.warning('Error getting reading progress: $bookId', e);
      return null;
    }
  }

  /// Save a preference value
  Future<bool> savePreference(String key, dynamic value) async {
    if (!_initialized) await initialize();
    
    try {
      final prefKey = _preferencesPrefix + key;
      bool result;
      int size = 0; // Initialize size for all types
      
      // Handle different types of values
      if (value is String) {
        result = await _preferences.setString(prefKey, value);
        size = CacheUtils.calculateStringSize(value);
      } else if (value is bool) {
        result = await _preferences.setBool(prefKey, value);
        size = 1; // Boolean size
      } else if (value is int) {
        result = await _preferences.setInt(prefKey, value);
        size = 8; // Int size (typically 8 bytes)
      } else if (value is double) {
        result = await _preferences.setDouble(prefKey, value);
        size = 8; // Double size (typically 8 bytes)
      } else {
        // Convert to JSON for complex objects
        final json = jsonEncode(value);
        result = await _preferences.setString(prefKey, json);
        size = CacheUtils.calculateStringSize(json);  // reuse encoded string
      }
      await _saveMetadata(prefKey, size);
      
      return result;
    } catch (e) {
      _log.warning('Error saving preference: $key', e);
      return false;
    }
  }

  /// Get a preference value
  T? getPreference<T>(String key) {
    if (!_initialized) {
      _log.warning('PreferencesCacheManager not initialized');
      return null;
    }
    
    try {
      final prefKey = _preferencesPrefix + key;
      
      // Handle different types
      if (T == String) {
        return _preferences.getString(prefKey) as T?;
      } else if (T == bool) {
        return _preferences.getBool(prefKey) as T?;
      } else if (T == int) {
        return _preferences.getInt(prefKey) as T?;
      } else if (T == double) {
        return _preferences.getDouble(prefKey) as T?;
      } else {
        // Try to decode JSON for complex objects
        final json = _preferences.getString(prefKey);
        if (json == null) return null;
        
        // Update access metadata
        // ignore: unawaited_futures
        _updateAccessMetadata(prefKey);
        
        return jsonDecode(json) as T?;
      }
    } catch (e) {
      _log.warning('Error getting preference: $key', e);
      return null;
    }
  }

  /// Remove a preference by key
  Future<bool> removePreference(String key) async {
    if (!_initialized) await initialize();
    
    try {
      final prefKey = _preferencesPrefix + key;
      final metadataKey = _metadataPrefix + prefKey;
      
      // Remove preference and metadata
      await _preferences.remove(metadataKey);
      return await _preferences.remove(prefKey);
    } catch (e) {
      _log.warning('Error removing preference: $key', e);
      return false;
    }
  }

  /// Remove bookmarks for a book
  Future<bool> removeBookmarks(String bookId) async {
    if (!_initialized) await initialize();
    
    try {
      final key = _bookmarksPrefix + bookId;
      final metadataKey = _metadataPrefix + key;
      
      // Remove bookmarks and metadata
      await _preferences.remove(metadataKey);
      return await _preferences.remove(key);
    } catch (e) {
      _log.warning('Error removing bookmarks: $bookId', e);
      return false;
    }
  }

  /// Remove reading progress for a book
  Future<bool> removeReadingProgress(String bookId) async {
    if (!_initialized) await initialize();
    
    try {
      final key = _readingProgressPrefix + bookId;
      final metadataKey = _metadataPrefix + key;
      
      // Remove reading progress and metadata
      await _preferences.remove(metadataKey);
      return await _preferences.remove(key);
    } catch (e) {
      _log.warning('Error removing reading progress: $bookId', e);
      return false;
    }
  }

  /// Clear all cached preferences
  Future<bool> clearAll() async {
    if (!_initialized) await initialize();
    
    try {
      return await _preferences.clear();
    } catch (e, stackTrace) {
      _log.severe('Error clearing preferences', e, stackTrace);
      return false;
    }
  }

  /// Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    if (!_initialized) await initialize();
    
    try {
      // Get all keys
      final keys = _preferences.getKeys();
      
      // Find bookmark keys
      final bookmarkKeys = keys.where((key) => key.startsWith(_bookmarksPrefix)).toList();
      
      // Remove each key
      for (final key in bookmarkKeys) {
        await _preferences.remove(key);
        final metadataKey = _metadataPrefix + key;
        await _preferences.remove(metadataKey);
      }
      
      CacheLogger.info('Cleared all bookmarks');
    } catch (e, stackTrace) {
      _log.severe('Error clearing all bookmarks', e, stackTrace);
    }
  }

  /// Clear all reading progress
  Future<void> clearAllReadingProgress() async {
    if (!_initialized) await initialize();
    
    try {
      // Get all keys
      final keys = _preferences.getKeys();
      
      // Find reading progress keys
      final progressKeys = keys.where((key) => key.startsWith(_readingProgressPrefix)).toList();
      
      // Remove each key
      for (final key in progressKeys) {
        await _preferences.remove(key);
        final metadataKey = _metadataPrefix + key;
        await _preferences.remove(metadataKey);
      }
      
      CacheLogger.info('Cleared all reading progress');
    } catch (e, stackTrace) {
      _log.severe('Error clearing all reading progress', e, stackTrace);
    }
  }

  /// Get all bookmark IDs
  Future<List<String>> getAllBookmarkIds() async {
    if (!_initialized) await initialize();
    
    try {
      // Get all keys
      final keys = _preferences.getKeys();
      
      // Find bookmark keys and extract IDs
      return keys
          .where((key) => key.startsWith(_bookmarksPrefix))
          .map((key) => key.substring(_bookmarksPrefix.length))
          .toList();
    } catch (e) {
      _log.warning('Error getting all bookmark IDs', e);
      return [];
    }
  }

  /// Get all reading progress IDs
  Future<List<String>> getAllReadingProgressIds() async {
    if (!_initialized) await initialize();
    
    try {
      // Get all keys
      final keys = _preferences.getKeys();
      
      // Find reading progress keys and extract IDs
      return keys
          .where((key) => key.startsWith(_readingProgressPrefix))
          .map((key) => key.substring(_readingProgressPrefix.length))
          .toList();
    } catch (e) {
      _log.warning('Error getting all reading progress IDs', e);
      return [];
    }
  }

  /// Save metadata for a preference key
  Future<void> _saveMetadata(String key, int sizeBytes) async {
    final metadataKey = _metadataPrefix + key;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final metadata = {
      'timestamp': now,
      'size': sizeBytes,
      'access_count': 0,
      'last_access': now,
    };
    
    await _preferences.setString(metadataKey, jsonEncode(metadata));
  }

  /// Update access metadata for a key
  Future<void> _updateAccessMetadata(String key) async {
    try {
      final metadataKey = _metadataPrefix + key;
      final metadataJson = _preferences.getString(metadataKey);
      
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        
        // Update access count and timestamp
        metadata['access_count'] = (metadata['access_count'] as int) + 1;
        metadata['last_access'] = DateTime.now().millisecondsSinceEpoch;
        
        await _preferences.setString(metadataKey, jsonEncode(metadata));
      }
    } catch (e) {
      // Only log, don't propagate error for metadata updates
      _log.warning('Error updating metadata for: $key', e);
    }
  }

  /// Get the total size of all preferences in bytes
  Future<int> getTotalSize() async {
    if (!_initialized) await initialize();
    
    try {
      int totalSize = 0;
      
      // Get all metadata keys
      final keys = _preferences.getKeys();
      final metadataKeys = keys.where((key) => key.startsWith(_metadataPrefix)).toList();
      
      // Sum up sizes from metadata
      for (final key in metadataKeys) {
        final metadataJson = _preferences.getString(key);
        if (metadataJson != null) {
          try {
            final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
            totalSize += metadata['size'] as int;
          } catch (e) {
            // Ignore errors for individual entries
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      _log.warning('Error calculating total preferences size', e);
      return 0;
    }
  }
}
