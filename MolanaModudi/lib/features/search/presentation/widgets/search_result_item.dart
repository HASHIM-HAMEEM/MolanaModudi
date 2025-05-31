import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/search_result_entity.dart';

/// Widget to display a single search result
class SearchResultItem extends StatelessWidget {
  final SearchResultEntity result;

  const SearchResultItem({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToResult(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon or image
              _buildLeadingWidget(theme),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type indicator
                    _buildTypeIndicator(theme),
                    
                    const SizedBox(height: 4),
                    
                    // Title
                    Text(
                      result.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Subtitle if available
                    if (result.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Description if available
                    if (result.description != null && result.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        result.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the leading widget (icon or image)
  Widget _buildLeadingWidget(ThemeData theme) {
    // If we have an image URL, show the image
    if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.network(
            result.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackIcon(theme);
            },
          ),
        ),
      );
    }
    
    // Otherwise, show a fallback icon
    return _buildFallbackIcon(theme);
  }

  /// Build a fallback icon when no image is available
  Widget _buildFallbackIcon(ThemeData theme) {
    final IconData icon;
    final Color backgroundColor;
    
    switch (result.type) {
      case SearchResultType.book:
        icon = Icons.book;
        backgroundColor = Colors.blue.shade100;
        break;
      case SearchResultType.chapter:
        icon = Icons.bookmark;
        backgroundColor = Colors.green.shade100;
        break;
      case SearchResultType.video:
        icon = Icons.video_library;
        backgroundColor = Colors.red.shade100;
        break;
      case SearchResultType.biography:
        icon = Icons.history_edu;
        backgroundColor = Colors.purple.shade100;
        break;
      default:
        icon = Icons.search;
        backgroundColor = Colors.grey.shade100;
    }
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 30,
        ),
      ),
    );
  }

  /// Build a chip to indicate the result type
  Widget _buildTypeIndicator(ThemeData theme) {
    final String label;
    final Color color;
    
    switch (result.type) {
      case SearchResultType.book:
        label = 'Book';
        color = Colors.blue;
        break;
      case SearchResultType.chapter:
        label = 'Chapter';
        color = Colors.green;
        break;
      case SearchResultType.video:
        label = 'Video';
        color = Colors.red;
        break;
      case SearchResultType.biography:
        label = 'Biography';
        color = Colors.purple;
        break;
      default:
        label = 'Other';
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Navigate to the appropriate screen based on the result type
  void _navigateToResult(BuildContext context) {
    final routePath = result.getRoutePath();
    context.go(routePath);
  }
}
