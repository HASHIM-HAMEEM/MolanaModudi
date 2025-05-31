import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../services/unified_search_service.dart';
import 'providers.dart';

/// Search state enum
enum SearchStatus {
  initial,
  loading,
  success,
  error,
}

/// Minimalistic search state
class UnifiedSearchState {
  final SearchResults? results;
  final SearchStatus status;
  final String query;
  final SearchContext context;
  final String? errorMessage;
  final List<String> recentSearches;
  final List<String> suggestions;
  final bool isShowingSuggestions;

  const UnifiedSearchState({
    this.results,
    this.status = SearchStatus.initial,
    this.query = '',
    this.context = SearchContext.global,
    this.errorMessage,
    this.recentSearches = const [],
    this.suggestions = const [],
    this.isShowingSuggestions = false,
  });

  UnifiedSearchState copyWith({
    SearchResults? results,
    SearchStatus? status,
    String? query,
    SearchContext? context,
    String? errorMessage,
    List<String>? recentSearches,
    List<String>? suggestions,
    bool? isShowingSuggestions,
    bool clearError = false,
  }) {
    return UnifiedSearchState(
      results: results ?? this.results,
      status: status ?? this.status,
      query: query ?? this.query,
      context: context ?? this.context,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      recentSearches: recentSearches ?? this.recentSearches,
      suggestions: suggestions ?? this.suggestions,
      isShowingSuggestions: isShowingSuggestions ?? this.isShowingSuggestions,
    );
  }

  /// Convenience getters
  bool get isLoading => status == SearchStatus.loading;
  bool get hasError => status == SearchStatus.error;
  bool get hasResults => results != null && results!.hasResults;
  bool get isEmpty => results == null || !results!.hasResults;
  bool get isInitial => status == SearchStatus.initial;
}

/// Unified Search Notifier - Clean and efficient
class UnifiedSearchNotifier extends StateNotifier<UnifiedSearchState> {
  final Logger _log = Logger('UnifiedSearchNotifier');
  Timer? _debounceTimer;
  Timer? _suggestionTimer;

  UnifiedSearchNotifier(SearchContext context) : super(UnifiedSearchState(context: context)) {
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  /// Load initial data (recent searches)
  Future<void> _loadInitialData() async {
    try {
      final recentSearches = unifiedSearchService.getRecentSearches(state.context);
      if (mounted) {
        state = state.copyWith(recentSearches: recentSearches);
      }
    } catch (e) {
      _log.warning('Error loading initial data: $e');
    }
  }

  /// Main search method with debouncing
  void search(String query, {bool immediate = false}) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    // Update query immediately for responsive UI
    if (mounted) {
      state = state.copyWith(
        query: query,
        isShowingSuggestions: false,
        clearError: true,
      );
    }

    // Handle empty query
    if (query.trim().isEmpty) {
      if (mounted) {
        state = state.copyWith(
          status: SearchStatus.initial,
          results: null,
          recentSearches: unifiedSearchService.getRecentSearches(state.context),
        );
      }
      return;
    }

    // Debounce the actual search
    final delay = immediate ? Duration.zero : const Duration(milliseconds: 300);
    _debounceTimer = Timer(delay, () => _performSearch(query));
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    if (!mounted || query.trim().isEmpty) return;

    try {
      // Set loading state
      state = state.copyWith(status: SearchStatus.loading);

      // Perform search
      final results = await unifiedSearchService.search(
        query: query.trim(),
        context: state.context,
        limit: 20,
      );

      // Update state with results
      if (mounted) {
        state = state.copyWith(
          status: SearchStatus.success,
          results: results,
          recentSearches: unifiedSearchService.getRecentSearches(state.context),
        );
      }

      _log.info('Search completed: ${results.totalCount} results for "$query"');
    } catch (e, stackTrace) {
      _log.severe('Search error: $e', e, stackTrace);
      if (mounted) {
        state = state.copyWith(
          status: SearchStatus.error,
          errorMessage: 'Search failed. Please try again.',
        );
      }
    }
  }

