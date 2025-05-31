import 'cache_metadata.dart';

/// Defines the status of cached data, primarily for UI representation and logic.
enum CacheStatus {
  /// Data is fresh, typically from a recent network fetch or a non-expired cache entry.
  fresh,

  /// Data is from an expired cache entry. It might be usable while a background refresh occurs.
  stale,

  /// Data is actively being loaded. The `CacheResult` might hold previous (stale) data during this phase.
  loading,

  /// An error occurred during fetching or retrieval. The `CacheResult` might hold previous (stale) data.
  error,

  /// No data was found (e.g., cache miss and network fetch failed or returned no data like a 404).
  missing,
}

/// Represents the result of a cache operation, indicating the status and holding the data.
class CacheResult<T> {
  /// The data retrieved. Can be null if status is `missing`, `loading` (initially), or `error`.
  final T? data;

  /// The current status of the cache result.
  final CacheStatus status;

  /// Any error that occurred, relevant if status is `error`.
  final Object? error;

  /// Metadata about the cache entry, if applicable (e.g., for `fresh` or `stale` data).
  final CacheMetadata? metadata;

  /// Creates a new CacheResult instance.
  const CacheResult({
    required this.status,
    this.data,
    this.error,
    this.metadata,
  });

  /// Creates a result for fresh data.
  static CacheResult<T> fresh<T>(T data, {CacheMetadata? metadata}) {
    return CacheResult<T>(
      status: CacheStatus.fresh,
      data: data,
      metadata: metadata,
    );
  }

  /// Creates a result for stale data.
  static CacheResult<T> stale<T>(T data, {CacheMetadata? metadata, Object? error}) {
    return CacheResult<T>(
      status: CacheStatus.stale,
      data: data,
      metadata: metadata,
      error: error,
    );
  }

  /// Creates a result indicating data is loading.
  /// Optionally, [previousData] can be provided if showing stale data while loading new data.
  static CacheResult<T> loading<T>({T? previousData, CacheMetadata? previousMetadata}) {
    return CacheResult<T>(
      status: CacheStatus.loading,
      data: previousData,
      metadata: previousMetadata,
    );
  }

  /// Creates a result for an error condition.
  /// Optionally, [previousData] can be provided if showing stale data despite the error.
  static CacheResult<T> fromError<T>(Object error, {T? previousData, CacheMetadata? previousMetadata}) {
    return CacheResult<T>(
      status: CacheStatus.error,
      error: error,
      data: previousData,
      metadata: previousMetadata,
    );
  }

  /// Creates a result indicating data is missing.
  static CacheResult<T> missing<T>({Object? error}) {
    return CacheResult<T>(
      status: CacheStatus.missing,
      error: error,
    );
  }

  /// Whether the result has valid data (not null).
  bool get hasData => data != null;

  /// Whether the data is considered fresh.
  bool get isFresh => status == CacheStatus.fresh;

  /// Whether the data is from cache (fresh or stale).
  bool get isFromCache => status == CacheStatus.fresh || status == CacheStatus.stale;

  /// Whether the result represents an error.
  bool get hasError => status == CacheStatus.error && error != null;

  /// Whether data was not found or is missing.
  bool get isMissing => status == CacheStatus.missing;

  /// Whether the data is currently loading.
  bool get isLoading => status == CacheStatus.loading;

  /// Provides a simplified UI-centric status for the cache result.
  @Deprecated('Use status field directly. This getter will be removed.')
  CacheStatus get uiStatus {
        return status;
  }
  
  /// Convert the result to a different type using a conversion function
  CacheResult<R> mapData<R>(R Function(T) convert) {
    if (data == null) {
      // If there's no data to convert, return a new CacheResult with the same status but for type R.
      return CacheResult<R>(
        status: status,
        data: null, // Explicitly null for type R
        error: error,
        metadata: metadata,
      );
    }
    // If data exists, convert it and create a new CacheResult with the converted data.
    return CacheResult<R>(
      status: status,
      data: convert(data as T),
      error: error,
      metadata: metadata,
    );
  }
  
  /// Creates a copy of this CacheResult but with the given fields replaced.
  CacheResult<T> copyWith({
    T? data,
    CacheStatus? status,
    Object? error,
    CacheMetadata? metadata,
  }) {
    return CacheResult<T>(
      data: data ?? this.data,
      status: status ?? this.status,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }
  
  @override
  String toString() {
    return 'CacheResult{status: $status, hasData: $hasData, error: $error, metadata: $metadata}';
  }
}

/// Represents an error that occurred during a cache operation.
class CacheError {
  final String message;
  final StackTrace? stackTrace;

  CacheError(this.message, [this.stackTrace]);

  @override
  String toString() {
    return 'CacheError: $message${stackTrace == null ? '' : "\n$stackTrace"}';
  }
}

/// DEPRECATED: Renamed to CacheStatus. This will be removed.
enum CacheUiStatus {
  fresh,      // Data is fresh from network or non-expired cache
  stale,      // Data is from expired cache (might be background refreshing)
  missing,    // No data found, and not an error state (e.g. cache miss, 404)
  error,      // An error occurred during fetching or retrieval
  loading     // Actively loading (usually handled by FutureBuilder/StreamBuilder, not CacheResult directly)
}
