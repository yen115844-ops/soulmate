import 'package:equatable/equatable.dart';

import 'user_model.dart';

/// Auth Response Model for login/register/verify-otp responses
class AuthResponseModel extends Equatable {
  final UserModel user;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  const AuthResponseModel({
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.message,
  });

  bool get hasTokens => accessToken != null && accessToken!.isNotEmpty && refreshToken != null && refreshToken!.isNotEmpty;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : throw ArgumentError('Missing or invalid "user" in auth response');

    return AuthResponseModel(
      user: user,
      accessToken: _stringOrNull(json['accessToken']),
      refreshToken: _stringOrNull(json['refreshToken']),
      message: _stringOrNull(json['message']),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (message != null) 'message': message,
    };
  }

  @override
  List<Object?> get props => [user, accessToken, refreshToken, message];
}

/// Login Request DTO
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Register Request DTO
class RegisterRequest {
  final String email;
  final String password;
  final String phone;
  final String fullName;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.phone,
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    // Format phone number with country code if not present
    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      // Remove leading 0 if present and add +84 (Vietnam)
      if (phone.startsWith('0')) {
        formattedPhone = '+84${phone.substring(1)}';
      } else {
        formattedPhone = '+84$phone';
      }
    }
    
    return {
      'email': email,
      'password': password,
      'phone': formattedPhone,
      'fullName': fullName,
    };
  }
}

/// Refresh Token Request DTO
class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}

/// Change Password Request DTO
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}
