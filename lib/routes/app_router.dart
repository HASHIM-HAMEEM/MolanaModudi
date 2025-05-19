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
// Import FirebaseBookDetailScreen
import '../features/biography/presentation/screens/biography_screen.dart'; // Import BiographyScreen
import '../features/search/presentation/screens/search_screen.dart'; // Import SearchScreen
import '../features/library/presentation/screens/category_books_screen.dart'; // Import CategoryBooksScreen
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
    initialLocation: RouteNames.home,
    debugLogDiagnostics: true, 
    navigatorKey: _rootNavigatorKey,
    observers: [
      // Add navigation observer for logging
      _NavigationObserver(),
    ],

    routes: <RouteBase>[
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
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
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
            pageBuilder: (context, state) => const NoTransitionPage(child: LibraryScreenRedesigned()),
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
            // builder: (context, state) => const HistoryScreen(), // Commented out
            pageBuilder: (context, state) => const NoTransitionPage(child: Text("History Screen Placeholder")), // Placeholder for HistoryScreen
          ),
          // Reading Tab
          GoRoute(
            path: RouteNames.readingTab, // Path for the Reading Tab
            pageBuilder: (context, state) => const NoTransitionPage(child: ReadingTabScreen()), // Point to the new screen
          ),
          // Favorites Tab
          GoRoute(
            path: RouteNames.favorites,
            pageBuilder: (context, state) => NoTransitionPage(child: FavoritesScreen()),
          ),
          // Profile Tab
          GoRoute(
            path: RouteNames.profile,
             pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      // Top-level routes that cover the shell (no bottom nav)
      // Videos Route
      GoRoute(
        path: RouteNames.videos,
        pageBuilder: (context, state) => const NoTransitionPage(child: VideosScreen()),
        routes: <RouteBase>[
          GoRoute(
            path: ':playlistId', // Relative path from /videos
            name: 'playlistDetail', // Unique name
            parentNavigatorKey: _rootNavigatorKey, // Use root navigator
            builder: (context, state) {
              final playlistId = state.pathParameters['playlistId']!;
              return PlaylistDetailScreen(playlistId: playlistId);
            },
            routes: <RouteBase>[
              GoRoute(
                path: ':videoId', // Relative path from /videos/:playlistId
                name: 'videoPlayer', // Unique name
                parentNavigatorKey: _rootNavigatorKey, // Use root navigator
                builder: (context, state) {
                  final videoId = state.pathParameters['videoId']!;
                  // Placeholder for video player screen
                  return const Scaffold(
                    body: Center(child: Text('Loading video...')),
                  );
                },
              ),
            ],
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
      // GoRoute(
      //   name: RouteNames.authGate,
      //   path: RouteNames.authGate,
      //   parentNavigatorKey: _rootNavigatorKey,
      //   // pageBuilder: (context, state) => const MaterialPage(child: AuthGate()),
      //   pageBuilder: (context, state) => const NoTransitionPage(child: Text("AuthGate Placeholder")),
      // ),
      // GoRoute(
      //   name: RouteNames.login,
      //   path: RouteNames.login,
      //   parentNavigatorKey: _rootNavigatorKey,
      //   // pageBuilder: (context, state) => const MaterialPage(child: LoginScreen()),
      //   pageBuilder: (context, state) => const NoTransitionPage(child: Text("Login Placeholder")),
      // ),
      // GoRoute(
      //   name: RouteNames.signup,
      //   path: RouteNames.signup,
      //   parentNavigatorKey: _rootNavigatorKey,
      //   // pageBuilder: (context, state) => const MaterialPage(child: SignupScreen()),
      //   pageBuilder: (context, state) => const NoTransitionPage(child: Text("Signup Placeholder")),
      // ),
      // GoRoute(
      //   name: RouteNames.onboarding,
      //   path: RouteNames.onboarding,
      //   parentNavigatorKey: _rootNavigatorKey,
      //   // pageBuilder: (context, state) => const MaterialPage(child: OnboardingScreen()),
      //   pageBuilder: (context, state) => const NoTransitionPage(child: Text("Onboarding Placeholder")),
      // ),
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
