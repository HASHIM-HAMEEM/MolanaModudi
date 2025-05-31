import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A stub implementation of CacheService to support caching functionality in the app.
/// TODO: Implement actual caching logic appropriate for your app's persistence mechanism.
class CacheService {
  Future<void> prefetchUrls(List<String> urls) async {
    // TODO: Implement URL prefetching logic
    return;
  }

  Future<void> putRaw({required String key, required String boxName, required dynamic value}) async {
    // TODO: Implement raw data storage logic
    return;
  }
}

/// Provider for CacheService.
final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());
