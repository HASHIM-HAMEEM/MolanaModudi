import '../../domain/entities/article_entity.dart';

/// Data model for articles that extends ArticleEntity
class ArticleModel extends ArticleEntity {
  const ArticleModel({
    required super.id,
    required super.title,
    required super.content,
    required super.summary,
    required super.author,
    required super.publishedAt,
    super.updatedAt,
    required super.category,
    super.tags = const [],
    super.imageUrl,
    required super.estimatedReadTime,
    super.status = ArticleStatus.published,
    super.priority = ArticlePriority.normal,
    super.metadata,
    super.keyInsights,
    super.aiConfidenceScore,
    super.audioUrl,
  });

  /// Create ArticleModel from Firestore document
  factory ArticleModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return ArticleModel(
      id: docId,
      title: data['title'] as String,
      content: data['content'] as String,
      summary: data['summary'] as String,
      author: data['author'] as String,
      publishedAt: DateTime.parse(data['publishedAt'] as String),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
      category: data['category'] as String,
      tags: data['tags'] != null
          ? List<String>.from(data['tags'] as List)
          : [],
      imageUrl: data['imageUrl'] as String?,
      estimatedReadTime: data['estimatedReadTime'] as int,
      status: ArticleStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ArticleStatus.published,
      ),
      priority: ArticlePriority.values.firstWhere(
        (priority) => priority.name == data['priority'],
        orElse: () => ArticlePriority.normal,
      ),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : null,
      keyInsights: data['keyInsights'] != null
          ? List<String>.from(data['keyInsights'] as List)
          : null,
      aiConfidenceScore: data['aiConfidenceScore'] as double?,
      audioUrl: data['audioUrl'] as String?,
    );
  }

  /// Create ArticleModel from JSON
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String,
      author: json['author'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      category: json['category'] as String,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      imageUrl: json['imageUrl'] as String?,
      estimatedReadTime: json['estimatedReadTime'] as int,
      status: ArticleStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ArticleStatus.published,
      ),
      priority: ArticlePriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => ArticlePriority.normal,
      ),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      keyInsights: json['keyInsights'] != null
          ? List<String>.from(json['keyInsights'] as List)
          : null,
      aiConfidenceScore: json['aiConfidenceScore'] as double?,
      audioUrl: json['audioUrl'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'author': author,
      'publishedAt': publishedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'category': category,
      'tags': tags,
      'imageUrl': imageUrl,
      'estimatedReadTime': estimatedReadTime,
      'status': status.name,
      'priority': priority.name,
      'metadata': metadata,
      'keyInsights': keyInsights,
      'aiConfidenceScore': aiConfidenceScore,
      'audioUrl': audioUrl,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'author': author,
      'publishedAt': publishedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'category': category,
      'tags': tags,
      'imageUrl': imageUrl,
      'estimatedReadTime': estimatedReadTime,
      'status': status.name,
      'priority': priority.name,
      'metadata': metadata,
      'keyInsights': keyInsights,
      'aiConfidenceScore': aiConfidenceScore,
      'audioUrl': audioUrl,
    };
  }

  /// Create a copy of this model with updated fields
  @override
  ArticleModel copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    String? author,
    DateTime? publishedAt,
    DateTime? updatedAt,
    String? category,
    List<String>? tags,
    String? imageUrl,
    int? estimatedReadTime,
    ArticleStatus? status,
    ArticlePriority? priority,
    Map<String, dynamic>? metadata,
    List<String>? keyInsights,
    double? aiConfidenceScore,
    String? audioUrl,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      estimatedReadTime: estimatedReadTime ?? this.estimatedReadTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
      keyInsights: keyInsights ?? this.keyInsights,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  /// Calculate estimated reading time based on content length
  static int calculateReadingTime(String content) {
    // Average reading speed: 200-250 words per minute
    // We'll use 200 WPM for conservative estimate
    final wordCount = content.split(RegExp(r'\s+')).length;
    final readingTimeMinutes = (wordCount / 200).ceil();
    return readingTimeMinutes < 1 ? 1 : readingTimeMinutes;
  }

  /// Extract key insights from content using simple algorithm
  /// (This would be replaced with AI processing in production)
  static List<String> extractKeyInsights(String content) {
    final sentences = content.split(RegExp(r'[.!?]+'));
    final insights = <String>[];
    
    // Simple algorithm: find sentences with key phrases
    final keyPhrases = [
      'important',
      'significant',
      'crucial',
      'essential',
      'fundamental',
      'key',
      'main',
      'primary',
      'central',
      'critical',
    ];
    
    for (final sentence in sentences) {
      if (sentence.trim().length > 50) {
        for (final phrase in keyPhrases) {
          if (sentence.toLowerCase().contains(phrase)) {
            insights.add(sentence.trim());
            break;
          }
        }
      }
      if (insights.length >= 3) break;
    }
    
    return insights;
  }

  /// Generate summary from content using simple algorithm
  /// (This would be replaced with AI processing in production)
  static String generateSummary(String content, {int maxLength = 200}) {
    final sentences = content.split(RegExp(r'[.!?]+'));
    if (sentences.isEmpty) return '';
    
    // Take first few sentences up to maxLength
    final buffer = StringBuffer();
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isNotEmpty) {
        if (buffer.length + trimmed.length + 2 <= maxLength) {
          if (buffer.isNotEmpty) buffer.write('. ');
          buffer.write(trimmed);
        } else {
          break;
        }
      }
    }
    
    String summary = buffer.toString();
    if (!summary.endsWith('.')) summary += '.';
    return summary;
  }
} 