import 'package:flutter/material.dart';

/// Clean scaffold for reading screen - extracted from monolithic ReadingScreen
class ReadingScaffold extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
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
    );
  }
} 