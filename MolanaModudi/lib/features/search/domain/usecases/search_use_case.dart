import '../entities/search_result_entity.dart';
import '../repositories/search_repository.dart';

/// Use case for searching content across the app
class SearchUseCase {
  final SearchRepository _repository;

  SearchUseCase(this._repository);

  /// Search for content matching the query
  /// 
  /// [query] - The search query string
  /// [types] - Optional list of result types to filter by
  Future<List<SearchResultEntity>> execute(
    String query, {
    List<SearchResultType>? types,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    // Save the search query to recent searches
    await _repository.saveRecentSearch(query);
    
    // Perform the search
    return _repository.search(query, types: types);
  }

  /// Get recent searches
  Future<List<String>> getRecentSearches() {
    return _repository.getRecentSearches();
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() {
    return _repository.clearRecentSearches();
  }
}
