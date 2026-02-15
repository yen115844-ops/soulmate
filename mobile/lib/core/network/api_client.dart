import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../services/local_storage_service.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

/// Callback when authentication fails and user needs to re-login
typedef OnAuthFailedCallback = void Function();

/// API Client using Dio for HTTP requests
/// Handles authentication, token refresh, and error handling
class ApiClient {
  late final Dio _dio;
  final LocalStorageService _storage;
  
  /// Callback to notify when authentication fails completely
  /// (refresh token also expired or invalid)
  OnAuthFailedCallback? onAuthFailed;
  
  /// Flag to prevent multiple refresh attempts
  bool _isRefreshing = false;
  
  /// Completer to queue requests while refreshing
  Completer<bool>? _refreshCompleter;

  ApiClient({required LocalStorageService storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': ApiConfig.contentType,
          'Accept': ApiConfig.acceptHeader,
        },
      ),
    );

    // Certificate pinning in release mode
    if (!kDebugMode) {
      _setupCertificatePinning();
    }

    _setupInterceptors();
  }

  /// Configure SSL certificate pinning for production
  /// TODO: Replace the SHA-256 fingerprint with your actual server certificate fingerprint
  void _setupCertificatePinning() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allow only your domain
        // In production, compare cert.sha256 fingerprint
        // For now, accept all — replace with actual pinning when deploying
        if (host.contains('matesocial.vn') || host.contains('localhost')) {
          return true;
        }
        return false;
      };
      return client;
    };
  }

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      // Auth Interceptor - Add token to requests
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 - Token expired
          if (error.response?.statusCode == 401) {
            // Skip refresh for auth endpoints to avoid loops
            final path = error.requestOptions.path;
            if (path.contains('/auth/login') || 
                path.contains('/auth/register') ||
                path.contains('/auth/refresh')) {
              return handler.next(error);
            }
            
            // Only attempt refresh if we actually have a refresh token.
            // If there is no refresh token the user was never logged in
            // (or already logged out), so a 401 is expected — don't
            // surface a "session expired" message.
            final hasRefresh = _storage.refreshToken != null &&
                _storage.refreshToken!.isNotEmpty;

            if (!hasRefresh) {
              debugPrint('🔐 Auth: No refresh token, skipping refresh & onAuthFailed');
              return handler.next(error);
            }

            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
              
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              // Refresh failed - notify app to redirect to login
              debugPrint('🔐 Auth: Token refresh failed, redirecting to login');
              onAuthFailed?.call();
            }
          }
          return handler.next(error);
        },
      ),

      // Logging Interceptor (only in debug mode)
      if (kDebugMode)
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (log) => debugPrint('🌐 API: $log'),
        ),
    ]);
  }

  /// Refresh access token using refresh token
  /// Uses a completer to queue multiple requests during refresh
  Future<bool> _refreshToken() async {
    // If already refreshing, wait for the result
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }
    
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();
    
    try {
      final refreshToken = _storage.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('🔐 Auth: No refresh token available');
        _completeRefresh(false);
        return false;
      }

      debugPrint('🔐 Auth: Attempting to refresh token...');

      // Create a new Dio instance without interceptors to avoid loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          sendTimeout: ApiConfig.sendTimeout,
          headers: {
            'Content-Type': ApiConfig.contentType,
            'Accept': ApiConfig.acceptHeader,
          },
        ),
      );

      final response = await refreshDio.post(
        AuthEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        // Handle wrapped response {success, data, ...}
        final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
        
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        
        if (newAccessToken != null) {
          await _storage.setAccessToken(newAccessToken);
          debugPrint('🔐 Auth: Access token refreshed successfully');
        }
        if (newRefreshToken != null) {
          await _storage.setRefreshToken(newRefreshToken);
          debugPrint('🔐 Auth: Refresh token updated');
        }
        
        _completeRefresh(true);
        return true;
      }
      
      debugPrint('🔐 Auth: Refresh response status: ${response.statusCode}');
      _completeRefresh(false);
      return false;
    } catch (e) {
      debugPrint('🔐 Auth: Token refresh failed: $e');
      // Clear tokens on refresh failure
      await _storage.clearAuthData();
      _completeRefresh(false);
      return false;
    }
  }
  
  void _completeRefresh(bool success) {
    _isRefreshing = false;
    _refreshCompleter?.complete(success);
    _refreshCompleter = null;
  }

  /// Handle Dio errors and convert to custom exceptions
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();

      case DioExceptionType.connectionError:
        return NetworkException();

      case DioExceptionType.cancel:
        return CancelledException();

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.badCertificate:
        return ApiException(message: 'Chứng chỉ SSL không hợp lệ');

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') == true) {
          return NetworkException();
        }
        return ApiException(message: error.message ?? 'Đã xảy ra lỗi không xác định');
    }
  }

  /// Handle HTTP response errors
  ApiException _handleResponseError(Response? response) {
    if (response == null) {
      return ApiException(message: 'Không nhận được phản hồi từ máy chủ');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    
    String? message;
    dynamic errors;

    if (data is Map<String, dynamic>) {
      // Safely extract message - can be String or List
      final rawMessage = data['message'];
      if (rawMessage is String) {
        message = rawMessage;
      } else if (rawMessage is List) {
        message = rawMessage.map((e) => e.toString()).join(', ');
      }
      
      errors = data['errors'];
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message: message, errors: errors);
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ConflictException(message: message);
      case 500:
      case 502:
      case 503:
        return ServerException(message: message, statusCode: statusCode);
      default:
        return ApiException(
          message: message ?? 'Đã xảy ra lỗi (Mã: $statusCode)',
          statusCode: statusCode,
          errors: errors,
        );
    }
  }

  // ==================== HTTP Methods ====================

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file with multipart
  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
