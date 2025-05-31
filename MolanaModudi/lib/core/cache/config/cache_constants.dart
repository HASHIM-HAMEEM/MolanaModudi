/// Constants for the caching system
class CacheConstants {
  // Cache box names
  static const String metadataBoxName = 'cache_metadata';
  static const String booksBoxName = 'books_box';
  static const String volumesBoxName = 'volumes_box';
  static const String chaptersBoxName = 'chapters_cache';
  static const String headingsBoxName = 'headings_box';
  static const String contentBoxName = 'content_box';
  static const String videoMetadataBoxName = 'video_metadata_cache';
  static const String videosBoxName = 'videos_cache';
  static const String categoriesBoxName = 'categories_cache';
  static const String playlistBoxName = 'playlist_cache';
  static const String offlineQueueBoxName = 'offline_queue';
  static const String settingsBoxName = 'settings_box';
  static const String bookStructuresBoxName = 'book_structures_box';
  static const String thumbnailMetadataBoxName = 'thumbnail_metadata_box';
  static const String imageMetadataBoxName = 'image_metadata_box';
  static const String bookmarksBoxName = 'bookmarks_box';
  static const String notesBoxName = 'notes_box';
  static const String userBoxName = 'user_box';
  static const String MEMORY_CACHE_BOX = '_memory_cache_'; // For general in-memory items
  static const String offlinePinQueueBoxName = 'offline_pin_queue_box'; // For pending pin/unpin operations

  // Cache keys prefixes
  static const String bookKeyPrefix = 'book_';
  static const String volumeKeyPrefix = 'volume_';
  static const String chapterKeyPrefix = 'chapter_';
  static const String headingKeyPrefix = 'heading_';
  static const String headingContentKeyPrefix = 'headingContent_';
  static const String contentKeyPrefix = 'content_';
  static const String videoKeyPrefix = 'video_';
  static const String playlistKeyPrefix = 'playlist_';
  static const String imageKeyPrefix = 'image_';
  static const String thumbnailKeyPrefix = 'thumbnail_';
  static const String thumbnailMetadataPrefix = 'thumbnailMeta_';
  static const String imageMetadataPrefix = 'image_meta_';
  static const String bookmarkKeyPrefix = 'bookmark_';
  static const String userStatsKeyPrefix = 'user_stats_';
  static const String bookmarksKeyPrefix = 'bookmarks_';
  static const String readingProgressKeyPrefix = 'reading_progress_';
  static const String bookStructureKeyPrefix = 'structure_';
  
  // Cache specific keys
  static const String featuredBooksKey = 'featured_books';
  static const String popularBooksKey = 'popular_books';
  static const String recentBooksKey = 'recent_books';
  static const String categoriesKey = 'categories';
  static const String videoLecturesKey = 'video_lectures';

  // Cache limits
  static const int maxCacheSizeBytes = 200 * 1024 * 1024; // 200MB
  static const int maxImageCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int maxVideoCacheSizeBytes = 500 * 1024 * 1024; // 500MB
  // Hard cap for **all** Hive boxes combined (business requirement)
  static const int maxPersistentBytes = 500 * 1024 * 1024; // 500MB overall
  
  // Default TTL values for different content types
  static const Duration defaultCacheTtl = Duration(days: 7);
  static const Duration bookCacheTtl = Duration(days: 30); // Extended to 30 days for better offline access
  static const Duration volumeCacheTtl = Duration(days: 30); // Volumes have same TTL as books
  static const Duration chapterCacheTtl = Duration(days: 30); // Chapters have same TTL as books
  static const Duration videoCacheTtl = Duration(days: 14);
  static const Duration imageCacheTtl = Duration(days: 30);
  static const Duration thumbnailCacheTtl = Duration(days: 14); // Thumbnails can expire sooner than full images
  static const Duration metadataCacheTtl = Duration(days: 1);
  static const Duration homepageCacheTtl = Duration(days: 3); // Homepage data refreshes more often

  // Network timeouts
  static const Duration networkTimeoutDuration = Duration(seconds: 15);
  
  // Background sync intervals
  static const Duration syncInterval = Duration(hours: 24);

  // Private constructor to prevent instantiation
  CacheConstants._();
}
