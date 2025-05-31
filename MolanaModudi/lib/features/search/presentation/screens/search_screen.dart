import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/search_result_entity.dart';
import '../providers/search_provider.dart';
import '../providers/search_state.dart';
import '../widgets/search_filter_chip.dart';
import '../widgets/search_results_list.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the search controller with the provided query
    final decodedQuery = Uri.decodeComponent(widget.query);
    _searchController.text = decodedQuery;
    
    // Perform the initial search if query is not empty
    if (decodedQuery.isNotEmpty) {
      // Use a microtask to ensure the search happens after the build
      Future.microtask(() {
        ref.read(searchProvider.notifier).search(decodedQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme, searchState),
      body: Column(
        children: [
          // Filter chips row
          if (searchState.status == SearchStatus.success && searchState.results.isNotEmpty)
            _buildFilterChips(theme, searchState),
          
          // Results or appropriate state widget
          Expanded(
            child: _buildBody(theme, searchState),
          ),
        ],
      ),
    );
  }

  /// Build the app bar with search functionality
  PreferredSizeWidget _buildAppBar(ThemeData theme, SearchState searchState) {
    return AppBar(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (_isSearchActive) {
            // If search is active, deactivate it
            setState(() {
              _isSearchActive = false;
              _searchFocusNode.unfocus();
            });
          } else {
            // Otherwise, go back to previous screen
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go('/home');
            }
          }
        },
        tooltip: 'Back',
      ),
      title: _isSearchActive
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search books, videos...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                border: InputBorder.none,
              ),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(searchProvider.notifier).search(value);
                  setState(() {
                    _isSearchActive = false;
                    _searchFocusNode.unfocus();
                  });
                }
              },
            )
          : Text(
              searchState.query.isEmpty 
                  ? 'Search' 
                  : 'Results for "${searchState.query}"',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      actions: [
        if (_isSearchActive)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
            tooltip: 'Clear',
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = true;
                Future.microtask(() => _searchFocusNode.requestFocus());
              });
            },
            tooltip: 'Search',
          ),
      ],
      elevation: 1,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
    );
  }

  /// Build the filter chips row
  Widget _buildFilterChips(ThemeData theme, SearchState searchState) {
    final resultCounts = searchState.resultTypeCounts;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  'Filters:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (searchState.activeFilters.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearFilters();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SearchResultType.values
                  .where((type) => resultCounts[type]! > 0)
                  .map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SearchFilterChip(
                    type: type,
                    isActive: searchState.activeFilters.contains(type),
                    count: resultCounts[type]!,
                    onToggle: () {
                      ref.read(searchProvider.notifier).toggleFilter(type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the main body content based on search state
  Widget _buildBody(ThemeData theme, SearchState searchState) {
    // If we're in the initial state and have recent searches, show them
    if (searchState.isInitial && searchState.recentSearches.isNotEmpty) {
      return _buildRecentSearches(theme, searchState);
    }
    
    // If we're loading, show a loading indicator
    if (searchState.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // If we have an error, show an error message
    if (searchState.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Searching',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                searchState.errorMessage ?? 'An unknown error occurred.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(searchProvider.notifier).search(searchState.query);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // If we have results, show them
    if (searchState.status == SearchStatus.success) {
      return SearchResultsList(
        results: searchState.filteredResults,
        onRetry: searchState.filteredResults.isEmpty
            ? () => ref.read(searchProvider.notifier).search(searchState.query)
            : null,
      );
    }
    
    // Default empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for books, videos, and more',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a search term in the search bar above',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the recent searches list
  Widget _buildRecentSearches(ThemeData theme, SearchState searchState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(searchProvider.notifier).clearRecentSearches();
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchState.recentSearches.length,
              itemBuilder: (context, index) {
                final recentSearch = searchState.recentSearches[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(recentSearch),
                  onTap: () {
                    ref.read(searchProvider.notifier).selectRecentSearch(recentSearch);
                    _searchController.text = recentSearch;
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.north_west),
                    onPressed: () {
                      _searchController.text = recentSearch;
                      setState(() {
                        _isSearchActive = true;
                        Future.microtask(() => _searchFocusNode.requestFocus());
                      });
                    },
                    tooltip: 'Edit search',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
