import 'package:flutter/material.dart';
import 'package:modudi/core/utils/firestore_retry_helper.dart';

/// A reusable widget that displays error messages with retry options
/// Specifically designed for handling Firestore connectivity issues
class RetryErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? customRetryText;
  final Widget? customIcon;
  final bool showConnectivityHint;

  const RetryErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.customRetryText,
    this.customIcon,
    this.showConnectivityHint = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTemporaryError = errorMessage != null && 
        FirestoreRetryHelper.isTemporaryUnavailable(errorMessage!);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            customIcon ?? Icon(
              isTemporaryError ? Icons.cloud_off : Icons.error_outline,
              size: 64,
              color: isTemporaryError ? theme.colorScheme.primary : theme.colorScheme.error,
            ),
            
            const SizedBox(height: 16),
            
            // Error title
            Text(
              isTemporaryError ? 'Connection Issue' : 'Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTemporaryError ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Error message
            Text(
              errorMessage ?? 'An unexpected error occurred',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            
            if (showConnectivityHint && isTemporaryError) ...[
              const SizedBox(height: 12),
              
              // Connectivity hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is usually a temporary issue. Please check your internet connection.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              
              // Retry button
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(customRetryText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Additional help text for temporary errors
            if (isTemporaryError)
              Text(
                'The app will automatically retry in a few moments',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact version of the retry error widget for use in smaller spaces
class CompactRetryErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? customRetryText;

  const CompactRetryErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.customRetryText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTemporaryError = errorMessage != null && 
        FirestoreRetryHelper.isTemporaryUnavailable(errorMessage!);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isTemporaryError 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTemporaryError 
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isTemporaryError ? Icons.cloud_off : Icons.error_outline,
                size: 20,
                color: isTemporaryError ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage ?? 'An error occurred',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isTemporaryError ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(customRetryText ?? 'Retry'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 