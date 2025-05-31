import '../../domain/entities/search_result_entity.dart';

/// Data model for search results
class SearchResultModel extends SearchResultEntity {
  const SearchResultModel({
    required super.id,
    required super.title,
    super.subtitle,
    super.description,
    super.imageUrl,
    required super.type,
    super.parentId,
    super.metadata,
  });

  /// Create a book search result
  factory SearchResultModel.fromBook(Map<String, dynamic> book) {
    return SearchResultModel(
      id: book['id'],
      title: book['title'],
      subtitle: book['author'],
      description: book['description'],
      imageUrl: book['coverUrl'],
      type: SearchResultType.book,
      metadata: {
        'totalChapters': book['totalChapters'],
      },
    );
  }

  /// Create a chapter search result
  factory SearchResultModel.fromChapter(
    Map<String, dynamic> chapter,
    String bookId,
    String bookTitle,
  ) {
    return SearchResultModel(
      id: chapter['id'],
      title: chapter['title'],
      subtitle: 'From: $bookTitle',
      description: chapter['preview'] ?? '',
      type: SearchResultType.chapter,
      parentId: bookId,
      metadata: {
        'chapterId': chapter['id'],
        'chapterNumber': chapter['chapterNumber'],
        'bookTitle': bookTitle,
      },
    );
  }

  /// Create a video search result
  factory SearchResultModel.fromVideo(Map<String, dynamic> video) {
    return SearchResultModel(
      id: video['id'],
      title: video['title'],
      subtitle: video['duration'],
      description: video['description'],
      imageUrl: video['thumbnailUrl'],
      type: SearchResultType.video,
      metadata: {
        'playlistId': video['playlistId'],
        'playlistName': video['playlistName'],
        'duration': video['duration'],
      },
    );
  }

  /// Create a biography event search result
  factory SearchResultModel.fromBiographyEvent(Map<String, dynamic> event) {
    return SearchResultModel(
      id: event['id'] ?? 'biography',
      title: event['title'],
      subtitle: event['date'],
      description: event['description'],
      type: SearchResultType.biography,
    );
  }

  /// Convert model to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.toString(),
      'parentId': parentId,
      'metadata': metadata,
    };
  }

  /// Create model from a map
  factory SearchResultModel.fromMap(Map<String, dynamic> map) {
    return SearchResultModel(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      type: _typeFromString(map['type']),
      parentId: map['parentId'],
      metadata: map['metadata'],
    );
  }

  /// Convert string to SearchResultType
  static SearchResultType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'SearchResultType.book':
        return SearchResultType.book;
      case 'SearchResultType.chapter':
        return SearchResultType.chapter;
      case 'SearchResultType.video':
        return SearchResultType.video;
      case 'SearchResultType.biography':
        return SearchResultType.biography;
      default:
        return SearchResultType.book;
    }
  }
}
