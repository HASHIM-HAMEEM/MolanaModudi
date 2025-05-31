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
  final AppLanguage language;

  const AppSettingsState({
    this.themeMode = AppThemeMode.system,
    this.appFontFamily = AppFontFamily.system,
    this.language = AppLanguage.english,
  });

  // Helper properties
  ThemeMode get flutterThemeMode => themeMode.toThemeMode();
  bool get isSepia => themeMode == AppThemeMode.sepia;

  AppSettingsState copyWith({
    AppThemeMode? themeMode,
    AppFontFamily? appFontFamily,
    AppLanguage? language,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      appFontFamily: appFontFamily ?? this.appFontFamily,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AppSettingsState &&
      other.themeMode == themeMode &&
      other.appFontFamily == appFontFamily &&
      other.language == language;
  }

  @override
  int get hashCode {
    return Object.hash(themeMode, appFontFamily, language);
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
  static const String _appLanguageKey = 'app_language';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final themeModeIndex = prefs.getInt(_appThemeModeKey) ?? AppThemeMode.system.index;
      final fontFamilyIndex = prefs.getInt(_appFontFamilyKey) ?? AppFontFamily.system.index;
      final languageIndex = prefs.getInt(_appLanguageKey) ?? AppLanguage.english.index;
      
      state = state.copyWith(
        themeMode: AppThemeMode.values[themeModeIndex.clamp(0, AppThemeMode.values.length - 1)],
        appFontFamily: AppFontFamily.values[fontFamilyIndex.clamp(0, AppFontFamily.values.length - 1)],
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
      const defaultState = AppSettingsState();
      state = defaultState;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_appThemeModeKey, defaultState.themeMode.index);
      await prefs.setInt(_appFontFamilyKey, defaultState.appFontFamily.index);
      await prefs.setInt(_appLanguageKey, defaultState.language.index);
      
      _log.info('App settings reset successfully');
    } catch (e) {
      _log.severe('Error resetting app settings: $e');
    }
  }
} 