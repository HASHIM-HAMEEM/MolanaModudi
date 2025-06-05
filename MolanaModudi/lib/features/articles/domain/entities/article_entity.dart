import 'package:equatable/equatable.dart';

/// Represents an article entity in the domain layer
class ArticleEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final String summary;
  final String author;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final String category;
  final List<String> tags;
  final String? imageUrl;
  final int estimatedReadTime; // in minutes
  final ArticleStatus status;
  final ArticlePriority priority;
  final Map<String, dynamic>? metadata;
  final List<String>? keyInsights; // AI-generated key points
  final double? aiConfidenceScore; // AI confidence in content accuracy
  final String? audioUrl; // AI-generated audio version
  
  const ArticleEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.author,
    required this.publishedAt,
    this.updatedAt,
    required this.category,
    this.tags = const [],
    this.imageUrl,
    required this.estimatedReadTime,
    this.status = ArticleStatus.published,
    this.priority = ArticlePriority.normal,
    this.metadata,
    this.keyInsights,
    this.aiConfidenceScore,
    this.audioUrl,
  });

  /// Create a copy with updated fields
  ArticleEntity copyWith({
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
    return ArticleEntity(
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

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        summary,
        author,
        publishedAt,
        updatedAt,
        category,
        tags,
        imageUrl,
        estimatedReadTime,
        status,
        priority,
        metadata,
        keyInsights,
        aiConfidenceScore,
        audioUrl,
      ];
}

/// Article publication status
enum ArticleStatus {
  draft,
  published,
  archived,
  featured,
}

/// Article priority for sorting
enum ArticlePriority {
  low,
  normal,
  high,
  urgent,
}

/// Extension methods for ArticleStatus
extension ArticleStatusExtension on ArticleStatus {
  String get displayName {
    switch (this) {
      case ArticleStatus.draft:
        return 'Draft';
      case ArticleStatus.published:
        return 'Published';
      case ArticleStatus.archived:
        return 'Archived';
      case ArticleStatus.featured:
        return 'Featured';
    }
  }

  bool get isPublic {
    return this == ArticleStatus.published || this == ArticleStatus.featured;
  }
}

/// Extension methods for ArticlePriority
extension ArticlePriorityExtension on ArticlePriority {
  String get displayName {
    switch (this) {
      case ArticlePriority.low:
        return 'Low';
      case ArticlePriority.normal:
        return 'Normal';
      case ArticlePriority.high:
        return 'High';
      case ArticlePriority.urgent:
        return 'Urgent';
    }
  }

  int get sortOrder {
    switch (this) {
      case ArticlePriority.urgent:
        return 4;
      case ArticlePriority.high:
        return 3;
      case ArticlePriority.normal:
        return 2;
      case ArticlePriority.low:
        return 1;
    }
  }
} 