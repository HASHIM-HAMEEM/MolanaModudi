import 'package:equatable/equatable.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/reading/presentation/providers/reading_state.dart'; // Import AiFeatureStatus

enum BookDetailStatus { initial, loading, success, error }

class BookDetailState extends Equatable {
  final BookDetailStatus status;
  final Book? bookDetail;
  final String? errorMessage;
  
  // AI Enhanced Details
  final Map<String, dynamic>? aiSummaryData; // Includes summary, themes, takeaways
  final List<Map<String, dynamic>>? aiRecommendations;
  final AiFeatureStatus aiDetailsStatus;

  const BookDetailState({
    this.status = BookDetailStatus.initial,
    this.bookDetail,
    this.errorMessage,
    this.aiSummaryData,
    this.aiRecommendations,
    this.aiDetailsStatus = AiFeatureStatus.initial,
  });

  BookDetailState copyWith({
    BookDetailStatus? status,
    Book? bookDetail,
    String? errorMessage,
    Map<String, dynamic>? aiSummaryData,
    List<Map<String, dynamic>>? aiRecommendations,
    AiFeatureStatus? aiDetailsStatus,
    bool clearError = false,
    bool clearBookDetail = false,
  }) {
    return BookDetailState(
      status: status ?? this.status,
      bookDetail: clearBookDetail ? null : bookDetail ?? this.bookDetail,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      aiSummaryData: aiSummaryData ?? this.aiSummaryData,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      aiDetailsStatus: aiDetailsStatus ?? this.aiDetailsStatus,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    bookDetail, 
    errorMessage, 
    aiSummaryData, 
    aiRecommendations, 
    aiDetailsStatus
  ];
} 