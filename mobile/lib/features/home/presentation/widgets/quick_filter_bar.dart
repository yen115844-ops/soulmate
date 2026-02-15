import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/home_filter.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

/// Horizontal scrollable quick filter chips bar
class QuickFilterBar extends StatelessWidget {
  final HomeState state;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  const QuickFilterBar({
    super.key,
    required this.state,
    required this.onFilterTap,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    final filter = state.filter;
    final activeCount = _countActiveFilters(filter);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filter button with badge
            _QuickFilterChip(
              label: 'Bộ lọc',
              icon: Ionicons.options_outline,
              isActive: activeCount > 0,
              badge: activeCount > 0 ? activeCount : null,
              onTap: onFilterTap,
            ),
            const SizedBox(width: 8),
            // Sort chip
            _QuickFilterChip(
              label: _sortLabel(filter.sortBy),
              icon: Ionicons.swap_vertical_outline,
              isActive: filter.sortBy != 'rating',
              onTap: onSortTap,
            ),
            const SizedBox(width: 8),
            // Gender chip
            if (filter.gender != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _QuickFilterChip(
                  label: _genderLabel(filter.gender!),
                  icon: Ionicons.person_outline,
                  isActive: true,
                  onDismiss: () {
                    context.read<HomeBloc>().add(
                      HomeApplyFilter(filter.clear(clearGender: true)),
                    );
                  },
                ),
              ),
            // Location chip (not dismissable — location is always required)
            if (filter.locationDisplay != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _QuickFilterChip(
                  label: filter.locationDisplay!,
                  icon: Ionicons.map_outline,
                  isActive: true,
                ),
              ),
            // Verified chip
            _QuickFilterChip(
              label: 'Đã xác minh',
              icon: Ionicons.shield_checkmark_outline,
              isActive: filter.verifiedOnly,
              onTap: () {
                context.read<HomeBloc>().add(
                  HomeApplyFilter(
                    filter.copyWith(verifiedOnly: !filter.verifiedOnly),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Online chip
            _QuickFilterChip(
              label: 'Online',
              icon: Ionicons.wifi_outline,
              isActive: filter.availableNow,
              onTap: () {
                context.read<HomeBloc>().add(
                  HomeApplyFilter(
                    filter.copyWith(availableNow: !filter.availableNow),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _countActiveFilters(HomeFilter filter) {
    int count = 0;
    if (filter.gender != null) count++;
    if (filter.minAge != null || filter.maxAge != null) count++;
    if (filter.minRate != null || filter.maxRate != null) count++;
    if (filter.radius != null) count++;
    if (filter.verifiedOnly) count++;
    if (filter.availableNow) count++;
    if (filter.city != null || filter.district != null) count++;
    return count;
  }

  String _sortLabel(String sortBy) {
    switch (sortBy) {
      case 'rating':
        return 'Đánh giá cao';
      case 'price_low':
        return 'Giá thấp → cao';
      case 'price_high':
        return 'Giá cao → thấp';
      case 'newest':
        return 'Mới nhất';
      default:
        return 'Sắp xếp';
    }
  }

  String _genderLabel(String gender) {
    switch (gender) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return gender;
    }
  }
}

/// Quick filter chip widget
class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final int? badge;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.badge,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : context.appColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : context.appColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? AppColors.primary
                  : context.appColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isActive
                    ? AppColors.primary
                    : context.appColors.textPrimary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
            if (onDismiss != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Ionicons.close_circle,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
