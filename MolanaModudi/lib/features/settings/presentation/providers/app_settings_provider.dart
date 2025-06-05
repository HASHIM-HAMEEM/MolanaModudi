import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

// Provider for app-level settings (separate from reading content settings)
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});

// Extended theme mode that includes sepia
enum AppThemeMode {
  light,
  dark,
  system,
  sepia;
  
  // Convert to standard ThemeMode for Flutter
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.sepia:
        return ThemeMode.light; // Sepia is a variant of light theme
    }
  }
}

// Enum for app UI font family choices (simpler list for app interface)
enum AppFontFamily {
  system('System Default'),
  roboto('Roboto'),
  openSans('Open Sans'),
  lato('Lato'),
  inter('Inter');
  
  final String displayName;
  const AppFontFamily(this.displayName);
  
  // Helper methods for font family conversion
  String get fontFamily {
    switch (this) {
      case AppFontFamily.system:
        return 'System';
      case AppFontFamily.roboto:
        return 'Roboto';
      case AppFontFamily.openSans:
        return 'OpenSans';
      case AppFontFamily.lato:
        return 'Lato';
      case AppFontFamily.inter:
        return 'Inter';
    }
  }
}

// Enum for app UI font sizes (affects app interface only, not reading content)
enum AppFontSize {
  extraSmall('Extra Small', 0.85),
  small('Small', 0.9),
  medium('Medium', 1.0),
  large('Large', 1.1),
  extraLarge('Extra Large', 1.2);
  
  final String displayName;
  final double scale;
  const AppFontSize(this.displayName, this.scale);
  
  // Helper method to get the next larger size
  AppFontSize get larger {
    switch (this) {
      case AppFontSize.extraSmall:
        return AppFontSize.small;
      case AppFontSize.small:
        return AppFontSize.medium;
      case AppFontSize.medium:
        return AppFontSize.large;
      case AppFontSize.large:
      case AppFontSize.extraLarge:
        return AppFontSize.extraLarge;
    }
  }
  
  // Helper method to get the next smaller size
  AppFontSize get smaller {
    switch (this) {
      case AppFontSize.extraSmall:
      case AppFontSize.small:
        return AppFontSize.extraSmall;
      case AppFontSize.medium:
        return AppFontSize.small;
      case AppFontSize.large:
        return AppFontSize.medium;
      case AppFontSize.extraLarge:
        return AppFontSize.large;
    }
  }
}

// Enum for supported languages
enum AppLanguage {
  english('en', 'English'),
  arabic('ar', 'Arabic'),
  urdu('ur', 'Urdu');
  
  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);
}

// State class for app-level settings
@immutable
class AppSettingsState {
  final AppThemeMode themeMode;
  final AppFontFamily appFontFamily;
  final AppFontSize appFontSize;
  final AppLanguage language;

  const AppSettingsState({
    this.themeMode = AppThemeMode.system,
    this.appFontFamily = AppFontFamily.system,
    this.appFontSize = AppFontSize.medium,
    this.language = AppLanguage.english,
  });

  // Helper properties
  ThemeMode get flutterThemeMode => themeMode.toThemeMode();
  bool get isSepia => themeMode == AppThemeMode.sepia;
  double get fontScale => appFontSize.scale;

  AppSettingsState copyWith({
    AppThemeMode? themeMode,
    AppFontFamily? appFontFamily,
    AppFontSize? appFontSize,
    AppLanguage? language,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      appFontFamily: appFontFamily ?? this.appFontFamily,
      appFontSize: appFontSize ?? this.appFontSize,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AppSettingsState &&
      other.themeMode == themeMode &&
      other.appFontFamily == appFontFamily &&
      other.appFontSize == appFontSize &&
      other.language == language;
  }

  @override
  int get hashCode {
    return Object.hash(themeMode, appFontFamily, appFontSize, language);
  }
}

// StateNotifier for app settings
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final _log = Logger('AppSettingsNotifier');

  AppSettingsNotifier() : super(const AppSettingsState()) {
    _loadSettings();
  }

  // Keys for SharedPreferences (prefixed to avoid conflicts with reading settings)
  static const String _appThemeModeKey = 'app_themeMode';
  static const String _appFontFamilyKey = 'app_fontFamily';
  static const String _appFontSizeKey = 'app_fontSize';
  static const String _appLanguageKey = 'app_language';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final themeModeIndex = prefs.getInt(_appThemeModeKey) ?? AppThemeMode.system.index;
      final fontFamilyIndex = prefs.getInt(_appFontFamilyKey) ?? AppFontFamily.system.index;
      final fontSizeIndex = prefs.getInt(_appFontSizeKey) ?? AppFontSize.medium.index;
      final languageIndex = prefs.getInt(_appLanguageKey) ?? AppLanguage.english.index;
      
      state = state.copyWith(
        themeMode: AppThemeMode.values[themeModeIndex.clamp(0, AppThemeMode.values.length - 1)],
        appFontFamily: AppFontFamily.values[fontFamilyIndex.clamp(0, AppFontFamily.values.length - 1)],
        appFontSize: AppFontSize.values[fontSizeIndex.clamp(0, AppFontSize.values.length - 1)],
        language: AppLanguage.values[languageIndex.clamp(0, AppLanguage.values.length - 1)],
      );
      
      _log.info('App settings loaded successfully');
    } catch (e) {
      _log.severe('Error loading app settings: $e');
    }
  }

  Future<void> setThemeMode(AppThemeMode themeMode) async {
    _log.info('Setting app theme mode to: $themeMode');
    if (state.themeMode == themeMode) {
      _log.info('Theme mode is already set to $themeMode, skipping update.');
      return;
    }

    try {
      state = state.copyWith(themeMode: themeMode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_appThemeModeKey, themeMode.index);
      _log.info('App theme mode saved successfully');
    } catch (e) {
      _log.severe('Error setting app theme mode: $e');
    }
  }
  
  Future<void> setAppFontFamily(AppFontFamily family) async {
    _log.info('Setting app font family to: $family');
    if (state.appFontFamily == family) return;
    
    try {
      state = state.copyWith(appFontFamily: family);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_appFontFamilyKey, family.index);
      _log.info('App font family saved successfully');
    } catch (e) {
      _log.severe('Error setting app font family: $e');
    }
  }
  
  Future<void> setAppFontSize(AppFontSize fontSize) async {
    _log.info('Setting app font size to: $fontSize');
    if (state.appFontSize == fontSize) return;
    
    try {
      state = state.copyWith(appFontSize: fontSize);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_appFontSizeKey, fontSize.index);
      _log.info('App font size saved successfully');
    } catch (e) {
      _log.severe('Error setting app font size: $e');
    }
  }
  
  Future<void> setLanguage(AppLanguage language) async {
    _log.info('Setting app language to: $language');
    if (state.language == language) {
      _log.info('Language is already set to $language, skipping update.');
      return;
    }
    
    try {
      state = state.copyWith(language: language);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_appLanguageKey, language.index);
      _log.info('App language saved successfully');
    } catch (e) {
      _log.severe('Error setting app language: $e');
    }
  }

  // Reset to default values
  Future<void> resetToDefaults() async {
    _log.info('Resetting app settings to defaults');
    try {
      state = const AppSettingsState();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appThemeModeKey);
      await prefs.remove(_appFontFamilyKey);
      await prefs.remove(_appFontSizeKey);
      await prefs.remove(_appLanguageKey);
      _log.info('App settings reset to defaults successfully');
    } catch (e) {
      _log.severe('Error resetting app settings: $e');
    }
  }
} 