import 'package:cloud_firestore/cloud_firestore.dart';

class Bookmark {
  final String id;
  final String bookId;
  final String chapterId; // Corresponds to mainChapterKeys entry
  final String chapterTitle;
  final String headingId; // Corresponds to heading.firestoreDocId
  final String headingTitle;
  final Timestamp timestamp;
  final String? textContentSnippet;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterTitle,
    required this.headingId,
    required this.headingTitle,
    required this.timestamp,
    this.textContentSnippet,
  });

  //copyWith method
  Bookmark copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    String? chapterTitle,
    String? headingId,
    String? headingTitle,
    Timestamp? timestamp,
    String? textContentSnippet,
  }) {
    return Bookmark(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      headingId: headingId ?? this.headingId,
      headingTitle: headingTitle ?? this.headingTitle,
      timestamp: timestamp ?? this.timestamp,
      textContentSnippet: textContentSnippet ?? this.textContentSnippet,
    );
  }

  /// Convert to JSON compatible Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'headingId': headingId,
      'headingTitle': headingTitle,
      'timestamp': timestamp,
      'textContentSnippet': textContentSnippet,
    };
  }
  
  /// Alias for toJson to maintain backward compatibility
  Map<String, dynamic> toMap() => toJson();

  /// Create from a map that already contains the 'id' field
  factory Bookmark.fromJson(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      chapterId: map['chapterId'] as String,
      chapterTitle: map['chapterTitle'] as String,
      headingId: map['headingId'] as String,
      headingTitle: map['headingTitle'] as String,
      timestamp: map['timestamp'] as Timestamp,
      textContentSnippet: map['textContentSnippet'] as String?,
    );
  }
  
  /// Traditional fromMap method that takes separate id and map parameters
  factory Bookmark.fromMap(String id, Map<String, dynamic> map) {
    return Bookmark(
      id: id,
      bookId: map['bookId'] as String,
      chapterId: map['chapterId'] as String,
      chapterTitle: map['chapterTitle'] as String,
      headingId: map['headingId'] as String,
      headingTitle: map['headingTitle'] as String,
      timestamp: map['timestamp'] as Timestamp,
      textContentSnippet: map['textContentSnippet'] as String?,
    );
  }
}
