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
  serif('Serif'),
  sansSerif('SansSerif'),
  mono('Mono'),
  roboto('Roboto'),
  openSans('Open Sans'),
  lato('Lato'),
  notoNastaliq('NotoNastaliqUrdu'),
  jameelNoori('Jameel Noori Nastaleeq Regular'),
  notoNaskh('NotoNaskhArabic'),
  amiriQuran('Amiri Quran'),
  scheherazade('Scheherazade New');
  
  final String displayName;
  const ReadingFontFamily(this.displayName);
  
  // Helper methods for font family conversion
  String get fontFamily {
    switch (this) {
      case ReadingFontFamily.serif:
        return 'serif';
      case ReadingFontFamily.sansSerif:
        return 'sans-serif';
      case ReadingFontFamily.mono:
        return 'monospace';
      case ReadingFontFamily.roboto:
        return 'Roboto';
      case ReadingFontFamily.openSans:
        return 'OpenSans';
      case ReadingFontFamily.lato:
        return 'Lato';
      case ReadingFontFamily.notoNastaliq:
        return 'NotoNastaliqUrdu';
      case ReadingFontFamily.jameelNoori:
        return 'JameelNooriNastaleeqRegular';
      case ReadingFontFamily.notoNaskh:
        return 'NotoNaskhArabic';
      case ReadingFontFamily.amiriQuran:
        return 'AmiriQuran';
      case ReadingFontFamily.scheherazade:
        return 'ScheherazadeNew';
    }
  }
  
  bool get isCustomFont {
    return this == ReadingFontFamily.notoNastaliq || 
           this == ReadingFontFamily.jameelNoori || 
           this == ReadingFontFamily.notoNaskh ||
           this == ReadingFontFamily.amiriQuran ||
           this == ReadingFontFamily.scheherazade;
  }

  // Get font families suitable for Arabic/Urdu content
  static List<ReadingFontFamily> get arabicUrduFonts => [
    ReadingFontFamily.jameelNoori,
    ReadingFontFamily.notoNastaliq,
    ReadingFontFamily.notoNaskh,
    ReadingFontFamily.amiriQuran,
    ReadingFontFamily.scheherazade,
  ];

  // Get font families suitable for English content
  static List<ReadingFontFamily> get englishFonts => [
    ReadingFontFamily.roboto,
    ReadingFontFamily.openSans,
    ReadingFontFamily.lato,
    ReadingFontFamily.serif,
    ReadingFontFamily.sansSerif,
    ReadingFontFamily.mono,
  ];
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

  const ReadingSettingsState({
    this.fontSize = ReadingFontSize.size16,
    this.lineSpacing = 1.5,
    this.fontFamily = ReadingFontFamily.jameelNoori,
    this.letterSpacing = 0.0,
    this.wordSpacing = 0.0,
    this.fontWeight = FontWeight.normal,
    this.paragraphSpacing = 16.0,
  });

  ReadingSettingsState copyWith({
    ReadingFontSize? fontSize,
    double? lineSpacing,
    ReadingFontFamily? fontFamily,
    double? letterSpacing,
    double? wordSpacing,
    FontWeight? fontWeight,
    double? paragraphSpacing,
  }) {
    return ReadingSettingsState(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      fontWeight: fontWeight ?? this.fontWeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
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
      other.paragraphSpacing == paragraphSpacing;
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
      
      state = state.copyWith(
        fontSize: ReadingFontSize.values[fontSizeIndex.clamp(0, ReadingFontSize.values.length - 1)],
        lineSpacing: lineSpacingValue.clamp(1.0, 3.0),
        fontFamily: ReadingFontFamily.values[fontFamilyIndex.clamp(0, ReadingFontFamily.values.length - 1)],
        letterSpacing: letterSpacingValue.clamp(-2.0, 5.0),
        wordSpacing: wordSpacingValue.clamp(0.0, 10.0),
        fontWeight: FontWeight.values[fontWeightIndex.clamp(0, FontWeight.values.length - 1)],
        paragraphSpacing: paragraphSpacingValue.clamp(8.0, 32.0),
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
      
      _log.info('Reading settings reset successfully');
    } catch (e) {
      _log.severe('Error resetting reading settings: $e');
    }
  }
} 