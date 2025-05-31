import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/route_names.dart'; // Import route names

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Mapping between route paths and bottom nav indices
  final Map<String, int> _routeIndexMap = {
    RouteNames.home: 0,
    RouteNames.library: 1,
    RouteNames.readingTab: 2,
    RouteNames.favorites: 3, // Changed from videos to favorites
    RouteNames.profile: 4,
    // Add other primary tab routes here if needed
  };

  void _onTap(int index) {
    String destination = RouteNames.home; // Default destination
    
    switch (index) {
      case 0: destination = RouteNames.home; break;
      case 1: destination = RouteNames.library; break;
      case 2: destination = RouteNames.readingTab; break;
      case 3: destination = RouteNames.favorites; break; // Changed from videos to favorites
      case 4: destination = RouteNames.profile; break;
    }
    
    // Navigate using GoRouter
    GoRouter.of(context).go(destination);
  }

  @override
  Widget build(BuildContext context) {
    // Update _currentIndex based on the current route
    final location = GoRouterState.of(context).uri.toString();
    _currentIndex = _routeIndexMap[location] ?? 0; // Default to home if route not found

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_library_outlined),
            activeIcon: Icon(Icons.local_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Reading',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 