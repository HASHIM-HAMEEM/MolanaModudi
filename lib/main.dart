import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart'; // Import logging
import 'dart:ui'; // Import for PlatformDispatcher
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';
// Potentially import SharedPreferences if needed directly
// import 'package:shared_preferences/shared_preferences.dart';

void main() async { // Make main async
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences (optional here, provider handles it)
  // final prefs = await SharedPreferences.getInstance(); 

  // Configure Logging
  _setupLogging();
  
  // Initialize Firebase properly
  try {
    await Firebase.initializeApp(
      // No options needed - it will use the GoogleService-Info.plist for iOS 
      // and google-services.json for Android
    );
    Logger('Firebase').info('Firebase initialized successfully');
  } catch (e) {
    Logger('Firebase').severe('Failed to initialize Firebase', e);
  }
  
  runApp(
    // Wrap the entire app with ProviderScope for Riverpod state management
    const ProviderScope(
      child: MyApp(),
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
