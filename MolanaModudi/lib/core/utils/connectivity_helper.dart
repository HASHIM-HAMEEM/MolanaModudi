import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';

/// A helper class to check network connectivity status
/// Used by caching systems to determine if remote data should be fetched
class ConnectivityHelper {
  final Connectivity _connectivity;
  final Logger _log = Logger('ConnectivityHelper');
  
  // Stream controller to broadcast connectivity changes
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  // Cached connection status
  bool _isConnected = true;
  
  /// Stream of connectivity status changes (true = connected, false = disconnected)
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  /// Factory constructor
  factory ConnectivityHelper.instance() {
    return ConnectivityHelper._internal(Connectivity());
  }
  
  /// Internal constructor with dependency injection for testing
  ConnectivityHelper._internal(this._connectivity) {
    // Initialize by checking connectivity
    checkConnectivity();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        final hasConnection = results.any((status) => status != ConnectivityResult.none);
        _updateConnectionStatus(hasConnection ? ConnectivityResult.wifi : ConnectivityResult.none);
    });
  }
  
  /// Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    _log.info('Connectivity changed: $result');
    
    final isConnected = result != ConnectivityResult.none;
    
    // Only broadcast if there's a change
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(_isConnected);
      
      _log.info('Connection status updated: ${isConnected ? 'Connected' : 'Disconnected'}');
    }
  }
  
  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      final bool hasConnection = results.any((status) => status != ConnectivityResult.none);
      _updateConnectionStatus(hasConnection ? ConnectivityResult.wifi : ConnectivityResult.none);
      return _isConnected;
    } catch (e) {
      _log.warning('Error checking connectivity: $e');
      _updateConnectionStatus(ConnectivityResult.none); // Explicitly set to no connection on error
      return false;
    }
  }
  
  /// Returns the current cached connection status without making a new check
  bool get isConnectedSync => _isConnected;
  
  /// Check if the device is currently connected to a network
  Future<bool> isConnected() async {
    return await checkConnectivity();
  }
  
  /// Dispose resources
  void dispose() {
    _connectionStatusController.close();
  }
}
