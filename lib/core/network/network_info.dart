import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';

/// A service that provides information about the device's network connectivity
/// This is crucial for the caching system to properly handle offline mode
class NetworkInfo {
  final Connectivity _connectivity;
  final _log = Logger('NetworkInfo');
  
  bool _isConnected = true;
  
  final _connectivityStatusController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectivityStatusStream => _connectivityStatusController.stream;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  NetworkInfo({Connectivity? connectivity}) 
      : _connectivity = connectivity ?? Connectivity();
  
  /// Initialize the network monitoring
  Future<void> initialize() async {
    try {
      // Get initial connection status
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChange(result);
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (e) {
          _log.warning('Error monitoring connectivity: $e');
          // Assume connected when there's an error checking
          _updateConnectionStatus(true);
        }
      );
      
      _log.info('Network connectivity monitoring initialized');
    } catch (e) {
      _log.severe('Failed to initialize network monitoring: $e');
      // Assume connected when there's an error initializing
      _updateConnectionStatus(true);
    }
  }
  
  /// Handle connectivity change events
  void _handleConnectivityChange(List<ConnectivityResult> result) {
    // Consider connected if any of the results is not "none"
    final isConnected = result.any((r) => r != ConnectivityResult.none);
    _updateConnectionStatus(isConnected);
  }
  
  /// Update the connection status and notify listeners
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _log.info('Network connectivity changed: ${isConnected ? 'Connected' : 'Disconnected'}');
      _connectivityStatusController.add(isConnected);
    }
  }
  
  /// Check if device is connected to the internet
  bool get isConnected => _isConnected;
  
  /// Manually check connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final isConnected = result.any((r) => r != ConnectivityResult.none);
      _updateConnectionStatus(isConnected);
      return isConnected;
    } catch (e) {
      _log.warning('Error checking connectivity: $e');
      // Assume connected when there's an error checking
      return true;
    }
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityStatusController.close();
  }
}
