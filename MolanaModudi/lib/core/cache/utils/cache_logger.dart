import 'package:logging/logging.dart';

/// A logger specifically for cache operations
class CacheLogger {
  static final Logger _logger = Logger('CacheSystem');
  static bool _loggingEnabled = true;
  
  /// Set whether logging is enabled
  static void setLoggingEnabled(bool enabled) {
    _loggingEnabled = enabled;
  }
  
  /// Log an info message
  static void info(String message) {
    if (_loggingEnabled) {
      _logger.info(message);
    }
  }
  
  /// Log a warning message
  static void warning(String message) {
    if (_loggingEnabled) {
      _logger.warning(message);
    }
  }
  
  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_loggingEnabled) {
      _logger.severe(message, error, stackTrace);
    }
  }
  
  /// Log a cache hit
  static void logCacheHit(String key, String cacheType) {
    if (_loggingEnabled) {
      _logger.fine('Cache HIT [$cacheType]: $key');
    }
  }
  
  /// Log a cache miss
  static void logCacheMiss(String key, String cacheType) {
    if (_loggingEnabled) {
      _logger.fine('Cache MISS [$cacheType]: $key');
    }
  }
  
  /// Log a cache expiry
  static void logCacheExpiry(String key, String cacheType) {
    if (_loggingEnabled) {
      _logger.fine('Cache EXPIRED [$cacheType]: $key');
    }
  }
  
  /// Log a cache write
  static void logCacheWrite(String key, String cacheType, int sizeBytes) {
    if (_loggingEnabled) {
      _logger.fine('Cache WRITE [$cacheType]: $key (${_formatSize(sizeBytes)})');
    }
  }
  
  /// Log a cache eviction
  static void logCacheEviction(String key, String cacheType, String reason) {
    if (_loggingEnabled) {
      _logger.fine('Cache EVICT [$cacheType]: $key (Reason: $reason)');
    }
  }
  
  /// Format a size in bytes to a human-readable string
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
