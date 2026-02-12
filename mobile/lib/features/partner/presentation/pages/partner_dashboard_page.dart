import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/data/repositories/notification_repository.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../data/partner_repository.dart';
import '../bloc/partner_dashboard_bloc.dart';
import '../bloc/partner_dashboard_event.dart';
import '../bloc/partner_dashboard_state.dart';

class PartnerDashboardPage extends StatelessWidget {
  const PartnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure ProfileBloc is loaded for avatar sync
    final profileBloc = getIt<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(const ProfileLoadRequested());
    }
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PartnerDashboardBloc(
            partnerRepository: getIt<PartnerRepository>(),
            notificationRepository: getIt<NotificationRepository>(),
          )..add(const PartnerDashboardLoadRequested()),
        ),
        BlocProvider.value(value: profileBloc),
      ],
      child: const _PartnerDashboardContent(),
    );
  }
}

class _PartnerDashboardContent extends StatelessWidget {
  const _PartnerDashboardContent();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerDashboardBloc, PartnerDashboardState>(
      listener: (context, state) {
        // Show error snackbar when availability toggle fails
        if (state is PartnerAvailabilityToggleFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Đóng',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }

        // Show error snackbar from loaded state
        if (state is PartnerDashboardLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Clear error after showing
          context.read<PartnerDashboardBloc>().add(
            const PartnerDashboardClearError(),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Partner Dashboard'),
          actions: [
            BlocBuilder<PartnerDashboardBloc, PartnerDashboardState>(
              buildWhen: (prev, curr) {
                // Only rebuild when notification count changes
                final prevCount = prev is PartnerDashboardLoaded
                    ? prev.unreadNotificationCount
                    : 0;
                final currCount = curr is PartnerDashboardLoaded
                    ? curr.unreadNotificationCount
                    : 0;
                return prevCount != currCount;
              },
              builder: (context, state) {
                final unreadCount = state is PartnerDashboardLoaded
                    ? state.unreadNotificationCount
                    : 0;

                return IconButton(
                  onPressed: () async {
                    await context.push(RouteNames.notifications);
                    // Refresh notification count when returning
                    if (context.mounted) {
                      context.read<PartnerDashboardBloc>().add(
                        const PartnerDashboardRefreshAfterAction(),
                      );
                    }
                  },
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: unreadCount > 99
                        ? const Text('99+', style: TextStyle(fontSize: 8))
                        : Text(
                            '$unreadCount',
                            style: const TextStyle(fontSize: 10),
                          ),
                    child: const Icon(Ionicons.notifications_outline),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<PartnerDashboardBloc, PartnerDashboardState>(
          builder: (context, state) {
            if (state is PartnerDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PartnerDashboardError) {
              return _ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<PartnerDashboardBloc>().add(
                    const PartnerDashboardLoadRequested(),
                  );
                },
              );
            }

            // Handle all loaded states
            PartnerDashboardData? data;
            bool isUpdating = false;

            if (state is PartnerDashboardLoaded) {
              data = state.dashboardData;
            } else if (state is PartnerAvailabilityUpdating) {
              data = state.dashboardData;
              isUpdating = true;
            } else if (state is PartnerAvailabilityToggleFailed) {
              data = state.dashboardData;
            }

            if (data == null) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PartnerDashboardBloc>().add(
                  const PartnerDashboardRefreshRequested(),
                );
                // Wait for state to change
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Banner (if not verified)
                    if (!data.profile.isVerified)
                      _VerificationBanner(profile: data.profile),

                    if (!data.profile.isVerified) const SizedBox(height: 16),

                    // Welcome Header
                    _WelcomeHeader(
                      profile: data.profile,
                      userInfo: data.userInfo,
                      isUpdating: isUpdating,
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats
                    _QuickStats(profile: data.profile, stats: data.stats),

                    const SizedBox(height: 24),

                    // Today's Bookings
                    _SectionHeader(
                      title: 'Lịch hẹn sắp tới',
                      action: 'Xem tất cả',
                      onActionTap: () async {
                        await context.push(RouteNames.partnerBookings);
                        // Refresh after returning from bookings page
                        if (context.mounted) {
                          context.read<PartnerDashboardBloc>().add(
                            const PartnerDashboardRefreshAfterAction(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (data.upcomingBookings.isEmpty)
                      const _EmptyBookings()
                    else
                      ...data.upcomingBookings.map(
                        (booking) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(booking: booking),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const _QuickActions(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Icon(Ionicons.alert_circle_outline, size: 64, color: context.appColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Ionicons.refresh_outline),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Verification banner shown when partner is not verified
class _VerificationBanner extends StatelessWidget {
  final PartnerProfileResponse profile;

  const _VerificationBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(100)),
      ),
      child: Row(
        children: [
          const Icon(Ionicons.shield_checkmark_outline, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tài khoản chưa xác minh',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Xác minh tài khoản để tăng độ tin cậy với khách hàng',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(RouteNames.kyc),
            icon: const Icon(Ionicons.chevron_forward_outline, color: AppColors.warning),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final PartnerProfileResponse profile;
  final PartnerUserInfo? userInfo;
  final bool isUpdating;

  const _WelcomeHeader({
    required this.profile,
    this.userInfo,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userInfo?.name ?? 'Partner';

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        // Prefer avatar from ProfileBloc for sync, fallback to userInfo
        String? avatarUrl;
        if (profileState is ProfileLoaded) {
          avatarUrl = profileState.avatarUrl;
        }
        avatarUrl ??= userInfo?.avatarUrl;

        return Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.appColors.shimmerBase,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(ImageUtils.buildImageUrl(avatarUrl))
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ?   Icon(Ionicons.person_outline, color: context.appColors.textHint)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.waving_hand, size: 22, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Xin chào, $displayName!',
                          style: AppTypography.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: profile.isAvailable
                              ? AppColors.online
                              : context.appColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.isAvailable ? 'Đang hoạt động' : 'Tạm nghỉ',
                        style: AppTypography.labelMedium.copyWith(
                          color: profile.isAvailable
                              ? AppColors.online
                              : context.appColors.textHint,
                        ),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: 8),
                        Icon(Ionicons.checkmark_done_outline, size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status Toggle
            isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: profile.isAvailable,
                    onChanged: (value) {
                      context.read<PartnerDashboardBloc>().add(
                        PartnerAvailabilityToggled(value),
                      );
                    },
                    activeColor: AppColors.primary,
                  ),
          ],
        );
      },
    );
  }
}

class _QuickStats extends StatelessWidget {
  final PartnerProfileResponse profile;
  final PartnerStats stats;

  const _QuickStats({required this.profile, required this.stats});

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Ionicons.swap_horizontal_outline,
                  label: 'Tổng thu',
                  value: '${_formatCurrency(stats.totalEarned)}đ',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.textWhite.withAlpha(50),
              ),
              Expanded(
                child: _StatItem(
                  icon: Ionicons.calendar_outline,
                  label: 'Đang chờ',
                  value: '${stats.pending}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppColors.textWhite.withAlpha(50)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Ionicons.calendar_outline,
                  label: 'Đơn hàng',
                  value: '${stats.completed}/${stats.total}',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.textWhite.withAlpha(50),
              ),
              Expanded(
                child: _StatItem(
                  icon: Ionicons.star_outline,
                  label: 'Đánh giá',
                  value:
                      '${profile.averageRating.toStringAsFixed(1)} (${profile.totalReviews})',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textWhite, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textWhite.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const _SectionHeader({required this.title, this.action, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.titleMedium),
        if (action != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action!,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        children: [
            Icon(Ionicons.calendar_outline, size: 48, color: context.appColors.textHint),
          const SizedBox(height: 12),
          Text(
            'Không có lịch hẹn sắp tới',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final PartnerBooking booking;

  const _BookingCard({required this.booking});

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final user = booking.user;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: context.appColors.shimmerBase,
            backgroundImage: user?.avatarUrl != null
                ? CachedNetworkImageProvider(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ?   Icon(Ionicons.person_outline, color: context.appColors.textHint)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Khách hàng',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                      Icon(
                      Ionicons.time_outline,
                      size: 14,
                      color: context.appColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.startTime} - ${booking.endTime}',
                      style: AppTypography.labelSmall.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.statusText,
                        style: AppTypography.labelSmall.copyWith(
                          color: _getStatusColor(booking.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Ionicons.calendar_outline,
                      size: 14,
                      color: context.appColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(booking.date),
                      style: AppTypography.labelSmall.copyWith(
                        color: context.appColors.textHint,
                      ),
                    ),
                    if (booking.meetingLocation != null) ...[
                      const SizedBox(width: 8),
                        Icon(
                        Ionicons.location_outline,
                        size: 14,
                        color: context.appColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.meetingLocation!,
                          style: AppTypography.labelSmall.copyWith(
                            color: context.appColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${_formatCurrency(booking.subtotal)}đ',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'CONFIRMED':
      case 'PAID':
        return AppColors.success;
      case 'ONGOING':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.online;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Truy cập nhanh', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Ionicons.calendar_outline,
                label: 'Lịch trình',
                color: AppColors.secondary,
                onTap: () =>
                    context.push(RouteNames.partnerAvailabilitySettings),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Ionicons.swap_horizontal_outline,
                label: 'Thu nhập',
                color: AppColors.success,
                onTap: () => context.push(RouteNames.partnerEarnings),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Ionicons.create_outline,
                label: 'Hồ sơ',
                color: AppColors.accent,
                onTap: () => context.push(RouteNames.partnerProfile),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Ionicons.star_outline,
                label: 'Đánh giá',
                color: AppColors.warning,
                onTap: () =>
                    context.push('${RouteNames.partnerProfile}?tab=reviews'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Ionicons.image_outline,
                label: 'Ảnh',
                color: AppColors.info,
                onTap: () => context.push(RouteNames.partnerPhotoManager),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Ionicons.business_outline,
                label: 'Ngân hàng',
                color: AppColors.secondary,
                onTap: () => context.push(RouteNames.partnerBankAccount),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
