import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

/// Model chứa feature flags từ server
class AppConfig {
  final bool requirePremiumForBooking;
  final bool requireApprovalForPartner;

  const AppConfig({
    required this.requirePremiumForBooking,
    required this.requireApprovalForPartner,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      requirePremiumForBooking: json['requirePremiumForBooking'] as bool? ?? true,
      requireApprovalForPartner: json['requireApprovalForPartner'] as bool? ?? false,
    );
  }

  /// Default config khi không fetch được từ server
  factory AppConfig.defaults() {
    return const AppConfig(
      requirePremiumForBooking: true,
      requireApprovalForPartner: false,
    );
  }
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
}
