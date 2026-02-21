import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../data/models/partner_profile_model.dart';

/// Quick stats strip: completed bookings, response rate, experience, price
class PartnerStatsSection extends StatelessWidget {
  final PartnerDetailResponse detail;

  const PartnerStatsSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            context,
            icon: Ionicons.checkmark_done_circle_outline,
            value: '${detail.profile.completedBookings}',
            label: 'Hoàn thành',
            color: AppColors.success,
          ),
          _buildDivider(context),
          _buildStatItem(
            context,
            icon: Ionicons.chatbubble_ellipses_outline,
            value: '${detail.profile.totalReviews}',
            label: 'Đánh giá',
            color: AppColors.starFilled,
          ),
          _buildDivider(context),
          _buildStatItem(
            context,
            icon: Ionicons.time_outline,
            value: _formatExperience(),
            label: 'Kinh nghiệm',
            color: AppColors.info,
          ),
          _buildDivider(context),
          _buildStatItem(
            context,
            icon: Ionicons.flash_outline,
            value: '${detail.profile.totalBookings > 0 ? ((detail.profile.completedBookings / detail.profile.totalBookings) * 100).toInt() : 100}%',
            label: 'Phản hồi',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  String _formatExperience() {
    final years = detail.profile.experienceYears;
    if (years == null || years == 0) return 'Mới';
    return '${years} năm';
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.appColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: context.appColors.divider,
    );
  }
}
