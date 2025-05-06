import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

// Provider definition
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
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

// Enum for font size options
enum FontSize {
  small(12.0),
  medium(14.0),
  large(16.0),
  extraLarge(18.0);
  
  final double size;
  const FontSize(this.size);
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

// State class
@immutable
class SettingsState {
  final AppThemeMode themeMode;
  final FontSize fontSize;
  final AppLanguage language;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.fontSize = FontSize.medium,
    this.language = AppLanguage.english,
  });

  // Helper properties
  ThemeMode get flutterThemeMode => themeMode.toThemeMode();
  bool get isSepia => themeMode == AppThemeMode.sepia;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    FontSize? fontSize,
    AppLanguage? language,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      language: language ?? this.language,
    );
  }
}

// StateNotifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final _log = Logger('SettingsNotifier');

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  // Keys for SharedPreferences
  static const String _themeModeKey = 'themeMode';
  static const String _fontSizeKey = 'fontSize';
  static const String _languageKey = 'language';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? AppThemeMode.system.index;
    
    // Load font size
    final fontSizeIndex = prefs.getInt(_fontSizeKey) ?? FontSize.medium.index;
    
    // Load language
    final languageIndex = prefs.getInt(_languageKey) ?? AppLanguage.english.index;
    
    state = state.copyWith(
      themeMode: AppThemeMode.values[themeModeIndex],
      fontSize: FontSize.values[fontSizeIndex],
      language: AppLanguage.values[languageIndex],
    );
  }

  Future<void> setThemeMode(AppThemeMode themeMode) async {
    _log.info('Setting theme mode to: $themeMode');
    if (state.themeMode == themeMode) {
      _log.info('Theme mode is already set to $themeMode, skipping update.');
      return;
    }

    try {
      _log.info('Current state before update: themeMode=${state.themeMode}');
      state = state.copyWith(themeMode: themeMode);
      _log.info('State updated with new theme mode: ${state.themeMode}');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, themeMode.index);
      _log.info('Saved theme mode to preferences: ${themeMode.index}');
    } catch (e, stack) {
      _log.severe('Error setting theme mode: $e\n$stack');
    }
  }
  
  Future<void> setFontSize(FontSize fontSize) async {
    _log.info('Setting font size to: $fontSize');
    if (state.fontSize == fontSize) return;
    
    state = state.copyWith(fontSize: fontSize);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontSizeKey, fontSize.index);
  }
  
  Future<void> setLanguage(AppLanguage language) async {
    _log.info('Setting language to: $language');
    if (state.language == language) return;
    
    state = state.copyWith(language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, language.index);
  }
}
