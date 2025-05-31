import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:modudi/core/themes/app_theme.dart';
import 'package:modudi/core/l10n/l10n.dart';
import 'package:modudi/routes/app_router.dart'; // Import the router
import 'package:modudi/core/l10n/app_localizations_wrapper.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static final Logger _log = Logger('MyApp');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    
    _log.info('Building app with theme: ${appSettings.themeMode}, language: ${appSettings.language}, app font: ${appSettings.appFontFamily}');
    
    // Get base themes
    final lightTheme = AppTheme.lightTheme;
    final darkTheme = AppTheme.darkTheme;
    final sepiaTheme = AppTheme.sepiaTheme;

    // Get default font family for selected language
    final String languageCode = appSettings.language.code;
    final String defaultFontFamily = AppTheme.getFontFamilyForLanguage(languageCode);
    
    _log.info('Using default font family for ${appSettings.language.displayName}: $defaultFontFamily');

    // Apply app font family to themes (only for app UI, not reading content)
    String? appFontFamily;
    if (appSettings.appFontFamily != AppFontFamily.system) {
      appFontFamily = appSettings.appFontFamily.fontFamily;
    }

    // Create theme copies with the appropriate app font family
    final ThemeData currentLightTheme = appFontFamily != null
        ? lightTheme.copyWith(
            textTheme: lightTheme.textTheme.apply(fontFamily: appFontFamily),
          )
        : appSettings.language.code == 'ur' 
            ? lightTheme.copyWith(
                textTheme: lightTheme.textTheme.apply(fontFamily: 'JameelNooriNastaleeqRegular'),
              )
            : lightTheme;
        
    final ThemeData currentDarkTheme = appFontFamily != null
        ? darkTheme.copyWith(
            textTheme: darkTheme.textTheme.apply(fontFamily: appFontFamily),
          )
        : appSettings.language.code == 'ur'
            ? darkTheme.copyWith(
                textTheme: darkTheme.textTheme.apply(fontFamily: 'JameelNooriNastaleeqRegular'),
              )
            : darkTheme;
        
    final ThemeData currentSepiaTheme = appFontFamily != null
        ? sepiaTheme.copyWith(
            textTheme: sepiaTheme.textTheme.apply(fontFamily: appFontFamily),
          )
        : appSettings.language.code == 'ur'
            ? sepiaTheme.copyWith(
                textTheme: sepiaTheme.textTheme.apply(fontFamily: 'JameelNooriNastaleeqRegular'),
              )
            : sepiaTheme;

    return MaterialApp.router(
      title: 'Modudi',
      debugShowCheckedModeBanner: false,
      // Use the theme directly based on the current mode
      theme: appSettings.themeMode == AppThemeMode.sepia ? currentSepiaTheme : currentLightTheme,
      darkTheme: currentDarkTheme,
      themeMode: _getThemeMode(appSettings.themeMode),
      
      // Set localization delegates
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: _getLocale(appSettings.language),
      
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

  // Helper method to get the locale
  Locale? _getLocale(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return const Locale('en', '');
      case AppLanguage.arabic:
        return const Locale('ar', '');
      case AppLanguage.urdu:
        return const Locale('ur', '');
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
    }
  }
}
