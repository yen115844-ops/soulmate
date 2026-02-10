// Route Names - Define all route paths
class RouteNames {
  RouteNames._();

  // Root
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';

  // Main Navigation
  static const String main = '/main';
  static const String home = '/home';
  static const String search = '/search';
  static const String bookings = '/bookings';
  static const String chat = '/chat';
  static const String profile = '/profile';

  // Partner
  static const String partnerDetail = '/partner/:id';
  static const String partnerReviews = '/partner/:id/reviews';
  static const String partnerAvailability = '/partner/:id/availability';

  // Booking
  static const String createBooking = '/booking/create';
  static const String bookingDetail = '/booking/:id';
  static const String bookingConfirmation = '/booking/confirmation';
  static const String bookingPayment = '/booking/:id/payment';
  static const String writeReview = '/booking/:id/review';

  // Chat
  static const String chatRoom = '/chat/:id';
  static const String chatNew = '/chat/new';
  static const String chatWithUser = '/chat/user/:userId';

  // Profile
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String blockedUsers = '/blocked-users';
  static const String wallet = '/wallet';
  static const String walletTopUp = '/wallet/top-up';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String transactions = '/wallet/transactions';
  static const String kyc = '/kyc';
  static const String emergencyContacts = '/emergency-contacts';
  static const String favorites = '/favorites';
  static const String myReviews = '/my-reviews';
  static const String changePassword = '/change-password';
  static const String helpCenter = '/help-center';
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';

  // Partner Mode
  static const String becomePartner = '/become-partner';
  static const String partnerDashboard = '/partner/dashboard';
  static const String partnerBookings = '/partner/bookings';
  static const String partnerEarnings = '/partner/earnings';
  static const String partnerAvailabilitySettings = '/partner/availability';
  static const String partnerProfile = '/partner/profile';
  static const String partnerBankAccount = '/partner/bank-account';
  static const String partnerPhotoManager = '/partner/photos';

  // Notifications
  static const String notifications = '/notifications';

  // Safety
  static const String sos = '/sos';
}
