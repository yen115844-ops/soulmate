// Local Storage Keys

class StorageKeys {
  StorageKeys._();

  // Auth
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  
  // User
  static const String userProfile = 'user_profile';
  static const String isLoggedIn = 'is_logged_in';
  static const String isFirstLaunch = 'is_first_launch';
  static const String isOnboardingComplete = 'is_onboarding_complete';
  
  // Settings
  static const String theme = 'theme_mode';
  static const String language = 'language';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String locationEnabled = 'location_enabled';
  
  // Cache
  static const String cachedPartners = 'cached_partners';
  static const String cachedConversations = 'cached_conversations';
  static const String lastSync = 'last_sync';
}
