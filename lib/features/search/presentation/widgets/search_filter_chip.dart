import 'package:flutter/material.dart';
import '../../domain/entities/search_result_entity.dart';

/// A filter chip widget for search results
class SearchFilterChip extends StatelessWidget {
  final SearchResultType type;
  final bool isActive;
  final int count;
  final VoidCallback onToggle;

  const SearchFilterChip({
    super.key,
    required this.type,
    required this.isActive,
    required this.count,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get display name and icon for the filter type
    final displayName = _getDisplayName(type);
    final icon = _getIcon(type);
    
    return FilterChip(
      selected: isActive,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive 
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$displayName ($count)',
            style: TextStyle(
              color: isActive 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primary,
      onSelected: (_) => onToggle(),
    );
  }

  /// Get the display name for a search result type
  String _getDisplayName(SearchResultType type) {
    switch (type) {
      case SearchResultType.book:
        return 'Books';
      case SearchResultType.chapter:
        return 'Chapters';
      case SearchResultType.video:
        return 'Videos';
      case SearchResultType.biography:
        return 'Biography';
      default:
        return 'Unknown';
    }
  }

  /// Get the icon for a search result type
  IconData _getIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.book:
        return Icons.book;
      case SearchResultType.chapter:
        return Icons.bookmark;
      case SearchResultType.video:
        return Icons.video_library;
      case SearchResultType.biography:
        return Icons.history_edu;
      default:
        return Icons.search;
    }
  }
}
