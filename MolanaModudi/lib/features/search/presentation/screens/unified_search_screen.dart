import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/unified_search_provider.dart';
import '../../../../core/services/unified_search_service.dart';
import '../../../../core/widgets/modern_search_bar.dart';
import '../../../../core/widgets/modern_search_results.dart';

/// Modern unified search screen with context awareness
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  final SearchContext searchContext;
  final String? initialQuery;

  const UnifiedSearchScreen({
    super.key,
    this.searchContext = SearchContext.global,
    this.initialQuery,
  });

  /// Factory for global search (home page)
  const UnifiedSearchScreen.global({
    super.key,
    String? initialQuery,
  }) : searchContext = SearchContext.global, initialQuery = initialQuery;

  /// Factory for library search (library page)
  const UnifiedSearchScreen.library({
    super.key,
    String? initialQuery,
  }) : searchContext = SearchContext.library, initialQuery = initialQuery;

  @override
  ConsumerState<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();

    // Initialize search if there's an initial query
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getSearchNotifier().search(widget.initialQuery!, immediate: true);
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  AutoDisposeStateNotifierProvider<UnifiedSearchNotifier, UnifiedSearchState> get _searchProvider {
    return widget.searchContext == SearchContext.global 
        ? globalSearchProvider 
        : librarySearchProvider;
  }

  UnifiedSearchNotifier _getSearchNotifier() {
    return ref.read(_searchProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(_searchProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            _buildSearchHeader(context, searchState),
            
            // Content area
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(context, searchState),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, UnifiedSearchState searchState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with context info
          Row(
            children: [
              // Back button (always show)
              IconButton(
                onPressed: () {
                  // Try to pop first, if that fails, navigate to appropriate fallback
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Fallback navigation based on search context
                    switch (widget.searchContext) {
                      case SearchContext.global:
                        context.go('/home');
                        break;
                      case SearchContext.library:
                        context.go('/library');
                        break;
                    }
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Go back',
              ),
              const SizedBox(width: 4),
              
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getContextTitle(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _getContextSubtitle(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Clear button
              if (searchState.query.isNotEmpty) ...[
                IconButton(
                  onPressed: () => _getSearchNotifier().clear(),
                  icon: const Icon(Icons.clear_rounded),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Clear search',
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search bar
          ModernSearchBar(
            hintText: _getSearchHint(),
            initialValue: widget.initialQuery,
            onChanged: (query) => _getSearchNotifier().search(query),
            onSubmitted: (query) => _getSearchNotifier().search(query, immediate: true),
            autofocus: widget.initialQuery == null,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UnifiedSearchState searchState) {
    if (searchState.isLoading) {
      return _buildLoadingState(context);
    }

    if (searchState.hasError) {
      return _buildErrorState(context, searchState);
    }

    if (searchState.hasResults) {
      return ModernSearchResults(
        results: searchState.results!,
        onRetry: () => _getSearchNotifier().retry(),
      );
    }

    // Initial state or empty query
    return _buildInitialState(context, searchState);
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Searching...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best results for you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, UnifiedSearchState searchState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Search failed',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchState.errorMessage ?? 'Something went wrong. Please try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _getSearchNotifier().retry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, UnifiedSearchState searchState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (searchState.recentSearches.isNotEmpty) ...[
            RecentSearches(
              recentSearches: searchState.recentSearches,
              onSearchTap: (query) => _getSearchNotifier().selectSuggestion(query),
              onClearAll: () => _getSearchNotifier().clearRecentSearches(),
            ),
            const SizedBox(height: 32),
          ],
          
          // Search tips
          _buildSearchTips(context),
          
          // Browse categories
          const SizedBox(height: 32),
          _buildBrowseSection(context),
        ],
      ),
    );
  }

  Widget _buildSearchTips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tips = _getSearchTips();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                'Search tips',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBrowseSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.explore_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                'Browse categories',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Or explore our curated collections',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {
              // Navigate to library screen based on context
              switch (widget.searchContext) {
                case SearchContext.global:
                  context.go('/library');
                  break;
                case SearchContext.library:
                  // If already from library context, go back to library
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go('/library');
                  }
                  break;
              }
            },
            child: const Text('Browse Library'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getContextTitle() {
    switch (widget.searchContext) {
      case SearchContext.global:
        return 'Search Everything';
      case SearchContext.library:
        return 'Search Library';
    }
  }

  String _getContextSubtitle() {
    switch (widget.searchContext) {
      case SearchContext.global:
        return 'Books, chapters, and videos';
      case SearchContext.library:
        return 'Find books in your library';
    }
  }

  String _getSearchHint() {
    switch (widget.searchContext) {
      case SearchContext.global:
        return 'Search books, chapters, videos...';
      case SearchContext.library:
        return 'Search your books...';
    }
  }

  List<String> _getSearchTips() {
    switch (widget.searchContext) {
      case SearchContext.global:
        return [
          'Search for book titles, author names, or specific topics',
          'Use keywords to find relevant chapters and videos',
          'Browse by category if you\'re not sure what to search for',
        ];
      case SearchContext.library:
        return [
          'Search through your personal book collection',
          'Find books by title, author, or topic',
          'Use filters to narrow down your results',
        ];
    }
  }
} 