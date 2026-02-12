import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
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
            if (current is ProfileUpdating && _lastLoadedState != null)
              return true;
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

            final displayState = state is ProfileLoaded
                ? state
                : _lastLoadedState;
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
                  final picker = ImagePicker();
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
                        content: Text(
                          'Không thể truy cập camera. Vui lòng kiểm tra quyền truy cập.',
                        ),
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
                  final List<AssetEntity>? assets = await AssetPicker.pickAssets(
                    context,
                    pickerConfig: AssetPickerConfig(
                      maxAssets: 1,
                      requestType: RequestType.image,
                      themeColor: AppColors.primary,
                      textDelegate: const VietnameseAssetPickerTextDelegate(),
                    ),
                  );
                  if (assets != null && assets.isNotEmpty && context.mounted) {
                    final file = await assets.first.file;
                    if (file != null && context.mounted) {
                      context.read<ProfileBloc>().add(
                        ProfileAvatarUpdateRequested(imagePath: file.path),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Không thể truy cập thư viện ảnh. Vui lòng kiểm tra quyền truy cập.',
                        ),
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
              Icon(
              Ionicons.alert_circle_outline,
              size: 64,
              color: context.appColors.textHint,
            ),
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
      child: Column(
        children: [
          // Profile Hero Header
          _ProfileHeroHeader(
            displayName: displayName,
            email: user.email,
            avatarUrl: avatarUrl,
            roleText: roleText,
            isUpdatingAvatar: isUpdatingAvatar,
            onAvatarTap: onAvatarTap,
          ),

          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ModernStatsRow(
              totalBookings: stats.totalBookings,
              totalReviews: stats.totalReviews,
              averageRating: stats.averageRating,
            ),
          ),

          const SizedBox(height: 20),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _QuickActions(
              isPartner: stats.isPartner,
              partnerStatus: stats.partnerStatus,
            ),
          ),

          const SizedBox(height: 24),

          // Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _ModernMenuSection(
                  title: 'Tài khoản',
                  items: [
                    _ModernMenuItem(
                      icon: Ionicons.create_outline,
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF43A047),
                      title: 'Chỉnh sửa hồ sơ',
                      onTap: () => context.push(RouteNames.editProfile),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.wallet_outline,
                      iconBgColor: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFFF9800),
                      title: 'Ví của tôi',
                      subtitle: _formatCurrency(stats.walletBalance),
                      onTap: () => context.push(RouteNames.wallet),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.heart_outline,
                      iconBgColor: const Color(0xFFFCE4EC),
                      iconColor: const Color(0xFFE91E63),
                      title: 'Danh sách yêu thích',
                      onTap: () => context.push(RouteNames.favorites),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.star_outline,
                      iconBgColor: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFFFA000),
                      title: 'Đánh giá của tôi',
                      onTap: () => context.push(RouteNames.myReviews),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ModernMenuSection(
                  title: 'Bảo mật & Xác thực',
                  items: [
                    _ModernMenuItem(
                      icon: Ionicons.shield_checkmark_outline,
                      iconBgColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1976D2),
                      title: 'Xác minh danh tính (eKYC)',
                      subtitle: kycStatusText,
                      subtitleColor: isKycVerified
                          ? AppColors.success
                          : AppColors.warning,
                      onTap: () => context.push(RouteNames.kyc),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.call_outline,
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF43A047),
                      title: 'Liên hệ khẩn cấp',
                      onTap: () => context.push(RouteNames.emergencyContacts),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.lock_closed_outline,
                      iconBgColor: const Color(0xFFF3E5F5),
                      iconColor: const Color(0xFF7B1FA2),
                      title: 'Đổi mật khẩu',
                      onTap: () => context.push(RouteNames.changePassword),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _ModernMenuSection(
                  title: 'Cài đặt & Hỗ trợ',
                  items: [
                    _ModernMenuItem(
                      icon: Ionicons.cog_outline,
                      iconBgColor:   context.appColors.background,
                      iconColor: const Color(0xFF616161),
                      title: 'Cài đặt ứng dụng',
                      subtitle: 'Thông báo, giao diện, ngôn ngữ',
                      onTap: () => context.push(RouteNames.settings),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.help_circle_outline,
                      iconBgColor: const Color(0xFFE0F7FA),
                      iconColor: const Color(0xFF00ACC1),
                      title: 'Trung tâm trợ giúp',
                      onTap: () => context.push(RouteNames.helpCenter),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.document_text_outline,
                      iconBgColor:   context.appColors.background,
                      iconColor: const Color(0xFF616161),
                      title: 'Điều khoản sử dụng',
                      onTap: () => context.push(RouteNames.termsOfService),
                    ),
                    _ModernMenuItem(
                      icon: Ionicons.shield_checkmark_outline,
                      iconBgColor:   context.appColors.background,
                      iconColor: const Color(0xFF616161),
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
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(
                      Ionicons.log_out_outline,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Đăng xuất',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Mate Social v1.0.0',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.appColors.textHint,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Modern profile hero header with gradient background
class _ProfileHeroHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String roleText;
  final bool isUpdatingAvatar;
  final VoidCallback? onAvatarTap;

  const _ProfileHeroHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.roleText,
    this.isUpdatingAvatar = false,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.primaryLight,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              // Title row
              Row(
                children: [
                  Text(
                    'Cá nhân',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.settings),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.appColors.surface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Ionicons.cog_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Avatar
              GestureDetector(
                onTap: isUpdatingAvatar ? null : onAvatarTap,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.appColors.surface, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: context.appColors.textPrimary.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ImageUtils.buildImageUrl(avatarUrl!),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                errorWidget: (context, url, error) =>
                                    _DefaultAvatar(),
                              )
                            : _DefaultAvatar(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.appColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.textPrimary.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Ionicons.camera_outline,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                    if (isUpdatingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.appColors.textPrimary.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Name
              Text(
                displayName,
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                email,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 10),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleText,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.3),
      child: const Icon(Ionicons.person_outline, size: 42, color: Colors.white),
    );
  }
}

/// Modern stats row with individual cards
class _ModernStatsRow extends StatelessWidget {
  final int totalBookings;
  final int totalReviews;
  final double averageRating;

  const _ModernStatsRow({
    required this.totalBookings,
    required this.totalReviews,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.appColors.textPrimary.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModernStatItem(
                value: totalBookings.toString(),
                label: 'Lịch hẹn',
                icon: Ionicons.calendar_outline,
                color: const Color(0xFF3B82F6),
              ),
            ),
            Container(width: 1, height: 40, color: context.appColors.border),
            Expanded(
              child: _ModernStatItem(
                value: averageRating.toStringAsFixed(1),
                label: 'Đánh giá',
                icon: Ionicons.star,
                color: const Color(0xFFFFA000),
              ),
            ),
            Container(width: 1, height: 40, color: context.appColors.border),
            Expanded(
              child: _ModernStatItem(
                value: totalReviews.toString(),
                label: 'Nhận xét',
                icon: Ionicons.chatbubble_outline,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _ModernStatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.appColors.textSecondary,
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
                  isVerified
                      ? Ionicons.checkmark_done_outline
                      : Ionicons.time_outline,
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
                        color: context.appColors.textSecondary,
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
                color: context.appColors.textSecondary,
              ),
            ),
          ],
          if (isVerified) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ModernStatItem(
                    label: 'Đơn hàng',
                    value:
                        '${status.completedBookings}/${status.totalBookings}',
                    icon: Ionicons.bag_check_outline,
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _ModernStatItem(
                    label: 'Đánh giá',
                    value: status.averageRating.toStringAsFixed(1),
                    icon: Ionicons.star,
                    color: Colors.amber,
                  ),
                ),
                Expanded(
                  child: _ModernStatItem(
                    label: 'Reviews',
                    value: '${status.totalReviews}',
                    icon: Ionicons.chatbubble_outline,
                    color: AppColors.secondary,
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
                      status.isAvailable
                          ? Ionicons.eye_outline
                          : Ionicons.eye_off_outline,
                      size: 18,
                    ),
                    label: Text(
                      status.isAvailable ? 'Đang hoạt động' : 'Tạm nghỉ',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status.isAvailable
                          ? AppColors.success
                          : context.appColors.textSecondary,
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
        return AppColors.textSecondary;
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appColors.surface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
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

/// Modern menu section with clean design
class _ModernMenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ModernMenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.appColors.textPrimary.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 64, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Modern menu item with colored icon backgrounds
class _ModernMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;

  const _ModernMenuItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleColor ?? context.appColors.textSecondary,
                          fontWeight: subtitleColor != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Ionicons.chevron_forward_outline,
                  color: context.appColors.textHint,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
