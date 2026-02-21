import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../data/models/partner_profile_model.dart';

/// Hero header section with avatar, name, verification, and basic info
class PartnerDetailHeader extends StatelessWidget {
  final PartnerDetailResponse detail;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final VoidCallback? onImageTap;

  const PartnerDetailHeader({
    super.key,
    required this.detail,
    this.onBack,
    this.onShare,
    this.onFavorite,
    this.isFavorite = false,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SliverAppBar(
      expandedHeight: screenWidth * 1.1,
      pinned: true,
      stretch: true,
      backgroundColor: context.appColors.surface,
      leading: _buildCircleButton(
        context,
        icon: Ionicons.chevron_back,
        onTap: onBack ?? () => Navigator.of(context).pop(),
      ),
      actions: [
        _buildCircleButton(context, icon: Ionicons.share_outline, onTap: onShare),
        const SizedBox(width: 8),
        _buildCircleButton(
          context,
          icon: isFavorite ? Ionicons.heart : Ionicons.heart_outline,
          onTap: onFavorite,
          iconColor: isFavorite ? AppColors.error : Colors.white,
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: onImageTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Avatar image
              _buildAvatarImage(context),
              // Gradient overlay — pass through taps to the GestureDetector
              _buildGradientOverlay(),
              // Bottom info — pass through taps on empty areas
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: IgnorePointer(
                  child: _buildProfileInfo(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(BuildContext context) {
    final url = ImageUtils.buildImageUrlNullable(detail.avatarUrl);
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: context.appColors.background,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          color: context.appColors.background,
          child: const Icon(Ionicons.person, size: 80, color: AppColors.textHint),
        ),
      );
    }
    return Container(
      color: context.appColors.background,
      child: const Icon(Ionicons.person, size: 80, color: AppColors.textHint),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name + verification
        Row(
          children: [
            Expanded(
              child: Text(
                detail.displayName,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (detail.profile.isVerified) ...[
              const SizedBox(width: 8),
              _buildVerificationBadge(),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Age + Location
        Row(
          children: [
            if (detail.age != null) ...[
              Icon(Ionicons.calendar_outline, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${detail.age} tuổi',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              const SizedBox(width: 12),
            ],
            if (detail.location != null) ...[
              Icon(Ionicons.location_outline, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  detail.location!,
                  style:
                      AppTypography.bodyMedium.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Rating + Online status
        Row(
          children: [
            Icon(Ionicons.star, size: 16, color: AppColors.starFilled),
            const SizedBox(width: 4),
            Text(
              detail.profile.averageRating.toStringAsFixed(2),
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${detail.profile.totalReviews} đánh giá)',
              style: AppTypography.bodySmall.copyWith(color: Colors.white60),
            ),
            const Spacer(),
            _buildOnlineIndicator(),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationBadge() {
    final badge = detail.profile.verificationBadge;
    Color badgeColor;
    IconData badgeIcon;
    switch (badge) {
      case 'gold':
        badgeColor = const Color(0xFFFFD700);
        badgeIcon = Ionicons.shield_checkmark;
        break;
      case 'silver':
        badgeColor = const Color(0xFFC0C0C0);
        badgeIcon = Ionicons.shield_checkmark;
        break;
      default:
        badgeColor = AppColors.info;
        badgeIcon = Ionicons.checkmark_circle;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            'Xác minh',
            style: AppTypography.labelSmall.copyWith(color: badgeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    final isAvailable = detail.profile.isAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withOpacity(0.2)
            : AppColors.offline.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.success : AppColors.offline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'Sẵn sàng' : 'Không sẵn sàng',
            style: AppTypography.labelSmall.copyWith(
              color: isAvailable ? AppColors.success : AppColors.offline,
            ),
          ),
        ],
      ),
    );
  }
}
