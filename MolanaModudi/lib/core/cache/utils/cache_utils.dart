import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../config/cache_constants.dart';

/// Utility functions for the cache system
class CacheUtils {
  /// Generate a unique cache key for a resource
  static String generateCacheKey({
    required String type,
    required String id,
    Map<String, dynamic>? params,
  }) {
    String key = '${_getKeyPrefix(type)}$id';
    
    if (params != null && params.isNotEmpty) {
      // Sort keys to ensure consistent ordering
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      
      // Hash the params to get a shorter, consistent representation
      final paramsStr = jsonEncode(sortedParams);
      final paramsHash = sha256.convert(utf8.encode(paramsStr)).toString().substring(0, 8);
      
      key = '${key}_$paramsHash';
    }
    
    return key;
  }
  
  /// Get the key prefix for a specific cache type
  static String _getKeyPrefix(String type) {
    switch (type.toLowerCase()) {
      case 'book':
        return CacheConstants.bookKeyPrefix;
      case 'volume':
        return CacheConstants.volumeKeyPrefix;
      case 'chapter':
        return CacheConstants.chapterKeyPrefix;
      case 'heading':
        return CacheConstants.headingKeyPrefix;
      case 'content':
        return CacheConstants.contentKeyPrefix;
      case 'video':
        return CacheConstants.videoKeyPrefix;
      case 'playlist':
        return CacheConstants.playlistKeyPrefix;
      case 'image':
        return CacheConstants.imageKeyPrefix;
      case 'bookmarks':
        return CacheConstants.bookmarksKeyPrefix;
      case 'reading_progress':
        return CacheConstants.readingProgressKeyPrefix;
      default:
        return '${type.toLowerCase()}_';
    }
  }
  
  /// Calculate the size of an object in bytes
  static int calculateObjectSize(dynamic object) {
    if (object == null) return 0;
    
    try {
      // Attempt to convert to JSON string and calculate the length in bytes
      final jsonString = jsonEncode(object);
      return utf8.encode(jsonString).length;
    } catch (e) {
      // Fallback for objects that can't be converted to JSON
      return 100; // Arbitrary small size
    }
  }
  
  /// Calculate the estimated memory size for cache management
  /// Returns the size in bytes as an integer (rounded up)
  static int calculateEstimatedSize(dynamic object) {
    final size = calculateObjectSize(object);
    // Add a small overhead for memory management (20%)
    return (size * 1.2).ceil();
  }
  
  /// Calculate the size of a string in bytes
  static int calculateStringSize(String? str) {
    if (str == null || str.isEmpty) return 0;
    return utf8.encode(str).length;
  }
  
  /// Parameters hash delimiter used to separate IDs from parameter hashes
  static const String PARAM_HASH_DELIMITER = '_';
  
  /// Standard length for parameter hashes in cache keys
  static const int PARAM_HASH_LENGTH = 8;
  
  /// Extract the ID from a cache key with proper validation
  static String extractIdFromKey(String key, String type) {
    // Validate input
    if (key.isEmpty) {
      return key;
    }
    
    final prefix = _getKeyPrefix(type);
    if (key.startsWith(prefix)) {
      // Extract the part after the prefix
      final idWithPossibleParams = key.substring(prefix.length);
      
      // Find the last delimiter indicating parameter hash
      final delimiterIndex = idWithPossibleParams.lastIndexOf(PARAM_HASH_DELIMITER);
      
      // If there's a delimiter and enough characters after it to be a hash
      if (delimiterIndex != -1 && 
          idWithPossibleParams.length - delimiterIndex - 1 >= PARAM_HASH_LENGTH) {
        
        // Extract the potential hash part
        final possibleHash = idWithPossibleParams.substring(delimiterIndex + 1);
        
        // Validate that it looks like a hash (alphanumeric with correct length)
        if (possibleHash.length == PARAM_HASH_LENGTH && 
            RegExp(r'^[a-f0-9]+$').hasMatch(possibleHash)) {
          // Return just the ID part before the hash
          return idWithPossibleParams.substring(0, delimiterIndex);
        }
      }
      
      // Return the full ID if no valid hash delimiter was found
      return idWithPossibleParams;
    }
    
    // Return original key if prefix doesn't match
    return key;
  }
  
  /// Generate a timestamp for the current time
  static int generateTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Calculate time since a timestamp in a human-readable format
  static String getTimeSince(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - timestamp;
    
    final seconds = difference ~/ 1000;
    if (seconds < 60) return '$seconds seconds ago';
    
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes minutes ago';
    
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hours ago';
    
    final days = hours ~/ 24;
    if (days < 30) return '$days days ago';
    
    final months = days ~/ 30;
    if (months < 12) return '$months months ago';
    
    final years = months ~/ 12;
    return '$years years ago';
  }
  
  /// Check if a data object is a valid JSON object
static bool isValidJsonObject(dynamic data) {
  if (data == null || data is! Map) return false;
  
  try {
    jsonEncode(data);
    return true;
  } catch (e) {
    return false;
  }
}
  
  /// Format size in human-readable format (e.g., 1.5 MB)
  static String formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
