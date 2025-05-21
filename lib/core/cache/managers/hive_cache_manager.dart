import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/cache/models/cache_metadata.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import '../utils/cache_logger.dart';
import '../utils/cache_utils.dart';
import '../utils/concurrency_utils.dart';

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
  
  // Add lock for concurrent box operations
  final Lock _boxLock = Lock();

  /// Initialize Hive and open necessary boxes
  Future<void> initialize() async {
    return await _boxLock.synchronized(() async {
      if (_initialized) return;
      
      try {
        // Initialize metadata box - we'll use String type to store JSON serialized data
        // This avoids issues with CacheMetadata adapter registration
        if (!Hive.isBoxOpen(_metadataBoxName)) {
          await Hive.openBox<String>(_metadataBoxName);
        }
        
        _initialized = true;
        CacheLogger.info('HiveCacheManager initialized successfully');
      } catch (e, stackTrace) {
        _log.severe('Error initializing HiveCacheManager', e, stackTrace);
        rethrow;
      }
    });
  }

  /// Ensure the box is open, opening it if necessary
  /// Uses proper type synchronization to avoid "box already open" errors
  Future<Box<T>> _ensureBoxOpen<T>(String boxName) async {
    return await _boxLock.synchronized(() async {
      if (!_initialized) {
        await initialize();
      }
  
      if (!Hive.isBoxOpen(boxName)) {
        try {
          return await Hive.openBox<T>(boxName);
        } catch (e) {
          if (e.toString().contains('already open')) {
            // Box was opened by another concurrent call
            // This is safe to handle by just getting the existing box
            return Hive.box<T>(boxName);
          } else {
            rethrow;
          }
        }
      } else {
        return Hive.box<T>(boxName);
      }
    });
  }

  /// Generate hash for data integrity checks
  String? _generateHash(dynamic data) {
    if (data == null) return null;
    try {
      String stringData;
      if (data is String) {
        stringData = data;
      } else if (data is Map || data is List) {
        stringData = jsonEncode(data);
      } else {
        stringData = data.toString();
      }
      return crypto.md5.convert(utf8.encode(stringData)).toString();
    } catch (e) {
      _log.warning('Error generating hash: $e');
      return null;
    }
  }

  /// Convert data for serialization
  dynamic _convertForSerialization(dynamic data) {
    if (data == null) return null;
    
    if (data is Map) {
      return _convertMapForSerialization(data);
    } else if (data is List) {
      return _convertListForSerialization(data);
    } else {
      return data;
    }
  }

  /// Convert Map for serialization
  Map<String, dynamic> _convertMapForSerialization(Map data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _convertMapForSerialization(value);
      } else if (value is List) {
        result[key.toString()] = _convertListForSerialization(value);
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  /// Convert List for serialization
  List<dynamic> _convertListForSerialization(List data) {
    return data.map((item) {
      if (item is Map) {
        return _convertMapForSerialization(item);
      } else if (item is List) {
        return _convertListForSerialization(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Serialize data to string format for storage
  String _serializeData<T>(T data) {
    if (data == null) {
      return '';
    }
    
    // Handle String type
    if (data is String) {
      return data;
    }
    
    // Handle Map and List types
    if (data is Map || data is List) {
      try {
        // Convert Map or List to JSON
        return jsonEncode(_convertForSerialization(data));
      } catch (e) {
        _log.warning('Error serializing data to JSON: $e');
        // Fallback to toString if JSON encoding fails
        return data.toString();
      }
    }
    
    // Handle everything else by toString
    return data.toString();
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
      if (T == String) {
        return serializedData as T;
      }
      _log.warning('Error deserializing data: $e');
      return null;
    }
  }

  /// Update access statistics for a cached item
  Future<void> _updateAccessStats(String key, String boxName, CacheMetadata metadata) async {
    try {
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final updatedMetadata = metadata.copyWith(
        accessCount: metadata.accessCount + 1,
        lastAccessTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await metadataBox.put('$boxName:$key', jsonEncode(updatedMetadata.toMap()));
    } catch (e) {
      _log.warning('Error updating access stats: $e');
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
      final String? metadataJson = metadataBox.get('$boxName:$key');
      
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

  /// Check if key exists in box
  Future<bool> exists({required String key, required String boxName}) async {
    try {
      final box = await _ensureBoxOpen<String>(boxName);
      return box.containsKey(key);
    } catch (e) {
      _log.warning('Error checking if key exists: $key in $boxName: $e');
      return false;
    }
  }

  /// Delete a key from a box
  Future<void> delete(String key, String boxName) async {
    try {
      final box = await _ensureBoxOpen<String>(boxName);
      await box.delete(key);
      
      // Also delete metadata
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      await metadataBox.delete('$boxName:$key');
      
      CacheLogger.info('Deleted key from cache: $key from $boxName');
    } catch (e) {
      _log.warning('Error deleting key from cache: $key from $boxName: $e');
    }
  }

  /// Clear all data from a box
  Future<void> clearBox(String boxName) async {
    try {
      final box = await _ensureBoxOpen<String>(boxName);
      await box.clear();
      
      // Also clear metadata for this box
      final metadataBox = await _ensureBoxOpen<String>(_metadataBoxName);
      final keysToDelete = metadataBox.keys
          .where((key) => (key as String).startsWith('$boxName:'))
          .toList();
      
      for (final key in keysToDelete) {
        await metadataBox.delete(key);
      }
      
      CacheLogger.info('Cleared box: $boxName');
    } catch (e) {
      _log.warning('Error clearing box: $boxName: $e');
    }
  }

  /// Get all keys in a box
  Future<List<String>> getAllKeys(String boxName) async {
    try {
      final box = await _ensureBoxOpen<String>(boxName);
      return box.keys.map((key) => key.toString()).toList();
    } catch (e) {
      _log.warning('Error getting all keys from box: $boxName: $e');
      return [];
    }
  }

  /// Get the size of a box in bytes
  Future<int> getBoxSize(String boxName) async {
    try {
      final box = await _ensureBoxOpen<String>(boxName);
      int totalSize = 0;
      
      for (final key in box.keys) {
        final value = box.get(key);
        if (value != null) {
          totalSize += CacheUtils.calculateStringSize(key.toString());
          totalSize += CacheUtils.calculateStringSize(value);
        }
      }
      
      return totalSize;
    } catch (e) {
      _log.warning('Error calculating box size: $boxName: $e');
      return 0;
    }
  }

  /// Format size in human-readable format
  String _formatSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Check if system is in a low memory situation
  bool isLowMemorySituation() {
    // This is a simplified implementation
    // In a real app, you might check platform-specific memory usage
    // or use a more advanced heuristic
    return false;
  }
}
