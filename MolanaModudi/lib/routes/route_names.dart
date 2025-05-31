/// Contains constant definitions for route paths used in the app.
class RouteNames {
  static const String splash = '/';
  static const String home = '/home';
  static const String library = '/library';
  static const String history = '/history'; // Added History route
  static const String readingTab = '/reading-tab'; // New route for the tab
  static const String videos = '/videos'; // Add videos route
  static const String profile = '/profile';
  static const String favorites = '/favorites'; // Add favorites route
  static const String biography = '/biography'; // Add biography route name
  static const String search = '/search'; // New search route
  static const String settings = '/settings';
  static const String categoryBooks = '/category/:categoryId'; // Add category books route

  // Routes likely displayed *over* the main scaffold
  static const String readingBook = '/read/:bookId'; // Changed path for clarity
  static const String bookDetailItem = '/books/:bookId'; // Changed path for clarity
  static const String bookDetail = '/book-detail/:bookId'; // Add explicit path for book-detail
  static const String playlistDetail = '/videos/:playlistId'; // Add explicit path for playlist detail

  // Helper methods for dynamic routes
  static String readingWithId(String bookId) => '/read/$bookId';
  static String bookDetailWithId(String bookId) => '/book-detail/$bookId';

  // Remove unused/potentially confusing base paths if detail routes handle IDs
  // static const String reading = '/reading'; 
  // static const String bookDetail = '/book'; 
}
