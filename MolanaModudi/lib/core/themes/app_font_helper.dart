import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/app_settings_provider.dart';
import 'app_theme.dart';

/// Helper widget that automatically applies app font scaling to its child text
class AppScaledText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const AppScaledText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(appSettingsProvider).fontScale;
    
    return Text(
      text,
      style: style?.withAppFontScale(fontScale),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Helper function to get current font scale
double getAppFontScale(WidgetRef ref) {
  return ref.watch(appSettingsProvider).fontScale;
}

/// Extension to quickly apply font scaling to any widget that needs it
extension AppFontScaleContext on BuildContext {
  /// Get the current app font scale
  double get appFontScale {
    // This is a simplified approach - for full functionality,
    // the widget should be a ConsumerWidget to access WidgetRef
    return 1.0; // Default scale if not available
  }
}

/// Mixin for widgets that need app font scaling
mixin AppFontScaleMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Get the current app font scale
  double get appFontScale => ref.watch(appSettingsProvider).fontScale;
  
  /// Apply font scale to a text style
  TextStyle? scaleTextStyle(TextStyle? style) {
    return style?.withAppFontScale(appFontScale);
  }
} 