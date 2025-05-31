import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standardized button widget with consistent theming and accessibility support
class StandardButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final StandardButtonType type;
  final StandardButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  const StandardButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = StandardButtonType.primary,
    this.size = StandardButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.semanticLabel,
  });

  /// Primary action button
  const StandardButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = StandardButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.semanticLabel,
  }) : type = StandardButtonType.primary;

  /// Secondary action button
  const StandardButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = StandardButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.semanticLabel,
  }) : type = StandardButtonType.secondary;

  /// Tertiary/text button
  const StandardButton.tertiary({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = StandardButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.semanticLabel,
  }) : type = StandardButtonType.tertiary;

  /// Destructive action button
  const StandardButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = StandardButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.semanticLabel,
  }) : type = StandardButtonType.destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = _getButtonSize();
    final isEnabled = onPressed != null && !isLoading;

    Widget button = _buildButton(context, theme, buttonSize, isEnabled);

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    // Add accessibility semantics
    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: isEnabled,
      child: button,
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme, _ButtonSize buttonSize, bool isEnabled) {
    final onTap = isEnabled ? () {
      HapticFeedback.lightImpact();
      onPressed!();
    } : null;

    Widget content = _buildButtonContent(theme, buttonSize);

    switch (type) {
      case StandardButtonType.primary:
        return ElevatedButton(
          onPressed: onTap,
          style: _getPrimaryButtonStyle(theme, buttonSize),
          child: content,
        );
      case StandardButtonType.secondary:
        return OutlinedButton(
          onPressed: onTap,
          style: _getSecondaryButtonStyle(theme, buttonSize),
          child: content,
        );
      case StandardButtonType.tertiary:
        return TextButton(
          onPressed: onTap,
          style: _getTertiaryButtonStyle(theme, buttonSize),
          child: content,
        );
      case StandardButtonType.destructive:
        return ElevatedButton(
          onPressed: onTap,
          style: _getDestructiveButtonStyle(theme, buttonSize),
          child: content,
        );
    }
  }

  Widget _buildButtonContent(ThemeData theme, _ButtonSize buttonSize) {
    if (isLoading) {
      return SizedBox(
        width: buttonSize.iconSize,
        height: buttonSize.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == StandardButtonType.primary || type == StandardButtonType.destructive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: buttonSize.iconSize),
          SizedBox(width: buttonSize.spacing),
          Text(text, style: TextStyle(fontSize: buttonSize.fontSize)),
        ],
      );
    }

    return Text(text, style: TextStyle(fontSize: buttonSize.fontSize));
  }

  ButtonStyle _getPrimaryButtonStyle(ThemeData theme, _ButtonSize buttonSize) {
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: padding ?? buttonSize.padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow,
    );
  }

  ButtonStyle _getSecondaryButtonStyle(ThemeData theme, _ButtonSize buttonSize) {
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      side: BorderSide(color: theme.colorScheme.outline),
      padding: padding ?? buttonSize.padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _getTertiaryButtonStyle(ThemeData theme, _ButtonSize buttonSize) {
    return TextButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      padding: padding ?? buttonSize.padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _getDestructiveButtonStyle(ThemeData theme, _ButtonSize buttonSize) {
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.error,
      foregroundColor: theme.colorScheme.onError,
      padding: padding ?? buttonSize.padding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow,
    );
  }

  _ButtonSize _getButtonSize() {
    switch (size) {
      case StandardButtonSize.small:
        return _ButtonSize(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fontSize: 14,
          iconSize: 16,
          spacing: 6,
        );
      case StandardButtonSize.medium:
        return _ButtonSize(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fontSize: 16,
          iconSize: 18,
          spacing: 8,
        );
      case StandardButtonSize.large:
        return _ButtonSize(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          fontSize: 18,
          iconSize: 20,
          spacing: 10,
        );
    }
  }
}

/// Floating Action Button with consistent theming
class StandardFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final bool mini;
  final String? heroTag;

  const StandardFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.mini = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: tooltip ?? 'Floating action button',
      button: true,
      enabled: onPressed != null,
      child: FloatingActionButton(
        onPressed: onPressed != null ? () {
          HapticFeedback.lightImpact();
          onPressed!();
        } : null,
        mini: mini,
        tooltip: tooltip,
        heroTag: heroTag,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: Icon(icon),
      ),
    );
  }
}

/// Icon button with consistent theming
class StandardIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final StandardButtonSize size;
  final Color? color;
  final bool badge;

  const StandardIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.size = StandardButtonSize.medium,
    this.color,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonSize = _getIconButtonSize();

    Widget iconButton = IconButton(
      onPressed: onPressed != null ? () {
        HapticFeedback.lightImpact();
        onPressed!();
      } : null,
      icon: Icon(
        icon,
        size: buttonSize,
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: tooltip,
    );

    if (badge) {
      iconButton = Badge(
        child: iconButton,
      );
    }

    return Semantics(
      label: tooltip ?? 'Icon button',
      button: true,
      enabled: onPressed != null,
      child: iconButton,
    );
  }

  double _getIconButtonSize() {
    switch (size) {
      case StandardButtonSize.small:
        return 20;
      case StandardButtonSize.medium:
        return 24;
      case StandardButtonSize.large:
        return 28;
    }
  }
}

enum StandardButtonType {
  primary,
  secondary,
  tertiary,
  destructive,
}

enum StandardButtonSize {
  small,
  medium,
  large,
}

class _ButtonSize {
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;
  final double spacing;

  const _ButtonSize({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
  });
}
