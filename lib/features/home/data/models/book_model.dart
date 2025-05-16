import 'package:modudi/features/home/domain/entities/book_entity.dart';

/// Model class for parsing book data from the API.
class BookModel extends BookEntity {
  const BookModel({
    required super.id,
    required super.title,
    super.creator,
    super.coverUrl,
    super.category,
    super.year,
    super.languages,
    super.language,
    super.metadata,
  });

  /// Factory constructor to convert API JSON to BookModel
  factory BookModel.fromJson(Map<String, dynamic> json) {
    // Helper for safely extracting string values
    String safeString(String key) => json[key] is String ? json[key] as String : '';
    
    // Helper for safely extracting list of strings
    List<String> safeStringList(String key) {
      if (json[key] == null) return [];
      if (json[key] is String) return [json[key] as String];
      if (json[key] is List) {
        return (json[key] as List)
            .map((item) => item.toString())
            .toList();
      }
      return [];
    }
    
    // Extract the necessary data
    final identifier = safeString('identifier');
    final title = safeString('title');
    final creator = json['creator'] != null ? safeString('creator') : null;
    
    // Generate cover URL from identifier
    String? coverUrl;
    if (identifier.isNotEmpty) {
      coverUrl = 'https://archive.org/services/get-item-image.php?identifier=$identifier';
    }
    
    // Extract languages
    final languages = safeStringList('language');
    
    // Extract publication year
    final year = json['date'] != null ? safeString('date') : null;
    
    // Map category
    final String collection = json['collection'] is List
        ? (json['collection'] as List).join(', ')
        : json['collection']?.toString() ?? '';
    
    final subjects = safeStringList('subject');
    final category = _mapCategory(collection, subjects);
    
    // Create metadata map with original API fields for reference
    Map<String, dynamic> metadata = {};
    // Include interesting metadata fields
    final viewsRaw = json['views'];
    final views = viewsRaw is int ? viewsRaw : 0;
    metadata['views'] = views;
    
    // Add downloads if available
    final downloadsRaw = json['downloads'];
    if (downloadsRaw != null && downloadsRaw is int) {
      metadata['downloads'] = downloadsRaw;
    }
    
    // Add favorites if available 
    final favoritesRaw = json['favorites'];
    if (favoritesRaw != null && favoritesRaw is int) {
      metadata['favorites'] = favoritesRaw;
    }
    
    return BookModel(
      id: identifier,
      title: title,
      creator: creator,
      coverUrl: coverUrl,
      category: category,
      year: year,
      languages: languages.isNotEmpty ? languages : null,
      language: languages.isNotEmpty ? languages.first : null, // Maintain for backwards compatibility
      metadata: metadata,
    );
  }
  
  /// Categorizes the book based on collection and subject information
  static String _mapCategory(String collection, List<String> subjects) {
    // Priority categories to look for in subject or collection
    final keywords = {
      'tafsir': ['tafsir', 'quran', 'commentary', 'exegesis'],
      'islamic_law': ['islamic law', 'fiqh', 'shariah', 'shari\'ah', 'sharia', 'legal'],
      'biography': ['biography', 'seerah', 'sirah', 'life of'],
      'political_thought': ['politics', 'political', 'state', 'democracy', 'government', 'khilafat'],
      'islamic_studies': ['islamic studies', 'islam and', 'islamic', 'religion'],
    };
    
    // Check subjects first (more specific)
    final subjectText = subjects.join(' ').toLowerCase();
    for (final entry in keywords.entries) {
      for (final keyword in entry.value) {
        if (subjectText.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    // Then check collection (more general)
    final collectionLower = collection.toLowerCase();
    for (final entry in keywords.entries) {
      for (final keyword in entry.value) {
        if (collectionLower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    // Default category
    return 'general';
  }
  
  /// Serializes the model to JSON (useful for caching)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'creator': creator,
      'coverUrl': coverUrl,
      'category': category,
      'year': year,
      'languages': languages,
      'language': language,
      'metadata': metadata,
    };
  }
  
  /// Creates a copy of this BookModel with the given fields replaced with the new values.
  @override
  BookModel copyWith({
    String? id,
    String? title,
    String? creator,
    String? coverUrl,
    String? category,
    String? year,
    List<String>? languages,
    String? language,
    Map<String, dynamic>? metadata,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      year: year ?? this.year,
      languages: languages ?? this.languages,
      language: language ?? this.language,
      metadata: metadata,
    );
  }
}
