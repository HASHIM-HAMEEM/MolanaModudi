/// String extensions for language and text handling
/// 
/// This file contains extensions for String operations related to
/// language detection, RTL support, and text formatting.
library;

import 'package:flutter/widgets.dart';

extension LanguageExtensions on String {
  /// Determines if a language code represents a right-to-left language
  bool get isRTL => this == 'ar' || this == 'ur';
  
  /// Alias for [isRTL] using lowerCamel case to avoid naming confusion.
  bool get isRtl => isRTL;

  /// Returns the appropriate TextDirection for a language code
  TextDirection get textDirection => isRTL ? TextDirection.rtl : TextDirection.ltr;

  /// Determines if a language code represents Urdu
  bool get isUrdu => this == 'ur';

  /// Determines if a language code represents Arabic
  bool get isArabic => this == 'ar';
  
  /// Returns the standard font family for a language code
  String get preferredFontFamily {
    switch (this) {
      case 'ar':
        return 'NotoNaskhArabic';
      case 'ur':
        return 'JameelNooriNastaleeqRegular';
      default:
        return 'Roboto';
    }
  }
  
  /// Returns whether a language code is supported with special fonts
  bool get hasSpecialFont => ['ar', 'ur'].contains(this);
  
  /// Gets the default font family for a language to be used as a fallback
  String get defaultFontFamily {
    if (isUrdu) return 'JameelNooriNastaleeqRegular';
    if (isArabic) return 'NotoNaskhArabic';
    return 'Roboto';
  }
}
