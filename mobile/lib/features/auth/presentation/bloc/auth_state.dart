import 'package:equatable/equatable.dart';

import '../../data/models/user_enums.dart';
import '../../data/models/user_model.dart';

/// Auth States for AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when app starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is authenticated and active
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  /// Get user status enum
  UserStatus get userStatus => UserStatus.fromString(user.status ?? 'PENDING');

  /// Get KYC status enum
  KycStatus get kycStatus => KycStatus.fromString(user.kycStatus ?? 'NONE');

  /// Get user role enum
  UserRole get userRole => UserRole.fromString(user.role ?? 'USER');

  /// Check if user profile is complete
  bool get isProfileComplete {
    final profile = user.profile;
    if (profile == null) return false;
    return profile.fullName != null &&
        profile.fullName!.isNotEmpty &&
        profile.dateOfBirth != null &&
        profile.gender != null;
  }

  @override
  List<Object?> get props => [user];
}

/// State when user account is pending verification
class AuthPendingVerification extends AuthState {
  final UserModel user;
  final String message;

  const AuthPendingVerification({
    required this.user,
    this.message = 'Tài khoản của bạn đang chờ xác minh',
  });

  @override
  List<Object?> get props => [user, message];
}

/// State when user account is suspended
class AuthSuspended extends AuthState {
  final UserModel user;
  final String message;

  const AuthSuspended({
    required this.user,
    this.message = 'Tài khoản của bạn đã bị tạm khóa',
  });

  @override
  List<Object?> get props => [user, message];
}

/// State when user account is banned
class AuthBanned extends AuthState {
  final UserModel user;
  final String message;

  const AuthBanned({
    required this.user,
    this.message = 'Tài khoản của bạn đã bị cấm',
  });

  @override
  List<Object?> get props => [user, message];
}

/// State when user needs to complete profile
class AuthNeedsProfileSetup extends AuthState {
  final UserModel user;

  const AuthNeedsProfileSetup({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when auth operation fails
class AuthError extends AuthState {
  final String message;
  final dynamic errors;

  const AuthError({
    required this.message,
    this.errors,
  });

  @override
  List<Object?> get props => [message, errors];
}

/// State when login is successful
class AuthLoginSuccess extends AuthState {
  final UserModel user;

  const AuthLoginSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State when registration is successful
class AuthRegisterSuccess extends AuthState {
  final UserModel user;

  const AuthRegisterSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State when logout is successful
class AuthLogoutSuccess extends AuthState {
  const AuthLogoutSuccess();
}

/// State when password change is successful
class AuthPasswordChanged extends AuthState {
  const AuthPasswordChanged();
}

/// State when OTP verification is successful
class AuthOtpVerified extends AuthState {
  final UserModel user;

  const AuthOtpVerified({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State when OTP is being verified
class AuthOtpVerifying extends AuthState {
  const AuthOtpVerifying();
}

/// State when OTP is resent
class AuthOtpResent extends AuthState {
  final String message;

  const AuthOtpResent({this.message = 'Mã OTP đã được gửi lại'});

  @override
  List<Object?> get props => [message];
}

/// State when account is being deleted
class AuthDeletingAccount extends AuthState {
  const AuthDeletingAccount();
}

/// State when account deletion is successful
class AuthAccountDeleted extends AuthState {
  final String message;

  const AuthAccountDeleted({this.message = 'Tài khoản đã được xóa thành công'});

  @override
  List<Object?> get props => [message];
}
