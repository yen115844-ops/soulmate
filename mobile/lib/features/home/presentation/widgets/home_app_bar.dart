import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';

/// Sliver app bar with greeting, notification button and search bar
class HomeAppBar extends StatelessWidget {
  final VoidCallback onSearchTap;

  const HomeAppBar({super.key, required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
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
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: greeting + actions
                  Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<ProfileBloc, ProfileState>(
                          builder: (context, profileState) {
                            String greeting = 'Xin chào 👋';
                            if (profileState is ProfileLoaded) {
                              final name =
                                  profileState.displayName.split(' ').last;
                              greeting = 'Xin chào, $name 👋';
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tìm partner đồng hành cùng bạn',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      _CircleIconButton(
                        icon: Ionicons.notifications_outline,
                        onTap: () => context.push(RouteNames.notifications),
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
  }
}

/// Circle icon button used in the app bar
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
  }
}
