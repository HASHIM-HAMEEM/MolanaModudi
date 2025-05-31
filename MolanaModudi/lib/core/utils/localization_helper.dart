import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
import 'package:modudi/core/l10n/app_localizations_wrapper.dart';

/// Helper class for consistent localization across the app
class LocalizationHelper {
  /// Get the currently selected locale based on app settings
  static Locale getSelectedLocale(WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    switch (settings.language) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.arabic:
        return const Locale('ar');
      case AppLanguage.urdu:
        return const Locale('ur');
    }
  }
  
  /// Force reload the app with the selected locale
  static void updateAppLocale(WidgetRef ref, BuildContext context, AppLanguage language) {
    // Update the settings provider
    ref.read(settingsProvider.notifier).setLanguage(language);
  }
  
  /// Check if the current locale is right-to-left
  static bool isRtl(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar' || locale.languageCode == 'ur';
  }
  
  /// Get text direction based on locale
  static TextDirection getTextDirection(BuildContext context) {
    return isRtl(context) ? TextDirection.rtl : TextDirection.ltr;
  }
}

/// Extension on BuildContext to easily access localized strings
extension LocalizationHelperExtension on BuildContext {
  /// Get the AppLocalizations instance with a guarantee it exists
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  
  /// Check if current locale is RTL
  bool get isRtl => Localizations.localeOf(this).languageCode == 'ar' || 
                    Localizations.localeOf(this).languageCode == 'ur';
                    
  /// Get text direction based on current locale
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;
}
