import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/themes/app_color.dart';
import 'package:modudi/features/articles/presentation/providers/articles_provider.dart';
import '../../domain/entities/article_entity.dart';

/// Screen for displaying individual article details
class ArticleDetailScreen extends ConsumerWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(articleByIdProvider(articleId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;
            
    final backgroundColor = isDark
        ? AppColor.backgroundDark
        : isSepia
            ? AppColor.backgroundSepia
            : AppColor.background;
            
    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          articleAsync.when(
            data: (article) => article?.title ?? 'Article Detail',
            loading: () => 'Loading...',
            error: (_, __) => 'Error',
          ),
          style: TextStyle(color: textColor),
        ),
        backgroundColor: cardColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: articleAsync.when(
        data: (article) {
          if (article == null) {
            return _buildErrorContent('Article not found', textColor);
          }
          return _buildArticleContent(article, context, textColor, cardColor);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorContent(error.toString(), textColor),
      ),
    );
  }

  Widget _buildArticleContent(ArticleEntity article, BuildContext context, Color textColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
          const SizedBox(height: 12),

          // Author and Date
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                article.author,
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today_outlined, size: 16, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                '${article.publishedAt.day}/${article.publishedAt.month}/${article.publishedAt.year}',
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Category and Read Time
          Row(
            children: [
              Icon(Icons.category_outlined, size: 16, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                article.category,
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 16, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                '${article.estimatedReadTime} min read',
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary
          if (article.summary.isNotEmpty) ...[
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              article.summary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor.withValues(alpha: 0.85),
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Content
          Text(
            'Content',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            article.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor.withValues(alpha: 0.85),
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 24),

          // Key Insights (if available)
          if (article.keyInsights != null && article.keyInsights!.isNotEmpty) ...[
            Text(
              'Key Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: article.keyInsights!.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: textColor.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: textColor.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Tags (if available)
          if (article.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: article.tags.map((tag) => Chip(
                label: Text(tag, style: TextStyle(color: textColor.withValues(alpha: 0.9))),
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: textColor.withValues(alpha: 0.2))
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorContent(String message, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(
              'Error Loading Article',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
} 