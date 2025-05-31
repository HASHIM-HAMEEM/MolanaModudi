import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../domain/usecases/get_biography_events_usecase.dart';
import 'biography_state.dart';

class BiographyNotifier extends StateNotifier<BiographyState> {
  final GetBiographyEventsUseCase _getBiographyEventsUseCase;
  final _log = Logger('BiographyNotifier');

  BiographyNotifier(this._getBiographyEventsUseCase) : super(const BiographyState()) {
    fetchBiography(); // Fetch data on initialization
  }

  Future<void> fetchBiography() async {
    _log.info('Attempting to fetch biography data via use case...');
    state = state.copyWith(status: BiographyStatus.loading, clearError: true);
    try {
      final events = await _getBiographyEventsUseCase();
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
  final useCase = ref.watch(getBiographyEventsUseCaseProvider); // Depend on the use case provider
  return BiographyNotifier(useCase);
});