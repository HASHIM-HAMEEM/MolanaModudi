import 'dart:convert'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:logging/logging.dart';
import 'package:modudi/core/providers/providers.dart';
import 'package:modudi/features/reading/data/reading_repository_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookPrefetchPayload {
  final String bookId;
  final List<String> extraUrls;
  const BookPrefetchPayload({required this.bookId, this.extraUrls = const []});
}

/// Background prefetching extracted from UI layer.
class PrefetchNotifier extends StateNotifier<AsyncValue<void>> {
  PrefetchNotifier(this._ref) : super(const AsyncData(null));
  final Ref _ref;
  final _log = Logger('PrefetchNotifier');

  Future<void> prefetch(BookPrefetchPayload payload) async {
    if (state is AsyncLoading) return;
    state = const AsyncLoading();
    try {
      final CacheService cacheService = await _ref.read(cacheServiceProvider.future);
      final readingRepo = await _ref.read(readingRepositoryProvider.future);

      await readingRepo.getBookData(payload.bookId);

      if (payload.extraUrls.isNotEmpty) {
        await cacheService.prefetchUrls(payload.extraUrls);
      }

      final headingsSnap = await FirebaseFirestore.instance
          .collection('books')
          .doc(payload.bookId)
          .collection('headings')
          .get();
      for (final doc in headingsSnap.docs) {
        await cacheService.putRaw(
          key: 'heading_${doc.id}',
          boxName: 'headings',
          data: jsonEncode(doc.data()), // Ensure data is a JSON string
        );
      }
      state = const AsyncData(null);
      _log.info('Prefetch completed for ${payload.bookId}');
    } catch (e, st) {
      _log.severe('Prefetch error', e, st);
      state = AsyncError(e, st);
    }
  }
}

final prefetchNotifierProvider =
    StateNotifierProvider<PrefetchNotifier, AsyncValue<void>>((ref) {
  return PrefetchNotifier(ref);
});
