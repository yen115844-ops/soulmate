import Flutter
import UIKit
import flutter_local_notifications
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()
    
    // Required for iOS 10+ local notifications
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Configure notifications
    configureNotifications(application)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Configure push notification settings
  private func configureNotifications(_ application: UIApplication) {
    // Set notification center delegate for foreground/tap handling
    UNUserNotificationCenter.current().delegate = self

    // Request notification permissions
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        if let error = error {
          print("Notification permission error: \(error)")
        }
        print("Notification permission granted: \(granted)")
      }
    )

    // Register for remote notifications (FCM)
    application.registerForRemoteNotifications()

    // Set Firebase Messaging delegate
    Messaging.messaging().delegate = self
  }
  
  // Handle device token for remote notifications (FCM)
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Pass APNS token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // MARK: - UNUserNotificationCenterDelegate

  // Handle notification presentation when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification banner, sound and badge even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // Handle notification tap when app is in background or terminated
  // CRITICAL: Must call super to forward tap event to Flutter/Firebase plugin
  // Without super, onMessageOpenedApp and getInitialMessage will NOT work!
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Forward to super so Flutter Firebase Messaging plugin receives the tap event
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase FCM token: \(String(describing: fcmToken))")
    // Notify Flutter side about token refresh
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
