class SimpleBookmark {
  final String id;
  final String bookId;
  final String chapterId;
  final String chapterTitle;
  final String? headingId; // Optional for sub-chapters
  final String? headingTitle; // Optional for sub-chapters
  final DateTime timestamp;

  SimpleBookmark({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterTitle,
    this.headingId,
    this.headingTitle,
    required this.timestamp,
  });

  // Simple display name
  String get displayName {
    if (headingTitle != null && headingTitle!.isNotEmpty) {
      return headingTitle!; // Show sub-chapter title if available
    }
    return chapterTitle; // Otherwise show chapter title
  }

  // Check if this is a sub-chapter bookmark
  bool get isSubChapter => headingId != null;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'headingId': headingId,
      'headingTitle': headingTitle,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory SimpleBookmark.fromJson(Map<String, dynamic> map) {
    return SimpleBookmark(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      chapterId: map['chapterId'] as String,
      chapterTitle: map['chapterTitle'] as String,
      headingId: map['headingId'] as String?,
      headingTitle: map['headingTitle'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
  
  /// Create a unique key for this bookmark
  String get uniqueKey {
    if (headingId != null) {
      return '${bookId}_${chapterId}_$headingId';
    }
    return '${bookId}_$chapterId';
  }
}
