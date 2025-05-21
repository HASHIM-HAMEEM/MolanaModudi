# Modudi

## Description
A Flutter application for reading and exploring Islamic content, including books, videos, and more. This app offers features like reading with customizable settings, video playback, bookmarking, and AI-powered tools for vocabulary assistance.

## Features
- Book reading with customizable font size, type, and theme
- Video playback with YouTube integration
- Bookmarking system
- Content search
- User profiles
- AI-powered vocabulary assistance
- Multi-language support
- Offline reading capabilities
- Advanced caching system for improved performance
- Pinning books for offline access

## Technologies Used
- Flutter & Dart
- Firebase (Firestore, Analytics, Storage)
- Riverpod for state management
- Go Router for navigation
- Shared Preferences
- Hive for local caching
- Google's Gemini API for AI features

## Project Structure
- `/lib/app` - Application setup
- `/lib/config` - Configuration files
- `/lib/core` - Core utilities, widgets, and services
- `/lib/features` - Feature modules (books, reading, favorites, etc.)
- `/lib/routes` - App routing

## Getting Started
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase: Add your own `google-services.json` and Firebase configuration
4. Run the app: `flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY`

## Environment Setup
Ensure you have the following installed:
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code with Flutter/Dart plugins
- For iOS development: Xcode (on macOS)

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
- Thanks to all contributors who have helped with the development
- Special thanks to the open source community for all the amazing packages used in this project
