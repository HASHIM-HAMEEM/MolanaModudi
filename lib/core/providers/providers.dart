import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/cache/cache_service.dart';

/// Central provider for the CacheService to be used across the app
final cacheServiceProvider = FutureProvider<CacheService>((ref) async {
  final cacheService = CacheService();
  await cacheService.initialize();
  return cacheService;
});
