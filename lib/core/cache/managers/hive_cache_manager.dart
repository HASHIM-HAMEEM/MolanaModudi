import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/cache/models/cache_metadata.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import '../utils/cache_logger.dart';
import '../utils/cache_utils.dart';

/// Cache policies to determine how data should be cached and retrieved
enum CachePolicy {
  /// Always use cache if available, regardless of age
  cacheFirst,
  
  /// Use cache while fetching fresh data
  staleWhileRevalidate,
  
  /// Try network first, fall back to cache
  networkFirst
}

/// Manages cache operations using Hive boxes
class HiveCacheManager {
  static final Logger _log = Logger('HiveCacheManager');
  static const String _metadataBoxName = CacheConstants.metadataBoxName;
  bool _initialized = false;

  /// Initialize Hive and open necessary boxes
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize metadata box
      if (!Hive.isBoxOpen(_metadataBoxName)) {
        await Hive.openBox<String>(_metadataBoxName);
      }
      
      _initialized = true;
      CacheLogger.info('HiveCacheManager initialized successfully');
    } catch (e, stackTrace) {
      _log.severe('Error initializing HiveCacheManager', e, stackTrace);
      rethrow;
    }
  }

  /// Ensure the box is open, opening it if necessary
  Future<Box<T>> _ensureBoxOpen<T>(String boxName) async {
    if (!_initialized) {
      await initialize();
    }

    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<T>(boxName);
    } else {
      return Hive.box<T>(boxName);
    }
  }

  /// Cache data with metadata
  Future<void> put<T>({
    required String key,
    required T data,
    required String boxName,
    required Duration ttl,
    String? language,
    Map<String, dynamic>? properties,
  }) async {
    try {
      // Convert data to string (JSON)
      final String serializedData = _serializeData(data);
      final int dataSizeBytes = CacheUtils.calculateStringSize(serializedData);
      
      // Create metadata
      final String? hash = _generateHash(data);
      final metadata = CacheMetadata(
        originalKey: key,
        boxName: boxName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttlMillis: ttl.inMilliseconds,
        dataSizeBytes: dataSizeBytes,
        language: language,
        direction: language == 'ur' || language == 'ar' ? 'rtl' : 'ltr',
        source: 'network',
        hash: hash,
        accessCount: 0,
        properties: properties,
      );

      // Store data
      final dataBox = await _ensureBoxOpen<String>(boxName);
      await dataBox.put(key, serializedData);
      
      // Store metadata
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      await metadataBox.put('$boxName:$key', jsonEncode(metadata.toMap()));
      
      CacheLogger.logCacheWrite(key, boxName, dataSizeBytes);
    } catch (e, stackTrace) {
      _log.severe('Error putting data into cache: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Get data from cache
  Future<T?> get<T>({
    required String key,
    required String boxName,
    bool updateAccessStats = true,
  }) async {
    try {
      // Get data
      final dataBox = await _ensureBoxOpen<String>(boxName);
      final serializedData = dataBox.get(key);
      
      if (serializedData == null) {
        CacheLogger.logCacheMiss(key, boxName);
        return null;
      }
      
      // Get metadata
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final metadataJson = metadataBox.get('$boxName:$key');
      
      if (metadataJson == null) {
        CacheLogger.warning('Metadata not found for existing cache entry: $key in $boxName');
        return _deserializeData<T>(serializedData);
      }
      
      // Parse metadata
      final metadata = CacheMetadata.fromMap(jsonDecode(metadataJson));
      
      // Check if expired
      if (metadata.isExpired) {
        CacheLogger.logCacheExpiry(key, boxName);
        return null;
      }
      
      // Update access stats if requested
      if (updateAccessStats) {
        _updateAccessStats(key, boxName, metadata);
      }
      
      CacheLogger.logCacheHit(key, boxName);
      return _deserializeData<T>(serializedData);
    } catch (e, stackTrace) {
      _log.severe('Error getting data from cache: $key', e, stackTrace);
      return null;
    }
  }
  
  /// Deserialize string to data
  T? _deserializeData<T>(String serializedData) {
    if (serializedData.isEmpty) {
      return null;
    }
    
    // Handle String type
    if (T == String) {
      return serializedData as T;
    }
    
    try {
      // Try to parse as JSON
      final dynamic jsonData = jsonDecode(serializedData);
      
      // Handle Map type
      if (T == Map || T == Map<String, dynamic>) {
        return jsonData as T;
      }
      
      // Handle List type
      if (T == List || T == List<dynamic>) {
        return jsonData as T;
      }
      
      // Handle regular Objects
      if (jsonData is Map) {
        // Check if data is wrapped
        if (jsonData.containsKey('data')) {
          return jsonData['data'] as T;
        }
        return jsonData as T;
      }
      
      return jsonData as T;
    } catch (e) {
      // If JSON parsing fails, return the raw string if type is compatible
      if (serializedData is T) {
        return serializedData as T;
      }
      
      _log.warning('Error deserializing data: $e');
      return null;
    }
  }
  
  /// Generate a hash for data integrity checks
  String? _generateHash(dynamic data) {
    if (data == null) return null;
    
    try {
      final String jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);
      final digest = crypto.sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      // If the data can't be encoded to JSON, return null
      return null;
    }
  }
  
  /// Serialize data to string
  /// Converts a Map to ensure all values are JSON serializable
  /// Specifically handles Firestore Timestamp objects by converting them to ISO format strings
  Map<String, dynamic> _convertMapForSerialization(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (key is String) {
        if (value != null) {
          if (value.toString().contains('Timestamp')) {
            // Handle Firestore Timestamp specifically
            try {
              // Convert Timestamp to ISO string format
              final timestamp = value as dynamic;
              if (timestamp.runtimeType.toString().contains('Timestamp') && 
                  timestamp.toString().contains('seconds')) {
                final seconds = timestamp.seconds as int;
                final nanoseconds = timestamp.nanoseconds as int;
                final dateTime = DateTime.fromMillisecondsSinceEpoch(
                  seconds * 1000 + (nanoseconds / 1000000).round(),
                );
                result[key] = dateTime.toIso8601String();
              } else {
                result[key] = value.toString();
              }
            } catch (e) {
              result[key] = value.toString();
            }
          } else if (value is Map) {
            result[key] = _convertMapForSerialization(value);
          } else if (value is List) {
            result[key] = _convertListForSerialization(value);
          } else {
            result[key] = value;
          }
        } else {
          result[key] = null;
        }
      }
    });
    return result;
  }

  /// Converts a List to ensure all values are JSON serializable
  /// Specifically handles Firestore Timestamp objects by converting them to ISO format strings
  List<dynamic> _convertListForSerialization(List<dynamic> list) {
    return list.map((item) {
      if (item != null) {
        if (item.toString().contains('Timestamp')) {
          // Handle Firestore Timestamp specifically
          try {
            // Convert Timestamp to ISO string format
            final timestamp = item as dynamic;
            if (timestamp.runtimeType.toString().contains('Timestamp') && 
                timestamp.toString().contains('seconds')) {
              final seconds = timestamp.seconds as int;
              final nanoseconds = timestamp.nanoseconds as int;
              final dateTime = DateTime.fromMillisecondsSinceEpoch(
                seconds * 1000 + (nanoseconds / 1000000).round(),
              );
              return dateTime.toIso8601String();
            } else {
              return item.toString();
            }
          } catch (e) {
            return item.toString();
          }
        } else if (item is Map) {
          return _convertMapForSerialization(item);
        } else if (item is List) {
          return _convertListForSerialization(item);
        } else {
          return item;
        }
      } else {
        return null;
      }
    }).toList();
  }

  String _serializeData<T>(T data) {
    if (data == null) {
      return '';
    }
    
    // Handle primitive types
    if (data is String) {
      return data;
    }
    
    // Handle maps and lists with Firestore Timestamp conversion
    if (data is Map) {
      return jsonEncode(_convertMapForSerialization(data));
    } else if (data is List) {
      return jsonEncode(_convertListForSerialization(data));
    }
    
    // Handle custom objects that might implement toJson
    try {
      if (data.toString().contains('toJson')) {
        // Try to encode the object as JSON
        final dataMap = {'data': data};
        return jsonEncode(_convertMapForSerialization(dataMap));
      }
    } catch (_) {
      // Ignore errors
    }
    
    // Fallback
    return data.toString();
  }

  /// Get data with metadata
  Future<Map<String, dynamic>?> getWithMetadata<T>({
    required String key,
    required String boxName,
    bool updateAccessStats = true,
  }) async {
    try {
      // Get data
      final dataBox = await _ensureBoxOpen<String>(boxName);
      final serializedData = dataBox.get(key);
      
      if (serializedData == null) {
        CacheLogger.logCacheMiss(key, boxName);
        return null;
      }
      
      // Get metadata
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final metadataJson = metadataBox.get('$boxName:$key');
      
      if (metadataJson == null) {
        CacheLogger.warning('Metadata not found for existing cache entry: $key in $boxName');
        return null;
      }
      
      // Parse metadata
      final metadata = CacheMetadata.fromMap(jsonDecode(metadataJson));
      
      // Check if expired
      if (metadata.isExpired) {
        CacheLogger.logCacheExpiry(key, boxName);
        return null;
      }
      
      // Update access stats if requested
      if (updateAccessStats) {
        _updateAccessStats(key, boxName, metadata);
      }
      
      CacheLogger.logCacheHit(key, boxName);
      final data = _deserializeData<T>(serializedData);
      
      return {
        'data': data,
        'metadata': metadata.toMap(),
      };
    } catch (e, stackTrace) {
      _log.severe('Error getting data with metadata from cache: $key', e, stackTrace);
      return null;
    }
  }

  /// Remove a cache entry
  Future<void> remove({
    required String key,
    required String boxName,
  }) async {
    try {
      // Remove data
      final dataBox = await _ensureBoxOpen<String>(boxName);
      await dataBox.delete(key);
      
      // Remove metadata
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      await metadataBox.delete('$boxName:$key');
      
      CacheLogger.info('Removed cache entry: $key from $boxName');
    } catch (e, stackTrace) {
      _log.severe('Error removing cache entry: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Clear all entries in a box
  Future<void> clearBox(String boxName) async {
    try {
      // Clear data box
      final dataBox = await _ensureBoxOpen<String>(boxName);
      await dataBox.clear();
      
      // Clear related metadata entries
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final keysToRemove = metadataBox.keys
          .where((key) => key.toString().startsWith('$boxName:'))
          .toList();
      
      for (final key in keysToRemove) {
        await metadataBox.delete(key);
      }
      
      CacheLogger.info('Cleared all entries from box: $boxName');
    } catch (e, stackTrace) {
      _log.severe('Error clearing box: $boxName', e, stackTrace);
      rethrow;
    }
  }

  /// Clear expired entries from a box
  Future<int> clearExpiredEntries(String boxName) async {
    try {
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final dataBox = await _ensureBoxOpen<String>(boxName);
      
      int removedCount = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Find all metadata entries for this box
      final metadataKeys = metadataBox.keys
          .where((key) => key.toString().startsWith('$boxName:'))
          .toList();
      
      for (final metadataKey in metadataKeys) {
        try {
          final metadataJson = metadataBox.get(metadataKey);
          if (metadataJson == null) continue;
          
          final metadata = CacheMetadata.fromMap(jsonDecode(metadataJson));
          
          // Check if expired
          if (now > (metadata.timestamp + metadata.ttlMillis)) {
            // Extract data key from metadata key
            final dataKey = metadataKey.toString().substring(boxName.length + 1);
            
            // Remove data and metadata
            await dataBox.delete(dataKey);
            await metadataBox.delete(metadataKey);
            
            removedCount++;
          }
        } catch (e) {
          // Log but continue with other entries
          _log.warning('Error processing metadata entry: $metadataKey', e);
        }
      }
      
      CacheLogger.info('Cleared $removedCount expired entries from box: $boxName');
      return removedCount;
    } catch (e, stackTrace) {
      _log.severe('Error clearing expired entries: $boxName', e, stackTrace);
      return 0;
    }
  }

  /// Enforce size limits on a box by removing least recently used entries
  Future<int> enforceSizeLimit(String boxName, int maxSizeBytes) async {
    try {
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final dataBox = await _ensureBoxOpen<String>(boxName);
      
      // Find all metadata entries for this box
      final metadataKeys = metadataBox.keys
          .where((key) => key.toString().startsWith('$boxName:'))
          .toList();
      
      // Calculate current size and collect entries
      int currentSize = 0;
      final entries = <String, CacheMetadata>{};
      
      for (final metadataKey in metadataKeys) {
        try {
          final metadataJson = metadataBox.get(metadataKey);
          if (metadataJson == null) continue;
          
          final metadata = CacheMetadata.fromMap(jsonDecode(metadataJson));
          currentSize += metadata.dataSizeBytes;
          
          // Extract data key from metadata key
          final dataKey = (metadataKey as String).substring(boxName.length + 1);
          entries[dataKey] = metadata;
        } catch (e) {
          // Log but continue with other entries
          _log.warning('Error processing metadata entry: $metadataKey', e);
        }
      }
      
      // If already under the limit, do nothing
      if (currentSize <= maxSizeBytes) {
        return 0;
      }
      
      // Sort entries by last access time (oldest first)
      final sortedEntries = entries.entries.toList()
        ..sort((a, b) => a.value.lastAccessTimestamp.compareTo(b.value.lastAccessTimestamp));
      
      int removedCount = 0;
      int freedBytes = 0;
      
      // Remove entries until below size limit
      for (final entry in sortedEntries) {
        if (currentSize <= maxSizeBytes) break;
        
        final dataKey = entry.key;
        final metadata = entry.value;
        
        // Remove data and metadata
        await dataBox.delete(dataKey);
        await metadataBox.delete('$boxName:$dataKey');
        
        freedBytes += metadata.dataSizeBytes;
        currentSize -= metadata.dataSizeBytes;
        removedCount++;
        
        CacheLogger.logCacheEviction(dataKey, boxName, 'Size limit');
      }
      
      CacheLogger.info('Removed $removedCount entries (${_formatSize(freedBytes)}) from $boxName to enforce size limit');
      return removedCount;
    } catch (e, stackTrace) {
      _log.severe('Error enforcing size limit on box: $boxName', e, stackTrace);
      return 0;
    }
  }

  /// Check if a key exists in the cache and is not expired
  Future<bool> exists({
    required String key,
    required String boxName,
  }) async {
    try {
      // Get data
      final dataBox = await _ensureBoxOpen<String>(boxName);
      final serializedData = dataBox.get(key);
      
      if (serializedData == null) {
        return false;
      }
      
      // Get metadata
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final metadataJson = metadataBox.get('$boxName:$key');
      
      if (metadataJson == null) {
        return true; // No metadata, assume valid
      }
      
      // Parse metadata and check expiry
      final metadata = CacheMetadata.fromMap(jsonDecode(metadataJson));
      return !metadata.isExpired;
    } catch (e) {
      _log.warning('Error checking existence of cache entry: $key', e);
      return false;
    }
  }

  /// Get all keys in a box
  Future<List<String>> getAllKeys(String boxName) async {
    try {
      final dataBox = await _ensureBoxOpen<String>(boxName);
      return dataBox.keys.map((key) => key.toString()).toList();
    } catch (e, stackTrace) {
      _log.severe('Error getting all keys from box: $boxName', e, stackTrace);
      return [];
    }
  }

  /// Get the total size of a box in bytes
  Future<int> getBoxSize(String boxName) async {
    try {
      int totalSizeBytes = 0;
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      
      // Find all metadata entries for this box
      final keys = metadataBox.keys.where((key) => key.startsWith('$boxName:'));
      
      for (final key in keys) {
        final metadataJson = metadataBox.get(key);
        if (metadataJson != null) {
          try {
            final metadataMap = jsonDecode(metadataJson) as Map<String, dynamic>;
            final metadata = CacheMetadata.fromMap(metadataMap);
            totalSizeBytes += metadata.dataSizeBytes;
          } catch (e) {
            _log.warning('Error calculating box size for key: $key - $e');
          }
        }
      }
      
      return totalSizeBytes;
    } catch (e, stackTrace) {
      _log.severe('Error calculating box size: $boxName', e, stackTrace);
      return 0;
    }
  }

  /// Update access statistics for a cache entry
  Future<void> _updateAccessStats(
    String key,
    String boxName,
    CacheMetadata metadata,
  ) async {
    try {
      // Create updated metadata
      final updatedMetadata = metadata.incrementAccessCount();
      
      // Store updated metadata
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      await metadataBox.put(
        '$boxName:$key',
        jsonEncode(updatedMetadata.toMap()),
      );
    } catch (e) {
      // Only log, don't propagate error for stat updates
      _log.warning('Error updating access stats for: $key', e);
    }
  }

  /// Format a size in bytes to a human-readable string
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Delete data from cache
  Future<void> delete(String key, String boxName) async {
    _log.info('Attempting to delete item with key: $key from box: $boxName');
    try {
      final box = await _ensureBoxOpen<dynamic>(boxName); // Use <dynamic> as type doesn't matter for delete
      await box.delete(key);
      CacheLogger.info('Successfully deleted item with key: $key from box: $boxName');
    } catch (e, stackTrace) {
      _log.severe('Error deleting data from cache: $key in box $boxName', e, stackTrace);
      rethrow; // Or handle more gracefully
    }
  }
}
