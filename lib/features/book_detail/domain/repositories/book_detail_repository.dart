import '../entities/book_detail_entity.dart';

/// Abstract repository for fetching book details.
abstract class BookDetailRepository {
  Future<BookDetailEntity> getBookDetails(String bookId);
} 