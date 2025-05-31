import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/book_entity.dart';
import 'book_card.dart';
import '../../../../routes/route_names.dart';

// Placeholder data model - replace with actual BookEntity from domain layer later
class _PlaceholderBook {
  final String id;
  final String title;
  final String coverUrl;
  final String category;

  _PlaceholderBook(this.id, this.title, this.coverUrl, this.category);
}

class BookCarousel extends StatelessWidget {
  final String title;
  final List<dynamic> books; // Accept both BookEntity and _PlaceholderBook
  final VoidCallback? onViewAll;

  const BookCarousel({
    super.key,
    required this.title,
    required this.books,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Sample data matching the reference
    final featuredBooks = [
      _PlaceholderBook('1', "Tafhim-ul-Quran", "https://via.placeholder.com/120x180/047857/FFFFFF?text=Book1", "Tafsir"),
      _PlaceholderBook('2', "Islamic Way of Life", "https://via.placeholder.com/120x180/059669/FFFFFF?text=Book2", "Islamic Studies"),
      _PlaceholderBook('3', "Let Us Be Muslims", "https://via.placeholder.com/120x180/10B981/FFFFFF?text=Book3", "Islamic Studies"),
      _PlaceholderBook('4', "Another Book", "https://via.placeholder.com/120x180/D1FAE5/000000?text=Book4", "Fiqh"),
    ];

    // Use the sample data for now
    final displayBooks = books.isEmpty ? featuredBooks : books;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with "View All" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: textTheme.titleLarge),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12.0), // Spacing below header

        // Horizontal ListView for Book Cards
        SizedBox(
          height: 260, // Adjust height to fit BookCard (180 image + text + spacing)
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayBooks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16.0), // Spacing between cards
            itemBuilder: (context, index) {
              final book = displayBooks[index];
              // Handle both BookEntity and _PlaceholderBook
              String id, title, category, coverUrl;
              
              if (book is BookEntity) {
                id = book.id;
                title = book.title;
                category = book.category ?? 'Unknown';
                coverUrl = book.coverUrl ?? 'https://via.placeholder.com/120x180/047857/FFFFFF?text=Book';
              } else if (book is _PlaceholderBook) {
                id = book.id;
                title = book.title;
                category = book.category;
                coverUrl = book.coverUrl;
              } else {
                // Fallback for unknown types
                id = "unknown";
                title = "Unknown Book";
                category = "Unknown";
                coverUrl = "https://via.placeholder.com/120x180/047857/FFFFFF?text=Unknown";
              }
              
              return BookCard(
                title: title,
                category: category,
                coverImageUrl: coverUrl,
                onTap: () {
                  // Navigate to Book Detail Screen using GoRouter
                  // Ensure the bookId is not "unknown" before navigating
                  if (id != "unknown") {
                    // Option 1: Using push (adds to stack)
                    // context.push('${RouteNames.home}/book/$id'); 
                    // Option 2: Using go (replaces stack if necessary, better for top-level views)
                    context.goNamed(RouteNames.bookDetailItem, pathParameters: {'bookId': id});
                    print('Navigating to book detail for ID: $id');
                  } else {
                    print('Cannot navigate for unknown book.');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
