import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/app_button.dart';

/// Error State Widget - Shown when an error occurs
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Widget? customIcon;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.buttonText,
    this.onRetry,
    this.icon,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            customIcon ??
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Ionicons.alert_circle_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                ).animate().scale(
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    ),

            const SizedBox(height: 24),

            // Title
            Text(
              title ?? 'Đã có lỗi xảy ra',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // Message
            Text(
              message ?? 'Vui lòng thử lại sau hoặc kiểm tra kết nối mạng',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            if (onRetry != null) ...[
              const SizedBox(height: 32),

              // Retry Button
              SizedBox(
                width: 200,
                child: AppButton(
                  text: buttonText ?? 'Thử lại',
                  onPressed: onRetry,
                  icon: Ionicons.refresh_outline,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network Error Widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Ionicons.wifi_outline,
      title: 'Không có kết nối mạng',
      message: 'Vui lòng kiểm tra kết nối internet và thử lại',
      buttonText: 'Thử lại',
      onRetry: onRetry,
    );
  }
}

/// Server Error Widget
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Ionicons.cloud_offline_outline,
      title: 'Lỗi máy chủ',
      message: 'Hệ thống đang gặp sự cố, vui lòng thử lại sau',
      buttonText: 'Thử lại',
      onRetry: onRetry,
    );
  }
}

/// Permission Denied Widget
class PermissionDeniedWidget extends StatelessWidget {
  final String? permission;
  final VoidCallback? onOpenSettings;

  const PermissionDeniedWidget({
    super.key,
    this.permission,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Ionicons.lock_closed_outline,
      title: 'Cần cấp quyền truy cập',
      message: permission != null
          ? 'Ứng dụng cần quyền $permission để tiếp tục'
          : 'Vui lòng cấp quyền truy cập trong cài đặt',
      buttonText: 'Mở cài đặt',
      onRetry: onOpenSettings,
    );
  }
}

/// Timeout Error Widget
class TimeoutErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const TimeoutErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Ionicons.timer_outline,
      title: 'Hết thời gian chờ',
      message: 'Kết nối mất quá nhiều thời gian, vui lòng thử lại',
      buttonText: 'Thử lại',
      onRetry: onRetry,
    );
  }
}
