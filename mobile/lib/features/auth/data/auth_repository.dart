import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/local_storage_service.dart';
import 'models/auth_response_model.dart';
import 'models/user_model.dart';

/// Auth Repository handles all authentication related API calls
/// and local storage operations for auth data
class AuthRepository {
  final ApiClient _apiClient;
  final LocalStorageService _storage;

  AuthRepository({
    required ApiClient apiClient,
    required LocalStorageService storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  /// Login with email and password
  Future<AuthResponseModel> login(LoginRequest request) async {
    final response = await _apiClient.post(
      AuthEndpoints.login,
      data: request.toJson(),
    );

    final responseData = response.data as Map<String, dynamic>;
    // API returns {success, data, timestamp} - extract data
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;

    final authResponse = AuthResponseModel.fromJson(data);

    // Save tokens and user data to local storage
    await _saveAuthData(authResponse);

    return authResponse;
  }

  /// Register a new user (sends OTP to email - no tokens until verify OTP)
  Future<AuthResponseModel> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      AuthEndpoints.register,
      data: request.toJson(),
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;

    final authResponse = AuthResponseModel.fromJson(data);

    // Only save tokens if backend returned them (after verify OTP); register returns user + message only
    if (authResponse.hasTokens) {
      await _saveAuthData(authResponse);
    }

    return authResponse;
  }

  /// Refresh access token
  Future<AuthResponseModel> refreshToken() async {
    final currentRefreshToken = _storage.refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw UnauthorizedException(message: 'Không có refresh token');
    }

    final response = await _apiClient.post(
      AuthEndpoints.refresh,
      data: RefreshTokenRequest(refreshToken: currentRefreshToken).toJson(),
    );

    final authResponse = AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );

    // Save new tokens
    await _saveAuthData(authResponse);

    return authResponse;
  }

  /// Get current user profile and update cache
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get(AuthEndpoints.me);
    final responseData = response.data as Map<String, dynamic>;
    // API returns {success, data: {user: {...}}, timestamp} - extract user
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    final user = UserModel.fromJson(userData);

    // Update cached user (secure storage)
    await _storage.setUserProfileJson(json.encode(user.toJson()));

    return user;
  }

  /// Logout from current device
  Future<void> logout() async {
    try {
      final refreshToken = _storage.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          AuthEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } finally {
      // Always clear local data even if API call fails
      await _storage.clearAuthData();
      await _storage.clearCache();
    }
  }

  /// Logout from all devices
  Future<void> logoutAll() async {
    try {
      await _apiClient.post(AuthEndpoints.logoutAll);
    } finally {
      // Always clear local data even if API call fails
      await _storage.clearAuthData();
      await _storage.clearCache();
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => _storage.isLoggedIn;

  /// Get current access token
  String? get accessToken => _storage.accessToken;

  /// Get current user ID
  String? get userId => _storage.userId;

  /// Check if session is valid (has tokens)
  bool get hasValidSession {
    final token = _storage.accessToken;
    final refreshToken = _storage.refreshToken;
    return token != null &&
        token.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  /// Get cached user from local storage (now from secure storage)
  UserModel? getCachedUser() {
    final userJson = _storage.userProfileJson;
    if (userJson == null) return null;

    try {
      final Map<String, dynamic> userData = json.decode(userJson);
      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  /// Save auth data to local storage (requires tokens)
  Future<void> _saveAuthData(AuthResponseModel authResponse) async {
    if (!authResponse.hasTokens) return;
    await Future.wait([
      _storage.setAccessToken(authResponse.accessToken!),
      _storage.setRefreshToken(authResponse.refreshToken!),
      _storage.setUserId(authResponse.user.id),
      _storage.setLoggedIn(true),
      _storage.setUserProfileJson(
        json.encode(authResponse.user.toJson()),
      ),
    ]);
  }

  /// Verify OTP code
  Future<AuthResponseModel> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      AuthEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;

    final authResponse = AuthResponseModel.fromJson(data);

    // Save tokens and user data to local storage
    await _saveAuthData(authResponse);

    return authResponse;
  }

  /// Resend OTP code
  Future<void> resendOtp({required String email}) async {
    await _apiClient.post(AuthEndpoints.resendOtp, data: {'email': email});
  }

  /// Request forgot password - send OTP to email
  Future<void> requestForgotPassword({required String email}) async {
    await _apiClient.post(
      AuthEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  /// Reset password with OTP (from forgot password flow)
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.post(
      AuthEndpoints.resetPassword,
      data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
  }

  /// Delete account (requires password confirmation)
  Future<void> deleteAccount({required String password}) async {
    await _apiClient.delete(
      AuthEndpoints.deleteAccount,
      data: {'password': password},
    );
    // Clear local auth data and cache after successful deletion
    await _storage.clearAuthData();
    await _storage.clearCache();
  }
}
