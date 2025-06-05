import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

// Provider for reading-specific settings
final readingSettingsProvider = StateNotifierProvider<ReadingSettingsNotifier, ReadingSettingsState>((ref) {
  return ReadingSettingsNotifier();
});

// Enum for reading content font size options
enum ReadingFontSize {
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
  size28(28.0),
  size30(30.0),
  size32(32.0),
  size36(36.0);
  
  final double size;
  const ReadingFontSize(this.size);
  
  // Get ReadingFontSize from double value
  static ReadingFontSize fromSize(double size) {
    final clampedSize = size.clamp(12.0, 36.0);
    
    try {
      return ReadingFontSize.values.reduce((a, b) => 
        (a.size - clampedSize).abs() < (b.size - clampedSize).abs() ? a : b
      );
    } catch (e) {
      return ReadingFontSize.size16;
    }
  }
}

// Enum for reading content font family choices
enum ReadingFontFamily {
  notoNastaliq('NotoNastaliqUrdu'),
  jameelNoori('Jameel Noori Nastaleeq Regular'),
  amiriQuran('Amiri Quran');
  
  final String displayName;
  const ReadingFontFamily(this.displayName);
  
  // Helper methods for font family conversion
  String get fontFamily {
    switch (this) {
      case ReadingFontFamily.notoNastaliq:
        return 'NotoNastaliqUrdu';
      case ReadingFontFamily.jameelNoori:
        return 'JameelNooriNastaleeqRegular';
      case ReadingFontFamily.amiriQuran:
        return 'AmiriQuran';
    }
  }
  
  bool get isCustomFont {
    return this == ReadingFontFamily.notoNastaliq || 
           this == ReadingFontFamily.jameelNoori || 
           this == ReadingFontFamily.amiriQuran;
  }

  // Get font families suitable for Arabic/Urdu content
  static List<ReadingFontFamily> get arabicUrduFonts => [
    ReadingFontFamily.jameelNoori,
    ReadingFontFamily.notoNastaliq,
    ReadingFontFamily.amiriQuran,
  ];

  // Get font families suitable for English content (kept for compatibility but empty)
  static List<ReadingFontFamily> get englishFonts => [];
}

// Reading-specific theme mode (separate from global app theme)
enum ReadingThemeMode {
  light,
  dark,
  sepia,
  system;
  
  // Convert to standard ThemeMode for Flutter
  ThemeMode toThemeMode() {
    switch (this) {
      case ReadingThemeMode.light:
        return ThemeMode.light;
      case ReadingThemeMode.dark:
        return ThemeMode.dark;
      case ReadingThemeMode.system:
        return ThemeMode.system;
      case ReadingThemeMode.sepia:
        return ThemeMode.light; // Sepia is a variant of light theme
    }
  }
}

// State class for reading settings
@immutable
class ReadingSettingsState {
  final ReadingFontSize fontSize;
  final double lineSpacing;
  final ReadingFontFamily fontFamily;
  final double letterSpacing;
  final double wordSpacing;
  final FontWeight fontWeight;
  final double paragraphSpacing;
  final bool pageFlipAnimationEnabled;
  final bool focusModeEnabled;
  final ReadingThemeMode themeMode; // Add reading-specific theme

  const ReadingSettingsState({
    this.fontSize = ReadingFontSize.size16,
    this.lineSpacing = 1.5,
    this.fontFamily = ReadingFontFamily.jameelNoori,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.fontWeight = FontWeight.normal,
    this.paragraphSpacing = 16.0,
    this.pageFlipAnimationEnabled = true,
    this.focusModeEnabled = false,
    this.themeMode = ReadingThemeMode.system, // Default to system
  });

  // Helper properties for reading theme
  bool get isSepia => themeMode == ReadingThemeMode.sepia;
  bool get isDark => themeMode == ReadingThemeMode.dark;
  bool get isLight => themeMode == ReadingThemeMode.light;

  ReadingSettingsState copyWith({
    ReadingFontSize? fontSize,
    double? lineSpacing,
    ReadingFontFamily? fontFamily,
    double? letterSpacing,
    double? wordSpacing,
    FontWeight? fontWeight,
    double? paragraphSpacing,
    bool? pageFlipAnimationEnabled,
    bool? focusModeEnabled,
    ReadingThemeMode? themeMode,
  }) {
    return ReadingSettingsState(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      fontWeight: fontWeight ?? this.fontWeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      pageFlipAnimationEnabled: pageFlipAnimationEnabled ?? this.pageFlipAnimationEnabled,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ReadingSettingsState &&
      other.fontSize == fontSize &&
      other.lineSpacing == lineSpacing &&
      other.fontFamily == fontFamily &&
      other.letterSpacing == letterSpacing &&
      other.wordSpacing == wordSpacing &&
      other.fontWeight == fontWeight &&
      other.paragraphSpacing == paragraphSpacing &&
      other.pageFlipAnimationEnabled == pageFlipAnimationEnabled &&
      other.focusModeEnabled == focusModeEnabled &&
      other.themeMode == themeMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontSize,
      lineSpacing,
      fontFamily,
      letterSpacing,
      wordSpacing,
      fontWeight,
      paragraphSpacing,
      pageFlipAnimationEnabled,
      focusModeEnabled,
      themeMode,
    );
  }
}

