import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/biography_event_entity.dart';
import '../repositories/biography_repository.dart';
import '../../data/repositories/enhanced_biography_repository.dart'; // To access enhancedBiographyRepositoryProvider

class GetBiographyEventsUseCase {
  final BiographyRepository _repository;

  GetBiographyEventsUseCase(this._repository);

  Future<List<BiographyEventEntity>> call() async {
    // Any specific business logic before or after fetching can go here.
    // For now, it's a direct call.
    return _repository.getBiographyEvents();
  }
}

// Provider for the GetBiographyEventsUseCase
final getBiographyEventsUseCaseProvider = Provider<GetBiographyEventsUseCase>((ref) {
  final repository = ref.watch(enhancedBiographyRepositoryProvider);
  return GetBiographyEventsUseCase(repository);
});
