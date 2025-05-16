import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_data_source.dart';

/// Implementation of SearchRepository
class SearchRepositoryImpl implements SearchRepository {
  final SearchDataSource _dataSource;

  SearchRepositoryImpl(this._dataSource);

  @override
  Future<List<SearchResultEntity>> search(
    String query, {
    List<SearchResultType>? types,
  }) async {
    return _dataSource.search(query, types: types);
  }

  @override
  Future<List<String>> getRecentSearches() {
    return _dataSource.getRecentSearches();
  }

  @override
  Future<void> saveRecentSearch(String query) {
    return _dataSource.saveRecentSearch(query);
  }

  @override
  Future<void> clearRecentSearches() {
    return _dataSource.clearRecentSearches();
  }
}
