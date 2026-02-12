import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/app_router.dart';

/// Duration to wait after navigating to /home before pushing the target page.
const _kNavigationDelay = Duration(milliseconds: 200);

/// Timeout for retry when pending deep link was not consumed by splash.
const _kRetryTimeout = Duration(seconds: 4);

/// Service for handling deep link navigation from notifications
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  /// Pending deep link data - saved when app is not ready (still on splash)
  Map<String, dynamic>? _pendingDeepLinkData;

  /// Flag: app is ready to navigate (past splash)
  bool _isAppReady = false;

  /// Timer retry for pending deep link
  Timer? _retryTimer;

  bool get hasPendingDeepLink => _pendingDeepLinkData != null;
  bool get isAppReady => _isAppReady;

  /// Mark app ready (call after splash finishes)
  void markAppReady() {
    debugPrint('DeepLinkService: App marked as ready');
    _isAppReady = true;
  }

  /// Consume and clear pending deep link data
  Map<String, dynamic>? consumePendingDeepLink() {
    final data = _pendingDeepLinkData;
    _pendingDeepLinkData = null;
    debugPrint('DeepLinkService: Consumed pending deep link: $data');
    return data;
  }

  /// Save deep link data to process later (when app is on splash)
  void savePendingDeepLink(Map<String, dynamic> data) {
    debugPrint('DeepLinkService: Saving pending deep link: $data');
    _pendingDeepLinkData = data;
  }

  /// Handle navigation from notification data.
  void handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint(
      'DeepLinkService.handleNotificationNavigation called with: $data, isAppReady=$_isAppReady',
    );

    if (!_isAppReady && _tryAutoDetectReady()) {
      debugPrint('DeepLinkService: Auto-detected app is ready');
      _performNavigation(data);
      return;
    }

    if (!_isAppReady) {
      savePendingDeepLink(data);
      _scheduleRetry();
      return;
    }

    _performNavigation(data);
  }

  bool _tryAutoDetectReady() {
    try {
      final router = AppRouter.router;
      final location = router.routerDelegate.currentConfiguration.fullPath;
      if (location != '/' &&
          !location.startsWith('/login') &&
          !location.startsWith('/onboarding') &&
          !location.startsWith('/register')) {
        _isAppReady = true;
        return true;
      }
    } catch (e) {
      debugPrint('DeepLinkService: Router not ready yet: $e');
    }
    return false;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_kRetryTimeout, () {
      if (_pendingDeepLinkData != null) {
        debugPrint('DeepLinkService: Retry processing pending deep link');
        _isAppReady = true;
        processPendingDeepLink();
      }
    });
  }

  /// Navigate to home first, then push the target route after a short delay.
  void _goHomeThenPush(GoRouter router, String targetRoute) {
    try {
      Future.microtask(() {
        router.go('/home');
        Future.delayed(_kNavigationDelay, () {
          router.push(targetRoute);
        });
      });
    } catch (e) {
      debugPrint('DeepLinkService: Navigation failed for $targetRoute: $e');
    }
  }

  void _performNavigation(Map<String, dynamic> data) {
    String? actionType = (data['actionType'] ?? data['type']) as String?;
    String? actionId = (data['actionId'] ?? data['object_id']) as String?;

    // Fallback for chat: payload may only have conversationId
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
          _goHomeThenPush(router, '/booking/$actionId');
        }
        break;
      case 'chat':
        if (actionId != null && actionId.isNotEmpty) {
          _goHomeThenPush(router, '/chat/$actionId');
        }
        break;
      case 'wallet':
        _goHomeThenPush(router, '/wallet');
        break;
      case 'profile':
        if (actionId != null && actionId.isNotEmpty) {
          _goHomeThenPush(router, '/partner/$actionId');
        }
        break;
      case 'review':
        if (actionId != null && actionId.isNotEmpty) {
          _goHomeThenPush(router, '/booking/$actionId/review');
        }
        break;
      case 'safety':
        _goHomeThenPush(router, '/sos');
        break;
      default:
        _goHomeThenPush(router, '/notifications');
        break;
    }
  }

  /// Process pending deep link if available.
  /// Call after splash completes and app is on home page.
  /// Returns true if a pending deep link was processed.
  bool processPendingDeepLink() {
    final data = consumePendingDeepLink();
    if (data != null) {
      debugPrint('DeepLinkService: Processing pending deep link: $data');
      Future.delayed(const Duration(milliseconds: 100), () {
        _performNavigation(data);
      });
      return true;
    }
    return false;
  }

  /// Dispose resources - cancel retry timer
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
