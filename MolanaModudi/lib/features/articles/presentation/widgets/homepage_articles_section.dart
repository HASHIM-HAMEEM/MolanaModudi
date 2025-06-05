import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/core/themes/app_color.dart';
import '../../../../core/l10n/app_localizations_wrapper.dart';
import '../providers/articles_provider.dart';
import '../../domain/entities/article_entity.dart';

/// Homepage articles section with modern minimalistic design inspired by Apple/Airbnb
class HomepageArticlesSection extends ConsumerWidget {
  const HomepageArticlesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final primaryAccent = isDark
        ? AppColor.accentDark
        : isSepia
            ? AppColor.accentSepia
            : AppColor.accent;

    // Fetch recent articles with limit of 1 to match current UI
    final articlesAsync = ref.watch(recentArticlesProvider(
      const RecentArticlesParams(limit: 1),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40), // Generous spacing for breathing room
        
        // Section title with minimalistic styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            AppLocalizations.of(context)!.homeScreenRecentArticlesTitle,
            style: TextStyle(
              fontSize: 28, // Larger, more prominent
              fontWeight: FontWeight.w700, // Bolder for Apple-style impact
              color: textColor,
              letterSpacing: -0.8, // Tighter letter spacing for modern look
              height: 1.2, // Compact line height
            ),
          ),
        ),
        const SizedBox(height: 4), // Minimal gap between title and subtitle
        
        // Subtle subtitle for context
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Latest insights and scholarship',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark 
                  ? AppColor.textSecondaryDark 
                  : isSepia 
                      ? AppColor.textSecondarySepia 
                      : AppColor.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        
        const SizedBox(height: 24), // Space before content
        
        // Articles content with enhanced error handling
        articlesAsync.when(
          data: (articles) => _buildMinimalistArticleCard(
            context,
            articles.isNotEmpty ? articles.first : null,
            isDark,
            isSepia,
            textColor,
            primaryAccent,
          ),
          loading: () => _buildMinimalistLoadingCard(isDark, isSepia, primaryAccent),
          error: (error, _) => _buildMinimalistErrorCard(isDark, isSepia, textColor, primaryAccent),
        ),
        
        const SizedBox(height: 48), // Generous bottom spacing
      ],
    );
  }

  Widget _buildMinimalistArticleCard(
    BuildContext context,
    ArticleEntity? article,
    bool isDark,
    bool isSepia,
    Color textColor,
    Color primaryAccent,
  ) {
    // Enhanced fallback content
    final displayTitle = article?.title ?? "The Islamic State: Principles and Structure";
    final displaySummary = article?.summary ?? "An in-depth exploration of Maulana Maududi's political thought and his comprehensive vision for Islamic governance in the modern world.";
    final displayReadTime = article?.estimatedReadTime != null ? "${article!.estimatedReadTime} min read" : "7 min read";
    final displayAuthor = article?.author ?? "Dr. Ahmad Hassan";
    
    // Get relative time for published date (more dynamic than static time)
    final displayTime = article?.publishedAt != null 
        ? _formatRelativeTime(article!.publishedAt)
        : "2 days ago";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark 
              ? AppColor.surfaceDark.withValues(alpha: 0.6)
              : isSepia 
                  ? AppColor.surfaceSepia.withValues(alpha: 0.8)
                  : Colors.white,
          borderRadius: BorderRadius.circular(24), // More rounded for modern feel
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : isSepia
                    ? AppColor.accent.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onArticleTap(context, article),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(28), // More generous padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article metadata row
                  Row(
                    children: [
                      // Author avatar placeholder
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            displayAuthor.split(' ').map((name) => name[0]).take(2).join(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Author and time info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayAuthor,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                letterSpacing: -0.1,
                              ),
                            ),
                            Text(
                              displayTime,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isDark 
                                    ? AppColor.textSecondaryDark 
                                    : isSepia 
                                        ? AppColor.textSecondarySepia 
                                        : AppColor.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Reading time badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          displayReadTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryAccent,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Article title
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20, // Larger for more impact
                      color: textColor,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Article summary
                  Text(
                    displaySummary,
                    style: TextStyle(
                      fontSize: 16, // Slightly larger for better readability
                      color: isDark 
                          ? AppColor.textSecondaryDark 
                          : isSepia 
                              ? AppColor.textSecondarySepia 
                              : AppColor.textSecondary,
                      height: 1.5, // More generous line height
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Read more button with modern styling
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48, // Standard touch target
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryAccent.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onArticleTap(context, article),
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Text(
                                  'Read Article',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalistLoadingCard(bool isDark, bool isSepia, Color primaryAccent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: isDark 
              ? AppColor.surfaceDark.withValues(alpha: 0.6)
              : isSepia 
                  ? AppColor.surfaceSepia.withValues(alpha: 0.8)
                  : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryAccent.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading fresh insights...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark 
                      ? AppColor.textSecondaryDark 
                      : isSepia 
                          ? AppColor.textSecondarySepia 
                          : AppColor.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalistErrorCard(bool isDark, bool isSepia, Color textColor, Color primaryAccent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark 
              ? AppColor.surfaceDark.withValues(alpha: 0.6)
              : isSepia 
                  ? AppColor.surfaceSepia.withValues(alpha: 0.8)
                  : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.article_outlined,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Articles Coming Soon",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're preparing insightful articles on Islamic scholarship. Check back soon for the latest content.",
              style: TextStyle(
                fontSize: 15,
                color: isDark 
                    ? AppColor.textSecondaryDark 
                    : isSepia 
                        ? AppColor.textSecondarySepia 
                        : AppColor.textSecondary,
                height: 1.4,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primaryAccent.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: primaryAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onArticleTap(BuildContext context, ArticleEntity? article) {
    if (article != null) {
      // Navigate to article detail screen
      context.push('/articles/${article.id}');
    } else {
      // Show coming soon message with modern snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.schedule_outlined, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Articles coming soon!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Format relative time in a user-friendly way
  String _formatRelativeTime(DateTime publishedAt) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 