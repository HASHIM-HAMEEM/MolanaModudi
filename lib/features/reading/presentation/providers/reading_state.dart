import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/reading/data/models/bookmark_model.dart'; // Import Bookmark model
import 'package:collection/collection.dart'; // Added for DeepCollectionEquality

enum ReadingStatus { 
  initial, 
  loadingMetadata, // Fetching file list
  downloading, // Downloading selected file
  loadingContent, // Parsing/loading downloaded file
  displayingText,
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
  final String? textContent;
  final String? bookTitle; // Add book title
  
  // Reading progress tracking
  final int currentChapter; // For EPUB/Text, maybe pages for PDF?
  final int totalChapters; // For EPUB/Text, maybe total pages for PDF?
  final double textScrollPosition;
  final String? lastPosition; // EPUB CFI string for position tracking
  
  // AI Features
  final List<Map<String, dynamic>>? aiExtractedChapters;
  final Map<String, String>? difficultWords;
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

  // Add these fields to the ReadingState class
  final String? currentChapterTitle;
  final String? currentHeadingTitle;
  final String? currentLanguage;
  final List<dynamic>? headings;

  // Add new state variables for main chapters/segments
  final List<String> mainChapterKeys; // Stores the unique keys for main chapters (e.g., chapter_id)
  final int currentMainChapterIndex; // Index for the PageView

  final List<Bookmark> bookmarks; // Added for bookmarks

  final String? bookId; // Ensure this is present
  final Book? book; // Ensure this is present
  final bool isTocExtracted; // Ensure this is present

  const ReadingState({
    this.status = ReadingStatus.initial,
    this.errorMessage,
    this.downloadProgress = 0.0,
    this.textContent,
    this.bookTitle,
    this.currentChapter = 0, // This will now represent the logical index of the current main chapter
    this.totalChapters = 0, // This will represent the total count of main logical chapters
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
    this.currentChapterTitle,
    this.currentHeadingTitle,
    this.currentLanguage,
    this.headings,
    this.mainChapterKeys = const [], // Initialize new field
    this.currentMainChapterIndex = 0, // Initialize new field - will be synced with currentChapter
    this.bookmarks = const [], // Initialize bookmarks
    this.bookId, // Add to constructor
    this.book, // Add to constructor
    this.isTocExtracted = false, // Add to constructor
  });

  ReadingState copyWith({
    ReadingStatus? status,
    String? errorMessage,
    double? downloadProgress,
    String? textContent,
    String? bookTitle,
    int? currentChapter, // Logical index of the current main chapter
    int? totalChapters,  // Total count of main logical chapters
    double? textScrollPosition,
    String? lastPosition,
    List<Map<String, dynamic>>? aiExtractedChapters,
    Map<String, String>? difficultWords,
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
    String? currentChapterTitle,
    String? currentHeadingTitle,
    String? currentLanguage,
    List<dynamic>? headings,
    List<String>? mainChapterKeys,
    int? currentMainChapterIndex,
    List<Bookmark>? bookmarks, // Add to copyWith
    String? bookId, // Add to copyWith
    Book? book, // Add to copyWith
    bool? isTocExtracted, // Add to copyWith
  }) {
    // Determine which content fields to keep based on the NEW status
    String? newTextContent = textContent ?? this.textContent;
    
    final targetStatus = status ?? this.status;
    if (status != null) { // Only clear if status is explicitly changing
      if (targetStatus != ReadingStatus.displayingText) newTextContent = null;
    }

    return ReadingState(
      status: targetStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      textContent: newTextContent,
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
      currentChapterTitle: currentChapterTitle ?? this.currentChapterTitle,
      currentHeadingTitle: currentHeadingTitle ?? this.currentHeadingTitle,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      headings: headings ?? this.headings,
      mainChapterKeys: mainChapterKeys ?? this.mainChapterKeys,
      currentMainChapterIndex: currentMainChapterIndex ?? this.currentMainChapterIndex,
      bookmarks: bookmarks ?? this.bookmarks, // Add to copyWith
      bookId: bookId ?? this.bookId, // Add to copyWith
      book: book ?? this.book, // Add to copyWith
      isTocExtracted: isTocExtracted ?? this.isTocExtracted, // Add to copyWith
    );
  }
  
