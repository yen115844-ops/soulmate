import 'dart:async';

import 'package:flutter/foundation.dart';

/// Global Auth Service to manage authentication state across the app
/// This service handles auth events like token expiration and logout
class AuthService {
  AuthService._();
  
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;
  
  /// Stream controller for auth state changes
  final _authStateController = StreamController<AuthState>.broadcast();
  
  /// Stream of auth state changes
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  /// Current auth state
  AuthState _currentState = AuthState.unknown;
  AuthState get currentState => _currentState;
  
  /// Emit authenticated state
  void setAuthenticated() {
    _currentState = AuthState.authenticated;
    _authStateController.add(AuthState.authenticated);
    debugPrint('🔐 AuthService: User authenticated');
  }
  
  /// Emit unauthenticated state (user logged out voluntarily)
  void setUnauthenticated() {
    _currentState = AuthState.unauthenticated;
    _authStateController.add(AuthState.unauthenticated);
    debugPrint('🔐 AuthService: User logged out');
  }
  
  /// Emit session expired state (token expired and refresh failed)
  void setSessionExpired() {
    _currentState = AuthState.sessionExpired;
    _authStateController.add(AuthState.sessionExpired);
    debugPrint('🔐 AuthService: Session expired');
  }
  
  /// Dispose the service
  void dispose() {
    _authStateController.close();
  }
}

/// Auth state enum
enum AuthState {
  /// Unknown state - app just started
  unknown,
  
  /// User is authenticated
  authenticated,
  
  /// User is not authenticated (logged out)
  unauthenticated,
  
  /// Session expired - token expired and refresh failed
  /// UI should show a message and redirect to login
  sessionExpired,
}
