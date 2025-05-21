import 'cache_constants.dart';

/// Defines the cache policy to use for data fetching
enum CachePolicy {
  /// Try network first, fall back to cache if network fails
  networkFirst,
  
  /// Try cache first, fetch from network only if cache misses or is stale
  cacheFirst,
  
  /// Only fetch from network, don't use cache
  networkOnly,
  
  /// Only use cache, don't fetch from network (offline mode)
  cacheOnly,
  
  /// Use cache immediately (regardless of staleness) but update cache in background
  staleWhileRevalidate,
}

/// Configuration for the caching system
class CacheConfig {
  /// Default cache policy when not explicitly provided
  final CachePolicy defaultPolicy;
  
  /// Maximum cache size in bytes
  final int maxCacheSize;
  
  /// Default time-to-live for cached items
  final Duration defaultTtl;
  
  /// Whether to enable logging of cache operations
  final bool enableLogging;
  
  /// Whether to automatically clear stale cache entries on app start
  final bool autoClearStaleOnStart;
  
  /// Whether to perform background synchronization for cached data
  final bool enableBackgroundSync;
  
  /// Whether to enable cache analytics
  final bool enableAnalytics;
  
  /// Whether to track detailed cache metrics like hit/miss rates
  final bool trackCacheMetrics;
  
  /// Whether to report cache analytics to a monitoring service
  final bool reportCacheAnalytics;
  
  /// Whether to preload common assets
  final bool enablePreloading;
  
  /// Whether to compress cache entries
  final bool enableCompression;
  
  /// Whether to cache content for offline use
  final bool enableOfflineMode;
  
  /// Duration between cache analytics reports
  final Duration analyticsReportInterval;

  /// Creates a new CacheConfig instance
  const CacheConfig({
    this.defaultPolicy = CachePolicy.cacheFirst,
    this.maxCacheSize = CacheConstants.maxCacheSizeBytes,
    this.defaultTtl = CacheConstants.defaultCacheTtl,
    this.enableLogging = true,
    this.autoClearStaleOnStart = true,
    this.enableBackgroundSync = true,
    this.enableAnalytics = false,
    this.trackCacheMetrics = false,
    this.reportCacheAnalytics = false,
    this.enablePreloading = true,
    this.enableCompression = true,
    this.enableOfflineMode = true,
    this.analyticsReportInterval = const Duration(hours: 24),
  });
  
  /// Default configuration
  static const CacheConfig defaultConfig = CacheConfig();
  
  /// Configuration for low-end devices
  static const CacheConfig lowEndConfig = CacheConfig(
    maxCacheSize: 50 * 1024 * 1024, // 50MB
    enableBackgroundSync: false,
    enableAnalytics: false,
    enablePreloading: false,
    enableCompression: false,
  );
  
  /// Configuration for offline-focused usage
  static const CacheConfig offlineFocusedConfig = CacheConfig(
    defaultPolicy: CachePolicy.cacheFirst,
    maxCacheSize: 500 * 1024 * 1024, // 500MB
    defaultTtl: Duration(days: 60),
    enableBackgroundSync: true,
    enablePreloading: true,
    enableOfflineMode: true,
  );
  
  /// Creates a new CacheConfig with updated values
  CacheConfig copyWith({
    CachePolicy? defaultPolicy,
    int? maxCacheSize,
    Duration? defaultTtl,
    bool? enableLogging,
    bool? autoClearStaleOnStart,
    bool? enableBackgroundSync, 
    bool? enableAnalytics,
    bool? enablePreloading,
    bool? enableCompression,
    bool? enableOfflineMode,
  }) {
    return CacheConfig(
      defaultPolicy: defaultPolicy ?? this.defaultPolicy,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      defaultTtl: defaultTtl ?? this.defaultTtl,
      enableLogging: enableLogging ?? this.enableLogging,
      autoClearStaleOnStart: autoClearStaleOnStart ?? this.autoClearStaleOnStart,
      enableBackgroundSync: enableBackgroundSync ?? this.enableBackgroundSync,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enablePreloading: enablePreloading ?? this.enablePreloading,
      enableCompression: enableCompression ?? this.enableCompression,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
    );
  }
}
