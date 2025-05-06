import 'package:flutter/material.dart';
import 'article_card.dart';

// Placeholder data model
class _PlaceholderArticle {
  final String id;
  final String title;
  final String summary;
  final String readTime;

  _PlaceholderArticle(this.id, this.title, this.summary, this.readTime);
}

class ArticlesSection extends StatelessWidget {
  final String title;
  final List<_PlaceholderArticle> articles; // Use placeholder for now
  final VoidCallback? onViewAll;

  const ArticlesSection({
    super.key,
    required this.title,
    required this.articles,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Sample data matching the reference
    final sampleArticles = [
      _PlaceholderArticle(
        '1',
        "The Islamic State: Principles and Structure",
        "An analysis of Maududi's political thought and his vision for governance.",
        "7 min read",
      ),
      // Add more sample articles if needed
    ];

    // Use sample data for now
    final displayArticles = articles.isEmpty ? sampleArticles : articles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with "View All" button (optional)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: textTheme.titleLarge),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12.0),
        // List of Article Cards
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(), // Disable list scrolling
          shrinkWrap: true,
          itemCount: displayArticles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8.0), // Spacing between tiles
          itemBuilder: (context, index) {
            final article = displayArticles[index];
            return ArticleCard(
              title: article.title,
              summary: article.summary,
              readTime: article.readTime,
              onTap: () {
                // TODO: Implement navigation to article detail screen
                print('Tapped on article: ${article.title}');
              },
            );
          },
        ),
      ],
    );
  }
} 