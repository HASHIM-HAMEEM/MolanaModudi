import 'package:flutter/material.dart'; // Needed for BuildContext
import 'package:go_router/go_router.dart';
import '../core/utils/app_logger.dart'; // Import AppLogger
import '../core/widgets/main_scaffold.dart'; // Import the scaffold
import '../features/home/presentation/screens/home_screen.dart';
import '../features/books/presentation/screens/book_detail_screen.dart'; // Import for BookDetailScreen
import '../features/library/presentation/screens/library_screen_redesigned.dart'; // Use redesigned LibraryScreen
// import '../features/history/presentation/screens/history_screen.dart'; // Import HistoryScreen - Commented out
import '../features/profile/presentation/screens/profile_screen.dart'; // Import ProfileScreen
import '../features/reading/presentation/screens/reading_screen.dart'; // Import ReadingScreen
import '../features/books/presentation/screens/book_detail_screen.dart' as book_detail; // Use existing BookDetailScreen
import '../features/reading/presentation/screens/reading_tab_screen.dart'; // Import ReadingTabScreen
import '../features/favorites/presentation/screens/favorites_screen.dart'; // Import FavoritesScreen
import '../features/videos/presentation/screens/videos_screen.dart'; // Import VideosScreen
import '../features/videos/presentation/screens/playlist_detail_screen.dart'; // Import PlaylistDetailScreen
import '../features/videos/presentation/screens/video_player_screen.dart'; // Import VideoPlayerScreen
import '../features/videos/domain/entities/video_entity.dart'; // Import VideoEntity
import '../features/articles/presentation/screens/article_detail_screen.dart'; // Import ArticleDetailScreen
// Import FirebaseBookDetailScreen
import '../features/biography/presentation/screens/biography_screen.dart'; // Import BiographyScreen
import '../features/search/presentation/screens/search_screen.dart'; // Import SearchScreen
import '../features/search/presentation/screens/unified_search_screen.dart'; // Import UnifiedSearchScreen
import '../features/library/presentation/screens/category_books_screen.dart'; // Import CategoryBooksScreen
import '../features/splash/presentation/screens/splash_screen.dart'; // Import SplashScreen
import 'route_names.dart';
// import 'package:modudi/features/auth/presentation/screens/auth_gate.dart';
// import 'package:modudi/features/auth/presentation/screens/login_screen.dart';
// import 'package:modudi/features/auth/presentation/screens/signup_screen.dart';
// import 'package:modudi/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Application routing configuration using GoRouter.
class AppRouter {
  // Private navigator keys
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  // Key for the shell's navigator
  static final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ShellNavigator');

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true, 
    navigatorKey: _rootNavigatorKey,
    observers: [
      // Add navigation observer for logging
      _NavigationObserver(),
    ],


