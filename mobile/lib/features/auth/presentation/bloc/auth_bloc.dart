import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/models/user_enums.dart';
import '../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC handles authentication logic
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository,
       super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthRefreshRequested>(_onRefreshRequested);
    on<AuthClearError>(_onClearError);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthResendOtpRequested>(_onResendOtpRequested);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
  }

  /// Register FCM token via PushNotificationService
  Future<void> _registerFcmToken() async {
    try {
      await getIt<PushNotificationService>().registerTokenWithBackend();
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  /// Unregister FCM token via PushNotificationService
  Future<void> _unregisterFcmToken() async {
    try {
      await getIt<PushNotificationService>().unregisterToken();
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  /// Emit appropriate state based on user status
  void _emitUserState(UserModel user, Emitter<AuthState> emit) {
    final status = UserStatus.fromString(user.status ?? 'PENDING');

    switch (status) {
      case UserStatus.active:
        // Check if profile is complete
        final profile = user.profile;
        final isProfileComplete =
            profile != null &&
            profile.fullName != null &&
            profile.fullName!.isNotEmpty &&
            profile.dateOfBirth != null &&
            profile.gender != null;

        if (isProfileComplete) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthNeedsProfileSetup(user: user));
        }
        break;

      case UserStatus.pending:
        emit(AuthPendingVerification(user: user));
        break;

      case UserStatus.suspended:
        emit(AuthSuspended(user: user));
        break;

      case UserStatus.banned:
        emit(AuthBanned(user: user));
        break;
    }
  }

  /// Check authentication status on app start
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      if (_authRepository.hasValidSession) {
        // Try to get current user from API with full details
        final user = await _authRepository.getCurrentUser();
        
        // Register FCM token when session is valid
        await _registerFcmToken();
        
        _emitUserState(user, emit);
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('Auth check failed: $e');
      // If token is invalid, clear and show unauthenticated
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _authRepository.login(
        LoginRequest(email: event.email, password: event.password),
      );

      emit(AuthLoginSuccess(user: response.user));

      // Register FCM token after successful login
      await _registerFcmToken();

      // Check user status and emit appropriate state
      _emitUserState(response.user, emit);
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, errors: e.errors));
    } catch (e) {
      emit(AuthError(message: getErrorMessage(e)));
    }
  }

  /// Handle register request
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final response = await _authRepository.register(
        RegisterRequest(
          email: event.email,
          password: event.password,
          phone: event.phone,
          fullName: event.fullName,
        ),
      );

      emit(AuthRegisterSuccess(user: response.user));

      // If backend returned tokens (legacy), emit user state; else stay on AuthRegisterSuccess for OTP flow
      if (response.hasTokens) {
        _emitUserState(response.user, emit);
      }
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, errors: e.errors));
    } catch (e) {
      emit(AuthError(message: getErrorMessage(e)));
    }
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Unregister FCM token before logout
      await _unregisterFcmToken();
      
      if (event.logoutAll) {
        await _authRepository.logoutAll();
      } else {
        await _authRepository.logout();
      }
      emit(const AuthLogoutSuccess());
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even if API fails, still logout locally
      emit(const AuthLogoutSuccess());
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle token refresh request
  Future<void> _onRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await _authRepository.refreshToken();
      _emitUserState(response.user, emit);
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Clear error state
  void _onClearError(AuthClearError event, Emitter<AuthState> emit) {
    // Determine what state to return to based on auth status
    if (_authRepository.isLoggedIn) {
      final cachedUser = _authRepository.getCachedUser();
      if (cachedUser != null) {
        _emitUserState(cachedUser, emit);
      } else {
        emit(const AuthUnauthenticated());
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handle OTP verification
  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOtpVerifying());

    try {
      final response = await _authRepository.verifyOtp(
        email: event.email,
        otp: event.otp,
      );

      emit(AuthOtpVerified(user: response.user));

      // Emit appropriate state based on user status
      _emitUserState(response.user, emit);
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, errors: e.errors));
    } catch (e) {
      debugPrint('OTP verification error: $e');
      emit(AuthError(message: getErrorMessage(e)));
    }
  }

  /// Handle resend OTP
  Future<void> _onResendOtpRequested(
    AuthResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.resendOtp(email: event.email);
      emit(const AuthOtpResent());
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, errors: e.errors));
    } catch (e) {
      debugPrint('Resend OTP error: $e');
      emit(AuthError(message: getErrorMessage(e)));
    }
  }

  /// Handle delete account request
  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthDeletingAccount());

    try {
      await _authRepository.deleteAccount(password: event.password);
      emit(const AuthAccountDeleted());
      emit(const AuthUnauthenticated());
    } on ApiException catch (e) {
      emit(AuthError(message: e.message, errors: e.errors));
    } catch (e) {
      debugPrint('Delete account error: $e');
      emit(AuthError(message: getErrorMessage(e)));
    }
  }
}
