import 'package:equatable/equatable.dart';

/// Auth Events for AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check authentication status on app start
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event to register a new user
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String phone;
  final String fullName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.phone,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, password, phone, fullName];
}

/// Event to logout
class AuthLogoutRequested extends AuthEvent {
  final bool logoutAll;

  const AuthLogoutRequested({this.logoutAll = false});

  @override
  List<Object?> get props => [logoutAll];
}

/// Event to refresh token
class AuthRefreshRequested extends AuthEvent {
  const AuthRefreshRequested();
}

/// Event to change password
class AuthChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Event to clear error message
class AuthClearError extends AuthEvent {
  const AuthClearError();
}

/// Event to verify OTP
class AuthVerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;

  const AuthVerifyOtpRequested({
    required this.email,
    required this.otp,
  });

  @override
  List<Object?> get props => [email, otp];
}

/// Event to resend OTP
class AuthResendOtpRequested extends AuthEvent {
  final String email;

  const AuthResendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to delete account
class AuthDeleteAccountRequested extends AuthEvent {
  final String password;

  const AuthDeleteAccountRequested({required this.password});

  @override
  List<Object?> get props => [password];
}
