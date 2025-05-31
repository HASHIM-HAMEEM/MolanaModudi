import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Maududi'**
  String get appTitle;

  /// No description provided for @readingTabRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh reading list'**
  String get readingTabRefreshTooltip;

  /// No description provided for @readingTabFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reading history.'**
  String get readingTabFailedToLoad;

  /// No description provided for @readingTabTryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get readingTabTryAgainButton;

  /// No description provided for @readingTabEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your reading journey awaits'**
  String get readingTabEmptyStateTitle;

  /// No description provided for @readingTabEmptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Books you read will appear here, allowing you to easily continue your reading journey'**
  String get readingTabEmptyStateSubtitle;

  /// No description provided for @readingTabExploreLibraryButton.
  ///
  /// In en, this message translates to:
  /// **'Explore Library'**
  String get readingTabExploreLibraryButton;

  /// No description provided for @readingTabContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get readingTabContinueReading;

  /// No description provided for @readingTabReadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get readingTabReadingHistory;

  /// No description provided for @readingTabProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get readingTabProgressLabel;

  /// No description provided for @readingTabContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get readingTabContinueButton;

  /// No description provided for @homeScreenSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search books, videos...'**
  String get homeScreenSearchHint;

  /// No description provided for @homeScreenAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Maulana Maududi'**
  String get homeScreenAppBarTitle;

  /// No description provided for @homeScreenFailedToLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content'**
  String get homeScreenFailedToLoadContent;

  /// No description provided for @homeScreenUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get homeScreenUnknownError;

  /// No description provided for @homeScreenRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeScreenRetryButton;

  /// No description provided for @homeScreenWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Maulana Maududi\'s Works'**
  String get homeScreenWelcomeTitle;

  /// No description provided for @homeScreenWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the comprehensive collection'**
  String get homeScreenWelcomeSubtitle;

  /// No description provided for @homeScreenFeaturedBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Books'**
  String get homeScreenFeaturedBooksTitle;

  /// No description provided for @homeScreenViewAllButton.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeScreenViewAllButton;

  /// No description provided for @homeScreenErrorLoadingFeaturedBooks.
  ///
  /// In en, this message translates to:
  /// **'Error loading featured books'**
  String get homeScreenErrorLoadingFeaturedBooks;

  /// No description provided for @homeScreenNoFeaturedBooks.
  ///
  /// In en, this message translates to:
  /// **'No featured books available'**
  String get homeScreenNoFeaturedBooks;

  /// No description provided for @homeScreenUntitledBook.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get homeScreenUntitledBook;

  /// No description provided for @homeScreenCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeScreenCategoriesTitle;

  /// No description provided for @homeScreenVideoLecturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Lectures'**
  String get homeScreenVideoLecturesTitle;

  /// No description provided for @homeScreenErrorLoadingVideos.
  ///
  /// In en, this message translates to:
  /// **'Error loading videos'**
  String get homeScreenErrorLoadingVideos;

  /// No description provided for @homeScreenNoVideos.
  ///
  /// In en, this message translates to:
  /// **'No videos available at the moment.'**
  String get homeScreenNoVideos;

  /// No description provided for @homeScreenExploreMoreVideosButton.
  ///
  /// In en, this message translates to:
  /// **'Explore More Videos'**
  String get homeScreenExploreMoreVideosButton;

  /// No description provided for @homeScreenRecentArticlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Articles'**
  String get homeScreenRecentArticlesTitle;

  /// No description provided for @homeScreenNoRecentArticles.
  ///
  /// In en, this message translates to:
  /// **'No recent articles to display.'**
  String get homeScreenNoRecentArticles;

  /// No description provided for @bookDetailScreenLoadingAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get bookDetailScreenLoadingAppBarTitle;

  /// No description provided for @bookDetailScreenLoadingBodyText.
  ///
  /// In en, this message translates to:
  /// **'Loading book details...'**
  String get bookDetailScreenLoadingBodyText;

  /// No description provided for @bookDetailScreenErrorAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get bookDetailScreenErrorAppBarTitle;

  /// No description provided for @bookDetailScreenErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load book details'**
  String get bookDetailScreenErrorTitle;

  /// No description provided for @bookDetailScreenUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get bookDetailScreenUnknownError;

  /// No description provided for @bookDetailScreenTryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get bookDetailScreenTryAgainButton;

  /// No description provided for @bookDetailScreenShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share Book'**
  String get bookDetailScreenShareButton;

  /// No description provided for @bookDetailScreenAppBarDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Detail'**
  String get bookDetailScreenAppBarDefaultTitle;

  /// No description provided for @bookDetailScreenAvailableOfflineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get bookDetailScreenAvailableOfflineTooltip;

  /// No description provided for @bookDetailScreenDownloadOfflineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download for offline'**
  String get bookDetailScreenDownloadOfflineTooltip;

  /// No description provided for @bookDetailScreenAlreadyOfflineSnackbar.
  ///
  /// In en, this message translates to:
  /// **'This book is already available offline'**
  String get bookDetailScreenAlreadyOfflineSnackbar;

  /// No description provided for @bookDetailScreenDownloadingSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Downloading book for offline reading...'**
  String get bookDetailScreenDownloadingSnackbar;

  /// No description provided for @bookDetailScreenDownloadFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Failed to download book'**
  String get bookDetailScreenDownloadFailedSnackbar;

  /// No description provided for @bookDetailScreenOverviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get bookDetailScreenOverviewTab;

  /// No description provided for @bookDetailScreenChaptersTab.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get bookDetailScreenChaptersTab;

  /// No description provided for @bookDetailScreenBookmarksTab.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookDetailScreenBookmarksTab;

  /// No description provided for @bookDetailScreenAiInsightsTab.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get bookDetailScreenAiInsightsTab;

  /// No description provided for @bookDetailScreenStartReadingButton.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get bookDetailScreenStartReadingButton;

  /// No description provided for @bookDetailScreenImageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get bookDetailScreenImageNotFound;

  /// No description provided for @bookDetailScreenNoCover.
  ///
  /// In en, this message translates to:
  /// **'No Cover'**
  String get bookDetailScreenNoCover;

  /// No description provided for @bookDetailScreenDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get bookDetailScreenDescriptionTitle;

  /// No description provided for @bookDetailScreenNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get bookDetailScreenNoDescription;

  /// No description provided for @bookDetailScreenBookDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetailScreenBookDetailsTitle;

  /// No description provided for @bookDetailScreenAuthorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get bookDetailScreenAuthorLabel;

  /// No description provided for @bookDetailScreenPublisherLabel.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get bookDetailScreenPublisherLabel;

  /// No description provided for @bookDetailScreenPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get bookDetailScreenPagesLabel;

  /// No description provided for @bookDetailScreenBookDetailsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Book details not available.'**
  String get bookDetailScreenBookDetailsNotAvailable;

  /// No description provided for @bookDetailScreenNoChaptersFound.
  ///
  /// In en, this message translates to:
  /// **'No chapters found'**
  String get bookDetailScreenNoChaptersFound;

  /// No description provided for @bookDetailScreenSingleReadingInfo.
  ///
  /// In en, this message translates to:
  /// **'This book is presented as a single reading'**
  String get bookDetailScreenSingleReadingInfo;

  /// No description provided for @bookDetailScreenVolumePrefix.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get bookDetailScreenVolumePrefix;

  /// No description provided for @bookDetailScreenUntitledVolume.
  ///
  /// In en, this message translates to:
  /// **'Untitled Volume'**
  String get bookDetailScreenUntitledVolume;

  /// No description provided for @bookDetailScreenNoChaptersInVolume.
  ///
  /// In en, this message translates to:
  /// **'No chapters in this volume'**
  String get bookDetailScreenNoChaptersInVolume;

  /// No description provided for @bookDetailScreenCannotOpenChapterError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this chapter. Missing required information.'**
  String get bookDetailScreenCannotOpenChapterError;

  /// No description provided for @bookDetailScreenCannotOpenSectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this section. Missing required information.'**
  String get bookDetailScreenCannotOpenSectionError;

  /// No description provided for @bookDetailScreenUntitledChapter.
  ///
  /// In en, this message translates to:
  /// **'Untitled Chapter'**
  String get bookDetailScreenUntitledChapter;

  /// No description provided for @bookDetailScreenNoSubtopicsInChapter.
  ///
  /// In en, this message translates to:
  /// **'No sub-topics in this chapter.'**
  String get bookDetailScreenNoSubtopicsInChapter;

  /// No description provided for @bookDetailScreenUntitledHeading.
  ///
  /// In en, this message translates to:
  /// **'Untitled Heading'**
  String get bookDetailScreenUntitledHeading;

  /// No description provided for @bookDetailScreenCouldNotLoadBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookmarks'**
  String get bookDetailScreenCouldNotLoadBookmarks;

  /// No description provided for @bookDetailScreenPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get bookDetailScreenPleaseTryAgainLater;

  /// No description provided for @bookDetailScreenNoBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get bookDetailScreenNoBookmarksYet;

  /// No description provided for @bookDetailScreenAddBookmarksHint.
  ///
  /// In en, this message translates to:
  /// **'You can add bookmarks while reading.'**
  String get bookDetailScreenAddBookmarksHint;

  /// No description provided for @bookDetailScreenBookmarkChapterPrefix.
  ///
  /// In en, this message translates to:
  /// **'Chapter:'**
  String get bookDetailScreenBookmarkChapterPrefix;

  /// No description provided for @bookDetailScreenRepositoryError.
  ///
  /// In en, this message translates to:
  /// **'Repository error'**
  String get bookDetailScreenRepositoryError;

  /// No description provided for @bookDetailScreenAiInsightsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI Insights Coming Soon'**
  String get bookDetailScreenAiInsightsComingSoon;

  /// No description provided for @readingScreenSettingsPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Settings'**
  String get readingScreenSettingsPanelTitle;

  /// No description provided for @readingScreenSettingsPanelPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Settings panel content'**
  String get readingScreenSettingsPanelPlaceholder;

  /// No description provided for @readingScreenTocPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get readingScreenTocPanelTitle;

  /// No description provided for @readingScreenAiToolAnalyzeVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Analyze Vocabulary'**
  String get readingScreenAiToolAnalyzeVocabulary;

  /// No description provided for @readingScreenAiToolSummarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get readingScreenAiToolSummarize;

  /// No description provided for @readingScreenAiToolSimilarBooks.
  ///
  /// In en, this message translates to:
  /// **'Similar Books'**
  String get readingScreenAiToolSimilarBooks;

  /// No description provided for @readingScreenAppBarDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingScreenAppBarDefaultTitle;

  /// No description provided for @readingScreenAiFeaturesTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get readingScreenAiFeaturesTooltip;

  /// No description provided for @readingScreenBookmarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get readingScreenBookmarkTooltip;

  /// No description provided for @readingScreenTextSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Text Settings'**
  String get readingScreenTextSettingsTooltip;

  /// No description provided for @readingScreenLoadingBookDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading book details...'**
  String get readingScreenLoadingBookDetails;

  /// No description provided for @readingScreenDownloadingBook.
  ///
  /// In en, this message translates to:
  /// **'Downloading book ({progress}%)...'**
  String readingScreenDownloadingBook(Object progress);

  /// No description provided for @readingScreenPreparingContent.
  ///
  /// In en, this message translates to:
  /// **'Preparing content...'**
  String get readingScreenPreparingContent;

  /// No description provided for @readingScreenUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get readingScreenUnknownError;

  /// No description provided for @readingScreenFailedToLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content'**
  String get readingScreenFailedToLoadContent;

  /// No description provided for @readingScreenRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get readingScreenRetryButton;

  /// No description provided for @readingScreenContentFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get readingScreenContentFallbackTitle;

  /// No description provided for @readingScreenNoContentSegments.
  ///
  /// In en, this message translates to:
  /// **'No content segments to display.'**
  String get readingScreenNoContentSegments;

  /// No description provided for @readingScreenChapterFallbackPrefix.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get readingScreenChapterFallbackPrefix;

  /// No description provided for @readingScreenSectionFallbackPrefix.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get readingScreenSectionFallbackPrefix;

  /// No description provided for @readingScreenNoSectionContent.
  ///
  /// In en, this message translates to:
  /// **'No content for this section.'**
  String get readingScreenNoSectionContent;

  /// No description provided for @readingScreenChapterExtractionError.
  ///
  /// In en, this message translates to:
  /// **'Could not start chapter extraction'**
  String get readingScreenChapterExtractionError;

  /// No description provided for @readingScreenDefinitionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Definition not available for this word'**
  String get readingScreenDefinitionNotAvailable;

  /// No description provided for @readingScreenPlainTextBookContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Content'**
  String get readingScreenPlainTextBookContentTitle;

  /// No description provided for @readingScreenNoContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get readingScreenNoContentAvailable;

  /// No description provided for @profileScreenManageNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get profileScreenManageNotificationsSubtitle;

  /// No description provided for @profileScreenNotificationsNotImplementedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Notification settings not implemented yet.'**
  String get profileScreenNotificationsNotImplementedSnackbar;

  /// No description provided for @profileScreenManageDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your download preferences'**
  String get profileScreenManageDownloadsSubtitle;

  /// No description provided for @profileScreenDownloadsNotImplementedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Download settings not implemented yet.'**
  String get profileScreenDownloadsNotImplementedSnackbar;

  /// No description provided for @profileScreenCacheManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache Management'**
  String get profileScreenCacheManagementTitle;

  /// No description provided for @profileScreenCacheManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View usage and clear cached content'**
  String get profileScreenCacheManagementSubtitle;

  /// No description provided for @profileScreenAppInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get profileScreenAppInfoTitle;

  /// No description provided for @profileScreenThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileScreenThemeLabel;

  /// No description provided for @profileScreenThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileScreenThemeLight;

  /// No description provided for @profileScreenThemeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get profileScreenThemeSepia;

  /// No description provided for @profileScreenThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileScreenThemeDark;

  /// No description provided for @profileScreenFontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get profileScreenFontSizeLabel;

  /// No description provided for @profileScreenFontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get profileScreenFontSizeSmall;

  /// No description provided for @profileScreenFontSizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get profileScreenFontSizeMedium;

  /// No description provided for @profileScreenFontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get profileScreenFontSizeLarge;

  /// No description provided for @profileScreenLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileScreenLanguageLabel;

  /// No description provided for @profileScreenVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get profileScreenVersionLabel;

  /// No description provided for @profileScreenCacheDialogTotalSize.
  ///
  /// In en, this message translates to:
  /// **'Total cache size: {size}'**
  String profileScreenCacheDialogTotalSize(Object size);

  /// No description provided for @profileScreenCacheDialogMemoryCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory Cache'**
  String get profileScreenCacheDialogMemoryCacheLabel;

  /// No description provided for @profileScreenCacheDialogPersistentCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Persistent Cache'**
  String get profileScreenCacheDialogPersistentCacheLabel;

  /// No description provided for @profileScreenCacheDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Clearing the cache will free up storage space but may cause slower loading times when you next access content.'**
  String get profileScreenCacheDialogDescription;

  /// No description provided for @profileScreenCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileScreenCancelButton;

  /// No description provided for @profileScreenClearMemoryCacheButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Memory Cache'**
  String get profileScreenClearMemoryCacheButton;

  /// No description provided for @profileScreenMemoryCacheClearedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Memory cache cleared'**
  String get profileScreenMemoryCacheClearedSnackbar;

  /// No description provided for @profileScreenClearPersistentCacheButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Persistent Cache'**
  String get profileScreenClearPersistentCacheButton;

  /// No description provided for @profileScreenPersistentCacheClearedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Persistent cache cleared'**
  String get profileScreenPersistentCacheClearedSnackbar;

  /// No description provided for @profileScreenClearAllCachesButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All Caches'**
  String get profileScreenClearAllCachesButton;

  /// No description provided for @profileScreenAllCachesClearedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'All caches cleared'**
  String get profileScreenAllCachesClearedSnackbar;

  /// No description provided for @profileScreenHelpFAQTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get profileScreenHelpFAQTitle;

  /// No description provided for @profileScreenHelpFAQSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get answers to frequently asked questions'**
  String get profileScreenHelpFAQSubtitle;

  /// No description provided for @profileScreenHelpNotImplementedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Help not implemented yet.'**
  String get profileScreenHelpNotImplementedSnackbar;

  /// No description provided for @profileScreenContactUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get profileScreenContactUsTitle;

  /// No description provided for @profileScreenContactUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with our support team'**
  String get profileScreenContactUsSubtitle;

  /// No description provided for @profileScreenContactNotAvailableSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Contact info not available yet.'**
  String get profileScreenContactNotAvailableSnackbar;

  /// No description provided for @videoPlayerScreenCouldNotOpenInYouTubeSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Could not open in YouTube.'**
  String get videoPlayerScreenCouldNotOpenInYouTubeSnackbar;

  /// No description provided for @videoPlayerScreenClosePlayerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close Player'**
  String get videoPlayerScreenClosePlayerTooltip;

  /// No description provided for @videoPlayerScreenUnknownChannel.
  ///
  /// In en, this message translates to:
  /// **'Unknown Channel'**
  String get videoPlayerScreenUnknownChannel;

  /// No description provided for @videoPlayerScreenDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get videoPlayerScreenDescriptionTitle;

  /// No description provided for @videoPlayerScreenOpenInYouTubeButton.
  ///
  /// In en, this message translates to:
  /// **'Open in YouTube App'**
  String get videoPlayerScreenOpenInYouTubeButton;

  /// No description provided for @videosScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Library'**
  String get videosScreenTitle;

  /// No description provided for @videosScreenPlaylistsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} playlist{count, plural, =1{} other{s}} available'**
  String videosScreenPlaylistsAvailable(num count);

  /// No description provided for @videosScreenLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String videosScreenLastUpdated(Object time);

  /// No description provided for @videosScreenJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get videosScreenJustNow;

  /// No description provided for @videosScreenMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minute{count, plural, =1{} other{s}} ago'**
  String videosScreenMinutesAgo(num count);

  /// No description provided for @videosScreenHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hour{count, plural, =1{} other{s}} ago'**
  String videosScreenHoursAgo(num count);

  /// No description provided for @videosScreenDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} day{count, plural, =1{} other{s}} ago'**
  String videosScreenDaysAgo(num count);

  /// No description provided for @videosScreenRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh Playlists'**
  String get videosScreenRefreshTooltip;

  /// No description provided for @videosScreenScrollToTopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get videosScreenScrollToTopTooltip;

  /// No description provided for @videosScreenLoadingPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Loading playlists...'**
  String get videosScreenLoadingPlaylists;

  /// No description provided for @videosScreenErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something Went Wrong'**
  String get videosScreenErrorTitle;

  /// No description provided for @videosScreenErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the playlists. Please check your connection and try again.'**
  String get videosScreenErrorMessage;

  /// No description provided for @videosScreenRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get videosScreenRetryButton;

  /// No description provided for @videosScreenGoHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get videosScreenGoHomeButton;

  /// No description provided for @videosScreenNoPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Playlists Found'**
  String get videosScreenNoPlaylistsTitle;

  /// No description provided for @videosScreenNoPlaylistsMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any video playlists at the moment.'**
  String get videosScreenNoPlaylistsMessage;

  /// No description provided for @videosScreenOutdatedDataWarning.
  ///
  /// In en, this message translates to:
  /// **'Some data might be outdated. {error}'**
  String videosScreenOutdatedDataWarning(Object error);

  /// No description provided for @videosScreenNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: Connection lost. Videos may not load properly.'**
  String get videosScreenNetworkError;

  /// No description provided for @videosScreenNoInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get videosScreenNoInternetConnection;

  /// No description provided for @accessibilityVideoPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Video playlist: {title}'**
  String accessibilityVideoPlaylist(Object title);

  /// No description provided for @accessibilityRefreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh content'**
  String get accessibilityRefreshButton;

  /// No description provided for @accessibilityScrollToTop.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top of page'**
  String get accessibilityScrollToTop;

  /// No description provided for @accessibilityNetworkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network connection status'**
  String get accessibilityNetworkStatus;

  /// No description provided for @accessibilityErrorState.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading content'**
  String get accessibilityErrorState;

  /// No description provided for @accessibilityLoadingState.
  ///
  /// In en, this message translates to:
  /// **'Content is loading'**
  String get accessibilityLoadingState;

  /// No description provided for @accessibilityEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get accessibilityEmptyState;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
