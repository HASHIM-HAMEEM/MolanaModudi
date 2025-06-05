import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../domain/entities/article_entity.dart';
import '../models/article_model.dart';

/// AI service for article-related AI features
class ArticlesAIService {
  final FirebaseFirestore _firestore;
  final http.Client _httpClient;
  
  // Mock API endpoints (replace with actual AI service endpoints)
  static const String _aiBaseUrl = 'https://api.example.com/ai';
  static const String _ttsBaseUrl = 'https://api.example.com/tts';
  
  ArticlesAIService({
    required FirebaseFirestore firestore,
    http.Client? httpClient,
  }) : _firestore = firestore,
       _httpClient = httpClient ?? http.Client();

  /// Search articles using AI-enhanced search
  Future<List<ArticleEntity>> searchArticles({
    required String query,
    String? category,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      // In a real implementation, this would call an AI search service
      // For now, we'll implement a more sophisticated local search
      
      final snapshot = await _firestore
          .collection('articles')
          .where('status', whereIn: ['published', 'featured'])
          .get();

      final articles = snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // AI-like scoring algorithm
      final scoredArticles = articles.map((article) {
        double score = 0.0;
        
        // Title match (highest weight)
        if (article.title.toLowerCase().contains(query.toLowerCase())) {
          score += 10.0;
        }
        
        // Summary match
        if (article.summary.toLowerCase().contains(query.toLowerCase())) {
          score += 5.0;
        }
        
        // Content match
        if (article.content.toLowerCase().contains(query.toLowerCase())) {
          score += 2.0;
        }
        
        // Tag match
        for (final tag in article.tags) {
          if (tag.toLowerCase().contains(query.toLowerCase())) {
            score += 3.0;
          }
        }
        
        // Category match
        if (category != null && article.category == category) {
          score += 4.0;
        }
        
        // Relevance boost for recent articles
        final daysSincePublished = DateTime.now().difference(article.publishedAt).inDays;
        if (daysSincePublished < 30) {
          score += 1.0;
        }
        
        return MapEntry(article, score);
      }).where((entry) => entry.value > 0);

      // Sort by score and return top results
      final sortedArticles = scoredArticles.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedArticles
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      debugPrint('Error in AI search: $e');
      return [];
    }
  }

  /// Get trending articles using AI analysis
  Future<List<ArticleEntity>> getTrendingArticles({int limit = 10}) async {
    try {
      // Mock implementation - in reality, this would analyze:
      // - Read counts, time spent reading, shares, etc.
      // - Social signals, external links
      // - AI content quality scores
      
      final snapshot = await _firestore
          .collection('articles')
          .where('status', whereIn: ['published', 'featured'])
          .orderBy('publishedAt', descending: true)
          .limit(50) // Get recent articles to analyze
          .get();

      final articles = snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Simple trending algorithm based on recency and estimated engagement
      final trendy = articles.map((article) {
        double trendScore = 0.0;
        
        // Recency factor (articles from last 7 days get boost)
        final daysSince = DateTime.now().difference(article.publishedAt).inDays;
        if (daysSince <= 7) {
          trendScore += 10.0 * (7 - daysSince) / 7;
        }
        
        // Priority boost
        trendScore += article.priority.sortOrder * 2.0;
        
        // Length factor (moderate length articles tend to perform better)
        final contentLength = article.content.length;
        if (contentLength > 500 && contentLength < 3000) {
          trendScore += 3.0;
        }
        
        // Category diversity bonus
        if (['Political Thought', 'Islamic Governance', 'Contemporary Issues'].contains(article.category)) {
          trendScore += 2.0;
        }
        
        return MapEntry(article, trendScore);
      }).toList();

      trendy.sort((a, b) => b.value.compareTo(a.value));
      
      return trendy
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      debugPrint('Error getting trending articles: $e');
      return [];
    }
  }

