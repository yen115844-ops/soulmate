import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/image_utils.dart';

/// Partner Card - Horizontal style for featured/recommendations
class PartnerCard extends StatelessWidget {
  final String id;
  final String name;
  final int age;
  final String avatarUrl;
  final double rating;
  final int reviews;
  final String hourlyRate;
  final bool isOnline;
  final bool isVerified;
  final String? distance;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const PartnerCard({
    super.key,
    required this.id,
    required this.name,
    required this.age,
    required this.avatarUrl,
    required this.rating,
    required this.reviews,
    required this.hourlyRate,
    this.isOnline = false,
    this.isVerified = false,
    this.distance,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/partner/$id'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appColors.border),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Stack(
              children: [
                // Avatar
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(avatarUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.appColors.background,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: context.appColors.background,
                        child: const Icon(Ionicons.person_outline, size: 40),
                      ),
                    ),
                  ),
                ),

                // Online indicator
                if (isOnline)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration:   BoxDecoration(
                              color: context.appColors.surface,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Online',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.appColors.surface.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Ionicons.heart_outline,
                        size: 18,
                        color: isFavorite
                            ? AppColors.error
                            : context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                // Distance badge
                if (distance != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.textSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Ionicons.location_outline,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance!,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name, $age',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        const Icon(
                          Ionicons.checkmark_done_outline,
                          size: 18,
                          color: AppColors.info,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Ionicons.star_outline,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviews)',
                        style: AppTypography.labelSmall.copyWith(
                          color: context.appColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '$hourlyRate/giờ',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Partner List Item - Vertical style for search results
class PartnerListItem extends StatelessWidget {
  final String id;
  final String name;
  final int age;
  final String avatarUrl;
  final double rating;
  final int reviews;
  final int hourlyRate;
  final List<String> services;
  final bool isOnline;
  final bool isVerified;
  final double distance;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const PartnerListItem({
    super.key,
    required this.id,
    required this.name,
    required this.age,
    required this.avatarUrl,
    required this.rating,
    required this.reviews,
    required this.hourlyRate,
    required this.services,
    this.isOnline = false,
    this.isVerified = false,
    required this.distance,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/partner/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(avatarUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: context.appColors.background),
                      errorWidget: (context, url, error) => Container(
                        color: context.appColors.background,
                        child: const Icon(Ionicons.person_outline),
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.appColors.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Verified
                  Row(
                    children: [
                      Text(
                        '$name, $age',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Ionicons.checkmark_done_outline,
                          size: 16,
                          color: AppColors.info,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating & Distance
                  Row(
                    children: [
                      const Icon(
                        Ionicons.star_outline,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)} ($reviews)',
                        style: AppTypography.labelSmall.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                        Icon(
                        Ionicons.location_outline,
                        size: 14,
                        color: context.appColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: AppTypography.labelSmall.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Services
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: services.take(3).map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Price & Favorite
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onFavorite,
                  child: Icon(
                    isFavorite ? Icons.favorite : Ionicons.heart_outline,
                    size: 22,
                    color: isFavorite ? AppColors.error : context.appColors.textHint,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_formatPrice(hourlyRate)}đ',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/giờ',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.appColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}
