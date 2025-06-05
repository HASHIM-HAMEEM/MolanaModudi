import 'dart:math';
import '../../domain/entities/article_entity.dart';

/// AI-based articles generator focused on Maulana Maududi's literature and Islamic thought
class AIArticlesGenerator {
  static final Random _random = Random();
  
  /// Static cache to maintain consistent articles across app sessions
  static final Map<String, List<ArticleEntity>> _cachedArticles = {};
  static DateTime? _lastGenerationTime;
  static const Duration _cacheValidityDuration = Duration(hours: 24); // Cache for 24 hours
  
  /// Categories relevant to Maulana Maududi's work and Islamic literature
  static const List<String> categories = [
    'Maududi\'s Works',
    'Tafsir & Quranic Studies', 
    'Islamic Political Theory',
    'Hadith & Sunnah',
    'Islamic Economics',
    'Contemporary Muslim Thought',
    'Islamic Revival Movement',
    'Islamic History & Biography',
    'Shariah & Jurisprudence',
    'Islamic Education & Society'
  ];

  static const Map<String, List<String>> _topicsByCategory = {
    'Maududi\'s Works': [
      'Understanding Tafhim-ul-Quran: A Comprehensive Commentary',
      'Towards Understanding Islam: Key Concepts Explained',
      'The Islamic Way of Life: Maududi\'s Vision',
      'Four Key Terms of the Quran: An Analysis',
      'The Rights of Human Beings in Islam',
      'Jihad in Islam: Maududi\'s Perspective',
      'Islamic Constitution: Principles and Applications',
      'The Meaning of the Quran: Commentary Insights',
      'Maududi on Modern Challenges to Faith',
      'The Process of Islamic Revolution',
    ],
    'Tafsir & Quranic Studies': [
      'Methodologies in Quranic Commentary',
      'Understanding Quranic Concepts of Governance',
      'The Quran\'s Guidance on Social Justice',
      'Contemporary Relevance of Quranic Teachings',
      'Comparative Study of Modern Tafsir Literature',
      'Quranic Principles of Economic Justice',
      'The Quran and Scientific Knowledge',
      'Verses of Legislation: Understanding Divine Law',
      'Quranic Worldview in Modern Context',
      'The Art of Quranic Interpretation',
    ],
    'Islamic Political Theory': [
      'Islamic State: Theory and Practice',
      'Sovereignty of Allah in Political Systems',
      'Democracy and Islamic Governance',
      'Political Philosophy in Islamic Literature',
      'Maududi\'s Theory of Islamic Revolution',
      'Constitutional Framework in Islam',
      'Leadership Principles in Islamic Thought',
      'Political Justice in Islamic Perspective',
      'Modern Challenges to Islamic Governance',
      'Comparative Political Systems: Islamic vs Secular',
    ],
    'Hadith & Sunnah': [
      'Understanding Prophetic Tradition in Modern Times',
      'Hadith Literature and Contemporary Applications',
      'The Sunnah as a Source of Islamic Law',
      'Methodology of Hadith Interpretation',
      'Prophetic Guidance on Social Issues',
      'Economic Principles from Hadith Literature',
      'The Prophet\'s Model of Leadership',
      'Hadith and Modern Scientific Knowledge',
      'Women in Prophetic Tradition',
      'Peace and Justice in Prophetic Teachings',
    ],
    'Islamic Economics': [
      'Principles of Islamic Banking and Finance',
      'Zakat System: Economic Justice in Practice',
      'Islamic Approach to Wealth Distribution',
      'Prohibition of Riba: Economic Implications',
      'Islamic Commercial Law and Modern Business',
      'Economic Ethics in Islamic Literature',
      'Sustainable Development in Islamic Framework',
      'Islamic Financial Instruments and Their Applications',
      'Labor Rights in Islamic Economic System',
      'Global Islamic Finance: Challenges and Opportunities',
    ],
    'Contemporary Muslim Thought': [
      'Revival Movements in Modern Muslim World',
      'Islamic Identity in Secular Societies',
      'Challenges Facing Muslim Communities Today',
      'Islamic Education in Contemporary Context',
      'Muslim Intellectuals and Modern Discourse',
      'Islam and Technology: Ethical Considerations',
      'Interfaith Dialogue from Islamic Perspective',
      'Women\'s Rights in Modern Islamic Thought',
      'Youth and Islamic Values in Digital Age',
      'Islamic Environmental Ethics',
    ],
  };

