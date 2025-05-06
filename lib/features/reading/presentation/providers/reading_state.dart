import 'package:equatable/equatable.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/foundation.dart';

enum ReadingStatus { 
  initial, 
  loadingMetadata, // Fetching file list
  downloading, // Downloading selected file
  loadingContent, // Parsing/loading downloaded file (e.g., EPUB)
  displayingEpub,
  displayingText,
  displayingPdf, // Added status for PDF
  error 
}

enum AiFeatureStatus {
  initial,
  loading,
  ready,
  error
}

class ReadingState extends Equatable {
  final ReadingStatus status;
  final String? errorMessage;
  final double downloadProgress; // 0.0 to 1.0
  
  // Content holders (only one should be non-null at a time based on status)
  final EpubController? epubController;
  final String? textContent;
  final String? pdfPath; // Add path for PDF file
  final String? bookTitle; // Add book title
  
  // Reading progress tracking
  final int currentChapter; // For EPUB/Text, maybe pages for PDF?
  final int totalChapters; // For EPUB/Text, maybe total pages for PDF?
  final double textScrollPosition;
  final String? lastPosition; // EPUB CFI string for position tracking
  
  // AI Features
  final List<Map<String, dynamic>>? aiExtractedChapters;
  final List<Map<String, dynamic>>? difficultWords;
  final Map<String, dynamic>? bookSummary;
  final Map<String, dynamic>? themeAnalysis;
  final List<Map<String, dynamic>>? suggestedBookmarks;
  final Map<String, dynamic>? recommendedSettings;
  final List<Map<String, dynamic>>? bookRecommendations;
  
  // AI Feature Status tracking
  final Map<String, AiFeatureStatus> aiFeatureStatus;
  
  // Current translation data
  final Map<String, dynamic>? currentTranslation;
  
  // Current search results
  final List<Map<String, dynamic>>? searchResults;
  final String? lastSearchQuery;
  
  // TTS Settings
  final Map<String, dynamic>? speechMarkers;
  final bool isSpeaking;
  final Map<String, dynamic>? highlightedTextPosition;

  const ReadingState({
    this.status = ReadingStatus.initial,
    this.errorMessage,
    this.downloadProgress = 0.0,
    this.epubController,
    this.textContent,
    this.pdfPath,
    this.bookTitle,
    this.currentChapter = 0,
    this.totalChapters = 0, // Represents pages for PDF?
    this.textScrollPosition = 0.0,
    this.lastPosition,
    this.aiExtractedChapters,
    this.difficultWords,
    this.bookSummary,
    this.themeAnalysis,
    this.suggestedBookmarks,
    this.recommendedSettings,
    this.bookRecommendations,
    this.aiFeatureStatus = const {},
    this.currentTranslation,
    this.searchResults,
    this.lastSearchQuery,
    this.speechMarkers,
    this.isSpeaking = false,
    this.highlightedTextPosition,
  });

  ReadingState copyWith({
    ReadingStatus? status,
    String? errorMessage,
    double? downloadProgress,
    EpubController? epubController,
    String? textContent,
    String? pdfPath,
    String? bookTitle,
    int? currentChapter,
    int? totalChapters,
    double? textScrollPosition,
    String? lastPosition,
    List<Map<String, dynamic>>? aiExtractedChapters,
    List<Map<String, dynamic>>? difficultWords,
    Map<String, dynamic>? bookSummary,
    Map<String, dynamic>? themeAnalysis,
    List<Map<String, dynamic>>? suggestedBookmarks,
    Map<String, dynamic>? recommendedSettings,
    List<Map<String, dynamic>>? bookRecommendations,
    Map<String, AiFeatureStatus>? aiFeatureStatus,
    Map<String, dynamic>? currentTranslation,
    List<Map<String, dynamic>>? searchResults,
    String? lastSearchQuery,
    Map<String, dynamic>? speechMarkers,
    bool? isSpeaking,
    Map<String, dynamic>? highlightedTextPosition,
    bool clearError = false,
  }) {
    // Determine which content fields to keep based on the NEW status
    EpubController? newEpubController = epubController ?? this.epubController;
    String? newTextContent = textContent ?? this.textContent;
    String? newPdfPath = pdfPath ?? this.pdfPath;
    
    final targetStatus = status ?? this.status;
    if (status != null) { // Only clear if status is explicitly changing
      if (targetStatus != ReadingStatus.displayingEpub) newEpubController = null;
      if (targetStatus != ReadingStatus.displayingText) newTextContent = null;
      if (targetStatus != ReadingStatus.displayingPdf) newPdfPath = null;
    }

    return ReadingState(
      status: targetStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      epubController: newEpubController,
      textContent: newTextContent,
      pdfPath: newPdfPath,
      bookTitle: bookTitle ?? this.bookTitle,
      currentChapter: currentChapter ?? this.currentChapter, 
      totalChapters: totalChapters ?? this.totalChapters, 
      textScrollPosition: textScrollPosition ?? this.textScrollPosition,
      lastPosition: lastPosition ?? this.lastPosition,
      aiExtractedChapters: aiExtractedChapters ?? this.aiExtractedChapters,
      difficultWords: difficultWords ?? this.difficultWords,
      bookSummary: bookSummary ?? this.bookSummary,
      themeAnalysis: themeAnalysis ?? this.themeAnalysis,
      suggestedBookmarks: suggestedBookmarks ?? this.suggestedBookmarks,
      recommendedSettings: recommendedSettings ?? this.recommendedSettings,
      bookRecommendations: bookRecommendations ?? this.bookRecommendations,
      aiFeatureStatus: aiFeatureStatus != null 
          ? {...this.aiFeatureStatus, ...aiFeatureStatus} 
          : this.aiFeatureStatus,
      currentTranslation: currentTranslation ?? this.currentTranslation,
      searchResults: searchResults ?? this.searchResults,
      lastSearchQuery: lastSearchQuery ?? this.lastSearchQuery,
      speechMarkers: speechMarkers ?? this.speechMarkers,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      highlightedTextPosition: highlightedTextPosition ?? this.highlightedTextPosition,
    );
  }
  
