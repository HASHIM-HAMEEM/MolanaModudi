import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../services/unified_search_service.dart';

/// Modern search results list with Airbnb-style design
class ModernSearchResults extends StatelessWidget {
  final SearchResults results;
  final VoidCallback? onRetry;
  final Function(UnifiedSearchResult)? onResultTap;

  const ModernSearchResults({
    super.key,
    required this.results,
    this.onRetry,
    this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!results.hasResults) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        // Results summary
        SliverToBoxAdapter(
          child: _buildResultsSummary(context),
        ),
        
        // Results by category
        if (results.books.isNotEmpty) ...[
          _buildSectionHeader(context, 'Books', results.books.length),
          _buildResultsSection(context, results.books),
        ],
        
        if (results.chapters.isNotEmpty) ...[
          _buildSectionHeader(context, 'Chapters', results.chapters.length),
          _buildResultsSection(context, results.chapters),
        ],
        
        if (results.videos.isNotEmpty) ...[
          _buildSectionHeader(context, 'Videos', results.videos.length),
          _buildResultsSection(context, results.videos),
        ],
        
        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildResultsSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${results.totalCount} results for "${results.query}"',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, List<UnifiedSearchResult> results) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final result = results[index];
          return _SearchResultTile(
            result: result,
            onTap: () => _handleResultTap(context, result),
          );
        },
        childCount: results.length,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms\nor browse our categories',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleResultTap(BuildContext context, UnifiedSearchResult result) {
    HapticFeedback.lightImpact();
    
    if (onResultTap != null) {
      onResultTap!(result);
    } else {
      // Default navigation
      context.go(result.getRoutePath());
    }
  }
}

/// Individual search result tile
class _SearchResultTile extends StatelessWidget {
  final UnifiedSearchResult result;
  final VoidCallback? onTap;

  const _SearchResultTile({
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(colorScheme),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(),
                    size: 20,
                    color: _getIconColor(colorScheme),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        result.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Subtitle
                      if (result.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          result.subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Description
                      if (result.description != null && result.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          result.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Trailing arrow
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (result.type) {
      case UnifiedSearchResultType.book:
        return Icons.menu_book_rounded;
      case UnifiedSearchResultType.chapter:
        return Icons.bookmark_rounded;
      case UnifiedSearchResultType.video:
        return Icons.play_circle_rounded;
    }
  }

  Color _getIconBackgroundColor(ColorScheme colorScheme) {
    switch (result.type) {
      case UnifiedSearchResultType.book:
        return colorScheme.primaryContainer;
      case UnifiedSearchResultType.chapter:
        return colorScheme.secondaryContainer;
      case UnifiedSearchResultType.video:
        return colorScheme.tertiaryContainer;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (result.type) {
      case UnifiedSearchResultType.book:
        return colorScheme.onPrimaryContainer;
      case UnifiedSearchResultType.chapter:
        return colorScheme.onSecondaryContainer;
      case UnifiedSearchResultType.video:
        return colorScheme.onTertiaryContainer;
    }
  }
}

/// Recent searches widget
class RecentSearches extends StatelessWidget {
  final List<String> recentSearches;
  final Function(String)? onSearchTap;
  final VoidCallback? onClearAll;

  const RecentSearches({
    super.key,
    required this.recentSearches,
    this.onSearchTap,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recent searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onClearAll != null)
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Recent search items
        ...recentSearches.map((search) => _RecentSearchTile(
          search: search,
          onTap: () => onSearchTap?.call(search),
        )),
      ],
    );
  }
}

/// Individual recent search tile
class _RecentSearchTile extends StatelessWidget {
  final String search;
  final VoidCallback? onTap;

  const _RecentSearchTile({
    required this.search,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  search,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search suggestions dropdown
class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String)? onSuggestionTap;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: index == 0 ? const Radius.circular(12) : Radius.zero,
                bottom: index == suggestions.length - 1 ? const Radius.circular(12) : Radius.zero,
              ),
              onTap: () => onSuggestionTap?.call(suggestion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: index < suggestions.length - 1
                      ? Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
} 