import '../entities/biography_event_entity.dart';

/// Abstract repository for fetching biography data.
abstract class BiographyRepository {
  /// Fetches the list of biography events.
  Future<List<BiographyEventEntity>> getBiographyEvents();
} 