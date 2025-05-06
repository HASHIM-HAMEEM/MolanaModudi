import 'package:flutter/material.dart';

/// App color theme based on the UI designs for Maulana Maududi app
/// This file defines all color constants used throughout the app
/// to maintain consistent branding and visual identity.
class AppColor {
  // Primary Emerald Colors
  static const Color primary = Color(0xFF047857);      // emerald-700 - Main brand color
  static const Color primaryLight = Color(0xFF059669); // emerald-600 - Secondary brand color
  static const Color accent = Color(0xFF10B981);       // emerald-500 - For highlights/progress
  static const Color primaryLighter = Color(0xFFD1FAE5); // emerald-100 - Very light brand color for backgrounds
  
  // Background Colors
  static const Color background = Color(0xFFF9FAFB);   // gray-50 - Main app background
  static const Color surface = Color(0xFFFFFFFF);      // white - Card/surface elements
  static const Color surfaceVariant = Color(0xFFF3F4F6); // gray-100 - Alternative surface color
  
  // Text Colors
  static const Color textPrimary = Color(0xFF374151);  // gray-700 - Main text color
  static const Color textSecondary = Color(0xFF6B7280); // gray-500 - Secondary text color
  static const Color textLight = Color(0xFF9CA3AF);    // gray-400 - Tertiary/hint text color
  static const Color textOnPrimary = Color(0xFFFFFFFF); // white - Text on primary color
  
  // UI Element Colors
  static const Color divider = Color(0xFFE5E7EB);      // gray-200 - Dividers and borders
  static const Color disabled = Color(0xFFD1D5DB);     // gray-300 - Disabled elements
  static const Color error = Color(0xFFDC2626);        // red-600 - Error states
  static const Color success = Color(0xFF10B981);      // emerald-500 - Success states
  static const Color warning = Color(0xFFF59E0B);      // amber-500 - Warning states
  static const Color info = Color(0xFF3B82F6);         // blue-500 - Info states
  
  // Specific UI Components
  static const Color progressBackground = Color(0xFFE5E7EB); // gray-200 - Background for progress bars
  static const Color progressFill = Color(0xFF10B981);       // emerald-500 - Fill for progress bars
  static const Color tabActive = Color(0xFF047857);          // emerald-700 - Active tab color
  static const Color tabInactive = Color(0xFF6B7280);        // gray-500 - Inactive tab color
  static const Color toggleActive = Color(0xFFD1FAE5);       // emerald-100 - Toggle button active background
  
  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF10B981);      // emerald-500 - More vibrant in dark theme
  static const Color accentDark = Color(0xFF34D399);       // emerald-400 - Accent for dark theme
  static const Color backgroundDark = Color(0xFF1F2937);   // gray-800 - Dark background
  static const Color surfaceDark = Color(0xFF374151);      // gray-700 - Dark surface elements
  static const Color surfaceVariantDark = Color(0xFF4B5563); // gray-600 - Dark alternative surface
  static const Color textPrimaryDark = Color(0xFFF9FAFB);  // gray-50 - Main text on dark
  static const Color textSecondaryDark = Color(0xFFD1D5DB); // gray-300 - Secondary text on dark
  static const Color textLightDark = Color(0xFF9CA3AF);    // gray-400 - Tertiary text on dark
  static const Color textOnPrimaryDark = Color(0xFF1F2937); // gray-800 - Text on primary in dark
  static const Color dividerDark = Color(0xFF6B7280);      // gray-500 - Dividers on dark
  static const Color errorDark = Color(0xFFFCA5A5);        // red-300 - Error states on dark
  static const Color tabActiveDark = Color(0xFF34D399);    // emerald-400 - Tab active on dark
  static const Color tabInactiveDark = Color(0xFF9CA3AF);  // gray-400 - Tab inactive on dark
  static const Color progressBackgroundDark = Color(0xFF4B5563); // gray-600 - Progress bg on dark
  
  // Sepia Theme Colors (for reading comfort)
  static const Color primarySepia = Color(0xFF8B5A2B);     // warm brown - Sepia primary
  static const Color accentSepia = Color(0xFFAD8255);      // lighte brown - Sepia accent
  static const Color backgroundSepia = Color(0xFFF5F1E4);  // cream - Sepia background
  static const Color surfaceSepia = Color(0xFFFBF8F1);     // light cream - Sepia surface
  static const Color textPrimarySepia = Color(0xFF492C14); // dark brown - Sepia text
  static const Color textSecondarySepia = Color(0xFF6F5632); // medium brown - Sepia secondary text
  static const Color textOnPrimarySepia = Color(0xFFFFF8EE); // off-white - Text on primary for sepia
}