// StateNotifier for reading settings
class ReadingSettingsNotifier extends StateNotifier<ReadingSettingsState> {
  final _log = Logger('ReadingSettingsNotifier');

  ReadingSettingsNotifier() : super(const ReadingSettingsState()) {
    _loadSettings();
  }

  // Keys for SharedPreferences (prefixed to avoid conflicts with app settings)
  static const String _readingFontSizeKey = 'reading_fontSize';
  static const String _readingLineSpacingKey = 'reading_lineSpacing';
  static const String _readingFontFamilyKey = 'reading_fontFamily';
  static const String _readingLetterSpacingKey = 'reading_letterSpacing';
  static const String _readingWordSpacingKey = 'reading_wordSpacing';
  static const String _readingFontWeightKey = 'reading_fontWeight';
  static const String _readingParagraphSpacingKey = 'reading_paragraphSpacing';
  static const String _pageFlipAnimationEnabledKey = 'reading_pageFlipAnimationEnabled';
  static const String _focusModeEnabledKey = 'reading_focusModeEnabled';
  static const String _readingThemeModeKey = 'reading_themeMode'; // Add reading theme key

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final fontSizeIndex = prefs.getInt(_readingFontSizeKey) ?? ReadingFontSize.size16.index;
      final lineSpacingValue = prefs.getDouble(_readingLineSpacingKey) ?? 1.5;
      final fontFamilyIndex = prefs.getInt(_readingFontFamilyKey) ?? ReadingFontFamily.jameelNoori.index;
      final letterSpacingValue = prefs.getDouble(_readingLetterSpacingKey) ?? 0.0;
      final wordSpacingValue = prefs.getDouble(_readingWordSpacingKey) ?? 0.0;
      final fontWeightIndex = prefs.getInt(_readingFontWeightKey) ?? FontWeight.normal.index;
      final paragraphSpacingValue = prefs.getDouble(_readingParagraphSpacingKey) ?? 16.0;
      final pageFlipAnimationEnabled = prefs.getBool(_pageFlipAnimationEnabledKey) ?? true;
      final focusModeEnabled = prefs.getBool(_focusModeEnabledKey) ?? false;
      final themeModeIndex = prefs.getInt(_readingThemeModeKey) ?? ReadingThemeMode.system.index;
      
      state = state.copyWith(
        fontSize: ReadingFontSize.values[fontSizeIndex.clamp(0, ReadingFontSize.values.length - 1)],
        lineSpacing: lineSpacingValue.clamp(1.0, 2.5),
        fontFamily: ReadingFontFamily.values[fontFamilyIndex.clamp(0, ReadingFontFamily.values.length - 1)],
        letterSpacing: letterSpacingValue.clamp(-1.0, 2.0),
        wordSpacing: wordSpacingValue.clamp(-1.0, 2.0),
        fontWeight: FontWeight.values[fontWeightIndex.clamp(0, FontWeight.values.length - 1)],
        paragraphSpacing: paragraphSpacingValue.clamp(8.0, 32.0),
        pageFlipAnimationEnabled: pageFlipAnimationEnabled,
        focusModeEnabled: focusModeEnabled,
        themeMode: ReadingThemeMode.values[themeModeIndex.clamp(0, ReadingThemeMode.values.length - 1)],
      );
      
