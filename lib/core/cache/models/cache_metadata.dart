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

  @HiveField(12) // New field for pinning
  final bool isPinned;

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
    this.isPinned = false, // Initialize isPinned
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
      isPinned: map['isPinned'] as bool? ?? false, // Add isPinned to fromMap
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
      'isPinned': isPinned, // Add isPinned to toMap
    };
  }

  /// Check if this cached item is expired
  bool get isExpired {
    if (isPinned) return false; // Pinned items are never considered expired by TTL
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

  /// Create a copy of this metadata with new values
  CacheMetadata copyWith({
    String? originalKey,
    String? boxName,
    int? timestamp,
    int? ttlMillis,
    int? dataSizeBytes,
    String? language,
    String? direction,
    String? source,
    String? hash,
    int? accessCount,
    int? lastAccessTimestamp,
    Map<String, dynamic>? properties,
    bool? isPinned,
  }) {
    return CacheMetadata(
      originalKey: originalKey ?? this.originalKey,
      boxName: boxName ?? this.boxName,
      timestamp: timestamp ?? this.timestamp,
      ttlMillis: ttlMillis ?? this.ttlMillis,
      dataSizeBytes: dataSizeBytes ?? this.dataSizeBytes,
      language: language ?? this.language,
      direction: direction ?? this.direction,
      source: source ?? this.source,
      hash: hash ?? this.hash,
      accessCount: accessCount ?? this.accessCount,
      lastAccessTimestamp: lastAccessTimestamp ?? this.lastAccessTimestamp,
      properties: properties ?? this.properties,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Create a copy of this metadata with incremented access count
  CacheMetadata incrementAccessCount() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return copyWith( // Use copyWith
      accessCount: accessCount + 1,
      lastAccessTimestamp: now,
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