  /// Get personalized recommendations using AI
  Future<List<ArticleEntity>> getPersonalizedRecommendations({
    required List<String> userInterests,
    required List<String> readHistory,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('articles')
          .where('status', whereIn: ['published', 'featured'])
          .get();

      final articles = snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .where((article) => !readHistory.contains(article.id)) // Exclude already read
          .toList();

      // AI-like recommendation scoring
      final scored = articles.map((article) {
        double score = 0.0;
        
        // Interest matching
        if (userInterests.contains(article.category)) {
          score += 5.0;
        }
        
        for (final interest in userInterests) {
          if (article.tags.contains(interest)) {
            score += 3.0;
          }
          if (article.title.toLowerCase().contains(interest.toLowerCase())) {
            score += 2.0;
          }
        }
        
        // Diversity factor - boost articles from different categories
        score += Random().nextDouble() * 2.0; // Add some randomness
        
        // Quality indicators
        if (article.keyInsights != null && article.keyInsights!.isNotEmpty) {
          score += 1.0;
        }
        
        if (article.aiConfidenceScore != null && article.aiConfidenceScore! > 0.8) {
          score += 2.0;
        }
        
        return MapEntry(article, score);
      }).where((entry) => entry.value > 0);

      final sorted = scored.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      debugPrint('Error getting personalized recommendations: $e');
      return [];
    }
  }

  /// Track user engagement for AI learning
  Future<void> trackEngagement({
    required String articleId,
    required Duration readTime,
    double? scrollDepth,
    bool? completed,
  }) async {
    try {
      // In production, this would send data to AI analytics service
      await _firestore
          .collection('article_analytics')
          .doc()
          .set({
        'articleId': articleId,
        'readTime': readTime.inSeconds,
        'scrollDepth': scrollDepth ?? 0.0,
        'completed': completed ?? false,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': 'anonymous', // In real app, use actual user ID
      });
    } catch (e) {
      debugPrint('Error tracking engagement: $e');
    }
  }

  /// Get AI-enhanced content (summary, key insights, etc.)
  Future<Map<String, dynamic>> getEnhancedContent(String articleId) async {
    try {
      // Check if enhanced content is cached
      final cacheDoc = await _firestore
          .collection('article_ai_cache')
          .doc(articleId)
          .get();

      if (cacheDoc.exists) {
        return cacheDoc.data() as Map<String, dynamic>;
      }

      // Get original article
      final articleDoc = await _firestore
          .collection('articles')
          .doc(articleId)
          .get();

      if (!articleDoc.exists) {
        return {};
      }

      final article = ArticleModel.fromFirestore(articleDoc.id, articleDoc.data() as Map<String, dynamic>);

      // Generate AI enhancements (mock implementation)
      final enhanced = {
        'summary': _generateEnhancedSummary(article.content),
        'keyInsights': _extractKeyInsights(article.content),
        'readingLevel': _assessReadingLevel(article.content),
        'topics': _extractTopics(article.content),
        'sentiment': _analyzeSentiment(article.content),
        'generatedAt': DateTime.now().toIso8601String(),
      };

      // Cache the results
      await _firestore
          .collection('article_ai_cache')
          .doc(articleId)
          .set(enhanced);

      return enhanced;
    } catch (e) {
      debugPrint('Error getting enhanced content: $e');
      return {};
    }
  }

  /// Generate audio version of article using TTS
  Future<String?> generateAudioVersion(String articleId) async {
    try {
      // Check if audio already exists
      final articleDoc = await _firestore
          .collection('articles')
          .doc(articleId)
          .get();

      if (!articleDoc.exists) return null;

      final data = articleDoc.data() as Map<String, dynamic>;
      if (data['audioUrl'] != null) {
        return data['audioUrl'] as String;
      }

      // In production, this would call a TTS service
      // For now, return a mock URL
      final mockAudioUrl = 'https://example.com/audio/$articleId.mp3';

      // Update article with audio URL
      await _firestore
          .collection('articles')
          .doc(articleId)
          .update({'audioUrl': mockAudioUrl});

      return mockAudioUrl;
    } catch (e) {
      debugPrint('Error generating audio version: $e');
      return null;
    }
  }

