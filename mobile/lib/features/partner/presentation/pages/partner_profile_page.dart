import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/service_type_emoji.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/partner_repository.dart';
import '../bloc/partner_profile_bloc.dart';
import '../bloc/partner_profile_event.dart';
import '../bloc/partner_profile_state.dart';

class PartnerProfilePage extends StatelessWidget {
  const PartnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PartnerProfileBloc(partnerRepository: getIt<PartnerRepository>())
            ..add(const PartnerProfileLoadRequested()),
      child: const _PartnerProfileContent(),
    );
  }
}

class _PartnerProfileContent extends StatelessWidget {
  const _PartnerProfileContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Partner'),
        actions: [
          IconButton(
            onPressed: () => _showSettingsMenu(context),
            icon: const Icon(Ionicons.cog_outline),
          ),
        ],
      ),
      body: BlocBuilder<PartnerProfileBloc, PartnerProfileState>(
        builder: (context, state) {
          if (state is PartnerProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PartnerProfileError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<PartnerProfileBloc>().add(
                  const PartnerProfileLoadRequested(),
                );
              },
            );
          }

          if (state is PartnerProfileLoaded ||
              state is PartnerProfileUpdating) {
            final profile = state is PartnerProfileLoaded
                ? state.profile
                : (state as PartnerProfileUpdating).profile;
            final userProfile = state is PartnerProfileLoaded
                ? state.userProfile
                : (state as PartnerProfileUpdating).userProfile;
            final isUpdating = state is PartnerProfileUpdating;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PartnerProfileBloc>().add(
                  const PartnerProfileRefreshRequested(),
                );
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _ProfileHeader(
                      profile: profile,
                      userProfile: userProfile,
                      isUpdating: isUpdating,
                    ),

                    // Stats
                    _StatsSection(profile: profile),

                    const Divider(height: 32),

                    // Basic Info Section
                    _SectionTitle(
                      title: 'Thông tin cơ bản',
                      actionText: 'Chỉnh sửa',
                      onAction: () => _showEditBasicInfo(context, profile),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Ionicons.person_outline,
                            label: 'Tên hiển thị',
                            value:
                                userProfile?.displayName ??
                                userProfile?.fullName ??
                                'Chưa cập nhật',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Ionicons.cash_outline,
                            label: 'Giá theo giờ',
                            value: _formatCurrency(profile.hourlyRate),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Ionicons.time_outline,
                            label: 'Thời gian tối thiểu',
                            value: '${profile.minimumHours} giờ',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giới thiệu',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.introduction ?? 'Chưa có mô tả',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Photos Section
                    _SectionTitle(
                      title: 'Ảnh của bạn',
                      actionText: 'Quản lý',
                      onAction: () =>
                          _showPhotoManager(context, userProfile?.photos ?? []),
                    ),
                    _PhotosGrid(photos: userProfile?.photos ?? []),

                    const SizedBox(height: 24),

                    // Services Section
                    _SectionTitle(
                      title: 'Dịch vụ cung cấp',
                      actionText: 'Chỉnh sửa',
                      onAction: () =>
                          _showEditServices(context, profile.serviceTypes),
                    ),
                    _ServicesGrid(serviceTypes: profile.serviceTypes),

                    const SizedBox(height: 24),

                    // Schedule Settings
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _MenuCard(
                        icon: Ionicons.calendar_outline,
                        title: 'Cài đặt lịch làm việc',
                        subtitle: 'Quản lý thời gian rảnh của bạn',
                        onTap: () => context.push(
                          RouteNames.partnerAvailabilitySettings,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bank Account
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _MenuCard(
                        icon: Ionicons.business_outline,
                        title: 'Tài khoản ngân hàng',
                        subtitle: 'Quản lý thông tin thanh toán',
                        onTap: () => _showBankAccountSettings(context),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Switch to User Mode
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go(RouteNames.home);
                        },
                        icon: const Icon(Ionicons.refresh_outline),
                        label: const Text('Chuyển về chế độ Người dùng'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ/giờ';
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Ionicons.eye_outline),
              title: const Text('Xem hồ sơ công khai'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Preview public profile
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.notifications_outline),
              title: const Text('Cài đặt thông báo'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.settings);
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.shield_checkmark_outline),
              title: const Text('Xác minh danh tính'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RouteNames.kyc);
              },
            ),
            ListTile(
              leading: Icon(Ionicons.close_circle_outline, color: AppColors.error),
              title: Text(
                'Tạm ngừng hoạt động Partner',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showPausePartnerDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPausePartnerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạm ngừng hoạt động?'),
        content: const Text(
          'Khi tạm ngừng, bạn sẽ không nhận được các lượt đặt lịch mới. Bạn có thể bật lại bất cứ lúc nào.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PartnerProfileBloc>().add(
                const PartnerAvailabilityToggleRequested(isAvailable: false),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tạm ngừng'),
          ),
        ],
      ),
    );
  }

  void _showEditBasicInfo(
    BuildContext context,
    PartnerProfileResponse profile,
  ) {
    final hourlyRateController = TextEditingController(
      text: profile.hourlyRate.toInt().toString(),
    );
    final introController = TextEditingController(
      text: profile.introduction ?? '',
    );
    final minHoursController = TextEditingController(
      text: profile.minimumHours.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chỉnh sửa thông tin', style: AppTypography.titleLarge),
            const SizedBox(height: 24),
            AppTextField(
              controller: hourlyRateController,
              label: 'Giá theo giờ (VNĐ)',
              hint: 'Nhập giá',
              prefixIcon: Ionicons.cash_outline,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: minHoursController,
              label: 'Thời gian tối thiểu (giờ)',
              hint: 'Nhập số giờ',
              prefixIcon: Ionicons.time_outline,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: introController,
              label: 'Giới thiệu',
              hint: 'Viết vài dòng giới thiệu về bản thân',
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Lưu thay đổi',
              onPressed: () {
                final hourlyRate = int.tryParse(hourlyRateController.text);
                final minHours = int.tryParse(minHoursController.text);

                context.read<PartnerProfileBloc>().add(
                  PartnerProfileUpdateRequested(
                    hourlyRate: hourlyRate,
                    minimumHours: minHours,
                    introduction: introController.text.isNotEmpty
                        ? introController.text
                        : null,
                  ),
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServices(BuildContext context, List<String> currentServices) {
    final allServices = ServiceTypeEmoji.all
        .where((s) => s.code != null)
        .map((s) => {'id': s.code!, 'name': s.nameVi, 'emoji': s.emoji})
        .toList();

    List<String> selectedServices = List.from(currentServices);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chọn dịch vụ', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Chọn các dịch vụ bạn muốn cung cấp',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: allServices.length,
                  itemBuilder: (context, index) {
                    final service = allServices[index];
                    final isSelected = selectedServices.contains(service['id']);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selectedServices.remove(service['id']);
                          } else {
                            selectedServices.add(service['id'] as String);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(25)
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              service['emoji'] as String,
                              style: TextStyle(
                                fontSize: 20,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              service['name'] as String,
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Lưu thay đổi',
                onPressed: () {
                  context.read<PartnerProfileBloc>().add(
                    PartnerProfileUpdateRequested(
                      serviceTypes: selectedServices,
                    ),
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoManager(BuildContext context, List<String> photos) {
    context.push(RouteNames.partnerPhotoManager, extra: photos).then((result) {
      // Refresh profile if photos were changed
      if (result == true && context.mounted) {
        context.read<PartnerProfileBloc>().add(
          const PartnerProfileLoadRequested(),
        );
      }
    });
  }

  void _showBankAccountSettings(BuildContext context) {
    context.push(RouteNames.partnerBankAccount).then((result) {
      // Refresh profile if bank info was changed
      if (result == true && context.mounted) {
        context.read<PartnerProfileBloc>().add(
          const PartnerProfileLoadRequested(),
        );
      }
    });
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
              style: AppTypography.bodyMedium.copyWith(
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

class _ProfileHeader extends StatelessWidget {
  final PartnerProfileResponse profile;
  final PartnerUserProfileInfo? userProfile;
  final bool isUpdating;

  const _ProfileHeader({
    required this.profile,
    this.userProfile,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = userProfile?.avatarUrl;
    final displayName =
        userProfile?.displayName ?? userProfile?.fullName ?? 'Partner';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Builder(
                builder: (context) {
                  final fullAvatarUrl = ImageUtils.buildImageUrlNullable(
                    avatarUrl,
                  );

                  return CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withAlpha(25),
                    backgroundImage:
                        fullAvatarUrl != null && fullAvatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(fullAvatarUrl)
                        : null,
                    child: fullAvatarUrl == null || fullAvatarUrl.isEmpty
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'P',
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  );
                },
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: profile.isAvailable
                        ? AppColors.success
                        : AppColors.textHint,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Ionicons.checkmark_done_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.isAvailable ? 'Đang hoạt động' : 'Tạm nghỉ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: profile.isAvailable
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Toggle availability
          if (isUpdating)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: profile.isAvailable,
              onChanged: (value) {
                context.read<PartnerProfileBloc>().add(
                  PartnerAvailabilityToggleRequested(isAvailable: value),
                );
              },
              activeColor: AppColors.success,
            ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final PartnerProfileResponse profile;

  const _StatsSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '${profile.totalBookings}',
              label: 'Đơn hàng',
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _StatItem(
              value: profile.averageRating.toStringAsFixed(1),
              label: 'Đánh giá',
              icon: Ionicons.star_outline,
              iconColor: Colors.amber,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
            child: _StatItem(
              value: '${profile.totalReviews}',
              label: 'Reviews',
            ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _PhotosGrid extends StatelessWidget {
  final List<String> photos;

  const _PhotosGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Ionicons.image_outline, color: AppColors.textHint, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Chưa có ảnh nào',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          final imageUrl = ImageUtils.buildImageUrl(photo);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 100,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 120,
                  color: AppColors.backgroundLight,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 120,
                  color: AppColors.backgroundLight,
                  child: const Icon(Ionicons.image_outline),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final List<String> serviceTypes;

  const _ServicesGrid({required this.serviceTypes});

  // Dùng ServiceTypeEmoji - đồng bộ với seed/CMS

  @override
  Widget build(BuildContext context) {
    if (serviceTypes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Chưa chọn dịch vụ nào',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: serviceTypes.map((serviceId) {
          final display = ServiceTypeEmoji.get(serviceId);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(display.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  display.nameVi,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.titleMedium),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Ionicons.chevron_forward_outline,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
