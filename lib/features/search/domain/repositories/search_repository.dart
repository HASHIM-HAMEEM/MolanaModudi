import '../entities/search_result_entity.dart';

/// Repository interface for search functionality
abstract class SearchRepository {
  /// Search across all content types (books, chapters, videos)
  /// 
  /// [query] - The search query string
  /// [types] - Optional list of result types to filter by
  /// 
  /// Returns a list of search results matching the query
  Future<List<SearchResultEntity>> search(
    String query, {
    List<SearchResultType>? types,
  });

  /// Get recent searches performed by the user
  /// 
  /// Returns a list of recent search queries
  Future<List<String>> getRecentSearches();

  /// Save a search query to recent searches
  /// 
  /// [query] - The search query to save
  Future<void> saveRecentSearch(String query);

  /// Clear all recent searches
  Future<void> clearRecentSearches();
}
