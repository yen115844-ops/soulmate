import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../data/models/partner_profile_model.dart';

/// Pricing card with hourly rate, minimum hours, and booking CTA
class PartnerPricingSection extends StatelessWidget {
  final PartnerDetailResponse detail;
  final VoidCallback? onBookNow;

  const PartnerPricingSection({
    super.key,
    required this.detail,
    this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final hourlyRate = detail.profile.hourlyRate.toInt();
    final minimumHours = detail.profile.minimumHours;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primaryLight.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá dịch vụ',
                      style: AppTypography.labelMedium.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$hourlyRate',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'credits / giờ',
                            style: AppTypography.bodySmall.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Minimum hours badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Ionicons.time_outline,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Tối thiểu $minimumHours giờ',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Estimated cost
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Ionicons.calculator_outline,
                    size: 18, color: context.appColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Ước tính tối thiểu: ',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                Text(
                  '${hourlyRate * minimumHours} credits',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
