import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Manages application lifecycle events for query refetching
class AppLifecycleManager extends WidgetsBindingObserver {
  static AppLifecycleManager? _instance;
  static AppLifecycleManager get instance =>
      _instance ??= AppLifecycleManager._();

  AppLifecycleManager._();

  final StreamController<AppLifecycleState> _lifecycleController =
      StreamController<AppLifecycleState>.broadcast();

  bool _initialized = false;
  AppLifecycleState? _currentState;

  /// Stream of app lifecycle changes
  Stream<AppLifecycleState> get lifecycleStream => _lifecycleController.stream;

  /// Current app lifecycle state
  AppLifecycleState? get currentState => _currentState;

  /// Whether app is currently in foreground
  bool get isInForeground => _currentState == AppLifecycleState.resumed;

  /// Initialize lifecycle monitoring
  void initialize() {
    if (_initialized) return;

    WidgetsBinding.instance.addObserver(this);
    _currentState = WidgetsBinding.instance.lifecycleState;
    _initialized = true;

    debugPrint('AppLifecycleManager initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final previousState = _currentState;
    _currentState = state;

    // Emit lifecycle change
    if (!_lifecycleController.isClosed) {
      _lifecycleController.add(state);
    }

    debugPrint('App lifecycle changed from $previousState to $state');
  }

  /// Dispose resources
  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
      _initialized = false;
    }

    _lifecycleController.close();
    _instance = null;

    debugPrint('AppLifecycleManager disposed');
  }
}
