import 'package:equatable/equatable.dart';

// Represents a chapter within a book
class ChapterEntity extends Equatable {
  final String id; // May not be directly available, could be generated or use title
  final String title;
  final int? pageStart; // Page number if available
  final int? pages;     // Number of pages if available

  const ChapterEntity({
    required this.id,
    required this.title,
    this.pageStart,
    this.pages,
  });

  @override
  List<Object?> get props => [id, title, pageStart, pages];
}

// Represents detailed information for a single book
class BookDetailEntity extends Equatable {
  final String id;
  final String title;
  final String? author; // Use creator field from API
  final String? coverUrl; // Generated from identifier
  final List<String>? categories; // Derived or from subject field?
  final double? rating; // Not directly from API, maybe calculated or placeholder
  final int? reviewCount; // Not directly from API
  final String? description;
  final String? language; // From language field
  final String? publishYear; // From date field
  final int? pages; // Not directly from API, maybe from metadata?
  final List<String>? format; // From format field
  final List<ChapterEntity>? chapters; // May need separate fetching or parsing
  // final List<RelatedBookEntity>? relatedBooks; // Would need separate logic/API call
  final String? publisher;
  final List<String>? subjects; // From API subject field
  final String? publicDate; // From API publicdate field
  final int? downloads; // From API downloads field
  final String? collection; // From API collection field

  const BookDetailEntity({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.categories,
    this.rating,
    this.reviewCount,
    this.description,
    this.language,
    this.publishYear,
    this.pages,
    this.format,
    this.chapters,
    this.publisher,
    this.subjects,
    this.publicDate,
    this.downloads,
    this.collection,
    // this.relatedBooks,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        coverUrl,
        categories,
        rating,
        reviewCount,
        description,
        language,
        publishYear,
        pages,
        format,
        chapters,
        publisher,
        subjects,
        publicDate,
        downloads,
        collection,
        // relatedBooks,
      ];
} 