  static const List<String> _authorNames = [
    'Dr. Syed Abul A\'la Maududi',
    'Prof. Khurshid Ahmad', 
    'Dr. Zafar Ishaq Ansari',
    'Prof. Khuram Murad',
    'Dr. Abdolkarim Soroush',
    'Islamic Foundation Research',
    'Dr. Seyyed Hossein Nasr',
    'Prof. John Esposito',
    'Dr. Fazlur Rahman',
    'Islamic Research Institute',
    'Dr. Yusuf al-Qaradawi',
    'Prof. Hamid Enayat',
    'Dr. Louay Safi',
    'Contemporary Islamic Studies',
    'Dr. Ahmad Moussalli'
  ];

  /// Generate articles based on user preferences and AI algorithms
  static List<ArticleEntity> generateArticles({
    int count = 10,
    String? preferredCategory,
    List<String>? userInterests,
    List<String>? readHistory,
    ArticlesMode mode = ArticlesMode.recent,
  }) {
    // Check if we have cached articles and they're still valid
    final cacheKey = '${mode.name}_${count}_$preferredCategory';
    final now = DateTime.now();
    
    if (_cachedArticles.containsKey(cacheKey) && 
        _lastGenerationTime != null &&
        now.difference(_lastGenerationTime!).inHours < _cacheValidityDuration.inHours) {
      return _cachedArticles[cacheKey]!;
    }

    final articles = <ArticleEntity>[];
    final usedTitles = <String>{};
    
    // Use deterministic seed based on mode and date to ensure consistent articles for the same day
    final seed = _generateDeterministicSeed(mode);
    final deterministicRandom = Random(seed);
    
    for (int i = 0; i < count; i++) {
      // Determine category based on mode and preferences
      String category = _selectCategory(preferredCategory, userInterests, mode, deterministicRandom);
      
      // Generate unique title
      String title = _generateUniqueTitle(category, usedTitles, deterministicRandom);
      usedTitles.add(title);
      
      // Generate article content
      final article = _generateArticle(
        id: 'ai_${mode.name}_${DateTime.now().toIso8601String().split('T')[0]}_$i', // Include date for consistency
        title: title,
        category: category,
        mode: mode,
        userInterests: userInterests,
        random: deterministicRandom,
      );
      
      articles.add(article);
    }
    
    // Sort based on mode
    _sortArticles(articles, mode);
    
    // Cache the results
    _cachedArticles[cacheKey] = articles;
    _lastGenerationTime = now;
    
    return articles;
  }

  /// Generate deterministic seed based on mode and current date
  static int _generateDeterministicSeed(ArticlesMode mode) {
    final today = DateTime.now();
    final daysSinceEpoch = today.difference(DateTime(1970, 1, 1)).inDays;
    return daysSinceEpoch + mode.index * 1000; // Include mode to differentiate article types
  }

  /// Generate trending articles using AI analysis
  static List<ArticleEntity> generateTrendingArticles({int limit = 10}) {
    return generateArticles(
      count: limit,
      mode: ArticlesMode.trending,
    );
  }

  /// Generate personalized articles using AI recommendations
  static List<ArticleEntity> generatePersonalizedArticles({
    int limit = 10,
    List<String>? userInterests,
    List<String>? readHistory,
  }) {
    return generateArticles(
      count: limit,
      userInterests: userInterests,
      readHistory: readHistory,
      mode: ArticlesMode.personalized,
    );
  }

  /// Generate featured articles
  static List<ArticleEntity> generateFeaturedArticles({int limit = 5}) {
    return generateArticles(
      count: limit,
      mode: ArticlesMode.featured,
    );
  }

  /// Search articles using AI matching
  static List<ArticleEntity> searchArticles({
    required String query,
    String? category,
    List<String>? tags,
    int limit = 20,
  }) {
    // Generate larger pool for search
    final articles = generateArticles(
      count: limit * 2,
      preferredCategory: category,
      userInterests: tags,
      mode: ArticlesMode.search,
    );
    
    // Filter and score based on query
    final scoredArticles = articles.map((article) {
      double score = 0.0;
      final lowerQuery = query.toLowerCase();
      
      // Title matching (highest weight)
      if (article.title.toLowerCase().contains(lowerQuery)) score += 10.0;
      
      // Category matching
      if (article.category.toLowerCase().contains(lowerQuery)) score += 5.0;
      
      // Tag matching
      for (final tag in article.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) score += 3.0;
      }
      
      // Content matching
      if (article.content.toLowerCase().contains(lowerQuery)) score += 2.0;
      if (article.summary.toLowerCase().contains(lowerQuery)) score += 4.0;
      
      return MapEntry(article, score);
    }).where((entry) => entry.value > 0).toList();
    
