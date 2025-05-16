import 'package:flutter/foundation.dart';

import '../../domain/entities/search_result_entity.dart';

/// Enum representing the status of a search operation
enum SearchStatus {
  initial,
  loading,
  success,
  error,
}

/// State class for search functionality
@immutable
class SearchState {
  final String query;
  final List<SearchResultEntity> results;
  final List<String> recentSearches;
  final List<SearchResultType> activeFilters;
  final SearchStatus status;
  final String? errorMessage;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.recentSearches = const [],
    this.activeFilters = const [],
    this.status = SearchStatus.initial,
    this.errorMessage,
  });

  /// Create a copy of this state with the given fields replaced
  SearchState copyWith({
    String? query,
    List<SearchResultEntity>? results,
    List<String>? recentSearches,
    List<SearchResultType>? activeFilters,
    SearchStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      activeFilters: activeFilters ?? this.activeFilters,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  /// Get filtered results based on active filters
  List<SearchResultEntity> get filteredResults {
    if (activeFilters.isEmpty) {
      return results;
    }
    return results.where((result) => activeFilters.contains(result.type)).toList();
  }

  /// Check if there are any results after filtering
  bool get hasResults => filteredResults.isNotEmpty;

  /// Check if the search is in progress
  bool get isSearching => status == SearchStatus.loading;

  /// Check if there was an error during search
  bool get hasError => status == SearchStatus.error && errorMessage != null;

  /// Check if this is the initial state (no search performed yet)
  bool get isInitial => status == SearchStatus.initial;

  /// Get the count of each result type
  Map<SearchResultType, int> get resultTypeCounts {
    final counts = <SearchResultType, int>{};
    for (final type in SearchResultType.values) {
      counts[type] = results.where((result) => result.type == type).length;
    }
    return counts;
  }
}
