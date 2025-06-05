import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/reading/presentation/providers/reading_settings_provider.dart';
import 'package:modudi/core/themes/app_color.dart';

/// Clean scaffold for reading screen - extracted from monolithic ReadingScreen
class ReadingScaffold extends ConsumerWidget {
  final String bookId;
  final bool showHeaderFooter;
  final VoidCallback onHeaderFooterToggle;
  final VoidCallback onBackPressed;
  final Widget header;
  final Widget content;
  final Widget controls;

  const ReadingScaffold({
    super.key,
    required this.bookId,
    required this.showHeaderFooter,
    required this.onHeaderFooterToggle,
    required this.onBackPressed,
    required this.header,
    required this.content,
    required this.controls,
  });

  // Get reading-specific theme colors
  ColorScheme _getReadingColorScheme(ReadingThemeMode themeMode) {
    switch (themeMode) {
      case ReadingThemeMode.light:
        return const ColorScheme.light(
          surface: AppColor.background,
          onSurface: AppColor.textPrimary,
          primary: AppColor.primary,
          secondary: AppColor.accent,
        );
      case ReadingThemeMode.dark:
        return const ColorScheme.dark(
          surface: AppColor.backgroundDark,
          onSurface: AppColor.textPrimaryDark,
          primary: AppColor.primaryDark,
          secondary: AppColor.accentDark,
        );
      case ReadingThemeMode.sepia:
        return const ColorScheme.light(
          surface: AppColor.backgroundSepia,
          onSurface: AppColor.textPrimarySepia,
          primary: AppColor.primarySepia,
          secondary: AppColor.accentSepia,
        );
      case ReadingThemeMode.system:
        // Use the current app theme for system mode
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        if (brightness == Brightness.dark) {
          return const ColorScheme.dark(
            surface: AppColor.backgroundDark,
            onSurface: AppColor.textPrimaryDark,
            primary: AppColor.primaryDark,
            secondary: AppColor.accentDark,
          );
        } else {
          return const ColorScheme.light(
            surface: AppColor.background,
            onSurface: AppColor.textPrimary,
            primary: AppColor.primary,
            secondary: AppColor.accent,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingSettings = ref.watch(readingSettingsProvider);
    final readingColors = _getReadingColorScheme(readingSettings.themeMode);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: readingColors,
        scaffoldBackgroundColor: readingColors.surface,
      ),
      child: Scaffold(
        backgroundColor: readingColors.surface,
      body: Stack(
        children: [
          // Main content area with gesture detection
          GestureDetector(
            onTap: onHeaderFooterToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.only(
                top: showHeaderFooter ? 100 : 20,
                bottom: showHeaderFooter ? 80 : 20,
              ),
              child: content,
            ),
          ),
          
          // Header with smooth animations
          AnimatedOpacity(
            opacity: showHeaderFooter ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSlide(
              offset: showHeaderFooter ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              child: header,
            ),
          ),
          
          // Controls/Footer
          AnimatedOpacity(
            opacity: showHeaderFooter ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSlide(
              offset: showHeaderFooter ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: controls,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
} 