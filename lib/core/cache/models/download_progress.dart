/// Represents the download progress for a book or content item
class DownloadProgress {
  /// The book ID this progress applies to
  final String bookId;
  
  /// The total number of items to download
  final int totalItems;
  
  /// The number of items downloaded so far
  final int completedItems;
  
  /// The status of the download
  final DownloadStatus status;
  
  /// Optional error message if the download failed
  final String? errorMessage;
  
  /// Create a new download progress object
  DownloadProgress({
    required this.bookId,
    required this.totalItems,
    required this.completedItems,
    required this.status,
    this.errorMessage,
  });
  
  /// The progress as a percentage (0.0 to 1.0)
  double get progressPercentage => 
      totalItems > 0 ? completedItems / totalItems : 0.0;
      
  /// Create a copy with updated values
  DownloadProgress copyWith({
    int? totalItems,
    int? completedItems,
    DownloadStatus? status,
    String? errorMessage,
  }) {
    return DownloadProgress(
      bookId: bookId,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  /// Factory to create an initial progress object
  factory DownloadProgress.start(String bookId, int totalItems) {
    return DownloadProgress(
      bookId: bookId,
      totalItems: totalItems,
      completedItems: 0,
      status: DownloadStatus.inProgress,
    );
  }
  
  /// Factory to create a completed progress object
  factory DownloadProgress.complete(String bookId, int totalItems) {
    return DownloadProgress(
      bookId: bookId,
      totalItems: totalItems,
      completedItems: totalItems,
      status: DownloadStatus.completed,
    );
  }
  
  /// Factory to create a failed progress object
  factory DownloadProgress.failed(String bookId, String errorMessage) {
    return DownloadProgress(
      bookId: bookId,
      totalItems: 0,
      completedItems: 0,
      status: DownloadStatus.failed,
      errorMessage: errorMessage,
    );
  }
}

/// Download status enumeration
enum DownloadStatus {
  /// Download is queued but not started yet
  queued,
  
  /// Download is in progress
  inProgress,
  
  /// Download is paused
  paused,
  
  /// Download completed successfully
  completed,
  
  /// Download canceled by user
  canceled,
  
  /// Download failed with an error
  failed
}
