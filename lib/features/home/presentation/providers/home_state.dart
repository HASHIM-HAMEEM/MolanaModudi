import 'package:equatable/equatable.dart';

// import '../../domain/entities/book_entity.dart'; Remove this
// import '../../../../core/models/book_model.dart'; // Add this
import 'package:modudi/models/book_models.dart'; // Use new models
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/video_entity.dart';

enum HomeStatus { initial, loading, success, error }

class HomeState extends Equatable {
  final HomeStatus status;
  // final List<BookEntity> featuredBooks;
  final List<Book> featuredBooks; // Change to Book
  final List<CategoryEntity> categories;
  final List<VideoEntity> videos;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.featuredBooks = const [],
    this.categories = const [],
    this.videos = const [],
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    // List<BookEntity>? featuredBooks,
    List<Book>? featuredBooks, // Change to Book
    List<CategoryEntity>? categories,
    List<VideoEntity>? videos,
    String? errorMessage,
    bool clearError = false, // Helper to explicitly clear error
  }) {
    return HomeState(
      status: status ?? this.status,
      featuredBooks: featuredBooks ?? this.featuredBooks,
      categories: categories ?? this.categories,
      videos: videos ?? this.videos,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, featuredBooks, categories, videos, errorMessage];
} 