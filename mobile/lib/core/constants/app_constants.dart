// App-wide constants

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Mate Social';
  static const String appVersion = '1.0.0';
  
  // Timing
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  /// Trạng thái "online" = user có hoạt động (tính từ lúc đăng nhập) trong N phút.
  /// Backend cần cập nhật lastActiveAt khi user đăng nhập và khi có hoạt động.
  static const int onlineThresholdMinutes = 15;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxCacheAge = 7; // days
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int otpLength = 6;
  static const int phoneLength = 10;
  
  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  
  // Partner
  static const int minBookingHours = 2;
  static const int maxBookingHours = 12;
  
  // Rating
  static const double maxRating = 5.0;
  static const int minReviewLength = 10;
}

// Service Types
enum ServiceType {
  walking('Đi dạo', 'walking'),
  movie('Xem phim', 'movie'),
  cafe('Cà phê', 'cafe'),
  dinner('Ăn tối', 'dinner'),
  party('Dự tiệc', 'party'),
  shopping('Mua sắm', 'shopping'),
  travel('Du lịch', 'travel'),
  event('Sự kiện', 'event'),
  gym('Tập gym', 'gym'),
  other('Khác', 'other');

  const ServiceType(this.label, this.value);
  final String label;
  final String value;
}
