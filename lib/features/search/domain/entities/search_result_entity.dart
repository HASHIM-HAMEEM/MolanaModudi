/// Enum representing the type of search result
enum SearchResultType {
  book,
  chapter,
  video,
  biography,
}

/// Entity representing a search result from any source
class SearchResultEntity {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final SearchResultType type;
  final String? parentId; // For chapters, this is the book ID
  final Map<String, dynamic>? metadata; // Additional data specific to result type

  const SearchResultEntity({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.type,
    this.parentId,
    this.metadata,
  });

  /// Returns the route path for this search result
  String getRoutePath() {
    switch (type) {
      case SearchResultType.book:
        return '/books/$id';
      case SearchResultType.chapter:
        // If we have a parent book ID, navigate to the specific chapter
        if (parentId != null) {
          final chapterId = metadata?['chapterId'] ?? id;
          return '/read/$parentId?chapter=$chapterId';
        }
        return '/books/$id';
      case SearchResultType.video:
        return '/videos/play/$id';
      case SearchResultType.biography:
        return '/biography';
      default:
        return '/home';
    }
  }

  /// Returns the icon data key for this search result type
  String get iconKey {
    switch (type) {
      case SearchResultType.book:
        return 'book';
      case SearchResultType.chapter:
        return 'bookmark';
      case SearchResultType.video:
        return 'video_library';
      case SearchResultType.biography:
        return 'history_edu';
      default:
        return 'search';
    }
  }
}
