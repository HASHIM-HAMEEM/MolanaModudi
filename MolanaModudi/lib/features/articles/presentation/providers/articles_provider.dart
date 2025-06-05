import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/article_entity.dart';
import '../../domain/repositories/articles_repository.dart';
import '../../data/repositories/ai_articles_repository_impl.dart';

// AI Repository provider (no Firebase dependencies)
final _articlesRepositoryProvider = Provider<ArticlesRepository>((ref) {
  return AIArticlesRepositoryImpl();
});

// Main articles providers

/// Provider for recent articles
final recentArticlesProvider = FutureProvider.family<List<ArticleEntity>, RecentArticlesParams>((ref, params) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getRecentArticles(
    limit: params.limit,
    category: params.category,
    statusFilter: params.statusFilter,
  );
});

/// Provider for featured articles
final featuredArticlesProvider = FutureProvider.family<List<ArticleEntity>, int>((ref, limit) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getFeaturedArticles(limit: limit);
});

/// Provider for trending articles
final trendingArticlesProvider = FutureProvider.family<List<ArticleEntity>, int>((ref, limit) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getTrendingArticles(limit: limit);
});

/// Provider for personalized recommendations
final personalizedArticlesProvider = FutureProvider.family<List<ArticleEntity>, PersonalizedArticlesParams>((ref, params) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getPersonalizedRecommendations(
    limit: params.limit,
    userInterests: params.userInterests,
    readHistory: params.readHistory,
  );
});

/// Provider for a single article by ID
final articleByIdProvider = FutureProvider.family<ArticleEntity?, String>((ref, articleId) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getArticleById(articleId);
});

/// Provider for searching articles
final searchArticlesProvider = FutureProvider.family<List<ArticleEntity>, SearchArticlesParams>((ref, params) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.searchArticles(
    query: params.query,
    category: params.category,
    tags: params.tags,
    limit: params.limit,
  );
});

/// Provider for related articles
final relatedArticlesProvider = FutureProvider.family<List<ArticleEntity>, RelatedArticlesParams>((ref, params) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getRelatedArticles(
    articleId: params.articleId,
    limit: params.limit,
  );
});

/// Provider for available categories
final articlesCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getCategories();
});

/// Provider for popular tags
final articlesTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getTags();
});

/// Provider for favorite articles
final favoriteArticlesProvider = FutureProvider<List<ArticleEntity>>((ref) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getFavoriteArticles();
});

/// Provider for reading history
final readingHistoryProvider = FutureProvider<List<ArticleEntity>>((ref) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getReadingHistory();
});

/// Provider for AI-enhanced content
final aiEnhancedContentProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, articleId) async {
  final repository = ref.watch(_articlesRepositoryProvider);
  return repository.getAIEnhancedContent(articleId);
});

// Notifier providers for user actions

/// Notifier for managing articles state and user actions
final articlesNotifierProvider = StateNotifierProvider<ArticlesNotifier, ArticlesState>((ref) {
  return ArticlesNotifier(ref);
});

/// State class for articles
class ArticlesState {
  final Set<String> favoriteArticleIds;
  final Set<String> readArticleIds;
  final Map<String, Duration> readingTimes;
  final bool isLoading;
  final String? error;

  const ArticlesState({
    this.favoriteArticleIds = const {},
    this.readArticleIds = const {},
    this.readingTimes = const {},
    this.isLoading = false,
    this.error,
  });

  ArticlesState copyWith({
    Set<String>? favoriteArticleIds,
    Set<String>? readArticleIds,
    Map<String, Duration>? readingTimes,
    bool? isLoading,
    String? error,
  }) {
    return ArticlesState(
      favoriteArticleIds: favoriteArticleIds ?? this.favoriteArticleIds,
      readArticleIds: readArticleIds ?? this.readArticleIds,
      readingTimes: readingTimes ?? this.readingTimes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing articles state
class ArticlesNotifier extends StateNotifier<ArticlesState> {
  final Ref ref;

  ArticlesNotifier(this.ref) : super(const ArticlesState()) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load user preferences from local storage
    // In a real implementation, this would load from SharedPreferences or similar
    state = state.copyWith(isLoading: false);
  }

  Future<void> toggleFavorite(String articleId) async {
    final repository = ref.read(_articlesRepositoryProvider);
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      if (state.favoriteArticleIds.contains(articleId)) {
        await repository.removeFromFavorites(articleId);
        final newFavorites = Set<String>.from(state.favoriteArticleIds)..remove(articleId);
        state = state.copyWith(
          favoriteArticleIds: newFavorites,
          isLoading: false,
        );
      } else {
        await repository.addToFavorites(articleId);
        final newFavorites = Set<String>.from(state.favoriteArticleIds)..add(articleId);
        state = state.copyWith(
          favoriteArticleIds: newFavorites,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update favorite: $e',
      );
    }
  }

  Future<void> markAsRead(String articleId) async {
    final repository = ref.read(_articlesRepositoryProvider);
    
    try {
      await repository.markAsRead(articleId);
      final newReadArticles = Set<String>.from(state.readArticleIds)..add(articleId);
      state = state.copyWith(readArticleIds: newReadArticles);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark as read: $e');
    }
  }

  void updateReadingTime(String articleId, Duration readingTime) {
    final newReadingTimes = Map<String, Duration>.from(state.readingTimes);
    newReadingTimes[articleId] = readingTime;
    state = state.copyWith(readingTimes: newReadingTimes);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Parameter classes for providers

class RecentArticlesParams {
  final int limit;
  final String? category;
  final List<ArticleStatus>? statusFilter;

  const RecentArticlesParams({
    this.limit = 10,
    this.category,
    this.statusFilter,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentArticlesParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          category == other.category &&
          _listEquals(statusFilter, other.statusFilter);

  @override
  int get hashCode => limit.hashCode ^ category.hashCode ^ statusFilter.hashCode;
}

class PersonalizedArticlesParams {
  final int limit;
  final List<String>? userInterests;
  final List<String>? readHistory;

  const PersonalizedArticlesParams({
    this.limit = 10,
    this.userInterests,
    this.readHistory,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizedArticlesParams &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          _listEquals(userInterests, other.userInterests) &&
          _listEquals(readHistory, other.readHistory);

  @override
  int get hashCode => 
      limit.hashCode ^ 
      userInterests.hashCode ^ 
      readHistory.hashCode;
}

class SearchArticlesParams {
  final String query;
  final String? category;
  final List<String>? tags;
  final int limit;

  const SearchArticlesParams({
    required this.query,
    this.category,
    this.tags,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchArticlesParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          category == other.category &&
          _listEquals(tags, other.tags) &&
          limit == other.limit;

  @override
  int get hashCode =>
      query.hashCode ^ category.hashCode ^ tags.hashCode ^ limit.hashCode;
}

class RelatedArticlesParams {
  final String articleId;
  final int limit;

  const RelatedArticlesParams({
    required this.articleId,
    this.limit = 5,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelatedArticlesParams &&
          runtimeType == other.runtimeType &&
          articleId == other.articleId &&
          limit == other.limit;

  @override
  int get hashCode => articleId.hashCode ^ limit.hashCode;
}

// Utility function for list comparison
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
} 