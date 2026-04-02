import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

/// Model chứa feature flags và config từ server
class AppConfig {
  // ── General ──
  final String appName;
  final String supportEmail;
  final String supportPhone;
  final String supportUrl;
  final String supportHotline;
  final String defaultCurrency;
  final String defaultLanguage;

  // ── Booking ──
  final int minBookingHours;
  final int maxBookingHours;
  final int advanceBookingDays;
  final int cancellationHours;
  final int serviceFeePercent;
  final double platformFeeRate;
  final bool allowInstantBooking;
  final bool requirePremiumForBooking;
  final bool requirePremiumForChat;

  // ── Security ──
  final bool requireApprovalForPartner;
  final bool requireKycForPartner;
  final int maxEmergencyContacts;

  const AppConfig({
    this.appName = 'Mate Social',
    this.supportEmail = '',
    this.supportPhone = '',
    this.supportUrl = '',
    this.supportHotline = '',
    this.defaultCurrency = 'VND',
    this.defaultLanguage = 'vi',
    this.minBookingHours = 1,
    this.maxBookingHours = 8,
    this.advanceBookingDays = 30,
    this.cancellationHours = 24,
    this.serviceFeePercent = 15,
    this.platformFeeRate = 0.15,
    this.allowInstantBooking = true,
    this.requirePremiumForBooking = true,
    this.requirePremiumForChat = true,
    this.requireApprovalForPartner = false,
    this.requireKycForPartner = true,
    this.maxEmergencyContacts = 5,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      // General
      appName: json['appName'] as String? ?? 'Mate Social',
      supportEmail: json['supportEmail'] as String? ?? '',
      supportPhone: json['supportPhone'] as String? ?? '',
      supportUrl: json['supportUrl'] as String? ?? '',
      supportHotline: json['supportHotline'] as String? ?? '',
      defaultCurrency: json['defaultCurrency'] as String? ?? 'VND',
      defaultLanguage: json['defaultLanguage'] as String? ?? 'vi',
      // Booking
      minBookingHours: (json['minBookingHours'] as num?)?.toInt() ?? 1,
      maxBookingHours: (json['maxBookingHours'] as num?)?.toInt() ?? 8,
      advanceBookingDays: (json['advanceBookingDays'] as num?)?.toInt() ?? 30,
      cancellationHours: (json['cancellationHours'] as num?)?.toInt() ?? 24,
      serviceFeePercent: (json['serviceFeePercent'] as num?)?.toInt() ?? 15,
      platformFeeRate: (json['platformFeeRate'] as num?)?.toDouble() ?? 0.15,
      allowInstantBooking: json['allowInstantBooking'] as bool? ?? true,
      requirePremiumForBooking: json['requirePremiumForBooking'] as bool? ?? true,
      requirePremiumForChat: json['requirePremiumForChat'] as bool? ?? true,
      // Security
      requireApprovalForPartner: json['requireApprovalForPartner'] as bool? ?? false,
      requireKycForPartner: json['requireKycForPartner'] as bool? ?? true,
      maxEmergencyContacts: (json['maxEmergencyContacts'] as num?)?.toInt() ?? 5,
    );
  }

  /// Default config khi không fetch được từ server
  factory AppConfig.defaults() => const AppConfig();
}

/// Repository để fetch app config (feature flags) từ server
class AppConfigRepository {
  final ApiClient _apiClient;

  /// Cached config để tránh gọi API nhiều lần
  AppConfig? _cached;
  DateTime? _cachedAt;
  static const _cacheDuration = Duration(minutes: 5);

  AppConfigRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch app config, có cache 5 phút
  Future<AppConfig> getConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null && _cachedAt != null) {
      if (DateTime.now().difference(_cachedAt!) < _cacheDuration) {
        return _cached!;
      }
    }

    try {
      final response = await _apiClient.get(ApiConfig.publicAppConfig);
      final data = response.data as Map<String, dynamic>;
      // API có thể wrap trong "data" hoặc trả trực tiếp
      final configData = data['data'] as Map<String, dynamic>? ?? data;
      _cached = AppConfig.fromJson(configData);
      _cachedAt = DateTime.now();
      return _cached!;
    } catch (e) {
      debugPrint('Failed to fetch app config: $e');
      // Trả về cached nếu có, hoặc default
      return _cached ?? AppConfig.defaults();
    }
  }

  /// Kiểm tra nhanh có yêu cầu premium cho booking không
  Future<bool> requirePremiumForBooking() async {
    final config = await getConfig();
    return config.requirePremiumForBooking;
  }

  /// Kiểm tra nhanh có yêu cầu premium cho chat không
  Future<bool> requirePremiumForChat() async {
    final config = await getConfig();
    return config.requirePremiumForChat;
  }
}
