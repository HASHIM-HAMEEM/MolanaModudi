import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/biography_event_entity.dart';
import '../../domain/repositories/biography_repository.dart';
import '../models/static_biography_data.dart';

class EnhancedBiographyRepository implements BiographyRepository {
  final Logger _log = Logger('EnhancedBiographyRepository');

  @override
  Future<List<BiographyEventEntity>> getBiographyEvents() async {
    _log.info('Loading static biography events...');
    
    try {
      // Simulate slight delay for consistent UX
      await Future.delayed(const Duration(milliseconds: 300));
      
      final events = StaticBiographyData.getTimelineEvents();
      _log.info('Successfully loaded ${events.length} biography events from static data.');
      
      return events;
    } catch (e, stackTrace) {
      _log.severe('Error loading static biography events: $e', e, stackTrace);
      throw Exception('Failed to load biography data: $e');
    }
  }
}

// Provider for the Enhanced Biography Repository
final enhancedBiographyRepositoryProvider = Provider<BiographyRepository>((ref) {
  return EnhancedBiographyRepository();
}); 