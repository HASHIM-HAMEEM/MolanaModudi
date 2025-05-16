import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension to simplify access to localized strings
extension LocalizationExtension on BuildContext {
  /// Get the AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Utility class for working with localization
class L10n {
  /// Get the list of supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ar'), // Arabic
    Locale('ur'), // Urdu
  ];

  /// Get the localization delegates
  static const localizationsDelegates = AppLocalizations.localizationsDelegates;
  
  /// Get the locale name from locale
  static String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }
}

extension LanguageExtensions on String {
  bool get isRTL => this == 'ar' || this == 'ur';
}
