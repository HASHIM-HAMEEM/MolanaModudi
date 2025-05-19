import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'cache_metadata.dart';

/// Represents a cache entry with both data and metadata
class CacheEntry<T> {
  /// The cached data
  final T data;
  
  /// Metadata about the cache entry
  final CacheMetadata metadata;
  
  /// Creates a new CacheEntry instance
  const CacheEntry({
    required this.data,
    required this.metadata,
  });
  
  /// Create a new cache entry with the current timestamp
  factory CacheEntry.create({
    required T data,
    required String originalKey,
    required String boxName,
    required int dataSizeBytes,
    required Duration ttl,
    String? language,
    String? hash,
    Map<String, dynamic>? properties,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Determine direction based on language
    String? direction;
    if (language != null) {
      // Set RTL for languages like Urdu, Arabic, Hebrew
      if (['ur', 'ar', 'he', 'fa', 'ku', 'ps', 'sd', 'yi'].contains(language)) {
        direction = 'rtl';
      } else {
        direction = 'ltr';
      }
    }
    
    return CacheEntry(
      data: data,
      metadata: CacheMetadata(
        originalKey: originalKey,
        boxName: boxName,
        timestamp: timestamp,
        ttlMillis: ttl.inMilliseconds,
        dataSizeBytes: dataSizeBytes,
        language: language,
        direction: direction,
        source: 'network',
        hash: hash,
        accessCount: 0,
        properties: properties,
      ),
    );
  }
  
  /// Create a new cache entry by incrementing the access count of an existing entry
  CacheEntry<T> incrementAccessCount() {
    return CacheEntry<T>(
      data: data,
      metadata: metadata.incrementAccessCount(),
    );
  }
  
  /// Check if this cache entry is expired
  bool get isExpired => metadata.isExpired;
  
  /// Generate a hash of the data for integrity checking
  /// Uses MD5 for performance, which is sufficient for cache integrity verification
  static String? generateHash(dynamic data) {
    if (data == null) return null;
    
    try {
      final String jsonData = jsonEncode(data);
      final bytes = utf8.encode(jsonData);
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      // If the data can't be encoded to JSON, return null
      return null;
    }
  }
  
  /// Estimate the size of a data object in bytes
  static int estimateDataSize(dynamic data) {
    if (data == null) return 0;
    
    try {
      final String jsonData = jsonEncode(data);
      return utf8.encode(jsonData).length;
    } catch (e) {
      // If the data can't be encoded to JSON, return a default size
      return 100;
    }
  }
}
