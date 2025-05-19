import 'cache_metadata.dart';

/// Represents the source of the data in a CacheResult
enum CacheResultSource {
  /// Data was retrieved from cache
  cache,
  
  /// Data was retrieved from network
  network,
  
  /// Data was retrieved from cache but is currently being refreshed
  cacheRefreshing,
  
  /// No data was available
  notFound,
  
  /// An error occurred while retrieving data
  error,
}

/// Represents the result of a cache operation
class CacheResult<T> {
  /// The data retrieved
  final T? data;
  
  /// The source of the data
  final CacheResultSource source;
  
  /// Whether this was a cache hit
  final bool isCacheHit;
  
  /// Any error that occurred
  final Object? error;
  
  /// Metadata about the cache entry
  final CacheMetadata? metadata;
  
  /// Creates a new CacheResult instance
  const CacheResult({
    this.data,
    required this.source,
    required this.isCacheHit,
    this.error,
    this.metadata,
  });
  
  /// Create a result representing data from cache
  static CacheResult<T> fromCache<T>(T data, CacheMetadata metadata) {
    return CacheResult<T>(
      data: data,
      source: CacheResultSource.cache,
      isCacheHit: true,
      metadata: metadata,
    );
  }
  
  /// Create a result representing data from network
  static CacheResult<T> fromNetwork<T>(T data) {
    return CacheResult<T>(
      data: data,
      source: CacheResultSource.network,
      isCacheHit: false,
    );
  }
  
  /// Create a result representing a stale cache hit that's being refreshed
  static CacheResult<T> fromCacheRefreshing<T>(T data, CacheMetadata metadata) {
    return CacheResult<T>(
      data: data,
      source: CacheResultSource.cacheRefreshing,
      isCacheHit: true,
      metadata: metadata,
    );
  }
  
  /// Create a result representing a not found condition
  static CacheResult<T> notFound<T>() {
    return CacheResult<T>(
      data: null,
      source: CacheResultSource.notFound,
      isCacheHit: false,
    );
  }
  
  /// Create a result representing an error condition
  static CacheResult<T> fromError<T>(Object error) {
    return CacheResult<T>(
      data: null,
      source: CacheResultSource.error,
      isCacheHit: false,
      error: error,
    );
  }
  
  /// Whether the result has valid data
  bool get hasData => data != null;
  
  /// Whether the data is fresh (from network or non-stale cache)
  bool get isFresh => source == CacheResultSource.network || 
    (source == CacheResultSource.cache && metadata?.isExpired == false);
  
  /// Whether the result represents an error
  bool get hasError => source == CacheResultSource.error && error != null;
  
  /// Whether data was not found
  bool get isNotFound => source == CacheResultSource.notFound;
  
  /// Convert the result to a different type using a conversion function
  CacheResult<R> mapData<R>(R Function(T) convert) {
     if (data == null) {
       return CacheResult<R>(
         data: null,
         source: source,
         isCacheHit: isCacheHit,
         error: error,
         metadata: metadata,
       );
     }
     
     // Use non-null assertion since we've checked data is not null above
     return CacheResult<R>(
      data: convert(data as T),
       source: source,
       isCacheHit: isCacheHit,
       error: error,
       metadata: metadata,
     );
   }
  
  @override
  String toString() {
    return 'CacheResult{source: $source, isCacheHit: $isCacheHit, hasData: $hasData, hasError: $hasError}';
  }
}
