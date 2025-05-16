import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// A utility class for consistent app logging across the application
class AppLogger {
  /// Initialize the logger system. Call this in main() before runApp
  static void init() {
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((record) {
      final message = '${record.level.name}: ${record.loggerName} - ${record.message}';
      
      // Include error and stack trace if available
      final errorDetails = record.error != null 
          ? '\nERROR: ${record.error}'
          : '';
      final stackDetails = record.stackTrace != null 
          ? '\nSTACK: ${record.stackTrace}'
          : '';
          
      debugPrint('${record.time}: $message$errorDetails$stackDetails');
    });
  }
  
  /// Get a logger for a specific component
  static Logger getLogger(String name) {
    return Logger(name);
  }
  
  /// Log user interactions like button clicks, navigation events, etc.
  static void logUserAction(String component, String action, {Map<String, dynamic>? details}) {
    final logger = Logger('UI:$component');
    final detailsStr = details != null ? ' - Details: $details' : '';
    logger.info('User action: $action$detailsStr');
  }
  
  /// Log navigation events to track screen flows
  static void logNavigation(String from, String to, {Map<String, dynamic>? parameters}) {
    final logger = Logger('Navigation');
    final paramsStr = parameters != null ? ' - Params: $parameters' : '';
    logger.info('From: $from → To: $to$paramsStr');
  }
} 