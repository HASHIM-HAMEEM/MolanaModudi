import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/providers/providers.dart';
import 'package:modudi/core/services/gemini_service.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import 'repositories/reading_repository_impl.dart';

/// Provides an instance of [ReadingRepository] backed by [ReadingRepositoryImpl].
final readingRepositoryProvider = FutureProvider<ReadingRepository>((ref) async {
  final GeminiService geminiService = ref.watch(geminiServiceProvider);
  final CacheService cacheService = await ref.watch(cacheServiceProvider.future);
  return ReadingRepositoryImpl(
    geminiService: geminiService,
    cacheService: cacheService,
  );
});
