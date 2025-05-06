// import 'package:modudi/core/models/book_model.dart';
import 'package:modudi/models/book_models.dart'; // Use new models
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the state of the library books.
/// 
/// This class is used to manage the state of the library books in the app.
/// Uses a simple class hierarchy instead of freezed.
sealed class LibraryState {
  const LibraryState();
}

/// Initial loading state.
class LibraryLoading extends LibraryState {
  LibraryLoading();
}

/// State when books are successfully loaded or being updated with more data.
class LibraryStateData extends LibraryState {
  // final List<BookModel> books;
  final List<Book> books; // Change to new Book model
  final DateTime lastUpdated;
  final DocumentSnapshot? lastDocument;
  final bool isLoadingMore;
  final String? error;

  const LibraryStateData({
    required this.books,
    required this.lastUpdated,
    this.lastDocument,
    this.isLoadingMore = false,
    this.error,
  });

  LibraryStateData copyWith({
    // List<BookModel>? books,
    List<Book>? books, // Change to new Book model
    DateTime? lastUpdated,
    DocumentSnapshot? lastDocument,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return LibraryStateData(
      books: books ?? this.books,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastDocument: lastDocument == null && (this.lastDocument != null && books == null) ? null : (lastDocument ?? this.lastDocument),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// State when an error occurs during loading.
class LibraryStateError extends LibraryState {
  final String message;
  LibraryStateError(this.message);
}

// Extension for maybeWhen like functionality (optional, but can be convenient)
extension LibraryStateExtensions on LibraryState {
  T maybeWhen<T>({
    T Function()? loading,
    // T Function(List<BookModel> books, DateTime lastUpdated, DocumentSnapshot? lastDocument, bool isLoadingMore, String? error)? data,
    T Function(List<Book> books, DateTime lastUpdated, DocumentSnapshot? lastDocument, bool isLoadingMore, String? error)? data, // Change to new Book model
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is LibraryLoading && loading != null) {
      return loading();
    }
    if (this is LibraryStateData && data != null) {
      final s = this as LibraryStateData;
      return data(s.books, s.lastUpdated, s.lastDocument, s.isLoadingMore, s.error);
    }
    if (this is LibraryStateError && error != null) {
      return error((this as LibraryStateError).message);
    }
    return orElse();
  }
} 