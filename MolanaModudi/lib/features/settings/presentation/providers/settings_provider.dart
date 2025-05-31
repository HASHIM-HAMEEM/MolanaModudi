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

// Enum for font size options - Extended for better slider support
enum FontSize {
  size12(12.0),
  size13(13.0),
  size14(14.0),
  size15(15.0),
  size16(16.0),
  size17(17.0),
  size18(18.0),
  size19(19.0),
  size20(20.0),
  size21(21.0),
  size22(22.0),
  size23(23.0),
  size24(24.0),
  size25(25.0),
  size26(26.0),
  size27(27.0),
  size28(28.0);
  
  final double size;
  const FontSize(this.size);
  
  // Helper properties for compatibility
  static FontSize get small => FontSize.size14;
  static FontSize get medium => FontSize.size16;
  static FontSize get large => FontSize.size18;
  static FontSize get extraLarge => FontSize.size22;
  
  // Get FontSize from double value
  static FontSize fromSize(double size) {
    // Clamp the size to valid range first
    final clampedSize = size.clamp(12.0, 28.0);
    
    try {
      return FontSize.values.reduce((a, b) => 
        (a.size - clampedSize).abs() < (b.size - clampedSize).abs() ? a : b
      );
    } catch (e) {
      // Fallback to medium size if any error occurs
      return FontSize.size16;
    }
  }
}

// Enum for font family choices
enum FontFamily {
  serif('Serif'),
  sansSerif('SansSerif'),
  mono('Mono'),
  notoNastaliq('NotoNastaliqUrdu'),
  jameelNoori('Jameel Noori Nastaleeq Regular'),
  notoNaskh('NotoNaskhArabic');
  
  final String displayName;
  const FontFamily(this.displayName);
  
  // Helper methods for font family conversion
  String get fontFamily {
    switch (this) {
      case FontFamily.serif:
        return 'serif';
      case FontFamily.sansSerif:
        return 'sans-serif';
      case FontFamily.mono:
        return 'monospace';
      case FontFamily.notoNastaliq:
        return 'NotoNastaliqUrdu';
      case FontFamily.jameelNoori:
        return 'JameelNooriNastaleeqRegular';
      case FontFamily.notoNaskh:
        return 'NotoNaskhArabic';
    }
  }
  
  bool get isCustomFont {
    return this == FontFamily.notoNastaliq || 
           this == FontFamily.jameelNoori || 
           this == FontFamily.notoNaskh;
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

// State class
@immutable
class SettingsState {
  final AppThemeMode themeMode;
  final FontSize fontSize;
  final double lineSpacing;
  final FontFamily fontFamily;
  final AppLanguage language;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.fontSize = FontSize.size16,
    this.lineSpacing = 1.5,
    this.fontFamily = FontFamily.jameelNoori,
    this.language = AppLanguage.english,
  });

  // Helper properties
  ThemeMode get flutterThemeMode => themeMode.toThemeMode();
  bool get isSepia => themeMode == AppThemeMode.sepia;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    FontSize? fontSize,
    double? lineSpacing,
    FontFamily? fontFamily,
    AppLanguage? language,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
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
  static const String _lineSpacingKey = 'lineSpacing';
  static const String _fontFamilyKey = 'fontFamily';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? AppThemeMode.system.index;
    
    // Load font size
    final fontSizeIndex = prefs.getInt(_fontSizeKey) ?? FontSize.size16.index;
    
    // Load language
    final languageIndex = prefs.getInt(_languageKey) ?? AppLanguage.english.index;
    
    final lineSpacingValue = prefs.getDouble(_lineSpacingKey) ?? 1.5;
    
    // Use jameelNoori as default if no preference is saved
    final fontFamilyIndex = prefs.getInt(_fontFamilyKey) ?? FontFamily.jameelNoori.index;
    
    state = state.copyWith(
      themeMode: AppThemeMode.values[themeModeIndex],
      fontSize: FontSize.values[fontSizeIndex],
      lineSpacing: lineSpacingValue,
      fontFamily: FontFamily.values[fontFamilyIndex],
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
    if (state.fontSize == fontSize) {
      _log.info('Font size is already set to $fontSize, skipping update.');
      return;
    }
    
    try {
      // Update state with new font size
      state = state.copyWith(fontSize: fontSize);
      _log.info('State updated with new font size: ${state.fontSize}');
      
      // Persist the change
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_fontSizeKey, fontSize.index);
      _log.info('Saved font size to preferences: ${fontSize.index}');
    } catch (e, stack) {
      _log.severe('Error setting font size: $e\n$stack');
    }
  }
  
  Future<void> setFontSizeFromDouble(double size) async {
    final nearest = FontSize.fromSize(size);
    await setFontSize(nearest);
  }
  
  Future<void> setLineSpacing(double spacing) async {
    _log.info('Setting line spacing to: $spacing');
    if ((state.lineSpacing - spacing).abs() < 0.01) return;
    state = state.copyWith(lineSpacing: spacing);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineSpacingKey, spacing);
  }
  
  Future<void> setFontFamily(FontFamily family) async {
    _log.info('Setting font family to: $family');
    if (state.fontFamily == family) return;
    state = state.copyWith(fontFamily: family);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontFamilyKey, family.index);
  }
  
  Future<void> setLanguage(AppLanguage language) async {
    _log.info('Setting language to: $language');
    if (state.language == language) {
      _log.info('Language is already set to $language, skipping update.');
      return;
    }
    
    try {
      // Update state with new language
      state = state.copyWith(language: language);
      _log.info('State updated with new language: ${state.language}');
      
      // Persist the change
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_languageKey, language.index);
      _log.info('Saved language to preferences: ${language.index}');
    } catch (e, stack) {
      _log.severe('Error setting language: $e\n$stack');
    }
  }
}
