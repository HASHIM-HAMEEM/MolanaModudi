import 'package:flutter/material.dart'; // Needed for BuildContext
import 'package:go_router/go_router.dart';
import '../core/widgets/main_scaffold.dart'; // Import the scaffold
import '../features/home/presentation/screens/home_screen.dart';
import '../features/library/presentation/screens/library_screen.dart'; // Use existing LibraryScreen
import '../features/history/presentation/screens/history_screen.dart'; // Import HistoryScreen
import '../features/profile/presentation/screens/profile_screen.dart'; // Import ProfileScreen
import '../features/reading/presentation/screens/reading_screen.dart'; // Import ReadingScreen
import '../features/book_detail/presentation/screens/book_detail_screen.dart'; // Use existing BookDetailScreen
import '../features/reading/presentation/screens/reading_tab_screen.dart'; // Import ReadingTabScreen
import '../features/favorites/presentation/screens/favorites_screen.dart'; // Import FavoritesScreen
import '../features/videos/presentation/screens/videos_screen.dart'; // Import VideosScreen
import '../features/videos/presentation/screens/playlist_detail_screen.dart'; // Import PlaylistDetailScreen
import '../features/biography/presentation/screens/biography_screen.dart'; // Import BiographyScreen
import 'route_names.dart';

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
             pageBuilder: (context, state) => const NoTransitionPage(child: LibraryScreen()),
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
            path: RouteNames.history, // History tab
            pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
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
      // Add route for Biography Screen
      GoRoute(
        name: RouteNames.biography,
        path: RouteNames.biography,
        parentNavigatorKey: _rootNavigatorKey, // Show over the shell
        pageBuilder: (context, state) => const MaterialPage(
          child: BiographyScreen(),
          fullscreenDialog: true, // Optionally show as a modal dialog
        ),
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
          return BookDetailScreen(bookId: bookId);
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
}
