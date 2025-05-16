import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';

/// Font utilities to help with consistent font sizing across the app
class FontUtils {
  /// Get a scaled font size based on a base size and the global font size setting
  static double getScaledFontSize(double baseSize, WidgetRef ref) {
    final settingsState = ref.read(settingsProvider);
    final fontSizeMultiplier = settingsState.fontSize.size / 14.0; // Use 14.0 as the base font size
    return baseSize * fontSizeMultiplier;
  }
  
  /// Apply font scaling to a TextStyle
  static TextStyle scaleTextStyle(TextStyle? style, double baseSize, WidgetRef ref) {
    if (style == null) return TextStyle(fontSize: getScaledFontSize(baseSize, ref));
    return style.copyWith(fontSize: getScaledFontSize(baseSize, ref));
  }
  
  /// Create a scaled headline style
  static TextStyle headlineStyle(BuildContext context, WidgetRef ref, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
    double baseSize = 22.0,
  }) {
    final theme = Theme.of(context);
    final scaledSize = getScaledFontSize(baseSize, ref);
    
    return theme.textTheme.headlineMedium?.copyWith(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
    ) ?? TextStyle(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
    );
  }
  
  /// Create a scaled title style
  static TextStyle titleStyle(BuildContext context, WidgetRef ref, {
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
    double baseSize = 18.0,
  }) {
    final theme = Theme.of(context);
    final scaledSize = getScaledFontSize(baseSize, ref);
    
    return theme.textTheme.titleMedium?.copyWith(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
    ) ?? TextStyle(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
    );
  }
  
  /// Create a scaled body style
  static TextStyle bodyStyle(BuildContext context, WidgetRef ref, {
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    double baseSize = 16.0,
  }) {
    final theme = Theme.of(context);
    final scaledSize = getScaledFontSize(baseSize, ref);
    
    return theme.textTheme.bodyMedium?.copyWith(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
    ) ?? TextStyle(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
    );
  }
  
  /// Create a scaled caption style
  static TextStyle captionStyle(BuildContext context, WidgetRef ref, {
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    double baseSize = 12.0,
  }) {
    final theme = Theme.of(context);
    final scaledSize = getScaledFontSize(baseSize, ref);
    
    return theme.textTheme.bodySmall?.copyWith(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurfaceVariant,
    ) ?? TextStyle(
      fontSize: scaledSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurfaceVariant,
    );
  }
}
