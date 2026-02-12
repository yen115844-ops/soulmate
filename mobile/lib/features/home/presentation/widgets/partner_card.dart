import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../partner/domain/entities/partner_entity.dart';

/// Modern Partner Card — Mioto-style listing
class PartnerCard extends StatelessWidget {
  final PartnerEntity partner;

  const PartnerCard({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.appColors.textPrimary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          _buildImageSection(context),

          // Info section
          _buildInfoSection(context, priceFormat),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Hero(
              tag: 'partner_${partner.id}',
              child: CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(
                  partner.gallery.isNotEmpty
                      ? partner.gallery.first
                      : partner.avatarUrl,
                ),
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: context.appColors.border,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: context.appColors.border,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: context.appColors.textHint,
                  ),
                ),
              ),
            ),
          ),
          // Top badges
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                if (partner.isOnline)
                  const _Badge(
                    text: 'Online',
                    color: Color(0xFF00C851),
                    icon: Icons.circle,
                    iconSize: 6,
                  ),
                if (partner.isPremium) ...[
                  if (partner.isOnline) const SizedBox(width: 6),
                  const _Badge(
                    text: 'Premium',
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                  ),
                ],
                const Spacer(),
                // Favorite button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.appColors.surface.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            context.appColors.textPrimary.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Ionicons.heart_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          // Verified badge
          if (partner.isVerified)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Ionicons.shield_checkmark,
                      size: 14,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đã xác minh',
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, NumberFormat priceFormat) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Rating row
          Row(
            children: [
              Expanded(
                child: Text(
                  '${partner.name}, ${partner.age}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Ionicons.star,
                      size: 14,
                      color: Color(0xFFFFA000),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      partner.rating.toStringAsFixed(1),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFA000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Location + distance
          if (partner.location != null || partner.distance != null)
            Row(
              children: [
                Icon(
                  Ionicons.location_outline,
                  size: 14,
                  color: context.appColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      if (partner.location != null) partner.location!,
                      if (partner.distance != null) partner.formattedDistance,
                    ].join(' • '),
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Services tags
          if (partner.services.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: partner.services.take(3).map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // Divider
          Container(height: 1, color: context.appColors.border),

          const SizedBox(height: 10),

          // Bottom row: stats + price
          Row(
            children: [
              Icon(
                Ionicons.chatbubble_outline,
                size: 14,
                color: context.appColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${partner.reviewCount} đánh giá',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Ionicons.checkmark_circle_outline,
                size: 14,
                color: context.appColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${partner.completedBookings} chuyến',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Price
              Text(
                priceFormat.format(partner.hourlyRate),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
              Text(
                '/giờ',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge widget for partner cards
class _Badge extends StatelessWidget {
  final String text;
  final Color? color;
  final Gradient? gradient;
  final IconData? icon;
  final double? iconSize;

  const _Badge({
    required this.text,
    this.color,
    this.gradient,
    this.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.primary) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: iconSize ?? 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
