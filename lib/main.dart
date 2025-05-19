import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';
import 'core/cache/cache_service.dart';
import 'features/search/di/search_module.dart';
import 'core/providers/providers.dart';

void main() async { // Make main async
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the AppLogger
  AppLogger.init();
  final log = AppLogger.getLogger('main');
  
  // Initialize Firebase properly
  try {
    await Firebase.initializeApp();
    
    // Enable Firestore offline persistence with a reasonable cache size (100MB)
    // This is critical for enabling the app to work offline
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100MB
    );
    
    log.info('Firebase initialized successfully with offline persistence enabled');
  } catch (e) {
    log.severe('Failed to initialize Firebase', e);
  }
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  log.info('SharedPreferences initialized');
  
  // Initialize Hive for caching
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    log.info('Hive initialized successfully');
    
    // Initialize the CacheService
    final cacheService = CacheService();
    await cacheService.initialize();
    log.info('CacheService initialized successfully');
    
    // Create providers overrides
    final overrides = [
      // Override SharedPreferences provider
      sharedPreferencesProvider.overrideWithValue(prefs),
      // Override CacheService provider
      cacheServiceProvider.overrideWith((ref) async => cacheService),
    ];
    
    log.info('Starting application');
    
    // Initialize the app with Riverpod for state management
    runApp(
      // Wrap the entire app with ProviderScope for Riverpod state management
      ProviderScope(
        overrides: overrides,
        child: const MyApp(),
      ),
    );
  } catch (e) {
    log.severe('Error during initialization', e);
    
    // Use default providers if initialization fails
    log.info('Starting application with default providers');
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );
  }
}
