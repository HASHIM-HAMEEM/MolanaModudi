/// Represents the priority of cached content for retention policies
enum CachePriorityLevel {
  /// High priority, retained even when cache space is low
  high,
  
  /// Medium priority, retained under normal conditions
  medium,
  
  /// Low priority, first to be evicted when cache space is needed
  low
}

/// Cache priority information for books
class CachePriority {
  /// The priority level assigned to this item
  final CachePriorityLevel level;
  
  /// Last access timestamp
  final int lastAccessTimestamp;
  
  /// Number of times this item has been accessed
  final int accessCount;
  
  /// Book ID this priority applies to
  final String bookId;
  
  /// Create a new cache priority item
  CachePriority({
    required this.bookId,
    required this.level,
    required this.lastAccessTimestamp,
    this.accessCount = 1,
  });
  
  /// Create a copy with updated values
  CachePriority copyWith({
    CachePriorityLevel? level,
    int? lastAccessTimestamp,
    int? accessCount,
  }) {
    return CachePriority(
      bookId: bookId,
      level: level ?? this.level,
      lastAccessTimestamp: lastAccessTimestamp ?? this.lastAccessTimestamp,
      accessCount: accessCount ?? this.accessCount,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'level': level.toString().split('.').last,
      'lastAccessTimestamp': lastAccessTimestamp,
      'accessCount': accessCount,
    };
  }
  
  /// Create from JSON
factory CachePriority.fromJson(Map<String, dynamic> json) {
  CachePriorityLevel level;
 final String levelStr = json['level'] as String? ?? 'low';
 switch (levelStr) {
    case 'high':
      level = CachePriorityLevel.high;
      break;
    case 'medium':
      level = CachePriorityLevel.medium;
      break;
   case 'low':
     level = CachePriorityLevel.low;
     break;
    default:
     // Log unexpected value but default to low
     print('Warning: Unknown cache priority level: $levelStr, defaulting to low');
     level = CachePriorityLevel.low;
  }
  
 // Ensure bookId is present
 if (json['bookId'] == null) {
   throw ArgumentError('bookId is required in CachePriority.fromJson');
 }

  return CachePriority(
    bookId: json['bookId'],
    level: level,
    lastAccessTimestamp: json['lastAccessTimestamp'],
    accessCount: json['accessCount'] ?? 1,
  );
}
  
  /// Create a new high-priority item
  static CachePriority createHigh(String bookId) {
    return CachePriority(
      bookId: bookId,
      level: CachePriorityLevel.high,
      lastAccessTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Create a new medium-priority item
  static CachePriority createMedium(String bookId) {
    return CachePriority(
      bookId: bookId,
      level: CachePriorityLevel.medium,
      lastAccessTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// Create a new low-priority item
  static CachePriority createLow(String bookId) {
    return CachePriority(
      bookId: bookId,
      level: CachePriorityLevel.low,
      lastAccessTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
