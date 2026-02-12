import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/home_state.dart';
import '../models/service_category_data.dart';

/// Section header showing title and clear-filter action
class HomeSectionHeader extends StatelessWidget {
  final HomeState state;
  final String? selectedService;
  final VoidCallback onClearFilter;

  const HomeSectionHeader({
    super.key,
    required this.state,
    required this.selectedService,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = selectedService != null
        ? ServiceCategoryData.labelForCode(selectedService!)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            serviceName != null ? 'Partner $serviceName' : 'Gợi ý cho bạn',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (state.partners.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${state.partners.length}+',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (!state.filter.isEmpty)
            GestureDetector(
              onTap: onClearFilter,
              child: Row(
                children: [
                  Icon(
                    Ionicons.close_circle_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Xóa lọc',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
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
