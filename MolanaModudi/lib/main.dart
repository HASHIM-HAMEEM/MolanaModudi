import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';
import 'core/cache/cache_service.dart';
import 'core/providers/providers.dart';
import 'package:logging/logging.dart'; // Added for Logger
import 'package:modudi/core/cache/config/cache_constants.dart'; // Added for CacheConstants

void main() async { 
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the AppLogger
  AppLogger.init();
  final log = AppLogger.getLogger('main');
  
  // Initialize Firebase properly
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Enable Firestore offline persistence (if not already)
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    
    // Initialize background workmanager for SWR refreshes
    await Workmanager().initialize(
      swrRefreshCallback,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      'swr_refresh_task',
      'swr_refresh',
      frequency: const Duration(hours: 12),
      initialDelay: const Duration(minutes: 5),
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
    
    // CacheService will be initialized by its Riverpod provider when first accessed.
    // No need to initialize or override it here if the provider handles it.
    // final cacheService = CacheService(); // REMOVE
    // await cacheService.initialize(); // REMOVE
    // log.info('CacheService initialized successfully'); // REMOVE
    
    // Create providers overrides
    // Remove the CacheService override, let the actual provider do its job.
    final overrides = [
      sharedPreferencesProvider.overrideWith((ref) => Future.value(prefs)),
      // cacheServiceProvider.overrideWith((ref) async => cacheService), // REMOVE
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
          sharedPreferencesProvider.overrideWith((ref) => Future.value(prefs)),
        ],
        child: const MyApp(),
      ),
    );
  }
}

// Background fetch callback for Workmanager
@pragma('vm:entry-point')
void swrRefreshCallback() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger('SWRWorker');
    logger.info('Running SWR refresh task: $task');

    try {
      // We just warm the cache for bookmarked / high priority books
      final cacheService = CacheService.instance;
      final hiveManager = cacheService.hiveManager;
      final keys = await hiveManager.getAllKeys(CacheConstants.booksBoxName);
      for (final key in keys) {
        if (key.startsWith(CacheConstants.bookKeyPrefix)) {
          final bookId = key.substring(CacheConstants.bookKeyPrefix.length);
          try {
            await cacheService.refreshBookIfStale(bookId);
          } catch (e) {
            logger.warning('Failed to refresh book $bookId: $e');
          }
        }
      }
    } catch (e, st) {
      Logger('SWRWorker').severe('Background task failed', e, st);
    }

    return Future.value(true);
  });
}
