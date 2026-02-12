import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'local_notification_service.dart';

/// Callback khi user nhấn vào thông báo (FCM hoặc local).
/// Nhận [data] từ payload; đợi app khởi động xong rồi navigate (delay trong callback).
typedef OnNotificationTapCallback = void Function(Map<String, dynamic> data);

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService =
      LocalNotificationService.instance;

  ApiClient? _apiClient;
  bool _isInitialized = false;
  String? _fcmToken;
  OnNotificationTapCallback? _onNotificationTapCallback;

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize push notification service.
  /// [onNotificationTapCallback]: gọi khi user nhấn thông báo (FCM hoặc local);
  /// trong callback nên delay 500ms rồi navigate để app/router sẵn sàng.
  Future<void> initialize({
    required ApiClient apiClient,
    OnNotificationTapCallback? onNotificationTapCallback,
  }) async {
    if (_isInitialized) return;

    _apiClient = apiClient;
    _onNotificationTapCallback = onNotificationTapCallback;

    try {
      await _requestPermission();

      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      await _setupMessageHandlers();

      _isInitialized = true;
      debugPrint('Push Notification Service initialized');
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  /// Gọi từ bên ngoài khi có tap thông báo (local notification hoặc launch từ notification).
  /// Dùng chung một callback với FCM để mọi đường đều đi qua onNotificationTapCallback.
  void handleNotificationTapFromPayload(Map<String, dynamic> data) {
    debugPrint('=== HANDLE NOTIFICATION TAP FROM PAYLOAD ===');
    debugPrint('Notification tap payload: $data');
    debugPrint('Callback is null: ${_onNotificationTapCallback == null}');
    _onNotificationTapCallback?.call(data);
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Setup message handlers for different app states
  Future<void> _setupMessageHandlers() async {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background/Terminated message tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check for initial message (app opened from terminated state via notification)
    // Must await to ensure pending deep link is saved BEFORE runApp/splash processes it
    await _checkInitialMessage();
  }

  /// Handle foreground messages (app đang mở).
  /// Hiển thị local notification; khi user nhấn, payload (actionType, actionId, ...)
  /// được xử lý bởi DeepLinkService → vào đúng trang (ví dụ chat: /chat/:conversationId).
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    final channel = _getNotificationChannel(message.data['type']);

    await _localNotificationService.showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'Thông báo mới',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
      channel: channel,
    );
  }

  /// Handle when user taps on notification (from background state)
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('=== NOTIFICATION TAP FROM BACKGROUND ===');
    debugPrint('Notification opened: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    _invokeTapCallback(Map<String, dynamic>.from(message.data));
  }

  /// Check if app was opened from a terminated state via FCM notification (giống vidu: gọi callback ngay, delay 500ms trong callback)
  Future<void> _checkInitialMessage() async {
    debugPrint('=== CHECKING INITIAL MESSAGE ===');
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('=== APP OPENED FROM TERMINATED STATE ===');
      debugPrint('App opened from terminated state via notification');
      debugPrint('Initial message data: ${initialMessage.data}');
      debugPrint(
        'Initial message notification: ${initialMessage.notification?.title} - ${initialMessage.notification?.body}',
      );
      _invokeTapCallback(Map<String, dynamic>.from(initialMessage.data));
    } else {
      debugPrint('No initial message (app not opened from notification)');
    }
  }

  /// FCM data có thể Map<String, String?>; chuẩn hóa sang Map<String, dynamic> rồi gọi callback
  void _invokeTapCallback(Map<String, dynamic> rawData) {
    debugPrint('=== INVOKING TAP CALLBACK ===');
    debugPrint('Invoking tap callback with data: $rawData');
    debugPrint('Callback is null: ${_onNotificationTapCallback == null}');
    final data = rawData.map((k, v) => MapEntry(k, v));
    _onNotificationTapCallback?.call(data);
  }

  /// Token refresh handler
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('FCM Token refreshed: $newToken');
    _fcmToken = newToken;

    // Re-register token with backend if user is logged in
    if (_apiClient != null) {
      await registerTokenWithBackend();
    }
  }

  /// Register FCM token with backend
  Future<bool> registerTokenWithBackend() async {
    if (_fcmToken == null || _apiClient == null) {
      return false;
    }

    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final deviceInfo =
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

      await _apiClient!.post(
        '/notifications/device-token',
        data: {
          'token': _fcmToken,
          'platform': platform,
          'deviceInfo': deviceInfo,
        },
      );

      debugPrint('FCM token registered with backend');
      return true;
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
      return false;
    }
  }

  /// Unregister FCM token from backend (call on logout)
  Future<bool> unregisterToken() async {
    if (_fcmToken == null || _apiClient == null) {
      return false;
    }

    try {
      await _apiClient!.delete(
        '/notifications/device-token',
        data: {'token': _fcmToken},
      );

      debugPrint('FCM token unregistered from backend');
      return true;
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
      return false;
    }
  }

  /// Get notification channel based on type
  NotificationChannel _getNotificationChannel(String? type) {
    switch (type?.toUpperCase()) {
      case 'BOOKING':
      case 'PAYMENT':
        return NotificationChannel.reminder;
      case 'CHAT':
        return NotificationChannel.message;
      case 'SAFETY':
      case 'REVIEW':
        return NotificationChannel.social;
      default:
        return NotificationChannel.defaultChannel;
    }
  }

  /// Subscribe to topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}

/// Top-level function for handling background messages
/// Must be a top-level function (not a method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handler
  await Firebase.initializeApp();

  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');

  // Note: We can store the notification data here for later processing
  // but UI-related operations should be avoided
}
