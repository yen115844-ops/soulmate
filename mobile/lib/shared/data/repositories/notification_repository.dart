import '../../../core/network/api_client.dart';
import '../../../core/network/base_repository.dart';
import '../models/notification_models.dart';

class NotificationRepository with BaseRepositoryMixin {
  final ApiClient _apiClient;

  NotificationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;


  /// Get notifications with pagination
  Future<NotificationsResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    NotificationType? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (isRead != null) {
      queryParams['isRead'] = isRead;
    }

    if (type != null) {
      queryParams['type'] = type.value;
    }

    final response = await _apiClient.get(
      '/notifications',
      queryParameters: queryParams,
    );

    // API returns {success, data: {data: [], meta: {}}}
    // Need to extract inner data object
    final responseData = response.data as Map<String, dynamic>;
    final innerData = responseData['data'] as Map<String, dynamic>;
    return NotificationsResponse.fromJson(innerData);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] ?? responseData;
    if (data is Map<String, dynamic>) {
      return data['unreadCount'] ?? 0;
    }
    return responseData['unreadCount'] ?? 0;
  }

  /// Mark single notification as read
  Future<bool> markAsRead(String notificationId) async {
    final response = await _apiClient.post(
      '/notifications/mark-read/$notificationId',
    );
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] ?? responseData;
    if (data is Map<String, dynamic>) {
      return data['success'] ?? responseData['success'] ?? false;
    }
    return responseData['success'] ?? false;
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead({List<String>? ids}) async {
    final response = await _apiClient.post(
      '/notifications/mark-all-read',
      data: ids != null ? {'ids': ids} : null,
    );
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] ?? responseData;
    if (data is Map<String, dynamic>) {
      return data['updatedCount'] ?? 0;
    }
    return 0;
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    final response = await _apiClient.delete(
      '/notifications/$notificationId',
    );
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] ?? responseData;
    if (data is Map<String, dynamic>) {
      return data['success'] ?? responseData['success'] ?? false;
    }
    return responseData['success'] ?? false;
  }

  /// Delete all read notifications
  Future<int> deleteAllRead() async {
    final response = await _apiClient.delete('/notifications/read/all');
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] ?? responseData;
    if (data is Map<String, dynamic>) {
      return data['deletedCount'] ?? 0;
    }
    return 0;
  }

  // ==================== Device Token APIs ====================

  /// Register FCM device token with backend
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceInfo,
  }) async {
    try {
      final response = await _apiClient.post(
        '/notifications/device-token',
        data: {
          'token': token,
          'platform': platform,
          if (deviceInfo != null) 'deviceInfo': deviceInfo,
        },
      );
      final responseData = response.data as Map<String, dynamic>;
      return responseData['success'] ?? 
             (responseData['data'] as Map<String, dynamic>?)?['success'] ?? 
             false;
    } catch (e) {
      return false;
    }
  }

  /// Unregister FCM device token from backend
  Future<bool> unregisterDeviceToken(String token) async {
    try {
      final response = await _apiClient.delete(
        '/notifications/device-token',
        data: {'token': token},
      );
      final responseData = response.data as Map<String, dynamic>;
      return responseData['success'] ?? 
             (responseData['data'] as Map<String, dynamic>?)?['success'] ?? 
             false;
    } catch (e) {
      return false;
    }
  }

  /// Unregister all device tokens (logout from all devices)
  Future<bool> unregisterAllDeviceTokens() async {
    try {
      final response = await _apiClient.delete('/notifications/device-tokens/all');
      final responseData = response.data as Map<String, dynamic>;
      return responseData['success'] ?? 
             (responseData['data'] as Map<String, dynamic>?)?['success'] ?? 
             false;
    } catch (e) {
      return false;
    }
  }
}
