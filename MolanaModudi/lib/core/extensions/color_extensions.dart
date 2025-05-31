import 'package:flutter/material.dart';

/// Extension to handle deprecated withOpacity usage
extension ColorExtensions on Color {
  /// Safe replacement for deprecated withOpacity method
  Color withOpacitySafe(double opacity) {
    return withValues(alpha: opacity);
  }
} 