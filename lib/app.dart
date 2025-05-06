import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/core/providers/settings_provider.dart';
import 'package:modudi/core/themes/app_theme.dart';
import 'package:modudi/l10n/l10n.dart';
import 'package:modudi/routes/app_router.dart'; // Import the router
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';

final _log = Logger('MyApp');

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access settings for theme mode
    final settings = ref.watch(settingsProvider);
    
    _log.info('Building app with theme: ${settings.themeMode}');
    
    // Create theme with adjusted font size
    final lightTheme = _createTheme(context, AppTheme.lightTheme, settings.fontSize.size);
    final darkTheme = _createTheme(context, AppTheme.darkTheme, settings.fontSize.size);
    final sepiaTheme = _createTheme(context, AppTheme.sepiaTheme, settings.fontSize.size);

    // Determine which theme to use based on the app theme mode
    ThemeData activeTheme;
    switch (settings.themeMode) {
      case AppThemeMode.light:
        activeTheme = lightTheme;
        break;
      case AppThemeMode.dark:
        activeTheme = darkTheme;
        break;
      case AppThemeMode.sepia:
        activeTheme = sepiaTheme;
        break;
      case AppThemeMode.system:
        activeTheme = MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? darkTheme
            : lightTheme;
        break;
    }

    return MaterialApp.router(
      title: 'Modudi',
      debugShowCheckedModeBanner: false,
      // Use the theme directly based on the current mode
      theme: settings.themeMode == AppThemeMode.sepia ? sepiaTheme : lightTheme,
      darkTheme: darkTheme,
      themeMode: _getThemeMode(settings.themeMode),
      
      // Set localization delegates
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: _getLocale(settings.language),
      
      // GoRouter configuration
      routerConfig: AppRouter.router,
      // Firebase initialization check
      builder: (context, child) {
        return FutureBuilder(
          // This checks if Firebase is initialized properly
          future: _checkFirebaseInitialized(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Material(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError || snapshot.data == false) {
              _log.severe('Firebase not initialized: ${snapshot.error}');
              return Material(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        const Text(
                          'Firebase Initialization Error',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please restart the app. Error: ${snapshot.error ?? "Unknown error"}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Try to initialize Firebase again
                            _tryInitializeFirebase();
                            // Simple way to retry - recreation causes a rebuild
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MyApp()),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            // Firebase is initialized, show the app
            return child!;
          },
        );
      },
    );
  }

  // Helper method to create a theme with adjusted font size
  ThemeData _createTheme(BuildContext context, ThemeData baseTheme, double fontSize) {
    // Get the base text theme
    final baseTextTheme = baseTheme.textTheme;
    
    // Create a new text theme with the adjusted font size
    final adjustedTextTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: fontSize * 2.5),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: fontSize * 2.25),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontSize: fontSize * 2),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: fontSize * 1.75),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: fontSize * 1.5),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: fontSize * 1.25),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: fontSize * 1.2),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: fontSize * 1.1),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: fontSize),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: fontSize),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: fontSize * 0.9),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: fontSize * 0.8),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: fontSize),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: fontSize * 0.9),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: fontSize * 0.8),
    );
    
    // Return a new theme with the adjusted text theme
    return baseTheme.copyWith(
      textTheme: adjustedTextTheme,
    );
  }

  // Helper method to get the locale
  Locale? _getLocale(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return const Locale('en', '');
      case AppLanguage.arabic:
        return const Locale('ar', '');
      case AppLanguage.urdu:
        return const Locale('ur', '');
      default:
        return const Locale('en', '');
    }
  }

  Future<bool> _checkFirebaseInitialized() async {
    try {
      // Simple check if Firebase is initialized
      final apps = Firebase.apps;
      return apps.isNotEmpty;
    } catch (e) {
      _log.severe('Error checking Firebase initialization: $e');
      return false;
    }
  }
  
  Future<void> _tryInitializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        _log.info('Firebase initialized');
      }
    } catch (e) {
      _log.severe('Error initializing Firebase: $e');
    }
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.sepia:
        return ThemeMode.light; // Sepia is a variation of light theme
      default:
        return ThemeMode.system;
    }
  }
}
