import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Premium Guard - Utility for checking and enforcing premium status
class PremiumGuard {
  /// Check if current user is premium
  static bool isPremium(BuildContext context) {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        return authState.user.isPremium;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Show premium upgrade dialog if user is not premium
  /// Returns true if user is premium, false if dialog was shown
  static bool requirePremium(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onUpgrade,
  }) {
    if (isPremium(context)) {
      return true;
    }

    showPremiumDialog(
      context,
      title: title,
      message: message,
      onUpgrade: onUpgrade,
    );
    return false;
  }

  /// Show premium upgrade dialog
  /// Returns true if user chose to upgrade, false if dismissed
  static Future<bool> showPremiumDialog(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onUpgrade,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PremiumUpgradeDialog(
        title: title ?? 'Tính năng Premium',
        message: message ?? 'Nâng cấp Premium để sử dụng tính năng này.',
        onUpgrade: onUpgrade,
      ),
    );
    return result ?? false;
  }
}

/// Premium upgrade dialog
class PremiumUpgradeDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onUpgrade;

  const PremiumUpgradeDialog({
    super.key,
    required this.title,
    required this.message,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Premium benefits preview
          _buildBenefitItem('Nhắn tin không giới hạn'),
          _buildBenefitItem('Ưu tiên hiển thị'),
          _buildBenefitItem('Xem ai đã quan tâm'),
          const SizedBox(height: 24),
          // Upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onUpgrade?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Nâng cấp Premium',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Để sau',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
