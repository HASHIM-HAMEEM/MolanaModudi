import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:modudi/core/cache/config/cache_config.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

/// Central provider for the CacheService to be used across the app
final cacheServiceProvider = FutureProvider<CacheService>((ref) async {
  final cacheServiceInstance = await CacheService.init(
    config: CacheConfig.defaultConfig,
  );
  return cacheServiceInstance;
});

// Provider for the DefaultCacheManager from ImageCacheManager
final defaultCacheManagerProvider = FutureProvider<fcm.DefaultCacheManager>((ref) async {
  final cacheService = await ref.watch(cacheServiceProvider.future);
  // ImageCacheManager is initialized within CacheService, and its DefaultCacheManager is exposed via a getter
  return cacheService.defaultCacheManager;
});

// Provider for SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});
