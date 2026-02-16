import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../config/routes/app_router.dart';
import '../network/api_config.dart';

/// Service for handling URL-based deep links (App Links / Universal Links).
///
/// This complements [DeepLinkService] which handles notification-based
/// deep links. This service handles links opened from the web or
/// other apps via https:// or custom scheme URLs.
class AppDeepLinkService {
  static final AppDeepLinkService _instance = AppDeepLinkService._internal();
  factory AppDeepLinkService() => _instance;
  AppDeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _pendingUri;

  /// Initialize the deep link listener.
  /// Call this once in main.dart after app setup.
  Future<void> init() async {
    // Check for initial link (app opened via deep link while closed)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('AppDeepLinkService: Initial URI: $initialUri');
        _pendingUri = initialUri;
      }
    } catch (e) {
      debugPrint('AppDeepLinkService: Error getting initial link: $e');
    }

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('AppDeepLinkService: Received URI: $uri');
        _handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint('AppDeepLinkService: Error in link stream: $error');
      },
    );
  }

  /// Process any pending deep link that arrived before app was ready.
  /// Returns true if a pending link was consumed.
  bool processPendingDeepLink() {
    final uri = _pendingUri;
    _pendingUri = null;
    if (uri != null) {
      debugPrint('AppDeepLinkService: Processing pending URI: $uri');
      _handleDeepLink(uri);
      return true;
    }
    return false;
  }

  /// Parse a URI and navigate to the appropriate route.
  void _handleDeepLink(Uri uri) {
    final route = _parseRoute(uri);
    if (route != null) {
      debugPrint('AppDeepLinkService: Navigating to route: $route');
      _navigateToRoute(route);
    } else {
      debugPrint('AppDeepLinkService: No matching route for URI: $uri');
    }
  }

  /// Parse a URI into an in-app route path.
  ///
  /// Supports:
  /// - https://gomate-cms.vercel.app/partner/{id} → /partner/{id}
  /// - matesocial://partner/{id} → /partner/{id}
  String? _parseRoute(Uri uri) {
    // Handle both https deep links and custom scheme
    final isHttpsLink = uri.scheme == 'https' &&
        uri.host == ApiConfig.deepLinkDomain;
    final isCustomScheme = uri.scheme == ApiConfig.deepLinkScheme;

    if (!isHttpsLink && !isCustomScheme) return null;

    final pathSegments = uri.pathSegments;

    // /partner/{id} → Partner detail
    if (pathSegments.length >= 2 && pathSegments[0] == 'partner') {
      final partnerId = pathSegments[1];
      if (partnerId.isNotEmpty) {
        return '/partner/$partnerId';
      }
    }

    // Add more route patterns here as needed
    // /booking/{id} → Booking detail
    // /chat/{id} → Chat room

    return null;
  }

  /// Navigate via GoRouter. Goes to /home first then pushes the target.
  void _navigateToRoute(String route) {
    try {
      final router = AppRouter.router;
      Future.microtask(() {
        router.go('/home');
        Future.delayed(const Duration(milliseconds: 200), () {
          router.push(route);
        });
      });
    } catch (e) {
      debugPrint('AppDeepLinkService: Navigation failed for $route: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