  /// Get related articles using AI
  Future<List<ArticleEntity>> getRelatedArticles({
    required String articleId,
    int limit = 5,
  }) async {
    try {
      // Get the source article
      final sourceDoc = await _firestore
          .collection('articles')
          .doc(articleId)
          .get();

      if (!sourceDoc.exists) return [];

      final sourceArticle = ArticleModel.fromFirestore(sourceDoc.id, sourceDoc.data() as Map<String, dynamic>);

      // Find related articles
      final snapshot = await _firestore
          .collection('articles')
          .where('status', whereIn: ['published', 'featured'])
          .get();

      final allArticles = snapshot.docs
          .map((doc) => ArticleModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .where((article) => article.id != articleId) // Exclude source article
          .toList();

      // Calculate similarity scores
      final related = allArticles.map((article) {
        double similarity = 0.0;

        // Category match
        if (article.category == sourceArticle.category) {
          similarity += 5.0;
        }

        // Tag overlap
        final commonTags = article.tags.where((tag) => sourceArticle.tags.contains(tag)).length;
        similarity += commonTags * 2.0;

        // Author match
        if (article.author == sourceArticle.author) {
          similarity += 3.0;
        }

        // Content similarity (simple keyword matching)
        final sourceWords = sourceArticle.content.toLowerCase().split(' ');
        final articleWords = article.content.toLowerCase().split(' ');
        final commonWords = sourceWords.where((word) => articleWords.contains(word) && word.length > 4).length;
        similarity += commonWords * 0.1;

        return MapEntry(article, similarity);
      }).where((entry) => entry.value > 0);

      final sorted = related.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      debugPrint('Error getting related articles: $e');
      return [];
    }
  }

  // Private helper methods for AI processing

  String _generateEnhancedSummary(String content) {
    // Simple algorithm - in production, use actual AI
    final sentences = content.split(RegExp(r'[.!?]+'));
    final importantSentences = sentences
        .where((s) => s.length > 30 && (
            s.toLowerCase().contains('important') ||
            s.toLowerCase().contains('significant') ||
            s.toLowerCase().contains('key') ||
            s.toLowerCase().contains('main')
        ))
        .take(3)
        .join('. ');
    
    return importantSentences.isNotEmpty ? '$importantSentences.' : ArticleModel.generateSummary(content);
  }

  List<String> _extractKeyInsights(String content) {
    return ArticleModel.extractKeyInsights(content);
  }

  String _assessReadingLevel(String content) {
    // Simple reading level assessment
    final sentences = content.split(RegExp(r'[.!?]+'));
    final words = content.split(RegExp(r'\s+'));
    final avgWordsPerSentence = words.length / sentences.length;
    
    if (avgWordsPerSentence < 15) {
      return 'Beginner';
    } else if (avgWordsPerSentence < 25) {
      return 'Intermediate';
    } else {
      return 'Advanced';
    }
  }

  List<String> _extractTopics(String content) {
    // Simple topic extraction based on keywords
    final topics = <String>[];
    final text = content.toLowerCase();
    
    final topicKeywords = {
      'Islamic Governance': ['governance', 'state', 'government', 'political', 'leadership'],
      'Theology': ['theology', 'god', 'allah', 'faith', 'belief', 'religion'],
      'Social Issues': ['society', 'social', 'community', 'people', 'culture'],
      'Economics': ['economy', 'economic', 'finance', 'money', 'wealth'],
      'Education': ['education', 'learning', 'knowledge', 'teaching', 'school'],
    };
    
    for (final entry in topicKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          topics.add(entry.key);
          break;
        }
      }
    }
    
    return topics.toSet().toList();
  }

  String _analyzeSentiment(String content) {
    // Simple sentiment analysis
    final positiveWords = ['good', 'great', 'excellent', 'positive', 'beneficial', 'important', 'valuable'];
    final negativeWords = ['bad', 'wrong', 'negative', 'harmful', 'dangerous', 'problematic'];
    
    final text = content.toLowerCase();
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      positiveCount += word.allMatches(text).length;
    }
    
    for (final word in negativeWords) {
      negativeCount += word.allMatches(text).length;
    }
    
    if (positiveCount > negativeCount) {
      return 'Positive';
    } else if (negativeCount > positiveCount) {
      return 'Negative';
    } else {
      return 'Neutral';
    }
  }
} 