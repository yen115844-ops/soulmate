import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/service_type_emoji.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/partner_profile_model.dart';

/// Activity interests section - shows what activities this user is interested in
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
    final serviceTypes = detail.profile.serviceTypes;
    if (serviceTypes.isEmpty) return const SizedBox.shrink();

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Ionicons.heart_circle_outline,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Hoạt động yêu thích',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: serviceTypes.map((type) {
              final display = ServiceTypeEmoji.get(type);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(display.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(display.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      display.nameVi,
                      style: AppTypography.labelMedium.copyWith(
                        color: Color(display.color),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
