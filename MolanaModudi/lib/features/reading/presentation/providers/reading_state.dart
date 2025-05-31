import 'package:equatable/equatable.dart';
import '../../../books/data/models/book_models.dart';
import 'package:flutter/widgets.dart'; // Added for Widget type

enum AiFeatureStatus { initial, loading, ready, success, error }

enum ReadingStatus { 
  initial, 
  loading, 
  success, 
  error, 
  displayingText, 
  loadingMetadata, 
  loadingContent 
}

class ReadingState extends Equatable {
  final ReadingStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? aiSummaryData;
  final AiFeatureStatus aiSummaryStatus;
  final List<String>? mainChapterKeys;
  final List<Heading>? headings;
  final List<dynamic> bookmarks;
  final String? currentLanguage;
  final String? bookTitle;
  final String? bookId;
  final int currentChapter;
  final String? currentChapterTitle;
  final String? currentHeadingTitle;
  final Map<String, dynamic>? aiExtractedChapters;
  final String? textContent;
  final Map<String, String>? difficultWords;
  final double? textScrollPosition;

  // Additional properties to match provider usage
  final Book? book;
  final bool isTocExtracted;
  final Map<String, AiFeatureStatus>? aiFeatureStatus;
  final Map<String, dynamic>? bookSummary;
  final List<Map<String, dynamic>>? bookRecommendations;
  final Map<String, dynamic>? themeAnalysis;
  final Map<String, dynamic>? highlightedTextPosition;
  final Map<String, dynamic>? currentTranslation;
  final Map<String, dynamic>? recommendedSettings;
  final List<Map<String, dynamic>>? searchResults;
  final String? lastSearchQuery;
  final List<Map<String, dynamic>>? suggestedBookmarks;
  final int? totalChapters;
  final bool isSpeaking;
  final Map<String, dynamic>? speechMarkers;
  final Map<String, List<Widget>>? cachedMarkdownWidgetsPerHeading;

  // NEW: canonical chapter navigation helpers
  final Map<String, int>? chapterIdToIndex; // maps chapterId -> logical index
  final Map<String, String>? headingIdToChapterId; // maps headingId -> chapterId
  final String? currentChapterId; // canonical current chapter identifier

  const ReadingState({
    this.status = ReadingStatus.initial,
    this.errorMessage,
    this.aiSummaryData,
    this.aiSummaryStatus = AiFeatureStatus.initial,
    this.mainChapterKeys,
    this.headings,
    this.bookmarks = const [],
    this.currentLanguage,
    this.bookTitle,
    this.bookId,
    this.currentChapter = 0,
    this.currentChapterTitle,
    this.currentHeadingTitle,
    this.aiExtractedChapters,
    this.textContent,
    this.difficultWords,
    this.textScrollPosition,
    this.book,
    this.isTocExtracted = false,
    this.aiFeatureStatus,
    this.bookSummary,
    this.bookRecommendations,
    this.themeAnalysis,
    this.highlightedTextPosition,
    this.currentTranslation,
    this.recommendedSettings,
    this.searchResults,
    this.lastSearchQuery,
    this.suggestedBookmarks,
    this.totalChapters,
    this.isSpeaking = false,
    this.speechMarkers,
    this.cachedMarkdownWidgetsPerHeading,
    this.chapterIdToIndex,
    this.headingIdToChapterId,
    this.currentChapterId,
  });

  bool get isAnyAiFeatureLoading => aiFeatureStatus != null && aiFeatureStatus!.values.any((status) => status == AiFeatureStatus.loading);
    
  bool isAiFeatureLoading(String feature) => 
    aiFeatureStatus != null && 
    aiFeatureStatus!.containsKey(feature) && 
    aiFeatureStatus![feature] == AiFeatureStatus.loading;