      _log.info('Reading settings loaded successfully');
    } catch (e) {
      _log.severe('Error loading reading settings: $e');
    }
  }

  Future<void> setFontSize(ReadingFontSize fontSize) async {
    _log.info('Setting reading font size to: $fontSize');
    if (state.fontSize == fontSize) return;
    
    try {
      state = state.copyWith(fontSize: fontSize);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_readingFontSizeKey, fontSize.index);
      _log.info('Reading font size saved successfully');
    } catch (e) {
      _log.severe('Error setting reading font size: $e');
    }
  }
  
  Future<void> setFontSizeFromDouble(double size) async {
    final nearest = ReadingFontSize.fromSize(size);
    await setFontSize(nearest);
  }
  
  Future<void> setLineSpacing(double spacing) async {
    _log.info('Setting reading line spacing to: $spacing');
    final clampedSpacing = spacing.clamp(1.0, 3.0);
    if ((state.lineSpacing - clampedSpacing).abs() < 0.01) return;
    
    try {
      state = state.copyWith(lineSpacing: clampedSpacing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_readingLineSpacingKey, clampedSpacing);
    } catch (e) {
      _log.severe('Error setting reading line spacing: $e');
    }
  }
  
  Future<void> setFontFamily(ReadingFontFamily family) async {
    _log.info('Setting reading font family to: $family');
    if (state.fontFamily == family) return;
    
    try {
      state = state.copyWith(fontFamily: family);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_readingFontFamilyKey, family.index);
    } catch (e) {
      _log.severe('Error setting reading font family: $e');
    }
  }

  Future<void> setLetterSpacing(double spacing) async {
    _log.info('Setting reading letter spacing to: $spacing');
    final clampedSpacing = spacing.clamp(-2.0, 5.0);
    if ((state.letterSpacing - clampedSpacing).abs() < 0.01) return;
    
    try {
      state = state.copyWith(letterSpacing: clampedSpacing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_readingLetterSpacingKey, clampedSpacing);
    } catch (e) {
      _log.severe('Error setting reading letter spacing: $e');
    }
  }

  Future<void> setWordSpacing(double spacing) async {
    _log.info('Setting reading word spacing to: $spacing');
    final clampedSpacing = spacing.clamp(0.0, 10.0);
    if ((state.wordSpacing - clampedSpacing).abs() < 0.01) return;
    
    try {
      state = state.copyWith(wordSpacing: clampedSpacing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_readingWordSpacingKey, clampedSpacing);
    } catch (e) {
      _log.severe('Error setting reading word spacing: $e');
    }
  }

  Future<void> setFontWeight(FontWeight weight) async {
    _log.info('Setting reading font weight to: $weight');
    if (state.fontWeight == weight) return;
    
    try {
      state = state.copyWith(fontWeight: weight);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_readingFontWeightKey, weight.index);
    } catch (e) {
      _log.severe('Error setting reading font weight: $e');
    }
  }

  Future<void> setParagraphSpacing(double spacing) async {
    _log.info('Setting reading paragraph spacing to: $spacing');
    final clampedSpacing = spacing.clamp(8.0, 32.0);
    if ((state.paragraphSpacing - clampedSpacing).abs() < 0.01) return;
    
    try {
      state = state.copyWith(paragraphSpacing: clampedSpacing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_readingParagraphSpacingKey, clampedSpacing);
    } catch (e) {
      _log.severe('Error setting reading paragraph spacing: $e');
    }
  }

  Future<void> setPageFlipAnimationEnabled(bool enabled) async {
    _log.info('Setting page flip animation to: $enabled');
    if (state.pageFlipAnimationEnabled == enabled) return;
    
    try {
      state = state.copyWith(pageFlipAnimationEnabled: enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pageFlipAnimationEnabledKey, enabled);
      _log.info('Page flip animation setting saved successfully');
    } catch (e) {
      _log.severe('Error setting page flip animation: $e');
    }
  }

  Future<void> setFocusModeEnabled(bool enabled) async {
    _log.info('Setting focus mode to: $enabled');
    if (state.focusModeEnabled == enabled) return;
    
    try {
      state = state.copyWith(focusModeEnabled: enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_focusModeEnabledKey, enabled);
      _log.info('Focus mode setting saved successfully');
    } catch (e) {
      _log.severe('Error setting focus mode: $e');
    }
  }

  // Add method to set reading theme mode
  Future<void> setReadingThemeMode(ReadingThemeMode themeMode) async {
    _log.info('Setting reading theme mode to: $themeMode');
    if (state.themeMode == themeMode) {
      _log.info('Reading theme mode is already set to $themeMode, skipping update.');
      return;
    }

    try {
      state = state.copyWith(themeMode: themeMode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_readingThemeModeKey, themeMode.index);
      _log.info('Reading theme mode saved successfully');
    } catch (e) {
      _log.severe('Error setting reading theme mode: $e');
    }
  }

  // Reset to default values
  Future<void> resetToDefaults() async {
    _log.info('Resetting reading settings to defaults');
    try {
      const defaultState = ReadingSettingsState();
      state = defaultState;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_readingFontSizeKey, defaultState.fontSize.index);
      await prefs.setDouble(_readingLineSpacingKey, defaultState.lineSpacing);
      await prefs.setInt(_readingFontFamilyKey, defaultState.fontFamily.index);
      await prefs.setDouble(_readingLetterSpacingKey, defaultState.letterSpacing);
      await prefs.setDouble(_readingWordSpacingKey, defaultState.wordSpacing);
      await prefs.setInt(_readingFontWeightKey, defaultState.fontWeight.index);
      await prefs.setDouble(_readingParagraphSpacingKey, defaultState.paragraphSpacing);
      await prefs.setBool(_pageFlipAnimationEnabledKey, defaultState.pageFlipAnimationEnabled);
      await prefs.setBool(_focusModeEnabledKey, defaultState.focusModeEnabled);
      await prefs.setInt(_readingThemeModeKey, defaultState.themeMode.index);
      
      _log.info('Reading settings reset successfully');
    } catch (e) {
      _log.severe('Error resetting reading settings: $e');
    }
  }
} 