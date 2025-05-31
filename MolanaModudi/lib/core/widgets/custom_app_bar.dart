import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_button.dart';

/// Standardized app bar widget with consistent theming and accessibility support
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onLeadingPressed;
  final String? leadingTooltip;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;
  final bool enableContextMenu;

  const StandardAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onLeadingPressed,
    this.leadingTooltip,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.enableContextMenu = false,
  });

  /// App bar with back button
  const StandardAppBar.withBack({
    super.key,
    required this.title,
    this.actions,
    required this.onLeadingPressed,
    this.leadingTooltip = 'Go back',
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.enableContextMenu = false,
  }) : leading = null, automaticallyImplyLeading = false;

  /// App bar with close button
  const StandardAppBar.withClose({
    super.key,
    required this.title,
    this.actions,
    required this.onLeadingPressed,
    this.leadingTooltip = 'Close',
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.enableContextMenu = false,
  }) : leading = null, automaticallyImplyLeading = false;

  /// Search app bar
  const StandardAppBar.search({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onLeadingPressed,
    this.leadingTooltip,
    this.centerTitle = false,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.enableContextMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget? effectiveLeading = leading;
    
    // Handle back/close buttons when no leading widget is provided
    if (leading == null && onLeadingPressed != null) {
      if (leadingTooltip == 'Close') {
        effectiveLeading = StandardIconButton(
          onPressed: onLeadingPressed,
          icon: Icons.close,
          tooltip: leadingTooltip,
        );
      } else {
        effectiveLeading = StandardIconButton(
          onPressed: onLeadingPressed,
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: leadingTooltip ?? 'Go back',
        );
      }
    }

    // Build title widget with accessibility
    Widget titleWidget = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.appBarTheme.titleTextStyle?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Add context menu for search app bars
    if (enableContextMenu) {
      titleWidget = _ContextMenuWrapper(
        title: title,
        child: titleWidget,
      );
    }

    return AppBar(
      title: titleWidget,
      leading: effectiveLeading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions?.map((action) {
        // Wrap actions in semantics if they're not already
        if (action is! Semantics) {
          return Semantics(
            button: true,
            child: action,
          );
        }
        return action;
      }).toList(),
      centerTitle: centerTitle,
      elevation: elevation ?? theme.appBarTheme.elevation ?? 0,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      bottom: bottom,
      systemOverlayStyle: _getSystemOverlayStyle(context),
    );
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}

/// Context menu wrapper for app bar titles
class _ContextMenuWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _ContextMenuWrapper({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: child,
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AppBarContextMenu(title: title),
    );
  }
}

/// Context menu for app bar actions
class _AppBarContextMenu extends StatelessWidget {
  final String title;

  const _AppBarContextMenu({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy Title'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: title));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Title copied to clipboard')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // Implement share functionality
            },
          ),
        ],
      ),
    );
  }
}

/// Search app bar with integrated search field
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onBack;
  final String? initialValue;
  final List<Widget>? actions;
  final bool autofocus;

  const SearchAppBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onBack,
    this.initialValue,
    this.actions,
    this.autofocus = true,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: StandardIconButton(
        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        icon: Icons.arrow_back_ios_new_rounded,
        tooltip: 'Go back',
      ),
      title: Semantics(
        textField: true,
        label: widget.hintText,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      actions: [
        if (_controller.text.isNotEmpty)
          StandardIconButton(
            onPressed: () {
              _controller.clear();
              widget.onClear?.call();
              widget.onChanged?.call('');
            },
            icon: Icons.clear,
            tooltip: 'Clear search',
          ),
        ...?widget.actions,
      ],
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: 0,
    );
  }
}

/// Tab bar app bar for screens with tabs
class TabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Tab> tabs;
  final TabController? controller;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;
  final String? leadingTooltip;

  const TabAppBar({
    super.key,
    required this.title,
    required this.tabs,
    this.controller,
    this.actions,
    this.leading,
    this.onLeadingPressed,
    this.leadingTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? effectiveLeading = leading;
    if (leading == null && onLeadingPressed != null) {
      effectiveLeading = StandardIconButton(
        onPressed: onLeadingPressed,
        icon: Icons.arrow_back_ios_new_rounded,
        tooltip: leadingTooltip ?? 'Go back',
      );
    }

    return AppBar(
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      leading: effectiveLeading,
      actions: actions,
      bottom: TabBar(
        controller: controller,
        tabs: tabs,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
      ),
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}
