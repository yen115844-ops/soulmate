import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';

/// Sort picker bottom sheet
class SortBottomSheet extends StatelessWidget {
  final String currentSort;

  const SortBottomSheet({super.key, required this.currentSort});

  static const _options = [
    (
      code: 'rating',
      label: 'Đánh giá cao nhất',
      icon: Ionicons.star_outline
    ),
    (
      code: 'price_low',
      label: 'Giá thấp đến cao',
      icon: Ionicons.trending_up_outline
    ),
    (
      code: 'price_high',
      label: 'Giá cao đến thấp',
      icon: Ionicons.trending_down_outline
    ),
    (code: 'newest', label: 'Mới nhất', icon: Ionicons.time_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Icon(Ionicons.swap_vertical_outline,
                      size: 22, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Sắp xếp theo',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.appColors.border),
            ..._options.map((opt) {
              final isSelected = currentSort == opt.code;
              return ListTile(
                onTap: () {
                  final bloc = context.read<HomeBloc>();
                  bloc.add(HomeApplyFilter(
                    bloc.state.filter.copyWith(sortBy: opt.code),
                  ));
                  Navigator.pop(context);
                },
                leading: Icon(opt.icon,
                    color: isSelected
                        ? AppColors.primary
                        : context.appColors.textSecondary),
                title: Text(
                  opt.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Ionicons.checkmark_circle,
                        color: AppColors.primary, size: 22)
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
