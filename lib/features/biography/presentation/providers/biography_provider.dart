import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../domain/repositories/biography_repository.dart';
import '../../data/repositories/biography_repository_impl.dart'; // Corrected import path
import 'biography_state.dart';

class BiographyNotifier extends StateNotifier<BiographyState> {
  final BiographyRepository _repository;
  final _log = Logger('BiographyNotifier');

  BiographyNotifier(this._repository) : super(const BiographyState()) {
    fetchBiography(); // Fetch data on initialization
  }

  Future<void> fetchBiography() async {
    _log.info('Attempting to fetch biography data...');
    state = state.copyWith(status: BiographyStatus.loading, clearError: true);
    try {
      final events = await _repository.getBiographyEvents();
      if (!mounted) return; // Check if the notifier is still mounted
      state = state.copyWith(
        status: BiographyStatus.success,
        events: events,
      );
      _log.info('Successfully fetched ${events.length} biography events.');
    } catch (e, stackTrace) {
      _log.severe('Error fetching biography: $e', e, stackTrace);
      if (!mounted) return;
      state = state.copyWith(
        status: BiographyStatus.error,
        errorMessage: e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString(),
      );
    }
  }
}

// Provider for the BiographyNotifier
final biographyNotifierProvider = StateNotifierProvider<BiographyNotifier, BiographyState>((ref) {
  final repository = ref.watch(biographyRepositoryProvider); // Depend on the repository provider
  return BiographyNotifier(repository);
}); 