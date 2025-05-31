import 'package:flutter/material.dart';
import 'custom_button.dart';

/// Standardized error widget with consistent theming and accessibility support
class StandardErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final EdgeInsetsGeometry padding;
  final bool showDetails;
  final String? technicalDetails;

  const StandardErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.onRetry,
    this.retryButtonText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.padding = const EdgeInsets.all(24.0),
    this.showDetails = false,
    this.technicalDetails,
  });

  /// Network error state
  const StandardErrorWidget.network({
    super.key,
    this.title = 'Network Error',
    this.message = 'Please check your internet connection and try again.',
    this.onRetry,
    this.retryButtonText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.padding = const EdgeInsets.all(24.0),
    this.showDetails = false,
    this.technicalDetails,
  }) : icon = Icons.wifi_off;

  /// Server error state
  const StandardErrorWidget.server({
    super.key,
    this.title = 'Server Error',
    this.message = 'Something went wrong on our end. Please try again later.',
    this.onRetry,
    this.retryButtonText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.padding = const EdgeInsets.all(24.0),
    this.showDetails = false,
    this.technicalDetails,
  }) : icon = Icons.cloud_off;

  /// Not found error state
  const StandardErrorWidget.notFound({
    super.key,
    this.title = 'Not Found',
    this.message = 'The content you\'re looking for could not be found.',
    this.onRetry,
    this.retryButtonText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.padding = const EdgeInsets.all(24.0),
    this.showDetails = false,
    this.technicalDetails,
  }) : icon = Icons.search_off;

  /// Permission error state
  const StandardErrorWidget.permission({
    super.key,
    this.title = 'Permission Denied',
    this.message = 'You don\'t have permission to access this content.',
    this.onRetry,
    this.retryButtonText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.padding = const EdgeInsets.all(24.0),
    this.showDetails = false,
    this.technicalDetails,
  }) : icon = Icons.lock_outline;

  /// Generic error state
  const StandardErrorWidget.generic({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'An unexpected error occurred. Please try again.',
    this.onRetry,
    this.retryButtonText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.padding = const EdgeInsets.all(24.0),
    this.showDetails = false,
    this.technicalDetails,
  }) : icon = Icons.error_outline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title: $message',
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Error icon
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Error title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Error message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Technical details (expandable)
            if (showDetails && technicalDetails != null) ...[
              const SizedBox(height: 16),
              _TechnicalDetailsWidget(details: technicalDetails!),
            ],

            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasRetry = onRetry != null;
    final hasSecondary = onSecondaryAction != null;

    if (!hasRetry && !hasSecondary) {
      return const SizedBox.shrink();
    }

    if (hasRetry && hasSecondary) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: StandardButton.secondary(
              text: secondaryActionText ?? 'Go Back',
              onPressed: onSecondaryAction,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: StandardButton.primary(
              text: retryButtonText ?? 'Try Again',
              onPressed: onRetry,
              icon: Icons.refresh,
            ),
          ),
        ],
      );
    }

    if (hasRetry) {
      return StandardButton.primary(
        text: retryButtonText ?? 'Try Again',
        onPressed: onRetry,
        icon: Icons.refresh,
      );
    }

    return StandardButton.secondary(
      text: secondaryActionText ?? 'Go Back',
      onPressed: onSecondaryAction,
    );
  }
}

/// Widget for showing technical error details
class _TechnicalDetailsWidget extends StatefulWidget {
  final String details;

  const _TechnicalDetailsWidget({required this.details});

  @override
  State<_TechnicalDetailsWidget> createState() => _TechnicalDetailsWidgetState();
}

class _TechnicalDetailsWidgetState extends State<_TechnicalDetailsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
          ),
          label: Text(
            _isExpanded ? 'Hide Details' : 'Show Technical Details',
            style: theme.textTheme.bodySmall,
          ),
        ),
        
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              widget.details,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Inline error widget for form fields and smaller components
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Error: $message',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              StandardIconButton(
                onPressed: onDismiss,
                icon: Icons.close,
                tooltip: 'Dismiss error',
                size: StandardButtonSize.small,
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner error widget for showing errors at the top of screens
class ErrorBannerWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool persistent;

  const ErrorBannerWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.persistent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Error banner: $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              StandardIconButton(
                onPressed: onRetry,
                icon: Icons.refresh,
                tooltip: 'Retry',
                size: StandardButtonSize.small,
                color: theme.colorScheme.error,
              ),
            ],
            if (!persistent && onDismiss != null) ...[
              const SizedBox(width: 8),
              StandardIconButton(
                onPressed: onDismiss,
                icon: Icons.close,
                tooltip: 'Dismiss',
                size: StandardButtonSize.small,
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
