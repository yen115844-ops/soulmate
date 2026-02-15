import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../config/routes/route_names.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// Utility class to guard authenticated-only features.
///
/// Instead of blocking the entire app behind a login screen,
/// this allows guest users to browse freely and only prompts
/// for authentication when they try to use auth-required features.
class AuthGuard {
  AuthGuard._();

  /// Returns `true` when the current user is authenticated.
  static bool get isAuthenticated {
    final state = getIt<AuthBloc>().state;
    return state is AuthAuthenticated ||
        state is AuthNeedsProfileSetup ||
        state is AuthPendingVerification;
  }

  /// Checks authentication. If authenticated, calls [onAuthenticated].
  /// Otherwise shows a login prompt bottom sheet.
  ///
  /// Usage:
  /// ```dart
  /// AuthGuard.requireAuth(
  ///   context,
  ///   onAuthenticated: () {
  ///     context.push('/booking/create?partnerId=$id');
  ///   },
  /// );
  /// ```
  static void requireAuth(
    BuildContext context, {
    required VoidCallback onAuthenticated,
    String? message,
  }) {
    if (isAuthenticated) {
      onAuthenticated();
      return;
    }
    _showLoginPrompt(context, message: message);
  }

  /// Checks authentication and navigates to the given route if authenticated.
  /// Otherwise shows a login prompt.
  static void requireAuthAndNavigate(
    BuildContext context, {
    required String route,
    Object? extra,
    String? message,
  }) {
    requireAuth(
      context,
      onAuthenticated: () => context.push(route, extra: extra),
      message: message,
    );
  }

  /// Shows a modern login prompt bottom sheet.
  static void _showLoginPrompt(BuildContext context, {String? message}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LoginPromptSheet(message: message),
    );
  }
}

class _LoginPromptSheet extends StatelessWidget {
  final String? message;

  const _LoginPromptSheet({this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? Colors.white60 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Ionicons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Đăng nhập để tiếp tục',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                message ?? 'Bạn cần đăng nhập hoặc đăng ký để sử dụng tính năng này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(RouteNames.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(RouteNames.register);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Tạo tài khoản mới',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Skip button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Để sau',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
