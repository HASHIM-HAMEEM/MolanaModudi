import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

/// Utility class for handling Firestore operations with retry logic
/// Implements exponential backoff for transient errors like 'unavailable'
class FirestoreRetryHelper {
  static final Logger _log = Logger('FirestoreRetryHelper');
  
  /// Maximum number of retry attempts
  static const int maxRetries = 3;
  
  /// Base delay in milliseconds for exponential backoff
  static const int baseDelayMs = 1000;
  
  /// Maximum delay in milliseconds
  static const int maxDelayMs = 8000;
  
  /// List of error codes that should trigger a retry
  static const List<String> retryableErrorCodes = [
    'unavailable',
    'deadline-exceeded',
    'internal',
    'cancelled',
    'resource-exhausted',
    'aborted',
  ];
  
  /// Executes a Firestore operation with retry logic
  /// 
  /// [operation] - The Firestore operation to execute
  /// [operationName] - Name for logging purposes
  /// [maxRetries] - Maximum number of retries (defaults to 3)
  /// 
  /// Returns the result of the operation or throws the last error
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    int? maxRetries,
  }) async {
    final maxAttempts = (maxRetries ?? FirestoreRetryHelper.maxRetries) + 1;
    Exception? lastError;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _log.fine('Executing $operationName (attempt $attempt/$maxAttempts)');
        final result = await operation();
        
        if (attempt > 1) {
          _log.info('$operationName succeeded after $attempt attempts');
        }
        
        return result;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        
        // Check if this is the last attempt
        if (attempt == maxAttempts) {
          _log.severe('$operationName failed after $maxAttempts attempts. Final error: $e');
          throw lastError;
        }
        
        // Check if the error is retryable
        if (!_isRetryableError(e)) {
          _log.warning('$operationName failed with non-retryable error: $e');
          throw lastError;
        }
        
        // Calculate delay with exponential backoff and jitter
        final delay = _calculateDelay(attempt - 1);
        _log.warning('$operationName failed (attempt $attempt/$maxAttempts): $e. Retrying in ${delay}ms...');
        
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    
    // This should never be reached, but just in case
    throw lastError ?? Exception('$operationName failed for unknown reason');
  }
  
  /// Checks if an error is retryable based on its type and code
  static bool _isRetryableError(dynamic error) {
    if (error is FirebaseException) {
      return retryableErrorCodes.contains(error.code);
    }
    
    // Check error message for retryable patterns
    final errorMessage = error.toString().toLowerCase();
    return retryableErrorCodes.any((code) => errorMessage.contains(code)) ||
           errorMessage.contains('network') ||
           errorMessage.contains('timeout') ||
           errorMessage.contains('connection');
  }
  
  /// Calculates delay for exponential backoff with jitter
  static int _calculateDelay(int retryCount) {
    final exponentialDelay = baseDelayMs * pow(2, retryCount);
    final delayWithJitter = exponentialDelay + Random().nextInt(baseDelayMs);
    return min(delayWithJitter.toInt(), maxDelayMs);
  }
  
  /// Convenient method for Firestore document get operations
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> docRef,
    String operationName,
  ) async {
    return executeWithRetry(
      () => docRef.get(),
      'Get document: $operationName',
    );
  }
  
  /// Convenient method for Firestore collection query operations
  static Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    Query<Map<String, dynamic>> query,
    String operationName,
  ) async {
    return executeWithRetry(
      () => query.get(),
      'Query collection: $operationName',
    );
  }
  
  /// Checks if a Firestore error indicates the service is temporarily unavailable
  static bool isTemporaryUnavailable(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable';
    }
    return error.toString().toLowerCase().contains('unavailable');
  }
  
  /// Provides a user-friendly error message for Firestore errors
  static String getUserFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
          return 'The service is temporarily unavailable. Please check your internet connection and try again.';
        case 'deadline-exceeded':
          return 'The request timed out. Please try again.';
        case 'permission-denied':
          return 'You don\'t have permission to access this content.';
        case 'not-found':
          return 'The requested content was not found.';
        case 'cancelled':
          return 'The request was cancelled. Please try again.';
        default:
          return 'A network error occurred. Please try again.';
      }
    }
    
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('unavailable') || errorMessage.contains('network')) {
      return 'The service is temporarily unavailable. Please check your internet connection and try again.';
    }
    
    return 'An error occurred while loading content. Please try again.';
  }
} 