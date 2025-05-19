import 'package:hive_flutter/hive_flutter.dart';

part 'cache_metadata.g.dart';

/// Represents metadata for a cached item
@HiveType(typeId: 0)
class CacheMetadata {
  @HiveField(0)
  final String originalKey;

  @HiveField(1)
  final String boxName;

  @HiveField(2)
  final int timestamp;
  
  @HiveField(3)
  final int ttlMillis;
  
  @HiveField(4)
  final int dataSizeBytes;
  
  @HiveField(5)
  final String? language;
  
  @HiveField(6)
  final String? direction;
  
  @HiveField(7)
  final String source;
  
  @HiveField(8)
  final String? hash;
  
  @HiveField(9)
  int accessCount;
  
  @HiveField(10)
  int lastAccessTimestamp;
  
  @HiveField(11)
  final Map<String, dynamic>? properties;

  CacheMetadata({
    required this.originalKey,
    required this.boxName,
    required this.timestamp,
    int? ttlMillis,
    int? dataSizeBytes,
    this.language,
    this.direction,
    String? source,
    this.hash,
    this.accessCount = 0,
    int? lastAccessTimestamp,
    this.properties,
  }) : 
    ttlMillis = ttlMillis ?? const Duration(days: 7).inMilliseconds,
    dataSizeBytes = dataSizeBytes ?? 0,
    source = source ?? 'network',
    lastAccessTimestamp = lastAccessTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  /// Creates a CacheMetadata instance from a map
  factory CacheMetadata.fromMap(Map<String, dynamic> map) {
    return CacheMetadata(
      originalKey: map['originalKey'] as String? ?? '',
      boxName: map['boxName'] as String? ?? '',
      timestamp: map['timestamp'] as int,
      ttlMillis: map['ttlMillis'] as int?,
      dataSizeBytes: map['dataSizeBytes'] as int?,
      language: map['language'] as String?,
      direction: map['direction'] as String?,
      source: map['source'] as String?,
      hash: map['hash'] as String?,
      accessCount: map['accessCount'] as int? ?? 0,
      lastAccessTimestamp: map['lastAccessTimestamp'] as int?,
      properties: map['properties'] as Map<String, dynamic>?,
    );
  }
  
  /// Converts the metadata to a map
  Map<String, dynamic> toMap() {
    return {
      'originalKey': originalKey,
      'boxName': boxName,
      'timestamp': timestamp,
      'ttlMillis': ttlMillis,
      'dataSizeBytes': dataSizeBytes,
      'language': language,
      'direction': direction,
      'source': source,
      'hash': hash,
      'accessCount': accessCount,
      'lastAccessTimestamp': lastAccessTimestamp,
      'properties': properties,
    };
  }

  /// Check if this cached item is expired
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now > (timestamp + ttlMillis);
  }
  
  /// Check if this cached item is stale based on a custom TTL
  /// This is useful for dynamic TTL policies
  bool isStale(Duration customTtl) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now > (timestamp + customTtl.inMilliseconds);
  }

  /// Get the remaining time-to-live in milliseconds
  int get remainingTtlMillis {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiryTime = timestamp + ttlMillis;
    if (now >= expiryTime) return 0;
    return expiryTime - now;
  }
  
  /// Get the TTL as a Duration object
  Duration get ttl => Duration(milliseconds: ttlMillis);

  /// Get the age of the cache entry in milliseconds
  int get ageMillis {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp;
  }

  /// Create a copy of this metadata with incremented access count
  CacheMetadata incrementAccessCount() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return CacheMetadata(
      originalKey: originalKey,
      boxName: boxName,
      timestamp: timestamp,
      ttlMillis: ttlMillis,
      dataSizeBytes: dataSizeBytes,
      language: language,
      direction: direction,
      source: source,
      hash: hash,
      accessCount: accessCount + 1,
      lastAccessTimestamp: now,
      properties: properties,
    );
  }

  /// Convert to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata.fromMap(json);
  }
}
