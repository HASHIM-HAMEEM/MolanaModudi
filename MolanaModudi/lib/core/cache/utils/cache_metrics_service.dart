import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CacheMetricsService {
  final Logger _log = Logger('CacheMetricsService');
  final bool _trackMetrics;

  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _writes = 0;

  CacheMetricsService({bool trackMetrics = true}) : _trackMetrics = trackMetrics;

  void recordHit(String key) {
    if (!_trackMetrics) return;
    _hits++;
    _log.fine('Cache HIT: key=$key');
    _printStatsIfNeeded();
  }

  void recordMiss(String key) {
    if (!_trackMetrics) return;
    _misses++;
    _log.fine('Cache MISS: key=$key');
    _printStatsIfNeeded();
  }

  void recordWrite(String key) {
    if (!_trackMetrics) return;
    _writes++;
    _log.fine('Cache WRITE: key=$key');
    _printStatsIfNeeded();
  }

  void recordEviction(String key, {String? reason}) {
    if (!_trackMetrics) return;
    _evictions++;
    _log.info('Cache EVICTION: key=$key${reason != null ? ', reason=$reason' : ''}');
    _printStatsIfNeeded();
  }

  void recordBoxPurge(String boxName) {
    if (!_trackMetrics) return;
    // We don't have individual keys here, so we don't increment _evictions count directly
    // as it's for key-based evictions. This is a different type of event.
    _log.info('Cache BOX PURGED: name=$boxName');
    // Consider if a separate counter for purges is needed or if hit/miss ratio is sufficient.
    // For now, just logging the event.
  }

  void resetMetrics() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _writes = 0;
    _log.info('Cache metrics reset.');
  }

  Map<String, dynamic> getMetrics() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? (_hits / totalRequests) * 100 : 0.0;
    return {
      'hits': _hits,
      'misses': _misses,
      'writes': _writes,
      'evictions': _evictions,
      'totalRequests': totalRequests,
      'hitRate': hitRate,
    };
  }

  void logCurrentMetrics() {
    if (!_trackMetrics) return;
    final metrics = getMetrics();
    _log.info(
      'Cache Stats: Hits=${metrics['hits']}, Misses=${metrics['misses']}, Writes=${metrics['writes']}, Evictions=${metrics['evictions']}, TotalRequests=${metrics['totalRequests']}, HitRate=${metrics['hitRate'].toStringAsFixed(1)}%'
    );
  }

  /// Export current metrics to CSV at the user's document directory.
  /// Returns the file path written.
  Future<String> exportCsv() async {
    try {
      final metrics = getMetrics();
      final buffer = StringBuffer()
        ..writeln('hits,misses,writes,evictions,totalRequests,hitRate')
        ..writeln('${metrics['hits']},${metrics['misses']},${metrics['writes']},${metrics['evictions']},${metrics['totalRequests']},${metrics['hitRate'].toStringAsFixed(1)}');

      // Obtain platform documents directory (path_provider)
      final directory = await getApplicationDocumentsDirectory();
      final filePath = join(directory.path, 'app_cache_metrics.csv');
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      _log.info('Cache metrics exported to $filePath');
      return filePath;
    } catch (e) {
      _log.warning('Failed to export cache metrics CSV: $e');
      rethrow;
    }
  }

  // Helper to periodically print stats, e.g., every 100 operations or so
  void _printStatsIfNeeded(){
    final totalOps = _hits + _misses + _writes + _evictions;
    if (totalOps % 100 == 0 && totalOps > 0) { // Log every 100 operations
        logCurrentMetrics();
    }
  }
}