    routes: <RouteBase>[
      // Splash Screen Route (Initial Route)
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      // Main App Route (After Splash)
      GoRoute(
        path: RouteNames.main,
        name: 'main',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => RouteNames.home, // Redirect to home tab
      ),
      
      // Application Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: <RouteBase>[
          // Primary Tabs (Bottom Nav)
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
            routes: <RouteBase>[
               // Example nested route accessible from Home: /home/book/1
               GoRoute(
                 path: 'book/:bookId', // Relative path from /home
                 name: 'homeBookDetail', // Unique name
                 parentNavigatorKey: _rootNavigatorKey, // Use root navigator
                 builder: (context, state) {
                    final bookId = state.pathParameters['bookId']!;
                    // Use the refactored BookDetailScreen
                    return BookDetailScreen(bookId: bookId);
                 },
              ),
            ]
          ),
          // Library Tab
          GoRoute(
            path: RouteNames.library,
            name: RouteNames.library, // Add name for named navigation
            builder: (context, state) => const LibraryScreenRedesigned(),
              routes: <RouteBase>[
                 // Route for book details accessible from Library: /library/book/1
                 GoRoute(
                   path: 'book/:bookId', // Relative path from /library
                   name: 'libraryBookDetail', // Unique name
                   parentNavigatorKey: _rootNavigatorKey, // Use root navigator
                   builder: (context, state) {
                      final bookId = state.pathParameters['bookId']!;
                      // Use the refactored BookDetailScreen
                      return BookDetailScreen(bookId: bookId);
                   },
                ),
              ]
          ),
          // History Tab
          GoRoute(
            path: 'history', // Path for HistoryScreen
            builder: (context, state) => const Text("History Screen Placeholder"), // Placeholder for HistoryScreen
          ),
          // Reading Tab
          GoRoute(
            path: RouteNames.readingTab, // Path for the Reading Tab
            builder: (context, state) => const ReadingTabScreen(), // Point to the new screen
          ),
          // Favorites Tab
          GoRoute(
            path: RouteNames.favorites,
            builder: (context, state) => FavoritesScreen(),
          ),
          // Profile Tab
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Top-level routes that cover the shell (no bottom nav)
      // Videos Route
      GoRoute(
        path: RouteNames.videos,
        builder: (context, state) => const VideosScreen(),
        routes: <RouteBase>[
          // Standalone video player route
          GoRoute(
            path: 'player', // /videos/player
            name: 'videoPlayer', // Unique name
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              
              if (extra != null && extra['video'] is VideoEntity) {
                return VideoPlayerScreen(
                  video: extra['video'] as VideoEntity,
                  playlistId: extra['playlistId'] ?? '',
                );
              }
              
              // Fallback: redirect back to videos if no video data
              return const VideosScreen();
            },
          ),
          // Playlist routes
          GoRoute(
            path: 'playlist/:playlistId', // /videos/playlist/:playlistId
            name: 'playlistDetail', // Unique name
            parentNavigatorKey: _rootNavigatorKey, // Use root navigator
            builder: (context, state) {
              final playlistId = state.pathParameters['playlistId']!;
              return PlaylistDetailScreen(playlistId: playlistId);
            },
          ),
          // Direct playlist access route
          GoRoute(
            path: ':playlistId', // /videos/:playlistId (for direct playlist IDs)
            name: 'directPlaylistDetail', // Unique name
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final playlistId = state.pathParameters['playlistId']!;
              return PlaylistDetailScreen(playlistId: playlistId);
            },
          ),
        ]
      ),
      // Generic Book Detail Route (used by LibraryScreen and potentially others)
      GoRoute(
        name: RouteNames.bookDetailItem, // Name for /books/:bookId
        path: RouteNames.bookDetailItem, // Matches /books/:bookId
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          // Use the refactored BookDetailScreen
          return book_detail.BookDetailScreen(bookId: bookId);
        },
      ),
      // Keep the /book-detail/:bookId route if explicitly used elsewhere
      GoRoute(
        name: RouteNames.bookDetail,
        path: RouteNames.bookDetail, // Matches /book-detail/:bookId
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          // Use the refactored BookDetailScreen
          return BookDetailScreen(bookId: bookId);
        },
      ),
      // Firebase Book Detail Route - REDIRECT to BookDetailScreen
      GoRoute(
        name: 'firebaseBook',
        path: '/firebase-book/:bookId',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          AppLogger.logNavigation('firebase-book', 'bookDetailItem', parameters: {'bookId': bookId});
          return '/books/$bookId'; // Redirect to the standard book detail route
        },
      ),
      // Reading Screen Route
      GoRoute(
        name: RouteNames.readingBook, 
        path: RouteNames.readingBook, // Matches /read/:bookId
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return ReadingScreen(bookId: bookId);
        },
      ),
      // Biography Screen Route (Top-Level)
      GoRoute(
        name: RouteNames.biography,
        path: RouteNames.biography,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BiographyScreen(),
      ),
      // Search Screen Route (Top-Level)
      GoRoute(
        name: RouteNames.search,
        path: RouteNames.search, // Should be "/search"
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchScreen(query: query);
        },
      ),
      // Unified Search Routes (Top-Level)
      GoRoute(
        name: 'unifiedSearchGlobal',
        path: '/search/global',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return UnifiedSearchScreen.global(initialQuery: query);
        },
      ),
      GoRoute(
        name: 'unifiedSearchLibrary', 
        path: '/search/library',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return UnifiedSearchScreen.library(initialQuery: query);
        },
      ),
      // Category Books Screen Route (Top-Level)
      GoRoute(
        name: RouteNames.categoryBooks,
        path: RouteNames.categoryBooks, // Should be "/category/:categoryId"
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'] ?? '';
          return CategoryBooksScreen(categoryId: categoryId);
        },
      ),
      // Articles Routes (Top-Level)
      GoRoute(
        name: 'articles',
        path: '/articles',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          // Navigate to articles list screen
          return const Scaffold(
            body: Center(child: Text('Articles List Coming Soon')),
          );
        },
        routes: <RouteBase>[
          // Individual article route
          GoRoute(
            path: ':articleId', // /articles/:articleId
            name: 'articleDetail',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final articleId = state.pathParameters['articleId']!;
              // Navigate to article detail screen
              return ArticleDetailScreen(articleId: articleId);
            },
          ),
        ],
      ),

    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
}

// Navigation observer for logging all navigation events
class _NavigationObserver extends NavigatorObserver {
  final _log = AppLogger.getLogger('Navigation');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.info('PUSH: ${_getRouteName(previousRoute)} → ${_getRouteName(route)}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.info('POP: ${_getRouteName(route)} → ${_getRouteName(previousRoute)}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log.info('REPLACE: ${_getRouteName(oldRoute)} → ${_getRouteName(newRoute)}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.info('REMOVE: ${_getRouteName(route)}');
  }

  String _getRouteName(Route<dynamic>? route) {
    return route?.settings.name ?? 'unknown';
  }
}
