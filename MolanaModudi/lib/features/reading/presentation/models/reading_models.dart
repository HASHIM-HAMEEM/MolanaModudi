import 'package:equatable/equatable.dart';

/// Placeholder model for chapter data.
/// Should be replaced with actual Chapter entity later.
class PlaceholderChapter extends Equatable {
  final String id;
  final String title;
  final int pageStart;
  final String? subtitle;
  
  const PlaceholderChapter({
     required this.id,
     required this.title,
     required this.pageStart,
     this.subtitle,
   });

  @override
  List<Object?> get props => [id, title, pageStart, subtitle];
}

/// Placeholder model for the book being read.
/// Should be replaced with actual Book entity/data later.
class PlaceholderReadingBook extends Equatable {
  final String id;
  final String title;
  final String author;
  final int currentPage;
  final int totalPages;
  final double progress;
  final List<PlaceholderChapter> chapters;

  const PlaceholderReadingBook({
    required this.id,
    required this.title,
    required this.author,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.chapters,
  });
  
  @override
  List<Object?> get props => [
    id, 
    title, 
    author, 
    currentPage, 
    totalPages, 
    progress, 
    chapters
  ];

  PlaceholderReadingBook copyWith({
    String? id,
    String? title,
    String? author,
    int? currentPage,
    int? totalPages,
    double? progress,
    List<PlaceholderChapter>? chapters,
  }) {
    return PlaceholderReadingBook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      progress: progress ?? this.progress,
      chapters: chapters ?? this.chapters,
    );
  }
}

// Model for reading progress tracking
class ReadingProgress {
  final String bookId;
  final int currentPage;
  final int totalPages;
  final double progressPercentage;
  final DateTime lastReadTime;

  ReadingProgress({
    required this.bookId,
    required this.currentPage,
    required this.totalPages,
    required this.progressPercentage,
    required this.lastReadTime,
  });
}

// Model for bookmarks
class Bookmark {
  final String id;
  final String bookId;
  final int pageNumber;
  final String? note;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    this.note,
    required this.createdAt,
  });
} 