import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

final liveReadingProgressProvider = StateNotifierProvider.family<LiveReadingProgressNotifier, double, String>((ref, bookId) {
  return LiveReadingProgressNotifier(bookId);
});

class LiveReadingProgressNotifier extends StateNotifier<double> {
  final String bookId;
  final _log = Logger('LiveReadingProgressNotifier');
  static const String _progressPrefix = 'live_progress_';

  LiveReadingProgressNotifier(this.bookId) : super(0.0) {
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressString = prefs.getString('$_progressPrefix$bookId');
      if (progressString != null) {
        final progressData = jsonDecode(progressString);
        if (progressData is Map<String, dynamic> && progressData.containsKey('scrollPosition')) {
          state = (progressData['scrollPosition'] as num?)?.toDouble() ?? 0.0;
           _log.info('Loaded initial live progress for book $bookId: $state');
        } else if (progressData is double) { // Backwards compatibility or simpler format
           state = progressData;
            _log.info('Loaded initial live progress (double) for book $bookId: $state');
        }
      }
    } catch (e, stackTrace) {
      _log.warning('Error loading initial live progress for book $bookId: $e', stackTrace);
      state = 0.0; // Default to 0 if error
    }
  }

  void setProgress(double newProgress) {
    if ((state - newProgress).abs() > 0.001) { // Only update if changed significantly
      state = newProgress.clamp(0.0, 1.0);
      _log.fine('Live progress for book $bookId updated to: $state');
    }
  }

  // This method might be called by ReadingNotifier after it saves to ensure consistency,
  // or this notifier could directly save to its own SharedPreferences key if desired.
  // For now, it's mainly updated by setProgress.
  Future<void> saveProgress(double currentProgress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store as a simple map to be consistent with how ReadingNotifier might save more complex data
      // but specifically for live progress, only scrollPosition is strictly needed here.
      final progressData = {'scrollPosition': currentProgress.clamp(0.0, 1.0)};
      await prefs.setString('$_progressPrefix$bookId', jsonEncode(progressData));
      _log.info('Saved live progress for book $bookId: $currentProgress');
    } catch (e, stackTrace) {
      _log.severe('Error saving live progress for book $bookId: $e', stackTrace);
    }
  }
} 