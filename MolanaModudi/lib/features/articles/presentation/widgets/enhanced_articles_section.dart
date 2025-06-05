import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/core/themes/app_color.dart';
import '../providers/articles_provider.dart';
import 'modern_article_card.dart';
import '../../domain/entities/article_entity.dart';

/// Enhanced articles section with AI features and modern UI
class EnhancedArticlesSection extends ConsumerStatefulWidget {
  final String title;
  final ArticlesDisplayMode displayMode;
  final int limit;
  final String? category;
  final VoidCallback? onViewAll;
  final bool showFilters;

  const EnhancedArticlesSection({
    super.key,
    this.title = 'Recent Articles',
    this.displayMode = ArticlesDisplayMode.recent,
    this.limit = 5,
    this.category,
    this.onViewAll,
    this.showFilters = false,
  });

  @override
  ConsumerState<EnhancedArticlesSection> createState() => _EnhancedArticlesSectionState();
}

class _EnhancedArticlesSectionState extends ConsumerState<EnhancedArticlesSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _selectedCategory;
  bool _showAIFeatures = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _selectedCategory = widget.category;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final accentColor = isDark
        ? AppColor.accentDark
        : isSepia
            ? AppColor.accentSepia
            : AppColor.accent;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              _buildSectionHeader(textColor, accentColor),
              
              // Filters (if enabled)
              if (widget.showFilters) ...[
                const SizedBox(height: 16),
                _buildFilters(accentColor),
              ],
              
              const SizedBox(height: 20),
              
              // Articles Content
              _buildArticlesContent(),
              
              // AI Insights (if available)
              if (_showAIFeatures) ...[
                const SizedBox(height: 20),
                _buildAIInsightsSection(textColor, accentColor),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Title with icon
          Icon(
            _getIconForDisplayMode(),
            size: 24,
            color: accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          // AI Toggle
          if (_showAIFeatures)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAIFeatures = !_showAIFeatures;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // View All Button
          if (widget.onViewAll != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: widget.onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters(Color accentColor) {
    return Consumer(
      builder: (context, ref, _) {
        final categoriesAsync = ref.watch(articlesCategoriesProvider);
        
        return categoriesAsync.when(
          data: (categories) => _buildCategoryFilter(categories, accentColor),
          loading: () => const SizedBox(height: 40),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildCategoryFilter(List<String> categories, Color accentColor) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: categories.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                isAll ? 'All' : category!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : accentColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
              backgroundColor: Colors.transparent,
              selectedColor: accentColor,
              side: BorderSide(color: accentColor),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticlesContent() {
    return Consumer(
      builder: (context, ref, _) {
        final articlesAsync = _getArticlesProvider(ref);
        
        return articlesAsync.when(
          data: (articles) => _buildArticlesList(articles),
          loading: () => _buildLoadingState(),
          error: (error, _) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  AsyncValue<List<ArticleEntity>> _getArticlesProvider(WidgetRef ref) {
    switch (widget.displayMode) {
      case ArticlesDisplayMode.recent:
        return ref.watch(recentArticlesProvider(
          RecentArticlesParams(
            limit: widget.limit,
            category: _selectedCategory ?? widget.category,
          ),
        ));
      case ArticlesDisplayMode.featured:
        return ref.watch(featuredArticlesProvider(widget.limit));
      case ArticlesDisplayMode.trending:
        return ref.watch(trendingArticlesProvider(widget.limit));
      case ArticlesDisplayMode.personalized:
        return ref.watch(personalizedArticlesProvider(
          PersonalizedArticlesParams(
            limit: widget.limit,
          ),
        ));
    }
  }

  Widget _buildArticlesList(List<ArticleEntity> articles) {
    if (articles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: articles.asMap().entries.map((entry) {
        final index = entry.key;
        final article = entry.value;
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: ModernArticleCard(
                  article: article,
                  onTap: () => _onArticleTap(article),
                  onFavorite: () => _onFavoriteToggle(article),
                  onShare: () => _onShare(article),
                  onAudio: article.audioUrl != null ? () => _onAudio(article) : null,
                  isFavorite: _isFavorite(article.id),
                  size: _getCardSize(),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          height: 160,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load articles',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: textColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No articles available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new content',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection(Color textColor, Color accentColor) {
    return Consumer(
      builder: (context, ref, _) {
        // For now, use static insights since we need an article ID for AI enhanced content
        final staticInsights = [
          'AI analysis shows increased interest in contemporary Islamic issues',
          'Readers spend 40% more time on articles about social justice',
          'Political thought articles have highest engagement rates',
        ];
        
        final insightsAsync = AsyncValue.data(staticInsights);
        
        return insightsAsync.when(
          data: (insights) {
            if (insights.isEmpty) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.05),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 18,
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Insights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...insights.take(3).map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 12),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            insight,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.8),
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
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  // Helper methods

  IconData _getIconForDisplayMode() {
    switch (widget.displayMode) {
      case ArticlesDisplayMode.recent:
        return Icons.schedule_outlined;
      case ArticlesDisplayMode.featured:
        return Icons.star_outline;
      case ArticlesDisplayMode.trending:
        return Icons.trending_up_outlined;
      case ArticlesDisplayMode.personalized:
        return Icons.person_outline;
    }
  }

  CardSize _getCardSize() {
    if (widget.limit <= 3) return CardSize.featured;
    if (widget.limit <= 5) return CardSize.normal;
    return CardSize.compact;
  }

  bool _isFavorite(String articleId) {
    // This would check against a favorites provider
    return false; // Placeholder
  }

  void _onArticleTap(ArticleEntity article) {
    // Navigate to article detail screen
    context.push('/articles/${article.id}');
  }

  void _onFavoriteToggle(ArticleEntity article) {
    // Toggle favorite status
    // ref.read(articlesProvider.notifier).toggleFavorite(article.id);
  }

  void _onShare(ArticleEntity article) {
    // Share article
    // Share.share('Check out this article: ${article.title}');
  }

  void _onAudio(ArticleEntity article) {
    // Play audio version
    // AudioPlayer().play(article.audioUrl!);
  }
}

/// Display modes for articles section
enum ArticlesDisplayMode {
  recent,
  featured,
  trending,
  personalized,
} 