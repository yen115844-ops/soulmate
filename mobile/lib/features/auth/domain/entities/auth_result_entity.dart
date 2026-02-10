import 'package:equatable/equatable.dart';

/// Auth Response Entity - Domain entity for authentication response
class AuthResultEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final UserAuthInfo user;

  const AuthResultEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}

/// Basic user info returned after authentication
class UserAuthInfo extends Equatable {
  final String id;
  final String email;
  final String? role;

  const UserAuthInfo({
    required this.id,
    required this.email,
    this.role,
  });

  @override
  List<Object?> get props => [id, email, role];
}