  // Calculate reading progress percentage (adjust interpretation for PDF)
  double get progressPercentage {
    if (totalChapters <= 0) return 0.0;
    // For EPUB/Text, it's chapter-based. 
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
    textContent,
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
    currentChapterTitle,
    currentHeadingTitle,
    currentLanguage,
    headings,
    mainChapterKeys,
    currentMainChapterIndex,
    bookmarks,
    bookId,
    book,
    isTocExtracted,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ReadingState &&
      other.status == status &&
      other.bookTitle == bookTitle &&
      other.errorMessage == errorMessage &&
      other.downloadProgress == downloadProgress &&
      other.textContent == textContent &&
      other.currentChapter == currentChapter &&
      other.totalChapters == totalChapters &&
      other.textScrollPosition == textScrollPosition &&
      other.lastPosition == lastPosition &&
      listEquals(other.aiExtractedChapters, aiExtractedChapters) &&
      mapEquals(other.difficultWords, difficultWords) &&
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
      mapEquals(other.highlightedTextPosition, highlightedTextPosition) &&
      other.currentChapterTitle == currentChapterTitle &&
      other.currentHeadingTitle == currentHeadingTitle &&
      other.currentLanguage == currentLanguage &&
      listEquals(other.headings, headings) &&
      listEquals(other.mainChapterKeys, mainChapterKeys) &&
      other.currentMainChapterIndex == currentMainChapterIndex &&
      listEquals(other.bookmarks, bookmarks) &&
      other.bookId == bookId &&
      other.book == book &&
      other.isTocExtracted == isTocExtracted;
  }

  @override
  int get hashCode =>
    status.hashCode ^
    errorMessage.hashCode ^
    downloadProgress.hashCode ^
    textContent.hashCode ^
    bookTitle.hashCode ^
    currentChapter.hashCode ^
    totalChapters.hashCode ^
    textScrollPosition.hashCode ^
    lastPosition.hashCode ^
    (aiExtractedChapters?.fold<int>(0, (prev, item) {
      int itemHash = 0;
 itemHash = item.hashCode ?? 0;       return prev ^ itemHash;
    }) ?? 0) ^
    const DeepCollectionEquality().hash(difficultWords) ^
    bookSummary.hashCode ^
    themeAnalysis.hashCode ^
    (suggestedBookmarks?.fold<int>(0, (prev, item) {
      int itemHash = 0;
 itemHash = item.hashCode ?? 0;       return prev ^ itemHash;
    }) ?? 0) ^
    recommendedSettings.hashCode ^
    (bookRecommendations?.fold<int>(0, (prev, item) {
      int itemHash = 0;
 itemHash = item.hashCode ?? 0;       return prev ^ itemHash;
    }) ?? 0) ^
    aiFeatureStatus.hashCode ^
    currentTranslation.hashCode ^
    (searchResults?.fold<int>(0, (prev, item) {
      int itemHash = 0;
 itemHash = item.hashCode ?? 0;       return prev ^ itemHash;
    }) ?? 0) ^
    lastSearchQuery.hashCode ^
    speechMarkers.hashCode ^
    isSpeaking.hashCode ^
    highlightedTextPosition.hashCode ^
    currentChapterTitle.hashCode ^
    currentHeadingTitle.hashCode ^
    currentLanguage.hashCode ^
    (headings?.fold<int>(0, (prev, item) {
      int itemHash = 0;
      if (item != null) { itemHash = item.hashCode ?? 0; }
      return prev ^ itemHash;
    }) ?? 0) ^
    (mainChapterKeys.fold<int>(0, (prev, item) {
      return prev ^ (item.hashCode ?? 0);
    })) ^ 
    currentMainChapterIndex.hashCode ^
    bookmarks.hashCode ^
    bookId.hashCode ^
    book.hashCode ^
    isTocExtracted.hashCode;
} 