  /// Get search suggestions with debouncing
  void getSuggestions(String partialQuery) {
    _suggestionTimer?.cancel();

    if (partialQuery.trim().isEmpty) {
      if (mounted) {
        state = state.copyWith(
          suggestions: [],
          isShowingSuggestions: false,
        );
      }
      return;
    }

    // Show suggestions immediately for better UX
    if (mounted) {
      state = state.copyWith(isShowingSuggestions: true);
    }

    // Debounce the suggestion request
    _suggestionTimer = Timer(const Duration(milliseconds: 150), () async {
      try {
        final suggestions = await unifiedSearchService.getSearchSuggestions(
          partialQuery: partialQuery.trim(),
          context: state.context,
          limit: 5,
        );

        if (mounted) {
          state = state.copyWith(suggestions: suggestions);
        }
      } catch (e) {
        _log.warning('Error getting suggestions: $e');
      }
    });
  }

  /// Hide suggestions
  void hideSuggestions() {
    if (mounted) {
      state = state.copyWith(isShowingSuggestions: false);
    }
  }

  /// Clear search
  void clear() {
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    
    if (mounted) {
      state = state.copyWith(
        query: '',
        status: SearchStatus.initial,
        results: null,
        suggestions: [],
        isShowingSuggestions: false,
        clearError: true,
        recentSearches: unifiedSearchService.getRecentSearches(state.context),
      );
    }
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    try {
      await unifiedSearchService.clearRecentSearches(state.context);
      if (mounted) {
        state = state.copyWith(recentSearches: []);
      }
    } catch (e) {
      _log.warning('Error clearing recent searches: $e');
    }
  }

  /// Select a suggestion or recent search
  void selectSuggestion(String query) {
    search(query, immediate: true);
  }

  /// Retry search
  void retry() {
    if (state.query.isNotEmpty) {
      search(state.query, immediate: true);
    }
  }

  /// Change search context
  void changeContext(SearchContext newContext) {
    if (newContext == state.context) return;

    // Clear and reset for new context
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    state = UnifiedSearchState(
      context: newContext,
      recentSearches: unifiedSearchService.getRecentSearches(newContext),
    );
  }
}

/// Global search provider (for home page)
final globalSearchProvider = StateNotifierProvider.autoDispose<UnifiedSearchNotifier, UnifiedSearchState>((ref) {
  // Initialize the service if not already done
  ref.watch(cacheServiceProvider).whenData((cacheService) {
    unifiedSearchService.initialize(cacheService);
  });

  return UnifiedSearchNotifier(SearchContext.global);
});

/// Library search provider (for library page)
final librarySearchProvider = StateNotifierProvider.autoDispose<UnifiedSearchNotifier, UnifiedSearchState>((ref) {
  // Initialize the service if not already done
  ref.watch(cacheServiceProvider).whenData((cacheService) {
    unifiedSearchService.initialize(cacheService);
  });

  return UnifiedSearchNotifier(SearchContext.library);
});

/// Search suggestions provider
final searchSuggestionsProvider = FutureProvider.family.autoDispose<List<String>, SearchSuggestionParams>((ref, params) async {
  await Future.delayed(const Duration(milliseconds: 100)); // Small delay for better UX
  
  return unifiedSearchService.getSearchSuggestions(
    partialQuery: params.query,
    context: params.context,
    limit: params.limit,
  );
});

/// Helper class for suggestion parameters
class SearchSuggestionParams {
  final String query;
  final SearchContext context;
  final int limit;

  const SearchSuggestionParams({
    required this.query,
    required this.context,
    this.limit = 5,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestionParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          context == other.context &&
          limit == other.limit;

  @override
  int get hashCode => query.hashCode ^ context.hashCode ^ limit.hashCode;
} 