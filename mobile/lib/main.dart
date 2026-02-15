import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/network/api_client.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/location_service.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

/// Top-level function for handling background messages
/// Must be a top-level function (not a method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

/// Main entry point of the application
void main() {
  runZonedGuarded<Future<void>>(
    () async {
      // Ensure Flutter bindings are initialized
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Crashlytics
      if (!kDebugMode) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Initialize date formatting for Vietnamese locale
      await initializeDateFormatting('vi_VN', null);

      // Initialize local storage
      await LocalStorageService.init();

      // Initialize connectivity monitoring
      await ConnectivityService.instance.init();

      // Setup dependency injection
      await setupDependencies();

      // Initialize local notifications
      await LocalNotificationService.instance.init();

      // Request notification permission
      await LocalNotificationService.instance.requestPermission();

      // Khởi tạo Push Notification Service trước runApp (giống vidu) để getInitialMessage và callback sẵn sàng khi mở app từ thông báo
      final pushService = getIt<PushNotificationService>();
      await pushService.initialize(
        apiClient: getIt<ApiClient>(),
        onNotificationTapCallback: (Map<String, dynamic> data) {
          debugPrint('=== MAIN.DART NOTIFICATION CALLBACK ===');
          debugPrint('Notification tapped with data: $data');
          // DeepLinkService tự quyết định navigate ngay hay lưu pending
          // dựa vào isAppReady flag
          DeepLinkService().handleNotificationNavigation(data);
        },
      );
      debugPrint('=== PUSH SERVICE INITIALIZED ===');
      LocalNotificationService.payloadTapCallback = (data) {
        debugPrint('=== LOCAL NOTIFICATION PAYLOAD CALLBACK ===');
        debugPrint('Local notification payload: $data');
        pushService.handleNotificationTapFromPayload(data);
      };

      // Khi mở app bằng cách nhấn vào thông báo local (app đã đóng) – giống vidu xử lý tap trong một luồng
      final launchDetails = await LocalNotificationService.instance
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse?.payload != null &&
          launchDetails!.notificationResponse!.payload!.trim().isNotEmpty) {
        try {
          final data =
              jsonDecode(launchDetails.notificationResponse!.payload!)
                  as Map<String, dynamic>;
          pushService.handleNotificationTapFromPayload(data);
        } catch (_) {
          debugPrint('Deep link from launch: invalid payload');
        }
      }

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Set system UI mode
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
      FlutterNativeSplash.remove();

      // Pre-warm location detection (non-blocking)
      // Result gets cached so HomeAppBar picks it up instantly
      LocationService.instance.detectCurrentLocation();

      // Run the app
      runApp(const App());
    },
    (error, stackTrace) {
      // Log errors that occur outside of Flutter
      debugPrint('Unhandled error: $error');
      debugPrint('Stack trace: $stackTrace');
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
    },
  );
}
