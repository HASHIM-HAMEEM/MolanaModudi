import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// A service to handle Firebase initialization
class FirebaseInitializer {
  /// Initialize Firebase and return a Future that completes when initialization is done
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow; // Re-throw the exception to handle it at a higher level
    }
  }
  
  /// Widget that initializes Firebase and then loads the app
  /// Use this as the root of your widget tree
  static Widget initializeApp({
    required Widget Function() appBuilder,
    Widget Function(BuildContext, Object)? errorBuilder,
    Widget? loadingWidget,
  }) {
    return FutureBuilder(
      future: initialize(),
      builder: (context, snapshot) {
        // Check if initialization is complete
        if (snapshot.connectionState == ConnectionState.done) {
          // If we got an error
          if (snapshot.hasError) {
            debugPrint('Firebase initialization error: ${snapshot.error}');
            
            // Return error widget if provided, otherwise a default error widget
            return errorBuilder?.call(context, snapshot.error!) ?? 
              MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error initializing Firebase',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
          }

          // Initialize the app
          return appBuilder();
        }

        // Show loading indicator while initializing
        return loadingWidget ?? 
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing app...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
      },
    );
  }
} 