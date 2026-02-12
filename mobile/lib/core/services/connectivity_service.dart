import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnected = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Start listening for connectivity changes
  Future<void> init() async {
    // Check initial state
    final results = await _connectivity.checkConnectivity();
    _updateState(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    final connected = results.any((r) => r != ConnectivityResult.none);
    if (isConnected.value != connected) {
      isConnected.value = connected;
      debugPrint('📶 Connectivity: ${connected ? "Online" : "Offline"}');
    }
  }

  /// Dispose subscription
  void dispose() {
    _subscription?.cancel();
  }
}
