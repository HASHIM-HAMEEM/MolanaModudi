import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import repository providers from their respective locations
import '../../../features/biography/data/repositories/biography_repository_impl.dart';
import '../../../core/providers/books_providers.dart';
import '../../../core/services/gemini_service.dart';
import '../../../features/videos/presentation/providers/video_provider.dart';
import '../data/datasources/search_data_source.dart';
import '../data/repositories/search_repository_impl.dart';
import '../domain/repositories/search_repository.dart';
import '../domain/usecases/search_use_case.dart';

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Provider for VideoProvider
final videoProviderInstance = Provider<VideoProvider>((ref) {
  return VideoProvider();
});

/// Provider for SearchDataSource
final searchDataSourceProvider = Provider<SearchDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final bookRepository = ref.watch(booksRepositoryProvider);
  final videoProvider = ref.watch(videoProviderInstance);
  final biographyRepository = ref.watch(biographyRepositoryProvider);
  final geminiService = ref.watch(geminiServiceProvider);
  
  return SearchDataSourceImpl(
    prefs: prefs,
    bookRepository: bookRepository,
    videoRepository: videoProvider,
    biographyRepository: biographyRepository,
    geminiService: geminiService,
  );
});

/// Provider for SearchRepository
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dataSource = ref.watch(searchDataSourceProvider);
  return SearchRepositoryImpl(dataSource);
});

/// Provider for SearchUseCase
final searchUseCaseProvider = Provider<SearchUseCase>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SearchUseCase(repository);
});