  ReadingState copyWith({
    ReadingStatus? status,
    String? errorMessage,
    Map<String, dynamic>? aiSummaryData,
    AiFeatureStatus? aiSummaryStatus,
    List<String>? mainChapterKeys,
    List<Heading>? headings,
    List<dynamic>? bookmarks,
    String? currentLanguage,
    String? bookTitle,
    String? bookId,
    int? currentChapter,
    String? currentChapterTitle,
    String? currentHeadingTitle,
    Map<String, dynamic>? aiExtractedChapters,
    String? textContent,
    Map<String, String>? difficultWords,
    double? textScrollPosition,
    Book? book,
    bool? isTocExtracted,
    Map<String, AiFeatureStatus>? aiFeatureStatus,
    Map<String, dynamic>? bookSummary,
    List<Map<String, dynamic>>? bookRecommendations,
    Map<String, dynamic>? themeAnalysis,
    Map<String, dynamic>? highlightedTextPosition,
    Map<String, dynamic>? currentTranslation,
    Map<String, dynamic>? recommendedSettings,
    List<Map<String, dynamic>>? searchResults,
    String? lastSearchQuery,
    List<Map<String, dynamic>>? suggestedBookmarks,
    int? totalChapters,
    bool? isSpeaking,
    Map<String, dynamic>? speechMarkers,
    Map<String, List<Widget>>? cachedMarkdownWidgetsPerHeading,
    Map<String, int>? chapterIdToIndex,
    Map<String, String>? headingIdToChapterId,
    String? currentChapterId,
  }) {
    return ReadingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      aiSummaryData: aiSummaryData ?? this.aiSummaryData,
      aiSummaryStatus: aiSummaryStatus ?? this.aiSummaryStatus,
      mainChapterKeys: mainChapterKeys ?? this.mainChapterKeys,
      headings: headings ?? this.headings,
      bookmarks: bookmarks ?? this.bookmarks,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      bookTitle: bookTitle ?? this.bookTitle,
      bookId: bookId ?? this.bookId,
      currentChapter: currentChapter ?? this.currentChapter,
      currentChapterTitle: currentChapterTitle ?? this.currentChapterTitle,
      currentHeadingTitle: currentHeadingTitle ?? this.currentHeadingTitle,
      aiExtractedChapters: aiExtractedChapters ?? this.aiExtractedChapters,
      textContent: textContent ?? this.textContent,
      difficultWords: difficultWords ?? this.difficultWords,
      textScrollPosition: textScrollPosition ?? this.textScrollPosition,
      book: book ?? this.book,
      isTocExtracted: isTocExtracted ?? this.isTocExtracted,
      aiFeatureStatus: aiFeatureStatus ?? this.aiFeatureStatus,
      bookSummary: bookSummary ?? this.bookSummary,
      bookRecommendations: bookRecommendations ?? this.bookRecommendations,
      themeAnalysis: themeAnalysis ?? this.themeAnalysis,
      highlightedTextPosition: highlightedTextPosition ?? this.highlightedTextPosition,
      currentTranslation: currentTranslation ?? this.currentTranslation,
      recommendedSettings: recommendedSettings ?? this.recommendedSettings,
      searchResults: searchResults ?? this.searchResults,
      lastSearchQuery: lastSearchQuery ?? this.lastSearchQuery,
      suggestedBookmarks: suggestedBookmarks ?? this.suggestedBookmarks,
      totalChapters: totalChapters ?? this.totalChapters,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      speechMarkers: speechMarkers ?? this.speechMarkers,
      cachedMarkdownWidgetsPerHeading: cachedMarkdownWidgetsPerHeading ?? this.cachedMarkdownWidgetsPerHeading,
      chapterIdToIndex: chapterIdToIndex ?? this.chapterIdToIndex,
      headingIdToChapterId: headingIdToChapterId ?? this.headingIdToChapterId,
      currentChapterId: currentChapterId ?? this.currentChapterId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        aiSummaryData,
        aiSummaryStatus,
        mainChapterKeys,
        headings,
        bookmarks,
        currentLanguage,
        bookTitle,
        bookId,
        currentChapter,
        currentChapterTitle,
        currentHeadingTitle,
        aiExtractedChapters,
        textContent,
        difficultWords,
        textScrollPosition,
        book,
        isTocExtracted,
        aiFeatureStatus,
        bookSummary,
        bookRecommendations,
        themeAnalysis,
        highlightedTextPosition,
        currentTranslation,
        recommendedSettings,
        searchResults,
        lastSearchQuery,
        suggestedBookmarks,
        totalChapters,
        isSpeaking,
        speechMarkers,
        cachedMarkdownWidgetsPerHeading,
        chapterIdToIndex,
        headingIdToChapterId,
        currentChapterId,
      ];
}