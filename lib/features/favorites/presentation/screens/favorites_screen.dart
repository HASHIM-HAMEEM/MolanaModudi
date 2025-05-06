import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/favorites/providers/favorites_provider.dart';
import 'package:modudi/models/book_models.dart';
import 'package:modudi/features/library/presentation/widgets/book_grid_item.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

class FavoritesScreen extends ConsumerWidget {
  FavoritesScreen({super.key});
  
  final _log = Logger('FavoritesScreen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? _buildEmptyState(context)
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final Book book = favorites[index];
                return BookGridItem(
                  book: book,
                  onTap: () {
                    _log.info('Navigating to book detail for: ${book.firestoreDocId}');
                    context.go('/book-detail/${book.firestoreDocId}', extra: book);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_outlined,
            size: 72,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No favorites yet",
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Books you mark as favorite will appear here",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/library'),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text("Browse Library"),
          ),
        ],
      ),
    );
  }
} 