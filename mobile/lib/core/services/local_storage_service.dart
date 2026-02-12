import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Local Storage Service using SharedPreferences + FlutterSecureStorage
/// Sensitive data (tokens) stored in secure storage; other data in SharedPreferences
class LocalStorageService {
  LocalStorageService._();
  
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  /// In-memory cache for tokens (avoid async read on every request)
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedUserId;
  String? _cachedUserProfile;
  
  /// Get singleton instance
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }
  
  /// Initialize SharedPreferences and load cached tokens
  /// Must be called before using any storage methods
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Pre-load tokens into memory for synchronous access
    final inst = instance;
    inst._cachedAccessToken = await _secureStorage.read(key: StorageKeys.accessToken);
    inst._cachedRefreshToken = await _secureStorage.read(key: StorageKeys.refreshToken);
    inst._cachedUserId = await _secureStorage.read(key: StorageKeys.userId);
    inst._cachedUserProfile = await _secureStorage.read(key: StorageKeys.userProfile);
    // Migrate userProfile from SharedPreferences to secure storage (one-time)
    if (inst._cachedUserProfile == null && _prefs != null) {
      final oldProfile = _prefs!.getString(StorageKeys.userProfile);
      if (oldProfile != null) {
        await _secureStorage.write(key: StorageKeys.userProfile, value: oldProfile);
        await _prefs!.remove(StorageKeys.userProfile);
        inst._cachedUserProfile = oldProfile;
      }
    }
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
  
  // ==================== AUTH (Secure Storage) ====================
  
  /// Check if user is logged in
  bool get isLoggedIn {
    return prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }
  
  /// Set logged in status
  Future<bool> setLoggedIn(bool value) async {
    return await prefs.setBool(StorageKeys.isLoggedIn, value);
  }
  
  /// Get access token (synchronous from cache)
  String? get accessToken => _cachedAccessToken;
  
  /// Save access token (secure storage + cache)
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: StorageKeys.accessToken, value: token);
    _cachedAccessToken = token;
  }
  
  /// Get refresh token (synchronous from cache)
  String? get refreshToken => _cachedRefreshToken;
  
  /// Save refresh token (secure storage + cache)
  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: StorageKeys.refreshToken, value: token);
    _cachedRefreshToken = token;
  }
  
  /// Get user ID (synchronous from cache)
  String? get userId => _cachedUserId;
  
  /// Save user ID (secure storage + cache)
  Future<void> setUserId(String id) async {
    await _secureStorage.write(key: StorageKeys.userId, value: id);
    _cachedUserId = id;
  }
  
  // ==================== USER PROFILE (Secure Storage) ====================
  
  /// Get cached user profile JSON (synchronous from cache)
  String? get userProfileJson => _cachedUserProfile;
  
  /// Save user profile JSON (secure storage + cache) — PII stays encrypted
  Future<void> setUserProfileJson(String json) async {
    await _secureStorage.write(key: StorageKeys.userProfile, value: json);
    _cachedUserProfile = json;
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
    // Clear secure storage
    await _secureStorage.delete(key: StorageKeys.accessToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
    await _secureStorage.delete(key: StorageKeys.userId);
    await _secureStorage.delete(key: StorageKeys.userProfile);
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserId = null;
    _cachedUserProfile = null;
    // Clear SharedPreferences auth data
    await prefs.remove(StorageKeys.userRole);
    await prefs.remove(StorageKeys.userProfile); // Remove any leftover from migration
    await prefs.setBool(StorageKeys.isLoggedIn, false);
    debugPrint('🔐 Auth data cleared (secure + prefs)');
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    await prefs.remove(StorageKeys.cachedPartners);
    await prefs.remove(StorageKeys.cachedConversations);
    await prefs.remove(StorageKeys.lastSync);
  }
  
  /// Clear all data (for full reset)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserId = null;
    await prefs.clear();
  }
}
