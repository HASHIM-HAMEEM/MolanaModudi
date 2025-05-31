import 'package:flutter/material.dart';

/// App color palette
class AppColor {
  // Primary colors
  static const Color primary = Color(0xFF2E7D32);      // Green 800
  static const Color primaryLight = Color(0xFF4CAF50);  // Green 500
  static const Color primaryLighter = Color(0xFFA5D6A7); // Green 200
  static const Color primaryDark = Color(0xFF1B5E20);   // Green 900
  
  // Secondary colors
  static const Color secondary = Color(0xFF00796B);     // Teal 700
  static const Color secondaryLight = Color(0xFF26A69A); // Teal 400
  static const Color secondaryDark = Color(0xFF004D40);  // Teal 900
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);    // Grey 900
  static const Color textSecondary = Color(0xFF757575);  // Grey 600
  static const Color textLight = Color(0xFF9E9E9E);      // Grey 500
  static const Color textOnPrimary = Colors.white;
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);     // Grey 100
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);        // Grey 300
  
  // Semantic colors
  static const Color error = Color(0xFFD32F2F);          // Red 700
  static const Color warning = Color(0xFFFFA000);        // Amber 700
  static const Color success = Color(0xFF388E3C);        // Green 700
  static const Color info = Color(0xFF1976D2);           // Blue 700
}