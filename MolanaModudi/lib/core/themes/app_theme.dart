import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color.dart';

/// Extension for applying app-wide font scaling
/// This only affects app UI, not reading content
extension AppFontScaling on TextStyle {
  /// Apply app font scale to this text style
  TextStyle withAppFontScale(double scale) {
    return copyWith(
      fontSize: (fontSize ?? 14.0) * scale,
    );
  }
}

/// Theme data helper to create consistent themes throughout the app
class AppTheme {
  /// Get font family based on language (used for default font fallback)
  static String getFontFamilyForLanguage(String languageCode) {
    if (languageCode == 'ur') {
      return 'JameelNooriNastaleeqRegular';
    } else if (languageCode == 'ar') {
      return 'NotoNaskhArabic';
    }
    return 'Roboto';
  }
  
  /// Main app theme
  static ThemeData get lightTheme => ThemeData(
    // Set the primary color swatch
    primaryColor: AppColor.primary,
    colorScheme: ColorScheme.light(
      primary: AppColor.primary,
      secondary: AppColor.accent,
      surface: AppColor.surface,
      error: AppColor.error,
      onPrimary: AppColor.textOnPrimary,
      onSecondary: AppColor.textOnPrimary,
      onSurface: AppColor.textPrimary,
      onError: AppColor.textOnPrimary,
    ),
    
    // Enhanced accessibility support
    visualDensity: VisualDensity.adaptivePlatformDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    
    // Define the default app background color
    scaffoldBackgroundColor: AppColor.background,
    
    // Card theme for consistency
    cardTheme: CardThemeData(
      color: AppColor.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColor.primary,
      foregroundColor: AppColor.textOnPrimary,
      elevation: 0,
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColor.surface,
      selectedItemColor: AppColor.primary,
      unselectedItemColor: AppColor.tabInactive,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primary,
        foregroundColor: AppColor.textOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColor.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColor.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.error, width: 2),
      ),
      labelStyle: TextStyle(color: AppColor.textSecondary),
      hintStyle: TextStyle(color: AppColor.textLight),
    ),
    
    // Chip theme for categories
    chipTheme: ChipThemeData(
      backgroundColor: AppColor.surfaceVariant,
      labelStyle: TextStyle(color: AppColor.textSecondary),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    // Progress indicator theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColor.accent,
      linearTrackColor: AppColor.progressBackground,
      circularTrackColor: AppColor.progressBackground,
    ),
    
    // Define text themes for consistent typography
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        // Large titles like page headers
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColor.textPrimary,
        ),
        // Section headers
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColor.textPrimary,
        ),
        // Item titles
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColor.textPrimary,
        ),
        // Smaller titles
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColor.textPrimary,
        ),
        // Body text
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColor.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColor.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColor.textSecondary,
        ),
        // Labels
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColor.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: AppColor.textLight,
        ),
      ),
    ),
  );

  /// Dark theme with proper contrast and visibility
  static ThemeData get darkTheme => ThemeData(
    primaryColor: AppColor.primaryDark,
    colorScheme: ColorScheme.dark(
      primary: AppColor.primaryDark,
      secondary: AppColor.accentDark,
      surface: AppColor.surfaceDark,
      error: AppColor.errorDark,
      onPrimary: AppColor.textOnPrimaryDark,
      onSecondary: AppColor.textOnPrimaryDark,
      onSurface: AppColor.textPrimaryDark,
      onError: AppColor.textOnPrimaryDark,
    ),
    
    // Enhanced accessibility support
    visualDensity: VisualDensity.adaptivePlatformDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    
    scaffoldBackgroundColor: AppColor.backgroundDark,
    
    cardTheme: CardThemeData(
      color: AppColor.surfaceDark,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: AppColor.surfaceDark,
      foregroundColor: AppColor.textPrimaryDark,
      elevation: 0,
    ),
    
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColor.surfaceDark,
      selectedItemColor: AppColor.accentDark,
      unselectedItemColor: AppColor.tabInactiveDark,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primaryDark,
        foregroundColor: AppColor.textOnPrimaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColor.accentDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColor.surfaceDark.withValues(alpha: 0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.accentDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.errorDark),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColor.errorDark, width: 2),
      ),
      labelStyle: TextStyle(color: AppColor.textSecondaryDark),
      hintStyle: TextStyle(color: AppColor.textLightDark),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: AppColor.surfaceVariantDark,
      labelStyle: TextStyle(color: AppColor.textSecondaryDark),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColor.accentDark,
      linearTrackColor: AppColor.progressBackgroundDark,
      circularTrackColor: AppColor.progressBackgroundDark,
    ),
    
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColor.textPrimaryDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColor.textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColor.textPrimaryDark,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColor.textPrimaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColor.textPrimaryDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColor.textPrimaryDark,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColor.textSecondaryDark,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColor.textSecondaryDark,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: AppColor.textLightDark,
        ),
      ),
    ),
  );
  
  /// Sepia theme for comfortable reading
  static ThemeData get sepiaTheme {
    return ThemeData(
      primaryColor: AppColor.primarySepia,
      colorScheme: ColorScheme.light(
        primary: AppColor.primarySepia,
        secondary: AppColor.accentSepia,
        surface: AppColor.surfaceSepia,
        error: AppColor.error,
        onPrimary: AppColor.textOnPrimarySepia,
        onSecondary: AppColor.textOnPrimarySepia,
        onSurface: AppColor.textPrimarySepia,
        onError: AppColor.textOnPrimarySepia,
      ),
      
      scaffoldBackgroundColor: AppColor.backgroundSepia,
      
      cardTheme: CardThemeData(
        color: AppColor.surfaceSepia,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColor.primarySepia,
        foregroundColor: AppColor.textOnPrimarySepia,
        elevation: 0,
      ),
      
      textTheme: GoogleFonts.crimsonTextTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimarySepia,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimarySepia,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColor.textPrimarySepia,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.textPrimarySepia,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColor.textPrimarySepia,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColor.textPrimarySepia,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColor.textSecondarySepia,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColor.textSecondarySepia,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            color: AppColor.textSecondarySepia,
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primarySepia,
          foregroundColor: AppColor.textOnPrimarySepia,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.primarySepia,
          foregroundColor: AppColor.textOnPrimarySepia,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.primarySepia,
          side: BorderSide(color: AppColor.primarySepia),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.primarySepia.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.primarySepia.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.primarySepia, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: AppColor.accentSepia.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: AppColor.primarySepia),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: AppColor.primarySepia.withValues(alpha: 0.2),
        thickness: 1,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColor.surfaceSepia,
        selectedItemColor: AppColor.primarySepia,
        unselectedItemColor: AppColor.textSecondarySepia,
        type: BottomNavigationBarType.fixed,
      ),
      
      tabBarTheme: TabBarThemeData(
        labelColor: AppColor.primarySepia,
        unselectedLabelColor: AppColor.textSecondarySepia,
        indicatorColor: AppColor.primarySepia,
      ),
    );
  }
}
