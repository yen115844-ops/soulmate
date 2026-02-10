import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/user_enums.dart';

/// Splash Screen with animated logo
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _storage = LocalStorageService.instance;
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check if user has completed onboarding
    final isOnboardingComplete = _storage.isOnboardingComplete;

    debugPrint('=== SPLASH NAVIGATION ===');
    debugPrint('isOnboardingComplete: $isOnboardingComplete');
    debugPrint('isLoggedIn: ${_storage.isLoggedIn}');
    debugPrint('hasPendingDeepLink: ${_deepLinkService.hasPendingDeepLink}');

    if (!isOnboardingComplete) {
      // First time user - show onboarding
      context.go(RouteNames.onboarding);
    } else if (_storage.isLoggedIn) {
      // User is logged in - verify with API to get latest status
      try {
        final authRepo = getIt<AuthRepository>();
        final user = await authRepo.getCurrentUser();
        final status = UserStatus.fromString(user.status ?? 'PENDING');

        if (!mounted) return;

        switch (status) {
          case UserStatus.active:
          case UserStatus.pending:
            // Navigate to home first
            debugPrint('=== GOING TO HOME ===');
            context.go(RouteNames.home);
            // Mark app as ready and process pending deep link
            debugPrint('=== MARKING APP READY ===');
            _deepLinkService.markAppReady();
            debugPrint('=== PROCESSING PENDING DEEPLINK ===');
            final processed = _deepLinkService.processPendingDeepLink();
            debugPrint('Pending deeplink processed: $processed');
            break;
          case UserStatus.suspended:
          case UserStatus.banned:
            // Logout and show login
            await authRepo.logout();
            if (mounted) context.go(RouteNames.login);
            break;
        }
      } catch (e) {
        // If API call fails, still allow access if logged in
        debugPrint('Error checking user status: $e');
        if (mounted) {
          context.go(RouteNames.home);
          // Mark app as ready and process pending deep link
          _deepLinkService.markAppReady();
          _deepLinkService.processPendingDeepLink();
        }
      }
    } else {
      // Onboarding complete but not logged in - go to login
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: 24),
                // App Name
                const Text(
                      'Mate Social',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                // Tagline
                const Text(
                  'Kết nối bạn đồng hành',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
