import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Callback được gọi khi notification được tap trong background
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
    'Notification tapped in background: ${notificationResponse.payload}',
  );
}

/// Local Notification Service
/// Quản lý tất cả thông báo local cho ứng dụng
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService _instance =
      LocalNotificationService._();

  /// Singleton instance
  static LocalNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Stream controller để xử lý notification response
  static final ValueNotifier<NotificationResponse?> onNotificationTap =
      ValueNotifier(null);

  /// Callback khi tap notification có payload (giống vidu: gọi _handleNotificationTap trong cùng service).
  /// Nếu set thì khi tap sẽ parse payload và gọi callback thay vì chỉ set onNotificationTap.
  static void Function(Map<String, dynamic>)? payloadTapCallback;

  /// Kiểm tra xem service đã được khởi tạo chưa
  bool _isInitialized = false;

  /// Âm thanh thông báo tùy chỉnh (không có phần mở rộng file).
  /// - Android: Thêm file vào android/app/src/main/res/raw/ (vd: notification_sound.mp3)
  /// - iOS: Thêm file .caf vào ios/Runner/ và add vào Xcode project (vd: notification_sound.caf)
  /// Đặt null để dùng âm thanh mặc định của hệ thống.
  static const String? customNotificationSound = "notification_sound";

  /// Android notification sound (chỉ dùng khi customNotificationSound != null)
  static AndroidNotificationSound? get _androidNotificationSound =>
      customNotificationSound != null
      ? RawResourceAndroidNotificationSound(customNotificationSound!)
      : null;

  /// Android notification channel cho các loại thông báo khác nhau
  /// Dùng _v2 để tạo channel mới với custom sound (channel cũ có thể đã tạo với settings cũ không thay đổi được)
  static AndroidNotificationChannel get _defaultChannel =>
      AndroidNotificationChannel(
        'mate_social_default_v2',
        'Thông báo chung',
        description: 'Thông báo chung từ ứng dụng Mate Social',
        importance: Importance.high,
        playSound: true,
        sound: _androidNotificationSound,
        enableVibration: true,
        showBadge: true,
      );

  static AndroidNotificationChannel get _messageChannel =>
      AndroidNotificationChannel(
        'mate_social_messages_v2',
        'Tin nhắn',
        description: 'Thông báo tin nhắn mới',
        importance: Importance.max,
        playSound: true,
        sound: _androidNotificationSound,
        enableVibration: true,
        showBadge: true,
      );

  static AndroidNotificationChannel get _socialChannel =>
      AndroidNotificationChannel(
        'mate_social_social_v2',
        'Hoạt động xã hội',
        description: 'Thông báo về lượt thích, bình luận, theo dõi',
        importance: Importance.high,
        playSound: true,
        sound: _androidNotificationSound,
        enableVibration: true,
        showBadge: true,
      );

  static AndroidNotificationChannel get _reminderChannel =>
      AndroidNotificationChannel(
        'mate_social_reminders_v2',
        'Nhắc nhở',
        description: 'Thông báo nhắc nhở và lịch hẹn',
        importance: Importance.high,
        playSound: true,
        sound: _androidNotificationSound,
        enableVibration: true,
        showBadge: true,
      );

  static AndroidNotificationChannel get _bookingChannel =>
      AndroidNotificationChannel(
        'mate_social_bookings_v2',
        'Đặt lịch hẹn',
        description: 'Thông báo về đặt lịch và xác nhận hẹn',
        importance: Importance.max,
        playSound: true,
        sound: _androidNotificationSound,
        enableVibration: true,
        showBadge: true,
      );

  /// Khởi tạo notification service
  Future<void> init() async {
    if (_isInitialized) return;

    // Khởi tạo timezone
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      // Fallback nếu không tìm thấy timezone
      debugPrint('Timezone not found, using UTC: $e');
    }

    // Android initialization settings
    // Sử dụng ic_notification cho small icon trong status bar
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    // iOS initialization settings
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: true,
          notificationCategories: [
            DarwinNotificationCategory(
              'message_category',
              actions: [
                DarwinNotificationAction.plain(
                  'reply_action',
                  'Trả lời',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  'mark_read_action',
                  'Đánh dấu đã đọc',
                ),
              ],
              options: {
                DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
              },
            ),
            DarwinNotificationCategory(
              'social_category',
              actions: [
                DarwinNotificationAction.plain(
                  'view_action',
                  'Xem',
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        );

    // macOS initialization settings
    final DarwinInitializationSettings macOSSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Linux initialization settings
    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Combined initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
      linux: linuxSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Tạo notification channels cho Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
    debugPrint('LocalNotificationService initialized');
  }

  /// Tạo các notification channels cho Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_defaultChannel);
      await androidPlugin.createNotificationChannel(_messageChannel);
      await androidPlugin.createNotificationChannel(_socialChannel);
      await androidPlugin.createNotificationChannel(_reminderChannel);
      await androidPlugin.createNotificationChannel(_bookingChannel);
    }
  }

  /// Xử lý khi người dùng tap vào notification (giống vidu: parse payload và gọi callback)
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('=== LOCAL NOTIFICATION TAP ===');
    debugPrint('Notification tapped: ${response.payload}');
    debugPrint('payloadTapCallback is null: ${payloadTapCallback == null}');
    if (response.payload != null &&
        response.payload!.trim().isNotEmpty &&
        payloadTapCallback != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        debugPrint('Parsed payload data: $data');
        payloadTapCallback!(data);
      } catch (e) {
        debugPrint('Notification tap payload parse error: $e');
        onNotificationTap.value = response;
      }
    } else {
      debugPrint('No payload or callback, setting onNotificationTap.value');
      onNotificationTap.value = response;
    }
  }

  /// Yêu cầu quyền notification
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ cần yêu cầu quyền POST_NOTIFICATIONS
      final status = await Permission.notification.request();
      if (status.isGranted) {
        // Yêu cầu thêm quyền exact alarm cho scheduled notifications
        final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        return exactAlarmStatus.isGranted;
      }
      return false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
      return result ?? false;
    }
    return true;
  }

  /// Kiểm tra notification có được bật không
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final settings = await iosPlugin?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return true;
  }

  /// Lấy thông tin chi tiết về app launch từ notification
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    return await _notifications.getNotificationAppLaunchDetails();
  }

  /// Yêu cầu quyền exact alarm riêng (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Kiểm tra xem đã có quyền chưa
      final hasPermission = await androidPlugin.canScheduleExactNotifications();
      if (hasPermission == true) return true;

      // Yêu cầu quyền exact alarm
      final result = await androidPlugin.requestExactAlarmsPermission();
      return result ?? false;
    }
    return false;
  }

  /// Kiểm tra quyền exact alarm (Android 12+)
  Future<bool> canScheduleExactNotifications() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      return await androidPlugin.canScheduleExactNotifications() ?? false;
    }
    return false;
  }

  /// Kiểm tra quyền notification
  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      final settings = await iosPlugin?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return true;
  }

  /// Hiển thị notification ngay lập tức
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannel channel = NotificationChannel.defaultChannel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelForType(channel).id,
      _getChannelForType(channel).name,
      channelDescription: _getChannelForType(channel).description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      enableLights: true,
      ledColor: const Color(0xFF6366F1),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      playSound: true,
      sound: _androidNotificationSound,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Mate Social',
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Hiển thị notification với hình ảnh lớn
  Future<void> showBigPictureNotification({
    required int id,
    required String title,
    required String body,
    required String imageUrl,
    String? payload,
    NotificationChannel channel = NotificationChannel.defaultChannel,
  }) async {
    final BigPictureStyleInformation bigPictureStyleInformation =
        BigPictureStyleInformation(
          DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          contentTitle: title,
          summaryText: body,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );

    final androidDetails = AndroidNotificationDetails(
      _getChannelForType(channel).id,
      _getChannelForType(channel).name,
      channelDescription: _getChannelForType(channel).description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: _androidNotificationSound,
      styleInformation: bigPictureStyleInformation,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Lên lịch notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannel channel = NotificationChannel.defaultChannel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelForType(channel).id,
      _getChannelForType(channel).name,
      channelDescription: _getChannelForType(channel).description,
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      ledColor: const Color(0xFF6366F1),
      enableVibration: true,
      playSound: true,
      sound: _androidNotificationSound,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: null,
    );

    debugPrint('Scheduled notification $id for $scheduledDate');
  }

  /// Lên lịch notification theo chu kỳ
  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
    NotificationChannel channel = NotificationChannel.defaultChannel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelForType(channel).id,
      _getChannelForType(channel).name,
      channelDescription: _getChannelForType(channel).description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: _androidNotificationSound,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Lên lịch notification hàng ngày vào thời gian cố định
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
    NotificationChannel channel = NotificationChannel.defaultChannel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelForType(channel).id,
      _getChannelForType(channel).name,
      channelDescription: _getChannelForType(channel).description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: _androidNotificationSound,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Lên lịch notification hàng tuần vào ngày và thời gian cố định
  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required TimeOfDay time,
    String? payload,
    NotificationChannel channel = NotificationChannel.defaultChannel,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelForType(channel).id,
      _getChannelForType(channel).name,
      channelDescription: _getChannelForType(channel).description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: _androidNotificationSound,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(dayOfWeek, time),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Tính thời gian tiếp theo cho notification hàng ngày
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Tính thời gian tiếp theo cho notification hàng tuần
  tz.TZDateTime _nextInstanceOfWeekday(int dayOfWeek, TimeOfDay time) {
    var scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Hủy notification theo ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('Cancelled notification $id');
  }

  /// Hủy tất cả notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// Lấy danh sách pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Lấy danh sách active notifications (Android only)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      return await androidPlugin.getActiveNotifications();
    }
    return [];
  }

  /// Lấy notification channel tương ứng
  AndroidNotificationChannel _getChannelForType(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.message:
        return _messageChannel;
      case NotificationChannel.social:
        return _socialChannel;
      case NotificationChannel.reminder:
        return _reminderChannel;
      case NotificationChannel.booking:
        return _bookingChannel;
      case NotificationChannel.defaultChannel:
        return _defaultChannel;
    }
  }

  /// Hiển thị notification tin nhắn với action buttons
  Future<void> showMessageNotification({
    required int id,
    required String title,
    required String body,
    required String senderId,
    String? senderAvatar,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _messageChannel.id,
      _messageChannel.name,
      channelDescription: _messageChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      enableLights: true,
      ledColor: const Color(0xFF6366F1),
      enableVibration: true,
      playSound: true,
      sound: _androidNotificationSound,
      icon: '@drawable/ic_notification',
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Tin nhắn mới',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'reply_action',
          'Trả lời',
          showsUserInterface: true,
          inputs: [AndroidNotificationActionInput(label: 'Nhập tin nhắn...')],
        ),
        const AndroidNotificationAction(
          'mark_read_action',
          'Đánh dấu đã đọc',
          cancelNotification: true,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
      categoryIdentifier: 'message_category',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload ?? 'chat:$senderId',
    );
  }

  /// Hiển thị notification đặt lịch hẹn
  Future<void> showBookingNotification({
    required int id,
    required String title,
    required String body,
    required String bookingId,
    required String bookingStatus,
    String? payload,
  }) async {
    final List<AndroidNotificationAction> actions = [];

    if (bookingStatus == 'PENDING') {
      actions.addAll([
        const AndroidNotificationAction(
          'accept_action',
          'Chấp nhận',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'decline_action',
          'Từ chối',
          showsUserInterface: true,
        ),
      ]);
    } else {
      actions.add(
        const AndroidNotificationAction(
          'view_action',
          'Xem chi tiết',
          showsUserInterface: true,
        ),
      );
    }

    final androidDetails = AndroidNotificationDetails(
      _bookingChannel.id,
      _bookingChannel.name,
      channelDescription: _bookingChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      enableLights: true,
      ledColor: const Color(0xFF10B981),
      enableVibration: true,
      playSound: true,
      sound: _androidNotificationSound,
      icon: '@drawable/ic_notification',
      category: AndroidNotificationCategory.event,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Lịch hẹn',
      ),
      actions: actions,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload ?? 'booking:$bookingId',
    );
  }

  /// Hiển thị notification hoạt động xã hội (like, comment, follow)
  Future<void> showSocialNotification({
    required int id,
    required String title,
    required String body,
    required String actionType, // 'like', 'comment', 'follow', 'match'
    String? targetId,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _socialChannel.id,
      _socialChannel.name,
      channelDescription: _socialChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      enableLights: true,
      ledColor: const Color(0xFFF59E0B),
      enableVibration: true,
      playSound: true,
      sound: _androidNotificationSound,
      icon: '@drawable/ic_notification',
      category: AndroidNotificationCategory.social,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Mate Social',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_action',
          'Xem',
          showsUserInterface: true,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: customNotificationSound != null
          ? '$customNotificationSound.caf'
          : null,
      categoryIdentifier: 'social_category',
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload ?? '$actionType:$targetId',
    );
  }

  /// Cập nhật badge count (iOS only)
  Future<void> setBadgeCount(int count) async {
    if (Platform.isIOS) {
      // Sử dụng notification để cập nhật badge
      final iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentSound: false,
        badgeNumber: count,
      );

      await _notifications.show(
        -1,
        null,
        null,
        NotificationDetails(iOS: iosDetails),
      );

      // Then cancel it
      await _notifications.cancel(-1);
    }
  }

  /// Xóa badge count
  Future<void> clearBadgeCount() async {
    await setBadgeCount(0);
  }
}

/// Các loại notification channel
enum NotificationChannel { defaultChannel, message, social, reminder, booking }

/// Các notification ID constants
class NotificationIds {
  NotificationIds._();

  // Tin nhắn: 1000-1999
  static const int messageBase = 1000;

  // Hoạt động xã hội: 2000-2999
  static const int socialBase = 2000;
  static const int newLike = 2001;
  static const int newComment = 2002;
  static const int newFollow = 2003;
  static const int newMatch = 2004;

  // Nhắc nhở: 3000-3999
  static const int reminderBase = 3000;
  static const int dailyReminder = 3001;
  static const int weeklyReminder = 3002;

  // Hệ thống: 4000-4999
  static const int systemBase = 4000;
  static const int appUpdate = 4001;
  static const int maintenance = 4002;

  // Đặt lịch: 5000-5999
  static const int bookingBase = 5000;
  static const int newBookingRequest = 5001;
  static const int bookingAccepted = 5002;
  static const int bookingDeclined = 5003;
  static const int bookingReminder = 5004;
  static const int bookingCancelled = 5005;
  static const int bookingCompleted = 5006;

  // Payment: 6000-6999
  static const int paymentBase = 6000;
  static const int paymentReceived = 6001;
  static const int paymentFailed = 6002;
}
