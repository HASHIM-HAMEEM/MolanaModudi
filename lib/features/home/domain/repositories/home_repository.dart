// import '../entities/book_entity.dart'; Remove this
// import 'package:modudi/core/models/book_model.dart'; // Remove this
import 'package:modudi/features/books/data/models/book_models.dart'; // Use new models
import '../entities/category_entity.dart';
import '../entities/video_entity.dart';

/// Abstract repository defining the contract for fetching home screen data.
abstract class HomeRepository {
  Future<Book?> getBookById(String bookId);
  
  /// Fetches a list of featured books.
  /// 
  /// Throws an exception if the fetch fails.
  // Future<List<BookModel>> getFeaturedBooks({int perPage = 500});
  Future<List<Book>> getFeaturedBooks({int perPage = 500}); // Change to Book

  /// Fetches a list of categories.
  /// 
  /// Throws an exception if the fetch fails.
  Future<List<CategoryEntity>> getCategories();

  /// Fetches a list of video lectures.
  /// 
  /// Throws an exception if the fetch fails.
  Future<List<VideoEntity>> getVideoLectures({int perPage = 5});

  // TODO: Add methods for fetching biography summary, recent articles, etc.
  // Future<String> getBiographySummary();
  // Future<List<ArticleEntity>> getRecentArticles(); // Assuming an ArticleEntity exists
} 