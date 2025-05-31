import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern search bar with Airbnb-style minimalistic design
class ModernSearchBar extends StatefulWidget {
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;
  final bool showClearButton;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  const ModernSearchBar({
    super.key,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
    this.showClearButton = true,
    this.prefixIcon,
    this.suffixIcon,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.textStyle,
    this.hintStyle,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool get _hasText => _controller.text.isNotEmpty;
  bool get _isFocused => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_controller.text);
    
    if (_hasText && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!_hasText && _animationController.isCompleted) {
      _animationController.reverse();
    }
    
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final defaultBackgroundColor = _isFocused
        ? colorScheme.surface
        : colorScheme.surfaceContainerHighest;
    
    final backgroundColor = widget.backgroundColor ?? defaultBackgroundColor;
    
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);
    
    final defaultTextStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w400,
    );
    
    final defaultHintStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      fontWeight: FontWeight.w400,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutQuart,
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: _isFocused
              ? colorScheme.primary.withValues(alpha: 0.6)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Prefix icon
          if (widget.prefixIcon != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconTheme(
                  data: IconThemeData(
                    color: _isFocused
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  child: widget.prefixIcon!,
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.search_rounded,
                  color: _isFocused
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
          ],
          
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onTap: widget.onTap,
              onSubmitted: widget.onSubmitted,
              style: widget.textStyle ?? defaultTextStyle,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                hintStyle: widget.hintStyle ?? defaultHintStyle,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                isDense: true,
              ),
            ),
          ),
          
          // Clear button
          if (widget.showClearButton && _hasText) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _clearText,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // Suffix icon
          if (widget.suffixIcon != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: IconTheme(
                data: IconThemeData(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 20,
                ),
                child: widget.suffixIcon!,
              ),
            ),
          ] else ...[
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

/// Compact search bar for app bars
class CompactSearchBar extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final String? initialValue;

  const CompactSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return ModernSearchBar(
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      enabled: enabled,
      initialValue: initialValue,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

/// Search bar for overlays and modals
class OverlaySearchBar extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;
  final bool autofocus;
  final String? initialValue;

  const OverlaySearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.autofocus = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Cancel button
            if (onCancel != null) ...[
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            // Search bar
            Expanded(
              child: ModernSearchBar(
                hintText: hintText,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                autofocus: autofocus,
                initialValue: initialValue,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 