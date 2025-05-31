import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/search_result_entity.dart';
import '../../domain/usecases/search_use_case.dart';
import '../../di/search_module.dart';
import 'search_state.dart';

/// StateNotifier for managing search state
class SearchNotifier extends StateNotifier<SearchState> {
  final AsyncValue<SearchUseCase> _searchUseCaseAsyncValue;

  SearchNotifier(this._searchUseCaseAsyncValue) : super(const SearchState()) {
    _loadRecentSearches();
  }

  /// Load recent searches when the notifier is created
  Future<void> _loadRecentSearches() async {
    if (!_searchUseCaseAsyncValue.hasValue) {
      // If use case is not ready (still loading or has error), don't attempt to load recent searches.
      // The error state for use case loading will be handled elsewhere or reflected by initial empty recent searches.
      if (_searchUseCaseAsyncValue.hasError && mounted) {
         // Optionally, reflect this error in the SearchState if desired
         // state = state.copyWith(status: SearchStatus.error, errorMessage: 'Failed to load search service.');
      }
      return;
    }
    final SearchUseCase useCase = _searchUseCaseAsyncValue.value!;
    try {
      final recentSearches = await useCase.getRecentSearches();
      if (mounted) state = state.copyWith(recentSearches: recentSearches);
    } catch (e) {
      // Silently fail if we can't load recent searches
      // Optionally log e here
    }
  }

  /// Perform a search with the given query
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    if (mounted) {
      state = state.copyWith(
        query: query,
        status: SearchStatus.loading,
        clearError: true,
      );
    }

    if (!_searchUseCaseAsyncValue.hasValue) {
      if (mounted) {
        final error = _searchUseCaseAsyncValue.error ?? 'Search service not available';
        // final stackTrace = _searchUseCaseAsyncValue.stackTrace ?? StackTrace.current; // Removed unused variable
        state = state.copyWith(
          status: SearchStatus.error,
          errorMessage: 'Failed to perform search: $error',
        );
      }
      return;
    }
    final SearchUseCase useCase = _searchUseCaseAsyncValue.value!;

    try {
      // Perform the search
      final results = await useCase.execute(
        query,
        types: state.activeFilters.isEmpty ? null : state.activeFilters,
      );

      // Update recent searches
      final recentSearches = await useCase.getRecentSearches();

      // Update state with results
      if (mounted) {
        state = state.copyWith(
          results: results,
          recentSearches: recentSearches,
          status: SearchStatus.success,
        );
      }
    } catch (e) { // Removed unused 'st'
      // Update state with error
      if (mounted) {
        state = state.copyWith(
          status: SearchStatus.error,
          errorMessage: 'Failed to perform search: ${e.toString()}',
        );
      }
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
    if (!_searchUseCaseAsyncValue.hasValue) {
      if (mounted) {
        final error = _searchUseCaseAsyncValue.error ?? 'Search service not available';
        // final stackTrace = _searchUseCaseAsyncValue.stackTrace ?? StackTrace.current; // Removed unused variable
        state = state.copyWith(
          status: SearchStatus.error, // Assuming SearchState has a status for this
          errorMessage: 'Failed to clear recent searches: $error',
        );
      }
      return;
    }
    final SearchUseCase useCase = _searchUseCaseAsyncValue.value!;

    try {
      await useCase.clearRecentSearches();
      if (mounted) state = state.copyWith(recentSearches: []);
    } catch (e) { // Removed unused 'st'
      if (mounted) {
        state = state.copyWith(
          errorMessage: 'Failed to clear recent searches: ${e.toString()}',
        );
      }
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
