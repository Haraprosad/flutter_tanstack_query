import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// Represents the current network connectivity status.
enum NetworkStatus {
  /// The network status is unknown (e.g., during initialization).
  unknown,

  /// The device is online and connected to the internet.
  online,

  /// The device is offline and not connected to the internet.
  offline,
}

/// Monitors and provides the current network connectivity status.
///
/// This class uses `connectivity_plus` to listen for network changes.
class NetworkPolicy {
  static NetworkPolicy? _instance;

  /// Provides a singleton instance of [NetworkPolicy].
  static NetworkPolicy get instance => _instance ??= NetworkPolicy._();

  NetworkPolicy._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkStatus _status = NetworkStatus.unknown;

  /// A broadcast stream that emits the current [NetworkStatus] whenever it changes.
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  /// Exposes the stream of network status changes.
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// The current network status.
  NetworkStatus get status => _status;

  /// True if the device is currently online.
  bool get isOnline => _status == NetworkStatus.online;

  /// True if the device is currently offline.
  bool get isOffline => _status == NetworkStatus.offline;

  /// Initializes the [NetworkPolicy].
  ///
  /// This must be called before using network status, typically
  /// at the start of your application.
  Future<void> initialize() async {
    // Check initial connectivity
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
      _status = NetworkStatus.unknown; // Fallback to unknown on error
    }

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
    debugPrint('NetworkPolicy initialized.');
  }

  /// Internal method to update the network status and notify listeners.
  void _updateStatus(List<ConnectivityResult> results) {
    // Consider connected if any connection is available
    final newStatus = results.contains(ConnectivityResult.none)
        ? NetworkStatus.offline
        : NetworkStatus.online;

    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
      debugPrint('Network status changed to: $_status');
    }
  }

  /// Manually checks and returns the current connectivity status.
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false; // Assume offline on error
    }
  }

  /// Disposes the network policy resources. Should be called on app shutdown.
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    _instance = null; // Reset singleton
    debugPrint('NetworkPolicy disposed.');
  }
}
