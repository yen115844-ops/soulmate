import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Local Storage Service using SharedPreferences
/// Handles all local data persistence operations
class LocalStorageService {
  LocalStorageService._();
  
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;
  
  /// Get singleton instance
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }
  
  /// Initialize SharedPreferences
  /// Must be called before using any storage methods
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }
  
  // ==================== ONBOARDING ====================
  
  /// Check if onboarding has been completed
  bool get isOnboardingComplete {
    return prefs.getBool(StorageKeys.isOnboardingComplete) ?? false;
  }
  
  /// Mark onboarding as complete
  Future<bool> setOnboardingComplete() async {
    return await prefs.setBool(StorageKeys.isOnboardingComplete, true);
  }
  
  /// Check if this is first launch
  bool get isFirstLaunch {
    return prefs.getBool(StorageKeys.isFirstLaunch) ?? true;
  }
  
  /// Mark first launch as complete
  Future<bool> setFirstLaunchComplete() async {
    return await prefs.setBool(StorageKeys.isFirstLaunch, false);
  }
  
  // ==================== AUTH ====================
  
  /// Check if user is logged in
  bool get isLoggedIn {
    return prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }
  
  /// Set logged in status
  Future<bool> setLoggedIn(bool value) async {
    return await prefs.setBool(StorageKeys.isLoggedIn, value);
  }
  
  /// Get access token
  String? get accessToken {
    return prefs.getString(StorageKeys.accessToken);
  }
  
  /// Save access token
  Future<bool> setAccessToken(String token) async {
    return await prefs.setString(StorageKeys.accessToken, token);
  }
  
  /// Get refresh token
  String? get refreshToken {
    return prefs.getString(StorageKeys.refreshToken);
  }
  
  /// Save refresh token
  Future<bool> setRefreshToken(String token) async {
    return await prefs.setString(StorageKeys.refreshToken, token);
  }
  
  /// Get user ID
  String? get userId {
    return prefs.getString(StorageKeys.userId);
  }
  
  /// Save user ID
  Future<bool> setUserId(String id) async {
    return await prefs.setString(StorageKeys.userId, id);
  }
  
  // ==================== SETTINGS ====================
  
  /// Get theme mode
  String get themeMode {
    return prefs.getString(StorageKeys.theme) ?? 'light';
  }
  
  /// Set theme mode
  Future<bool> setThemeMode(String mode) async {
    return await prefs.setString(StorageKeys.theme, mode);
  }
  
  /// Get language
  String get language {
    return prefs.getString(StorageKeys.language) ?? 'vi';
  }
  
  /// Set language
  Future<bool> setLanguage(String lang) async {
    return await prefs.setString(StorageKeys.language, lang);
  }
  
  /// Check if notifications are enabled
  bool get notificationsEnabled {
    return prefs.getBool(StorageKeys.notificationsEnabled) ?? true;
  }
  
  /// Set notifications enabled
  Future<bool> setNotificationsEnabled(bool value) async {
    return await prefs.setBool(StorageKeys.notificationsEnabled, value);
  }
  
  // ==================== CLEAR DATA ====================
  
  /// Clear all auth data (for logout)
  Future<void> clearAuthData() async {
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.refreshToken);
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.userRole);
    await prefs.remove(StorageKeys.userProfile);
    await prefs.setBool(StorageKeys.isLoggedIn, false);
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    await prefs.remove(StorageKeys.cachedPartners);
    await prefs.remove(StorageKeys.cachedConversations);
    await prefs.remove(StorageKeys.lastSync);
  }
  
  /// Clear all data (for full reset)
  Future<void> clearAll() async {
    await prefs.clear();
  }
}
