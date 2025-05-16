import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/search_result_entity.dart';
import '../../domain/usecases/search_use_case.dart';
import '../../di/search_module.dart';
import 'search_state.dart';

/// StateNotifier for managing search state
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchUseCase _searchUseCase;

  SearchNotifier(this._searchUseCase) : super(const SearchState()) {
    _loadRecentSearches();
  }

  /// Load recent searches when the notifier is created
  Future<void> _loadRecentSearches() async {
    try {
      final recentSearches = await _searchUseCase.getRecentSearches();
      state = state.copyWith(recentSearches: recentSearches);
    } catch (e) {
      // Silently fail if we can't load recent searches
    }
  }

  /// Perform a search with the given query
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    // Update state to show loading
    state = state.copyWith(
      query: query,
      status: SearchStatus.loading,
      clearError: true,
    );

    try {
      // Perform the search
      final results = await _searchUseCase.execute(
        query,
        types: state.activeFilters.isEmpty ? null : state.activeFilters,
      );

      // Update recent searches
      final recentSearches = await _searchUseCase.getRecentSearches();

      // Update state with results
      state = state.copyWith(
        results: results,
        recentSearches: recentSearches,
        status: SearchStatus.success,
      );
    } catch (e) {
      // Update state with error
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: 'Failed to perform search: ${e.toString()}',
      );
    }
  }

  /// Toggle a filter for search results
  void toggleFilter(SearchResultType type) {
    final activeFilters = List<SearchResultType>.from(state.activeFilters);
    
    if (activeFilters.contains(type)) {
      activeFilters.remove(type);
    } else {
      activeFilters.add(type);
    }
    
    state = state.copyWith(activeFilters: activeFilters);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(activeFilters: []);
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    try {
      await _searchUseCase.clearRecentSearches();
      state = state.copyWith(recentSearches: []);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to clear recent searches: ${e.toString()}',
      );
    }
  }

  /// Select a recent search
  void selectRecentSearch(String query) {
    search(query);
  }
}

/// Provider for the search state
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchUseCase = ref.watch(searchUseCaseProvider);
  return SearchNotifier(searchUseCase);
});
