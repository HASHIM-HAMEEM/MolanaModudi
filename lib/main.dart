import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';
import 'features/search/di/search_module.dart';

void main() async { // Make main async
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the AppLogger
  AppLogger.init();
  final log = AppLogger.getLogger('main');
  
  // Initialize Firebase properly
  try {
    await Firebase.initializeApp();
    log.info('Firebase initialized successfully');
  } catch (e) {
    log.severe('Failed to initialize Firebase', e);
  }
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  log.info('SharedPreferences initialized');
  
  log.info('Starting application');
  
  // Create providers overrides
  final overrides = [
    // Override SharedPreferences provider
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
  
  // Initialize the app with Riverpod for state management
  
  runApp(
    // Wrap the entire app with ProviderScope for Riverpod state management
    ProviderScope(
      overrides: overrides,
      child: const MyApp(),
    ),
  );
}

// Logging Configuration
void _setupLogging() {
  Logger.root.level = Level.ALL; // Log all levels
  Logger.root.onRecord.listen((record) {
    // Customize log output format if desired
    debugPrint('[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack Trace: ${record.stackTrace}');
    }
  });
  
  // Optional: Log Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
     Logger('FlutterError').severe(details.exceptionAsString(), details.exception, details.stack);
  };

  // Optional: Log Platform errors (unhandled async errors)
   PlatformDispatcher.instance.onError = (error, stack) {
    Logger('PlatformDispatcher').severe('Unhandled Platform Error', error, stack);
    return true; // Indicates error was handled
  };
  
  // Initial log message
  Logger('main').info('Logging configured. App starting...');
}
