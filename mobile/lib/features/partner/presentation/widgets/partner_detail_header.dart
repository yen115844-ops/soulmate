import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/services/app_image_cache_manager.dart';
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
  final ValueChanged<int>? onImageTap;

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
    final headerImages = _buildHeaderImages();

    return SliverAppBar(
      expandedHeight: screenWidth * 1.1 + 150,
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
        background: Column(
          children: [
            Expanded(
              child: SizedBox.expand(
                child: _buildImageCarousel(context, headerImages),
              ),
            ),
            Container(
              width: double.infinity,
              color: context.appColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: _buildProfileInfo(context, onImageBackground: false),
            ),
          ],
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

  List<String> _buildHeaderImages() {
    final allPhotos = <String>[];
    allPhotos.addAll(detail.photos.where((p) => p.trim().isNotEmpty));
    if (detail.avatarUrl != null && detail.avatarUrl!.trim().isNotEmpty) {
      allPhotos.add(detail.avatarUrl!);
    }
    return allPhotos.toSet().toList();
  }

  Widget _buildImageCarousel(BuildContext context, List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: context.appColors.background,
        child: const Icon(Ionicons.person, size: 80, color: AppColors.textHint),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            final url = ImageUtils.buildImageUrlNullable(images[index]);
            return GestureDetector(
              onTap: () => onImageTap?.call(index),
              child: url != null && url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      cacheManager: AppImageCacheManager.instance,
                      fit: BoxFit.cover,
                      memCacheWidth: 1080,
                      memCacheHeight: 1440,
                      maxWidthDiskCache: 1080,
                      maxHeightDiskCache: 1440,
                      fadeInDuration: Duration.zero,
                      placeholderFadeInDuration: Duration.zero,
                      useOldImageOnUrlChange: true,
                      placeholder: (_, __) => Container(
                        color: context.appColors.background,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: context.appColors.background,
                        child: const Icon(
                          Ionicons.image_outline,
                          size: 56,
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  : Container(
                      color: context.appColors.background,
                      child: const Icon(
                        Ionicons.image_outline,
                        size: 56,
                        color: AppColors.textHint,
                      ),
                    ),
            );
          },
        ),
        if (images.length > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${images.length} ảnh',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context, {required bool onImageBackground}) {
    final primaryColor = onImageBackground
        ? Colors.white
        : context.appColors.textPrimary;
    final secondaryColor = onImageBackground
        ? Colors.white70
        : context.appColors.textSecondary;
    final tertiaryColor = onImageBackground
        ? Colors.white60
        : context.appColors.textHint;

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
                  color: primaryColor,
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
              Icon(Ionicons.calendar_outline, size: 14, color: secondaryColor),
              const SizedBox(width: 4),
              Text(
                '${detail.age} tuổi',
                style: AppTypography.bodyMedium.copyWith(color: secondaryColor),
              ),
              const SizedBox(width: 12),
            ],
            if (detail.location != null) ...[
              Icon(Ionicons.location_outline, size: 14, color: secondaryColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  detail.location!,
                  style: AppTypography.bodyMedium.copyWith(color: secondaryColor),
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
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${detail.profile.totalReviews} đánh giá)',
              style: AppTypography.bodySmall.copyWith(color: tertiaryColor),
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
