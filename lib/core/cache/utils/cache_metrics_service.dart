import 'package:hive/hive.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';
import 'package:modudi/core/cache/utils/cache_logger.dart'; // Ensure this path is correct
import 'dart:async';
import 'package:logging/logging.dart'; // Added for Logger

class CacheMetricsService {
  // Use the existing CacheLogger if it's suitable, or a local Logger
  // For consistency with the provided existing file, let's use a local Logger.
  // If CacheLogger is preferred, replace _log assignments and calls.
  final Logger _log = Logger('CacheMetricsService');

  int totalHits = 0;
  int totalMisses = 0;
  int totalWrites = 0;
  int totalEvictions = 0;

  Box? _metricsBox;
  Timer? _saveTimer;
  bool _isInitialized = false;

  // Added trackMetrics flag similar to the original file, can be controlled by CacheService
  final bool _trackMetrics;

  CacheMetricsService({bool trackMetrics = true}) : _trackMetrics = trackMetrics;

  Future<void> initialize() async {
    if (!_trackMetrics) {
      _log.info('Cache metrics tracking is disabled. Skipping initialization.');
      _isInitialized = true; // Mark as initialized to allow other operations to proceed (as no-ops)
      return;
    }
    try {
      _metricsBox = await Hive.openBox(CacheConstants.cacheAnalyticsBoxName);
      totalHits = _metricsBox?.get('totalHits', defaultValue: 0) ?? 0;
      totalMisses = _metricsBox?.get('totalMisses', defaultValue: 0) ?? 0;
      totalWrites = _metricsBox?.get('totalWrites', defaultValue: 0) ?? 0;
      totalEvictions = _metricsBox?.get('totalEvictions', defaultValue: 0) ?? 0;
      _log.info('CacheMetricsService initialized and metrics loaded.');
    } catch (e, stackTrace) {
      _log.severe('Error initializing CacheMetricsService or loading metrics: $e', e, stackTrace);
      if (_metricsBox?.isOpen == true) {
        try {
          await _metricsBox?.close();
        } catch (closeError) {
          _log.warning('Error closing metrics box after initialization failure: $closeError');
        }
      }
      _metricsBox = null;
      // Do not set _isInitialized to true here if Hive fails,
      // so that subsequent operations know initialization failed.
      // Or, handle it gracefully in each method. For now, methods will check _trackMetrics & _metricsBox.
      return; // Stop further execution if initialization fails
    }
    _isInitialized = true;
  }

  void recordHit(String key) {
    if (!_trackMetrics || !_isInitialized) return;
    totalHits++;
    _log.info('Cache hit for key: $key. Total hits: $totalHits');
    _scheduleSaveMetrics();
  }

  void recordMiss(String key) {
    if (!_trackMetrics || !_isInitialized) return;
    totalMisses++;
    _log.info('Cache miss for key: $key. Total misses: $totalMisses');
    _scheduleSaveMetrics();
  }

  void recordWrite(String key) {
    if (!_trackMetrics || !_isInitialized) return;
    totalWrites++;
    _log.info('Cache write for key: $key. Total writes: $totalWrites');
    _scheduleSaveMetrics();
  }

  void recordEviction(String key, {String? reason}) {
    if (!_trackMetrics || !_isInitialized) return;
    totalEvictions++;
    _log.info('Cache eviction for key: $key. Reason: ${reason ?? "N/A"}. Total evictions: $totalEvictions');
    _scheduleSaveMetrics();
  }

  void recordBoxPurge(String boxName) {
    if (!_trackMetrics || !_isInitialized) return;
    _log.info('Cache box purged: $boxName');
    // Optional: Increment a specific purge counter if needed.
    // Consider if a full box purge should also trigger _saveMetrics,
    // if it implies multiple evictions not individually recorded.
    // For now, just logging as per current spec.
  }

  void _scheduleSaveMetrics() {
    if (!_trackMetrics || !_isInitialized || _metricsBox == null) return;

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 10), () { // Debounce for 10 seconds
      _saveMetrics();
    });
  }

  Future<void> _saveMetrics() async {
    if (!_trackMetrics || !_isInitialized || _metricsBox == null) {
      _log.warning('Cannot save metrics: Tracking disabled, not initialized, or box is null.');
      return;
    }

    if (!_metricsBox!.isOpen) {
      _log.warning('Metrics box is not open. Attempting to reopen...');
      try {
        _metricsBox = await Hive.openBox(CacheConstants.cacheAnalyticsBoxName);
      } catch (e, stackTrace) {
        _log.severe('Failed to reopen metrics box in _saveMetrics: $e', e, stackTrace);
        return;
      }
    }

    try {
      await _metricsBox!.put('totalHits', totalHits);
      await _metricsBox!.put('totalMisses', totalMisses);
      await _metricsBox!.put('totalWrites', totalWrites);
      await _metricsBox!.put('totalEvictions', totalEvictions);
      _log.info('Cache metrics saved successfully.');
    } catch (e, stackTrace) {
      _log.severe('Error saving cache metrics: $e', e, stackTrace);
    }
  }

  Map<String, dynamic> getMetrics() {
    if (!_trackMetrics) {
        return {
        'tracking_disabled': true,
        'totalHits': 0,
        'totalMisses': 0,
        'totalWrites': 0,
        'totalEvictions': 0,
        'hitRatio': 0.0,
      };
    }
    double hitRatio = 0.0;
    if (totalHits + totalMisses > 0) {
      hitRatio = totalHits / (totalHits + totalMisses);
    }
    return {
      'totalHits': totalHits,
      'totalMisses': totalMisses,
      'totalWrites': totalWrites,
      'totalEvictions': totalEvictions,
      'hitRatio': hitRatio,
    };
  }

  Future<void> resetMetrics() async {
    if (!_trackMetrics || !_isInitialized) return;
    totalHits = 0;
    totalMisses = 0;
    totalWrites = 0;
    totalEvictions = 0;
    _log.info('Cache metrics have been reset.');
    await _saveMetrics(); // Persist the reset state
  }

  Future<void> dispose() async {
    if (!_trackMetrics) return;
    _saveTimer?.cancel();
    if (_isInitialized && _metricsBox != null && _metricsBox!.isOpen) {
      await _saveMetrics(); // Perform a final save
      try {
        await _metricsBox!.close();
        _log.info('CacheMetricsService Hive box closed.');
      } catch (e, stackTrace) {
        _log.severe('Error closing metrics box during dispose: $e', e, stackTrace);
      }
    }
    _isInitialized = false; // Mark as not initialized
    _log.info('CacheMetricsService disposed.');
  }

  // Method from the original file, adapted.
  void logCurrentMetrics() {
    if (!_trackMetrics) return;
    final metrics = getMetrics();
    _log.info(
      'Cache Stats: Hits=${metrics['totalHits']}, Misses=${metrics['totalMisses']}, Writes=${metrics['totalWrites']}, Evictions=${metrics['totalEvictions']}, HitRate=${(metrics['hitRatio'] * 100).toStringAsFixed(1)}%'
    );
  }

  // Helper from the original file to periodically print stats, adapted.
  void printStatsIfNeeded() {
    if (!_trackMetrics) return;
    final totalOps = totalHits + totalMisses + totalWrites + totalEvictions;
    if (totalOps % 100 == 0 && totalOps > 0) { // Log every 100 operations
        logCurrentMetrics();
    }
  }
}
