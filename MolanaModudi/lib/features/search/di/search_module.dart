import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import repository providers from their respective locations
import '../../../features/biography/data/repositories/biography_repository_impl.dart';
import '../../../core/providers/books_providers.dart';
import '../../../core/services/gemini_service.dart';
import '../../../features/videos/presentation/providers/video_providers.dart';
import '../data/datasources/search_data_source.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/repositories/search_repository.dart';
import '../domain/usecases/search_use_case.dart';

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Provider for SearchDataSource
final searchDataSourceProvider = FutureProvider<SearchDataSource>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final bookRepository = await ref.watch(booksRepositoryProvider.future);
  final videoRepository = await ref.watch(videoRepositoryProvider.future);
  final biographyRepository = ref.watch(biographyRepositoryProvider);
  final geminiService = ref.watch(geminiServiceProvider);
  
  return SearchDataSourceImpl(
    prefs: prefs,
    bookRepository: bookRepository,
    videoRepository: videoRepository,
    biographyRepository: biographyRepository,
    geminiService: geminiService,
  );
});

/// Provider for SearchRepository
final searchRepositoryProvider = FutureProvider<SearchRepository>((ref) async {
  final dataSource = await ref.watch(searchDataSourceProvider.future);
  return SearchRepositoryImpl(dataSource);
});

/// Provider for SearchUseCase
final searchUseCaseProvider = FutureProvider<SearchUseCase>((ref) async {
  final repository = await ref.watch(searchRepositoryProvider.future);
  return SearchUseCase(repository);
});
