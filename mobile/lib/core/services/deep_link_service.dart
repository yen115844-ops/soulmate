import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_router.dart';

/// Service for handling deep link navigation from notifications
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  /// Pending deep link data - được lưu khi app chưa sẵn sàng (đang ở splash)
  /// Sẽ được xử lý sau khi splash hoàn tất navigation
  Map<String, dynamic>? _pendingDeepLinkData;

  /// Flag đánh dấu app đã sẵn sàng để navigate (đã qua splash)
  bool _isAppReady = false;

  /// Getter để kiểm tra có pending deep link hay không
  bool get hasPendingDeepLink => _pendingDeepLinkData != null;

  /// Kiểm tra app đã sẵn sàng chưa
  bool get isAppReady => _isAppReady;

  /// Đánh dấu app đã sẵn sàng (gọi sau khi splash hoàn tất)
  void markAppReady() {
    debugPrint('DeepLinkService: App marked as ready');
    _isAppReady = true;
  }

  /// Lấy và xóa pending deep link data
  Map<String, dynamic>? consumePendingDeepLink() {
    final data = _pendingDeepLinkData;
    _pendingDeepLinkData = null;
    debugPrint('DeepLinkService: Consumed pending deep link: $data');
    return data;
  }

  /// Lưu deep link data để xử lý sau (khi app đang ở splash)
  void savePendingDeepLink(Map<String, dynamic> data) {
    debugPrint('DeepLinkService: Saving pending deep link: $data');
    _pendingDeepLinkData = data;
  }

  /// Handle navigation from notification data.
  /// Hỗ trợ hai format: actionType/actionId (backend Mate Social) hoặc type/object_id (format khác).
  /// Ví dụ: tin nhắn chat → actionType=chat, actionId=conversationId → mở trang chat.
  ///
  /// Tự động quyết định navigate ngay hay lưu pending dựa vào trạng thái app
  void handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint(
      'DeepLinkService.handleNotificationNavigation called with: $data, isAppReady=$_isAppReady',
    );

    // Nếu app chưa sẵn sàng (đang ở splash), lưu lại để xử lý sau
    if (!_isAppReady) {
      savePendingDeepLink(data);
      return;
    }

    // App đã sẵn sàng, navigate ngay
    _performNavigation(data);
  }

  /// Thực hiện navigation thực sự
  void _performNavigation(Map<String, dynamic> data) {
    String? actionType = (data['actionType'] ?? data['type']) as String?;
    String? actionId = (data['actionId'] ?? data['object_id']) as String?;

    // Fallback cho chat: payload có thể chỉ có conversationId (từ FCM data)
    if ((actionType == null || actionType.isEmpty) &&
        (data['conversationId'] != null &&
            data['conversationId'].toString().trim().isNotEmpty)) {
      actionType = 'chat';
      actionId ??= data['conversationId'].toString();
    }

    debugPrint('Deep link navigation: type=$actionType, id=$actionId');

    final router = AppRouter.router;

    switch (actionType) {
      case 'booking':
        if (actionId != null && actionId.isNotEmpty) {
          _navigateToBookingDetail(router, actionId);
        }
        break;

      case 'chat':
        if (actionId != null && actionId.isNotEmpty) {
          _navigateToChat(router, actionId);
        }
        break;

      case 'wallet':
        _navigateToWallet(router);
        break;

      case 'profile':
        if (actionId != null && actionId.isNotEmpty) {
          _navigateToPartnerProfile(router, actionId);
        }
        break;

      case 'review':
        if (actionId != null && actionId.isNotEmpty) {
          _navigateToReview(router, actionId);
        }
        break;

      case 'safety':
        _navigateToSafety(router);
        break;

      default:
        // Navigate to notifications page as fallback
        _navigateToNotifications(router);
        break;
    }
  }

  void _navigateToBookingDetail(GoRouter router, String bookingId) {
    try {
      debugPrint('=== NAVIGATING TO BOOKING ===');
      debugPrint('Navigating to booking: /booking/$bookingId');
      debugPrint(
        'Router current location: ${router.routerDelegate.currentConfiguration.fullPath}',
      );
      // Dùng go để đảm bảo navigation hoạt động
      // Trước tiên go đến home, sau đó push đến trang đích
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push('/booking/$bookingId');
        });
      });
    } catch (e) {
      debugPrint('Failed to navigate to booking: $e');
    }
  }

  void _navigateToChat(GoRouter router, String conversationId) {
    try {
      debugPrint('=== NAVIGATING TO CHAT ===');
      debugPrint('Navigating to chat: /chat/$conversationId');
      debugPrint(
        'Router current location: ${router.routerDelegate.currentConfiguration.fullPath}',
      );
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push('/chat/$conversationId');
        });
      });
    } catch (e) {
      debugPrint('Failed to navigate to chat: $e');
    }
  }

  void _navigateToWallet(GoRouter router) {
    try {
      debugPrint('=== NAVIGATING TO WALLET ===');
      debugPrint('Navigating to wallet: /wallet');
      debugPrint(
        'Router current location: ${router.routerDelegate.currentConfiguration.fullPath}',
      );
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push('/wallet');
        });
      });
    } catch (e) {
      debugPrint('Failed to navigate to wallet: $e');
    }
  }

  void _navigateToPartnerProfile(GoRouter router, String partnerId) {
    try {
      debugPrint('=== NAVIGATING TO PARTNER ===');
      debugPrint('Navigating to partner: /partner/$partnerId');
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push('/partner/$partnerId');
        });
      });
    } catch (e) {
      debugPrint('Failed to navigate to partner profile: $e');
    }
  }

  void _navigateToReview(GoRouter router, String bookingId) {
    try {
      debugPrint('=== NAVIGATING TO REVIEW ===');
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push('/booking/$bookingId/review');
        });
      });
    } catch (e) {
      debugPrint('Failed to navigate to review: $e');
    }
  }

  void _navigateToSafety(GoRouter router) {
    try {
      debugPrint('=== NAVIGATING TO SAFETY ===');
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push('/sos');
        });
      });
    } catch (e) {
      debugPrint('Failed to navigate to safety: $e');
    }
  }

  void _navigateToNotifications(GoRouter router) {
    try {
      debugPrint('=== NAVIGATING TO NOTIFICATIONS ===');
      debugPrint(
        'Router current location: ${router.routerDelegate.currentConfiguration.fullPath}',
      );
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push('/notifications');
        });
      });
    } catch (e) {
      debugPrint('Failed to navigate to notifications: $e');
    }
  }

  /// Xử lý pending deep link nếu có.
  /// Gọi method này sau khi splash hoàn tất và app đã ở trang home.
  /// Return true nếu có pending deep link được xử lý.
  bool processPendingDeepLink() {
    final data = consumePendingDeepLink();
    if (data != null) {
      debugPrint('DeepLinkService: Processing pending deep link: $data');
      // Delay nhỏ để đảm bảo home page đã mount xong
      Future.delayed(const Duration(milliseconds: 100), () {
        _performNavigation(data);
      });
      return true;
    }
    return false;
  }
}
