import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use existing ProfileBloc singleton and trigger load
    final profileBloc = getIt<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(const ProfileLoadRequested());
    }

    return BlocProvider.value(
      value: profileBloc,
      child: const _ProfilePageContent(),
    );
  }
}

class _ProfilePageContent extends StatefulWidget {
  const _ProfilePageContent();

  @override
  State<_ProfilePageContent> createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<_ProfilePageContent> {
  ProfileLoaded? _lastLoadedState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) _lastLoadedState = state;
            if (state is ProfileError && _lastLoadedState != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            if (state is ProfileAvatarUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã cập nhật ảnh đại diện'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          buildWhen: (previous, current) {
            if (current is ProfileUpdating && _lastLoadedState != null) return true;
            return true;
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError && _lastLoadedState == null) {
              return _ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<ProfileBloc>().add(const ProfileLoadRequested());
                },
              );
            }

            final displayState = state is ProfileLoaded ? state : _lastLoadedState;
            if (displayState != null) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ProfileBloc>().add(
                    const ProfileRefreshRequested(),
                  );
                },
                child: _ProfileContent(
                  user: displayState.user,
                  stats: displayState.stats,
                  displayName: displayState.displayName,
                  avatarUrl: displayState.avatarUrl,
                  roleText: displayState.roleText,
                  kycStatusText: displayState.kycStatusText,
                  isKycVerified: displayState.isKycVerified,
                  isUpdatingAvatar: state is ProfileUpdating,
                  onAvatarTap: () => _showAvatarPicker(context),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Ionicons.camera_outline),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                try {
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 80,
                  );
                  if (image != null && context.mounted) {
                    context.read<ProfileBloc>().add(
                          ProfileAvatarUpdateRequested(imagePath: image.path),
                        );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể truy cập camera. Vui lòng kiểm tra quyền truy cập.'),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.image_outline),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                try {
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 80,
                  );
                  if (image != null && context.mounted) {
                    context.read<ProfileBloc>().add(
                          ProfileAvatarUpdateRequested(imagePath: image.path),
                        );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể truy cập thư viện ảnh. Vui lòng kiểm tra quyền truy cập.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
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
            const Icon(Ionicons.alert_circle_outline, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
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

class _ProfileContent extends StatelessWidget {
  final UserModel user;
  final ProfileStats stats;
  final String displayName;
  final String? avatarUrl;
  final String roleText;
  final String kycStatusText;
  final bool isKycVerified;
  final bool isUpdatingAvatar;
  final VoidCallback? onAvatarTap;

  const _ProfileContent({
    required this.user,
    required this.stats,
    required this.displayName,
    required this.avatarUrl,
    required this.roleText,
    required this.kycStatusText,
    required this.isKycVerified,
    this.isUpdatingAvatar = false,
    this.onAvatarTap,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          _ProfileHeader(
            displayName: displayName,
            email: user.email,
            avatarUrl: avatarUrl,
            roleText: roleText,
            isUpdatingAvatar: isUpdatingAvatar,
            onAvatarTap: onAvatarTap,
          ),

          const SizedBox(height: 24),

          // Stats Row
          _StatsRow(
            totalBookings: stats.totalBookings,
            totalReviews: stats.totalReviews,
            averageRating: stats.averageRating,
          ),

          const SizedBox(height: 24),

          // Quick Actions
          _QuickActions(
            isPartner: stats.isPartner,
            partnerStatus: stats.partnerStatus,
          ),

          const SizedBox(height: 24),

          // Menu Items
          _MenuSection(
            title: 'Tài khoản',
            items: [
              _MenuItem(
                icon: Ionicons.create_outline,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () => context.push(RouteNames.editProfile),
              ),
              _MenuItem(
                icon: Ionicons.wallet_outline,
                title: 'Ví của tôi',
                subtitle: _formatCurrency(stats.walletBalance),
                onTap: () => context.push(RouteNames.wallet),
              ),
              _MenuItem(
                icon: Ionicons.heart_outline,
                title: 'Danh sách yêu thích',
                onTap: () => context.push(RouteNames.favorites),
              ),
              _MenuItem(
                icon: Ionicons.star_outline,
                title: 'Đánh giá của tôi',
                onTap: () => context.push(RouteNames.myReviews),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _MenuSection(
            title: 'Bảo mật & Xác thực',
            items: [
              _MenuItem(
                icon: Ionicons.shield_checkmark_outline,
                title: 'Xác minh danh tính (eKYC)',
                subtitle: kycStatusText,
                subtitleColor: isKycVerified
                    ? AppColors.success
                    : AppColors.warning,
                onTap: () => context.push(RouteNames.kyc),
              ),
              _MenuItem(
                icon: Ionicons.call_outline,
                title: 'Liên hệ khẩn cấp',
                onTap: () => context.push(RouteNames.emergencyContacts),
              ),
              _MenuItem(
                icon: Ionicons.lock_closed_outline,
                title: 'Đổi mật khẩu',
                onTap: () => context.push(RouteNames.changePassword),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _MenuSection(
            title: 'Cài đặt',
            items: [
              _MenuItem(
                icon: Ionicons.cog_outline,
                title: 'Cài đặt ứng dụng',
                subtitle: 'Thông báo, giao diện, ngôn ngữ',
                onTap: () => context.push(RouteNames.settings),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _MenuSection(
            title: 'Hỗ trợ',
            items: [
              _MenuItem(
                icon: Ionicons.help_circle_outline,
                title: 'Trung tâm trợ giúp',
                onTap: () => context.push(RouteNames.helpCenter),
              ),
              _MenuItem(
                icon: Ionicons.document_text_outline,
                title: 'Điều khoản sử dụng',
                onTap: () => context.push(RouteNames.termsOfService),
              ),
              _MenuItem(
                icon: Ionicons.shield_checkmark_outline,
                title: 'Chính sách bảo mật',
                onTap: () => context.push(RouteNames.privacyPolicy),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(Ionicons.log_out_outline, color: AppColors.error),
              label: Text(
                'Đăng xuất',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // App Version
          Text(
            'Mate Social v1.0.0',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textHint),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Trigger global logout
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String roleText;
  final bool isUpdatingAvatar;
  final VoidCallback? onAvatarTap;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.roleText,
    this.isUpdatingAvatar = false,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar - tappable to upload
        GestureDetector(
          onTap: isUpdatingAvatar ? null : onAvatarTap,
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ImageUtils.buildImageUrl(avatarUrl!),
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppColors.shimmerBase),
                          errorWidget: (context, url, error) => _DefaultAvatar(),
                        )
                      : _DefaultAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                  ),
                  child: const Icon(
                    Ionicons.camera_outline,
                    color: AppColors.textWhite,
                    size: 16,
                  ),
                ),
              ),
              if (isUpdatingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Name
        Text(displayName, style: AppTypography.headlineSmall),

        const SizedBox(height: 4),

        // Email
        Text(
          email,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 8),

        // User type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            roleText,
            style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: const Icon(Ionicons.person_outline, size: 48, color: AppColors.textHint),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalBookings;
  final int totalReviews;
  final double averageRating;

  const _StatsRow({
    required this.totalBookings,
    required this.totalReviews,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: totalBookings.toString(), label: 'Lịch hẹn'),
          Container(width: 1, height: 40, color: AppColors.divider),
          _StatItem(value: totalReviews.toString(), label: 'Đánh giá'),
          Container(width: 1, height: 40, color: AppColors.divider),
          _StatItem(
            value: averageRating.toStringAsFixed(1),
            label: 'Điểm TB',
            icon: Ionicons.star_outline,
            iconColor: AppColors.starFilled,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _StatItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isPartner;
  final PartnerStatus? partnerStatus;

  const _QuickActions({required this.isPartner, this.partnerStatus});

  @override
  Widget build(BuildContext context) {
    // If user is a partner, show partner status card
    if (isPartner && partnerStatus != null) {
      return _PartnerStatusCard(status: partnerStatus!);
    }

    // If not a partner, show "Become Partner" button
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Ionicons.people_outline,
            label: 'Trở thành Partner',
            color: AppColors.secondary,
            onTap: () => context.push(RouteNames.becomePartner),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Ionicons.gift_outline,
            label: 'Mời bạn bè',
            color: AppColors.accent,
            onTap: () {
              // TODO: Invite friends
            },
          ),
        ),
      ],
    );
  }
}

/// Partner status card widget
class _PartnerStatusCard extends StatelessWidget {
  final PartnerStatus status;

  const _PartnerStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final isVerified = status.isVerified;
    final statusColor = isVerified ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVerified
              ? [
                  AppColors.success.withAlpha(25),
                  AppColors.success.withAlpha(10),
                ]
              : [
                  AppColors.warning.withAlpha(25),
                  AppColors.warning.withAlpha(10),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVerified ? Ionicons.checkmark_done_outline : Ionicons.time_outline,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái Partner',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.statusText,
                      style: AppTypography.titleSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.verificationBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(status.verificationBadge!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.verificationBadge!.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            Text(
              'Hồ sơ của bạn đang được xét duyệt. Chúng tôi sẽ thông báo kết quả trong vòng 24-48 giờ.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (isVerified) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Đơn hàng',
                    value:
                        '${status.completedBookings}/${status.totalBookings}',
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Đánh giá',
                    value: status.averageRating.toStringAsFixed(1),
                    icon: Ionicons.star_outline,
                    iconColor: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Reviews',
                    value: '${status.totalReviews}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.partnerDashboard),
                    icon: const Icon(Ionicons.bar_chart_outline, size: 18),
                    label: const Text('Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: statusColor,
                      side: BorderSide(color: statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Toggle availability
                    },
                    icon: Icon(
                      status.isAvailable ? Ionicons.eye_outline : Ionicons.eye_off_outline,
                      size: 18,
                    ),
                    label: Text(
                      status.isAvailable ? 'Đang hoạt động' : 'Tạm nghỉ',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status.isAvailable
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'gold':
        return Colors.amber.shade700;
      case 'silver':
        return Colors.grey.shade500;
      case 'bronze':
        return Colors.brown.shade400;
      default:
        return AppColors.primary;
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor ?? colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Ionicons.chevron_forward_outline,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
