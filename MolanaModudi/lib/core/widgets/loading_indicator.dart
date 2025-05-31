import 'package:flutter/material.dart';

/// Standardized loading indicator widget with consistent theming and accessibility support
class StandardLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool adaptive;
  final EdgeInsetsGeometry padding;

  const StandardLoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
    this.adaptive = true,
    this.padding = const EdgeInsets.all(16.0),
  });

  /// Small loading indicator for inline use
  const StandardLoadingIndicator.small({
    super.key,
    this.message,
    this.color,
    this.adaptive = true,
  }) : size = 20.0, padding = const EdgeInsets.all(8.0);

  /// Large loading indicator for full screen
  const StandardLoadingIndicator.large({
    super.key,
    this.message,
    this.color,
    this.adaptive = true,
  }) : size = 60.0, padding = const EdgeInsets.all(24.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    Widget indicator = adaptive
        ? CircularProgressIndicator.adaptive(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          )
        : CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          );

    // Apply size constraints
    indicator = SizedBox(
      width: size,
      height: size,
      child: indicator,
    );

    // Add accessibility semantics
    indicator = Semantics(
      label: message ?? 'Loading content',
      child: indicator,
    );

    Widget content = indicator;

    // Add message if provided
    if (message != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 12),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Padding(
      padding: padding,
      child: content,
    );
  }

  /// Static method for showing loading indicator in center
  static Widget center({
    String? message,
    double size = 40.0,
    Color? color,
    bool adaptive = true,
  }) {
    return Center(
      child: StandardLoadingIndicator(
        message: message,
        size: size,
        color: color,
        adaptive: adaptive,
      ),
    );
  }

  /// Static method for overlay loading indicator
  static Widget overlay({
    String? message,
    Color? backgroundColor,
    double size = 40.0,
    Color? color,
  }) {
    return Container(
      color: backgroundColor ?? Colors.black54,
      child: Center(
        child: StandardLoadingIndicator(
          message: message,
          size: size,
          color: color,
          adaptive: true,
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for content
class ShimmerLoadingIndicator extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final int count;

  const ShimmerLoadingIndicator({
    super.key,
    this.height = 16.0,
    this.width,
    this.borderRadius,
    this.count = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerLow;
    final highlightColor = isDark
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainerHigh;

    return Column(
      children: List.generate(count, (index) => Padding(
        padding: EdgeInsets.only(bottom: count > 1 ? 8.0 : 0),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(4),
            ),
          ),
        ),
      )),
    );
  }

  /// Text shimmer placeholder
  static Widget text({
    int lines = 3,
    double height = 16.0,
    BorderRadius? borderRadius,
  }) {
    return ShimmerLoadingIndicator(
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      count: lines,
    );
  }

  /// Card shimmer placeholder
  static Widget card({
    double height = 120.0,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return ShimmerLoadingIndicator(
      height: height,
      width: width,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}