  // Calculate reading progress percentage (adjust interpretation for PDF)
  double get progressPercentage {
    if (totalChapters <= 0) return 0.0;
    // For EPUB/Text, it's chapter-based. For PDF, treat currentChapter as currentPage.
    // Note: PDFView provides its own page count/callbacks, might need different state later.
    final currentPage = currentChapter + 1; // Assume currentChapter is 0-based page index for PDF
    return (currentPage / totalChapters).clamp(0.0, 1.0);
  }
  
  // Helper to check if an AI feature is loading
  bool isAiFeatureLoading(String feature) {
    return aiFeatureStatus[feature] == AiFeatureStatus.loading;
  }
  
  // Helper to check if an AI feature is ready
  bool isAiFeatureReady(String feature) {
    return aiFeatureStatus[feature] == AiFeatureStatus.ready;
  }
  
  // Get a specific AI feature status
  AiFeatureStatus getAiFeatureStatus(String feature) {
    return aiFeatureStatus[feature] ?? AiFeatureStatus.initial;
  }

  @override
  List<Object?> get props => [
    status, 
    errorMessage, 
    downloadProgress, 
    epubController, 
    textContent,
    pdfPath, // Added pdfPath to props
    bookTitle,
    currentChapter,
    totalChapters,
    textScrollPosition,
    lastPosition,
    aiExtractedChapters,
    difficultWords,
    bookSummary,
    themeAnalysis,
    suggestedBookmarks,
    recommendedSettings,
    bookRecommendations,
    aiFeatureStatus,
    currentTranslation,
    searchResults,
    lastSearchQuery,
    speechMarkers,
    isSpeaking,
    highlightedTextPosition,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ReadingState &&
      other.status == status &&
      other.bookTitle == bookTitle &&
      other.errorMessage == errorMessage &&
      other.downloadProgress == downloadProgress &&
      other.epubController == epubController &&
      other.textContent == textContent &&
      other.pdfPath == pdfPath &&
      other.currentChapter == currentChapter &&
      other.totalChapters == totalChapters &&
      other.textScrollPosition == textScrollPosition &&
      other.lastPosition == lastPosition &&
      listEquals(other.aiExtractedChapters, aiExtractedChapters) &&
      listEquals(other.difficultWords, difficultWords) &&
      mapEquals(other.bookSummary, bookSummary) &&
      mapEquals(other.themeAnalysis, themeAnalysis) &&
      listEquals(other.suggestedBookmarks, suggestedBookmarks) &&
      mapEquals(other.recommendedSettings, recommendedSettings) &&
      listEquals(other.bookRecommendations, bookRecommendations) &&
      mapEquals(other.aiFeatureStatus, aiFeatureStatus) &&
      mapEquals(other.currentTranslation, currentTranslation) &&
      listEquals(other.searchResults, searchResults) &&
      other.lastSearchQuery == lastSearchQuery &&
      mapEquals(other.speechMarkers, speechMarkers) &&
      other.isSpeaking == isSpeaking &&
      mapEquals(other.highlightedTextPosition, highlightedTextPosition);
  }

  @override
  int get hashCode {
    return status.hashCode ^
      bookTitle.hashCode ^
      errorMessage.hashCode ^
      downloadProgress.hashCode ^
      epubController.hashCode ^
      textContent.hashCode ^
      pdfPath.hashCode ^
      currentChapter.hashCode ^
      totalChapters.hashCode ^
      textScrollPosition.hashCode ^
      lastPosition.hashCode ^
      aiExtractedChapters.hashCode ^
      difficultWords.hashCode ^
      bookSummary.hashCode ^
      themeAnalysis.hashCode ^
      suggestedBookmarks.hashCode ^
      recommendedSettings.hashCode ^
      bookRecommendations.hashCode ^
      aiFeatureStatus.hashCode ^
      currentTranslation.hashCode ^
      searchResults.hashCode ^
      lastSearchQuery.hashCode ^
      speechMarkers.hashCode ^
      isSpeaking.hashCode ^
      highlightedTextPosition.hashCode;
  }
} 