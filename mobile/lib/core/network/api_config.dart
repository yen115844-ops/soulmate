/// API Configuration for the Mate Social backend
///
/// Use `--dart-define=API_BASE_URL=...` to override the base URL:
///   flutter run --dart-define=API_BASE_URL=http://localhost:3222/api
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3222/api  (Android emulator)
class ApiConfig {
  ApiConfig._();

  /// Base URL — configured via `--dart-define=API_BASE_URL=...`.
  /// In debug mode, falls back to localhost; in release mode, uses production URL.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defaultDebugUrl = 'https://gomate-backend.trancongtien.io.vn/api'; // For development, use localhost or
  static const String _defaultReleaseUrl = 'https://gomate-backend.trancongtien.io.vn/api'; // TODO: Replace with real production URL

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    // Use assert to catch missing base URL in release builds during development
    assert(() {
      return true; // In debug mode, use localhost fallback
    }());
    return const bool.fromEnvironment('dart.vm.product')
        ? _defaultReleaseUrl
        : _defaultDebugUrl;
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentType = 'application/json';
  static const String acceptHeader = 'application/json';

  // API Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String partners = '/partners';
  static const String bookings = '/bookings';
  static const String chat = '/chat';
  static const String reviews = '/reviews';
  static const String wallet = '/wallet';
  static const String notifications = '/notifications';
  static const String safety = '/safety';
}

/// Auth Endpoints
class AuthEndpoints {
  AuthEndpoints._();

  static const String register = '${ApiConfig.auth}/register';
  static const String login = '${ApiConfig.auth}/login';
  static const String refresh = '${ApiConfig.auth}/refresh';
  static const String logout = '${ApiConfig.auth}/logout';
  static const String logoutAll = '${ApiConfig.auth}/logout-all';
  static const String me = '${ApiConfig.auth}/me';
  static const String changePassword = '${ApiConfig.auth}/change-password';
  static const String verifyOtp = '${ApiConfig.auth}/verify-otp';
  static const String resendOtp = '${ApiConfig.auth}/resend-otp';
  static const String forgotPassword = '${ApiConfig.auth}/forgot-password';
  static const String resetPassword = '${ApiConfig.auth}/reset-password';
  static const String deleteAccount = '${ApiConfig.auth}/delete-account';
}

/// User Endpoints
class UserEndpoints {
  UserEndpoints._();

  static const String profile = '${ApiConfig.users}/profile';
  static const String profileStats = '${ApiConfig.users}/profile/stats';
  static const String location = '${ApiConfig.users}/location';
  static const String favorites = '${ApiConfig.users}/favorites';
  static const String settings = '${ApiConfig.users}/settings';
  static const String kyc = '${ApiConfig.users}/kyc';
  static const String emergencyContacts =
      '${ApiConfig.users}/emergency-contacts';
}

/// Review Endpoints
class ReviewEndpoints {
  ReviewEndpoints._();

  static const String base = ApiConfig.reviews;
  static const String given = '${ApiConfig.reviews}/given';
  static const String received = '${ApiConfig.reviews}/received';
  static const String stats = '${ApiConfig.reviews}/stats';
  static String detail(String id) => '${ApiConfig.reviews}/$id';
  static String respond(String id) => '${ApiConfig.reviews}/$id/response';
}

/// Partner Endpoints
class PartnerEndpoints {
  PartnerEndpoints._();

  static const String base = ApiConfig.partners;
  static const String search = '${ApiConfig.partners}/search';
  static const String register = '${ApiConfig.partners}/register';
  static const String presence = '${ApiConfig.partners}/me/presence';
  static String detail(String id) => '${ApiConfig.partners}/$id';
  static String availability(String id) =>
      '${ApiConfig.partners}/$id/availability';
}

/// Booking Endpoints
class BookingEndpoints {
  BookingEndpoints._();

  static const String base = ApiConfig.bookings;
  static String detail(String id) => '${ApiConfig.bookings}/$id';
  static String confirm(String id) => '${ApiConfig.bookings}/$id/confirm';
  static String start(String id) => '${ApiConfig.bookings}/$id/start';
  static String complete(String id) => '${ApiConfig.bookings}/$id/complete';
  static String cancel(String id) => '${ApiConfig.bookings}/$id/cancel';
}
