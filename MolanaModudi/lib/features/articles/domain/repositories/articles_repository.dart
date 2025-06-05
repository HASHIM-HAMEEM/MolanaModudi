import '../entities/article_entity.dart';

/// Repository interface for articles
abstract class ArticlesRepository {
  /// Get recent articles with optional filtering
  Future<List<ArticleEntity>> getRecentArticles({
    int limit = 10,
    String? category,
    List<ArticleStatus>? statusFilter,
  });

  /// Get featured articles
  Future<List<ArticleEntity>> getFeaturedArticles({int limit = 5});

  /// Get article by ID
  Future<ArticleEntity?> getArticleById(String id);

  /// Search articles
  Future<List<ArticleEntity>> searchArticles({
    required String query,
    String? category,
    List<String>? tags,
    int limit = 20,
  });

  /// Get articles by category
  Future<List<ArticleEntity>> getArticlesByCategory({
    required String category,
    int limit = 20,
  });

  /// Get articles by tags
  Future<List<ArticleEntity>> getArticlesByTags({
    required List<String> tags,
    int limit = 20,
  });

  /// Get all available categories
  Future<List<String>> getCategories();

  /// Get all available tags
  Future<List<String>> getTags();

  /// Get trending articles based on engagement
  Future<List<ArticleEntity>> getTrendingArticles({int limit = 10});

  /// Get personalized recommendations for user
  Future<List<ArticleEntity>> getPersonalizedRecommendations({
    int limit = 10,
    List<String>? userInterests,
    List<String>? readHistory,
  });

  /// Mark article as read/viewed
  Future<void> markAsRead(String articleId);

  /// Add article to favorites
  Future<void> addToFavorites(String articleId);

  /// Remove article from favorites
  Future<void> removeFromFavorites(String articleId);

  /// Get user's favorite articles
  Future<List<ArticleEntity>> getFavoriteArticles();

  /// Get user's reading history
  Future<List<ArticleEntity>> getReadingHistory({int limit = 50});

  /// Track article engagement (view time, scroll depth, etc.)
  Future<void> trackEngagement({
    required String articleId,
    required Duration readTime,
    double? scrollDepth,
    bool? completed,
  });

  /// Get AI-enhanced article content (summary, insights, etc.)
  Future<Map<String, dynamic>> getAIEnhancedContent(String articleId);

  /// Request AI-generated audio for article
  Future<String?> generateAudioVersion(String articleId);

  /// Get related articles using AI
  Future<List<ArticleEntity>> getRelatedArticles({
    required String articleId,
    int limit = 5,
  });
} 