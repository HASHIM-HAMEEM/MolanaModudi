import 'book_detail/book_detail_page.dart';

/// Backward compatibility wrapper - delegates to the new refactored BookDetailPage
/// This maintains existing route compatibility while using the clean architecture
class BookDetailScreen extends BookDetailPage {
  const BookDetailScreen({
    super.key,
    required super.bookId,
    super.source,
  });
}
