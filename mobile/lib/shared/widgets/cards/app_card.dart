import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_utils.dart';

/// Partner Card - Main card for displaying partner info
class PartnerCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double rating;
  final int reviewCount;
  final String hourlyRate;
  final List<String> services;
  final bool isOnline;
  final bool isVerified;
  final String? distance;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const PartnerCard({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.hourlyRate,
    required this.services,
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
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: ImageUtils.buildImageUrl(avatarUrl ?? ''),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(height: 180, color: AppColors.shimmerBase),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: AppColors.backgroundLight,
                      child: const Icon(
                        Ionicons.person_outline,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                // Online Status
                if (isOnline)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.textWhite,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.textWhite.withAlpha(230),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Ionicons.heart_outline : Ionicons.heart_outline,
                        color: isFavorite
                            ? AppColors.error
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Verified Badge
                if (isVerified)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Ionicons.checkmark_done_outline,
                            color: AppColors.textWhite,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đã xác thực',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textWhite,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Ionicons.star_outline,
                        color: AppColors.starFilled,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' ($reviewCount)',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Distance
                  if (distance != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Ionicons.location_outline,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(distance!, style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Services
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: services.take(3).map((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getServiceColor(
                            service,
                          ).withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          service,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.getServiceColor(service),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(hourlyRate, style: AppTypography.price),
                      Text('/giờ', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

/// Compact Partner Card - For horizontal list
class PartnerCardCompact extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double rating;
  final String hourlyRate;
  final bool isOnline;
  final VoidCallback? onTap;

  const PartnerCardCompact({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.rating,
    required this.hourlyRate,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: ImageUtils.buildImageUrl(avatarUrl ?? ''),
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(height: 130, color: AppColors.shimmerBase),
                    errorWidget: (context, url, error) => Container(
                      height: 130,
                      color: AppColors.backgroundLight,
                      child: const Icon(
                        Ionicons.person_outline,
                        size: 32,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Ionicons.star_outline,
                        color: AppColors.starFilled,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hourlyRate,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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

/// Service Card
class ServiceCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;

  const ServiceCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Booking Card
class BookingCard extends StatelessWidget {
  final String partnerName;
  final String? partnerAvatar;
  final String serviceType;
  final String date;
  final String time;
  final String status;
  final String totalAmount;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.partnerName,
    this.partnerAvatar,
    required this.serviceType,
    required this.date,
    required this.time,
    required this.status,
    required this.totalAmount,
    this.onTap,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'in_progress':
        return 'Đang diễn ra';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundImage: partnerAvatar != null
                      ? CachedNetworkImageProvider(partnerAvatar!)
                      : null,
                  backgroundColor: AppColors.backgroundLight,
                  child: partnerAvatar == null
                      ? const Icon(Ionicons.person_outline, color: AppColors.textHint)
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partnerName, style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getServiceColor(
                            serviceType,
                          ).withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          serviceType,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.getServiceColor(serviceType),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText,
                    style: AppTypography.labelSmall.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                // Date
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Ionicons.calendar_outline,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(date, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                // Time
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Ionicons.time_outline,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                // Amount
                Text(totalAmount, style: AppTypography.price),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