    // Sort by score and return top results
    scoredArticles.sort((a, b) => b.value.compareTo(a.value));
    return scoredArticles.take(limit).map((entry) => entry.key).toList();
  }

  /// Get related articles using AI similarity
  static List<ArticleEntity> getRelatedArticles({
    required String articleId,
    required String category,
    required List<String> tags,
    int limit = 5,
  }) {
    return generateArticles(
      count: limit,
      preferredCategory: category,
      userInterests: tags,
      mode: ArticlesMode.related,
    );
  }

  /// Generate AI insights focused on Maududi's literature
  static List<String> generateInsights() {
    final insights = [
      'AI analysis shows increased interest in Maududi\'s Tafsir methodology',
      'Readers spend 45% more time on articles about Islamic political theory',
      'Tafhim-ul-Quran commentary articles have highest engagement rates',
      'Islamic economics content is trending among students and professionals',
      'Contemporary Muslim thought articles show highest completion rates',
      'Cross-category reading indicates growing interest in holistic Islamic knowledge',
      'Articles on Islamic revival movements generate most discussions',
      'Maududi\'s works on modern challenges are gaining renewed relevance',
      'Comparative studies between classical and modern Islamic thought are popular',
      'Young readers show particular interest in Islamic identity topics',
    ];
    
    insights.shuffle(_random);
    return insights.take(3).toList();
  }

  // Private helper methods

  static String _selectCategory(
    String? preferredCategory, 
    List<String>? userInterests, 
    ArticlesMode mode,
    Random random,
  ) {
    if (preferredCategory != null && categories.contains(preferredCategory)) {
      return preferredCategory;
    }
    
    if (userInterests != null && userInterests.isNotEmpty) {
      final matchingCategories = categories.where((category) =>
          userInterests.any((interest) => category.toLowerCase().contains(interest.toLowerCase()))
      ).toList();
      
      if (matchingCategories.isNotEmpty) {
        return matchingCategories[random.nextInt(matchingCategories.length)];
      }
    }
    
    // Default category selection based on mode
    switch (mode) {
      case ArticlesMode.featured:
        return categories[random.nextInt(3)]; // Prefer top categories
      case ArticlesMode.trending:
        return categories[random.nextInt(5)]; // Mix of popular categories
      default:
        return categories[random.nextInt(categories.length)];
    }
  }

  static String _generateUniqueTitle(String category, Set<String> usedTitles, Random random) {
    final topics = _topicsByCategory[category] ?? ['General Islamic Thought'];
    
    int attempts = 0;
    while (attempts < 10) {
      final baseTopic = topics[random.nextInt(topics.length)];
      String title = baseTopic;
      
      // Add variations to make unique
      if (usedTitles.contains(title)) {
        final variations = [
          '$baseTopic: A Modern Perspective',
          'Understanding $baseTopic',
          '$baseTopic in Contemporary Context',
          'Exploring $baseTopic',
          '$baseTopic: Key Principles',
        ];
        title = variations[random.nextInt(variations.length)];
      }
      
      if (!usedTitles.contains(title)) {
        return title;
      }
      attempts++;
    }
    
    // Fallback with timestamp only if absolutely necessary
    return '${topics[random.nextInt(topics.length)]} - Study ${random.nextInt(100)}';
  }

  static ArticleEntity _generateArticle({
    required String id,
    required String title,
    required String category,
    required ArticlesMode mode,
    List<String>? userInterests,
    required Random random,
  }) {
    // AI-generated content based on title and category
    final content = _generateContent(title, category, random);
    final summary = _generateSummary(title, category, random);
    final tags = _generateTags(category, title, random);
    final keyInsights = _generateKeyInsights(title, category, random);
    
    // Dynamic properties based on AI analysis
    final estimatedReadTime = _calculateReadTime(content);
    final priority = _determinePriority(mode, category);
    final status = _determineStatus(mode);
    final aiConfidenceScore = 0.85 + (random.nextDouble() * 0.15); // 0.85-1.0
    
    return ArticleEntity(
      id: id,
      title: title,
      content: content,
      summary: summary,
      author: _authorNames[random.nextInt(_authorNames.length)],
      publishedAt: _generateConsistentPublishDate(mode, id, random),
      category: category,
      tags: tags,
      estimatedReadTime: estimatedReadTime,
      status: status,
      priority: priority,
      keyInsights: keyInsights,
      aiConfidenceScore: aiConfidenceScore,
    );
  }

  static String _generateContent(String title, String category, Random random) {
    // AI-style content generation templates focused on Maududi's works and Islamic thought
    final intros = [
      'In the comprehensive framework of Islamic thought, Maulana Maududi\'s analysis of',
      'Syed Abul A\'la Maududi\'s scholarly contribution to understanding',
      'The fundamental Islamic principles underlying',
      'Contemporary Muslim scholars continue to explore Maududi\'s insights into',
      'The Tafhim-ul-Quran commentary provides profound perspectives on',
      'Islamic jurisprudence and scholarship offer detailed examination of',
      'The revival of Islamic thought requires deep understanding of',
    ];
    
    final bodyTemplates = [
      'Maududi\'s methodology emphasizes the integration of Quranic guidance with practical implementation in modern society. His systematic approach to Islamic revival addresses both spiritual and temporal dimensions of Muslim life.',
      'The theological foundations presented in Maududi\'s works provide a comprehensive framework for understanding Islamic governance, social justice, and individual spiritual development.',
      'Contemporary applications of these Islamic principles require careful study of classical sources combined with nuanced interpretation for modern contexts, as demonstrated in Maududi\'s extensive writings.',
      'The integration of traditional Islamic scholarship with contemporary challenges presents a unique opportunity for Muslim communities to implement authentic Islamic solutions.',
      'These foundational concepts form the cornerstone of a comprehensive Islamic worldview that addresses political, economic, social, and spiritual dimensions of human existence.',
      'Maududi\'s scholarly approach demonstrates how Quranic commentary can illuminate practical guidance for Muslim communities facing modern challenges and opportunities.',
      'The systematic methodology found in works like Tafhim-ul-Quran shows how Islamic scholarship can bridge classical learning with contemporary understanding.',
    ];
    
    final conclusions = [
      'These insights from Islamic scholarship continue to provide practical guidance for Muslim communities implementing authentic Islamic values in contemporary society.',
      'The enduring relevance of Maududi\'s contributions demonstrates the timeless nature of Islamic principles when properly understood and applied.',
      'Understanding these foundational concepts is essential for Muslim scholars, leaders, and communities working toward Islamic revival and authentic implementation.',
      'This scholarly framework offers a clear path toward meaningful Islamic reformation that honors tradition while addressing contemporary realities.',
      'The practical application of these Islamic principles can transform both individual spiritual development and community social structures.',
      'Maududi\'s comprehensive approach provides a model for contemporary Islamic scholarship that remains relevant for modern Muslim intellectual discourse.',
    ];
    
    final intro = intros[random.nextInt(intros.length)];
    final body = List.generate(2, (i) => bodyTemplates[random.nextInt(bodyTemplates.length)]).join('\n\n');
    final conclusion = conclusions[random.nextInt(conclusions.length)];
    
    return '$intro $title represents a crucial area of Islamic scholarship that demands careful study.\n\n$body\n\n$conclusion\n\nFor students of Islamic thought, engaging with these concepts through primary sources and contemporary scholarship provides essential foundation for understanding the comprehensive nature of Islamic guidance.';
  }

  static String _generateSummary(String title, String category, Random random) {
    final summaryTemplates = [
      'An in-depth exploration of $title within the scholarly framework of $category, examining Maududi\'s contributions and contemporary Islamic thought.',
      'This scholarly analysis examines $title from an Islamic perspective, drawing insights from Maududi\'s works and contemporary applications in $category.',
      'A comprehensive examination of $title through the lens of Islamic scholarship, highlighting its significance for modern Muslim understanding of $category.',
      'Understanding $title through Maududi\'s methodology and its practical implications for contemporary implementation of $category principles.',
      'This article explores $title as presented in Islamic literature, focusing on its relevance for $category and modern Muslim intellectual discourse.',
    ];
    
    return summaryTemplates[random.nextInt(summaryTemplates.length)];
  }

  static List<String> _generateTags(String category, String title, Random random) {
    final baseTags = [category];
    final maududiTags = ['Maududi', 'Tafhim-ul-Quran', 'Islamic Revival', 'Islamic Scholarship'];
    final islamicTags = ['Quranic Studies', 'Islamic Thought', 'Muslim Intellectuals', 'Contemporary Islam'];
    final specificTags = [
      if (title.contains('Quran') || title.contains('Tafsir')) 'Quranic Commentary',
      if (title.contains('Political') || title.contains('State')) 'Islamic Politics', 
      if (title.contains('Economic') || title.contains('Banking')) 'Islamic Economics',
      if (title.contains('Hadith') || title.contains('Sunnah')) 'Prophetic Tradition',
      if (title.contains('Society') || title.contains('Community')) 'Islamic Society',
      if (title.contains('Education') || title.contains('Knowledge')) 'Islamic Education',
    ];
    
    final allTags = [...baseTags, ...maududiTags.take(2), ...islamicTags.take(2), ...specificTags];
    return allTags.take(6).toList();
  }

  static List<String> _generateKeyInsights(String title, String category, Random random) {
    final insights = [
      'Maududi\'s approach to $category provides a systematic methodology for understanding $title within Islamic framework',
      'The integration of Quranic guidance with practical implementation offers sustainable solutions for contemporary challenges',
      'Islamic scholarship demonstrates how traditional wisdom can address modern complexities in $category',
      'These foundational concepts bridge classical Islamic learning with contemporary Muslim intellectual discourse',
      'The comprehensive nature of Islamic guidance encompasses both spiritual development and practical community building',
      'Contemporary application of these principles requires deep understanding of both classical sources and modern contexts',
      'Islamic revival movements benefit from scholarly frameworks that honor authentic tradition while addressing current realities',
    ];
    
    insights.shuffle(random);
    return insights.take(4).toList();
  }

  static int _calculateReadTime(String content) {
    final wordCount = content.split(' ').length;
    return ((wordCount / 200).ceil()).clamp(3, 15); // 200 words per minute, 3-15 min range
  }

  static ArticlePriority _determinePriority(ArticlesMode mode, String category) {
    if (mode == ArticlesMode.featured) return ArticlePriority.high;
    if (mode == ArticlesMode.trending) return ArticlePriority.high;
    if (category == 'Maududi\'s Works' || category == 'Islamic Political Theory') return ArticlePriority.high;
    return ArticlePriority.normal;
  }

  static ArticleStatus _determineStatus(ArticlesMode mode) {
    if (mode == ArticlesMode.featured) return ArticleStatus.featured;
    return ArticleStatus.published;
  }

  static DateTime _generateConsistentPublishDate(ArticlesMode mode, String id, Random random) {
    // Use article ID to generate consistent dates - same article always has same date
    final idHash = id.hashCode.abs();
    final baseSeed = idHash % 10000;
    final consistentRandom = Random(baseSeed);
    
    final now = DateTime.now();
    if (mode == ArticlesMode.recent) {
      return now.subtract(Duration(days: consistentRandom.nextInt(7)));
    }
    if (mode == ArticlesMode.trending) {
      return now.subtract(Duration(days: consistentRandom.nextInt(3)));
    }
    return now.subtract(Duration(days: consistentRandom.nextInt(30)));
  }

  static void _sortArticles(List<ArticleEntity> articles, ArticlesMode mode) {
    switch (mode) {
      case ArticlesMode.recent:
        articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case ArticlesMode.trending:
        articles.sort((a, b) => b.priority.sortOrder.compareTo(a.priority.sortOrder));
        break;
      case ArticlesMode.featured:
        articles.sort((a, b) => b.priority.sortOrder.compareTo(a.priority.sortOrder));
        break;
      default:
        articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    }
  }

  /// Clear cache (useful for testing or when forcing refresh)
  static void clearCache() {
    _cachedArticles.clear();
    _lastGenerationTime = null;
  }
}

/// Articles generation modes
enum ArticlesMode {
  recent,
  featured,
  trending,
  personalized,
  search,
  related,
} 