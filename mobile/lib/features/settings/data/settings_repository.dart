import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'models/user_settings_model.dart';

/// Settings Repository handles settings-related API calls
class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get current user settings
  Future<UserSettingsModel> getSettings() async {
    final response = await _apiClient.get(UserEndpoints.settings);
    final responseData = response.data as Map<String, dynamic>;
    
    // API returns settings object directly or wrapped in data
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    
    debugPrint('Settings API response: $data');
    return UserSettingsModel.fromJson(data);
  }

  /// Update user settings
  Future<UserSettingsModel> updateSettings({
    bool? pushNotificationsEnabled,
    bool? messageNotificationsEnabled,
    bool? soundEnabled,
    bool? darkModeEnabled,
    bool? useSystemTheme,
    String? language,
    bool? locationEnabled,
    bool? showOnlineStatus,
    String? allowMessagesFrom,
  }) async {
    final data = <String, dynamic>{};
    
    if (pushNotificationsEnabled != null) {
      data['pushNotificationsEnabled'] = pushNotificationsEnabled;
    }
    if (messageNotificationsEnabled != null) {
      data['messageNotificationsEnabled'] = messageNotificationsEnabled;
    }
    if (soundEnabled != null) {
      data['soundEnabled'] = soundEnabled;
    }
    if (darkModeEnabled != null) {
      data['darkModeEnabled'] = darkModeEnabled;
    }
    if (useSystemTheme != null) {
      data['useSystemTheme'] = useSystemTheme;
    }
    if (language != null) {
      data['language'] = language;
    }
    if (locationEnabled != null) {
      data['locationEnabled'] = locationEnabled;
    }
    if (showOnlineStatus != null) {
      data['showOnlineStatus'] = showOnlineStatus;
    }
    if (allowMessagesFrom != null) {
      data['allowMessagesFrom'] = allowMessagesFrom;
    }

    final response = await _apiClient.put(
      UserEndpoints.settings,
      data: data,
    );
    
    final responseData = response.data as Map<String, dynamic>;
    final resultData = responseData['data'] as Map<String, dynamic>? ?? responseData;
    
    debugPrint('Update settings response: $resultData');
    return UserSettingsModel.fromJson(resultData);
  }
}
