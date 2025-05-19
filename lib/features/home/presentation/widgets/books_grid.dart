import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/providers/books_providers.dart';
import 'book_card.dart';

class BooksGrid extends ConsumerWidget {
  final String? category;
  final bool featured;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  
  const BooksGrid({
    super.key,
    this.category,
    this.featured = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which provider to use based on params
    final booksAsync = featured 
      ? ref.watch(featuredBooksProvider)
      : category != null
          ? ref.watch(booksByCategoryProvider(category!))
          : ref.watch(booksProvider);
    
    return booksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading books',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Refresh providers based on the widget configuration
                // The UI will automatically rebuild when the provider state changes
                // Create a variable to store the refresh result
                AsyncValue<dynamic> refreshResult;
                
                if (featured) {
                  refreshResult = ref.refresh(featuredBooksProvider);
                } else if (category != null) {
                  refreshResult = ref.refresh(booksByCategoryProvider(category!));
                } else {
                  refreshResult = ref.refresh(booksProvider);
                }
                
                // Monitor the refresh status to provide feedback
                refreshResult.whenOrNull(
                  error: (error, stackTrace) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error refreshing: ${error.toString()}'))
                    );
                  }
                );
                
                // Show a message to indicate refresh is happening
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing books...'), duration: Duration(seconds: 1))
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.book_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No books found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: padding ?? const EdgeInsets.all(16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              title: book.title ?? 'Untitled',
              category: book.author ?? 'Unknown',
              coverImageUrl: book.thumbnailUrl ?? '',
              onTap: () {
                // Navigate to book detail screen
                Navigator.pushNamed(
                  context,
                  '/book/${book.id}',
                  arguments: book,
                );
              },
            );
          },
        );
      },
    );
  }
}
 