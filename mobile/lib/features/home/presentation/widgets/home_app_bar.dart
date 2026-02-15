import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import 'picker_bottom_sheet.dart';

/// Sliver app bar with location, notification button and search bar.
///
/// Pure presentation widget — all business logic lives in [HomeBloc].
class HomeAppBar extends StatelessWidget {
  final VoidCallback onSearchTap;

  const HomeAppBar({super.key, required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) =>
          prev.locationStatus != curr.locationStatus ||
          prev.filter.city != curr.filter.city ||
          prev.filter.district != curr.filter.district ||
          prev.provinces != curr.provinces,
      builder: (context, state) {
        return SliverAppBar(
          expandedHeight: 140,
          floating: true,
          snap: true,
          pinned: false,
          elevation: 0,
          backgroundColor: context.appColors.surface,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: location + actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildLocationSection(context, state),
                          ),
                          if (state.locationStatus ==
                              LocationDetectionStatus.permissionDenied)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CircleIconButton(
                                icon: Ionicons.locate_outline,
                                onTap: () => context
                                    .read<HomeBloc>()
                                    .add(const HomeRetryLocation()),
                                tooltip: 'Định vị lại',
                              ),
                            ),
                          _CircleIconButton(
                            icon: Ionicons.notifications_outline,
                            onTap: () {
                              AuthGuard.requireAuth(
                                context,
                                onAuthenticated: () =>
                                    context.push(RouteNames.notifications),
                                message: 'Đăng nhập để xem thông báo.',
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Search bar
                      GestureDetector(
                        onTap: onSearchTap,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.appColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Ionicons.search_outline,
                                color: context.appColors.textHint,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tìm kiếm partner, dịch vụ...',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: context.appColors.textHint,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: context.appColors.border,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Ionicons.options_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationSection(BuildContext context, HomeState state) {
    final isDetecting =
        state.locationStatus == LocationDetectionStatus.detecting ||
            state.locationStatus == LocationDetectionStatus.initial;

    if (isDetecting) {
      return _buildLocationRow(
        context,
        icon: Ionicons.location_outline,
        text: 'Đang xác định vị trí...',
        subtitle: 'Tìm partner gần bạn',
        textColor: context.appColors.textSecondary,
        onTap: null,
      );
    }

    if (state.filter.city != null) {
      final displayText = state.filter.district != null
          ? '${state.filter.district}, ${state.filter.city}'
          : state.filter.city!;
      return _buildLocationRow(
        context,
        icon: Ionicons.location,
        text: displayText,
        subtitle: 'Nhấn để thay đổi khu vực',
        textColor: AppColors.primary,
        onTap: () => _showCityPicker(context, state),
      );
    }

    // No location → prompt manual selection
    return _buildLocationRow(
      context,
      icon: Ionicons.location_outline,
      text: 'Chọn khu vực của bạn',
      subtitle: 'Nhấn để chọn tỉnh/thành phố',
      textColor: context.appColors.textPrimary,
      onTap: () => _showCityPicker(context, state),
      showArrow: true,
    );
  }

  void _showCityPicker(BuildContext context, HomeState state) {
    final items = state.provinces.map((p) {
      return (code: p.id, label: p.name);
    }).toList();

    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PickerBottomSheet(
        title: 'Chọn khu vực',
        icon: Ionicons.location_outline,
        items: items,
        selectedValue: state.filter.cityId,
        onSelect: (value) {
          Navigator.pop(context, value);
        },
      ),
    ).then((selectedId) {
      if (selectedId != null && context.mounted) {
        final province = state.provinces.firstWhere((p) => p.id == selectedId);
        context.read<HomeBloc>().add(
              HomeSelectCity(cityId: province.id, cityName: province.name),
            );
      }
    });
  }

  Widget _buildLocationRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String subtitle,
    required Color textColor,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            Icon(
              Ionicons.chevron_down_outline,
              size: 16,
              color: context.appColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

/// Circle icon button used in the app bar
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.appColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(icon, color: context.appColors.textPrimary, size: 22),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
