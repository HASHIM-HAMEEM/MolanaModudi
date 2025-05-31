import 'package:equatable/equatable.dart';

/// Represents the core data for a book, independent of the data source.
class BookEntity extends Equatable {
  final String id; // Internet Archive identifier
  final String title;
  final String? creator; // Author(s)
  final String? coverUrl; // URL for the cover image
  final String? category; // Derived category (e.g., Tafsir, Fiqh)
  final String? year; // Publication year
  final List<String>? languages; // List of languages (e.g., ['eng', 'urd'])
  final String? language; // Language field for backward compatibility
  final Map<String, dynamic>? metadata; // Additional metadata like OCR quality info

  const BookEntity({
    required this.id,
    required this.title,
    this.creator,
    this.coverUrl,
    this.category,
    this.year,
    this.languages,
    this.language,
    this.metadata,
  });

  /// Creates a copy of this BookEntity with the given fields replaced with the new values.
  BookEntity copyWith({
    String? id,
    String? title,
    String? creator,
    String? coverUrl,
    String? category,
    String? year,
    List<String>? languages,
    String? language,
    Map<String, dynamic>? metadata,
  }) {
    return BookEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      year: year ?? this.year,
      languages: languages ?? this.languages,
      language: language ?? this.language,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, title, creator, coverUrl, category, year, languages, language, metadata];
}
