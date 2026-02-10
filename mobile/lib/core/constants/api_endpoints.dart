// API Endpoints Configuration

class ApiEndpoints {
  ApiEndpoints._();

  // Base URLs
  static const String baseUrl = 'https://api.matesocial.vn';
  static const String devBaseUrl = 'http://localhost:3000';
  
  // API Version
  static const String apiVersion = '/api/v1';
  
  // Auth
  static const String login = '$apiVersion/auth/login';
  static const String register = '$apiVersion/auth/register';
  static const String logout = '$apiVersion/auth/logout';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String sendOtp = '$apiVersion/auth/otp/send';
  static const String verifyOtp = '$apiVersion/auth/otp/verify';
  static const String forgotPassword = '$apiVersion/auth/forgot-password';
  static const String resetPassword = '$apiVersion/auth/reset-password';
  
  // User
  static const String userProfile = '$apiVersion/users/me';
  static const String updateProfile = '$apiVersion/users/me';
  static const String uploadAvatar = '$apiVersion/users/me/avatar';
  
  // Partners
  static const String partners = '$apiVersion/partners';
  static const String partnerDetail = '$apiVersion/partners/:id';
  static const String partnerSearch = '$apiVersion/partners/search';
  static const String partnerAvailability = '$apiVersion/partners/:id/availability';
  
  // Bookings
  static const String bookings = '$apiVersion/bookings';
  static const String bookingDetail = '$apiVersion/bookings/:id';
  static const String cancelBooking = '$apiVersion/bookings/:id/cancel';
  static const String confirmBooking = '$apiVersion/bookings/:id/confirm';
  
  // Chat
  static const String conversations = '$apiVersion/conversations';
  static const String messages = '$apiVersion/conversations/:id/messages';
  
  // Wallet
  static const String wallet = '$apiVersion/wallet';
  static const String deposit = '$apiVersion/wallet/deposit';
  static const String withdraw = '$apiVersion/wallet/withdraw';
  static const String transactions = '$apiVersion/wallet/transactions';
  
  // Reviews
  static const String reviews = '$apiVersion/reviews';
  static const String partnerReviews = '$apiVersion/partners/:id/reviews';
  
  // KYC
  static const String kycSubmit = '$apiVersion/kyc/submit';
  static const String kycStatus = '$apiVersion/kyc/status';
  
  // Safety
  static const String sos = '$apiVersion/sos';
  static const String emergencyContacts = '$apiVersion/emergency-contacts';
  
  // Notifications
  static const String notifications = '$apiVersion/notifications';
  static const String markNotificationRead = '$apiVersion/notifications/:id/read';
  
  // Upload
  static const String uploadImage = '$apiVersion/upload/image';
  static const String uploadVideo = '$apiVersion/upload/video';
}
