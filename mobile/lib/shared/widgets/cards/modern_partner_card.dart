import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../features/partner/domain/entities/partner_entity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_utils.dart';

/// Modern Partner Card - Featured style with glassmorphism
class ModernPartnerCard extends StatefulWidget {
  final PartnerEntity partner;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double? width;
  final double? height;

  const ModernPartnerCard({
    super.key,
    required this.partner,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.width,
    this.height,
  });

  @override
  State<ModernPartnerCard> createState() => _ModernPartnerCardState();
}

class _ModernPartnerCardState extends State<ModernPartnerCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap:
          widget.onTap ?? () => context.push('/partner/${widget.partner.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width ?? 200,
        height: widget.height ?? 280,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(_isPressed ? 0.1 : 0.2),
              blurRadius: _isPressed ? 10 : 20,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(widget.partner.avatarUrl),
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: context.appColors.background,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: context.appColors.background,
                  child: Icon(
                    Ionicons.person_outline,
                    size: 48,
                    color: context.appColors.textHint,
                  ),
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Premium Badge
              if (widget.partner.isPremium)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Ionicons.ribbon_outline, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Online Status
              if (widget.partner.isOnline)
                Positioned(
                  top: widget.partner.isPremium ? 44 : 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
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
                            fontWeight: FontWeight.w600,
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
                  onTap: widget.onFavorite,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.appColors.textPrimary.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(
                      widget.isFavorite ? Icons.favorite : Ionicons.heart_outline,
                      size: 18,
                      color: widget.isFavorite ? AppColors.error : Colors.white,
                    ),
                  ),
                ),
              ),

              // Bottom Info
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Age & Verified
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.partner.name}, ${widget.partner.age}',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.partner.isVerified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.info.withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating & Price
                    Row(
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.surface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.starFilled,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.partner.rating.toStringAsFixed(1),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Distance
                        if (widget.partner.distance != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.surface.withOpacity(0.2),
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
                                  widget.partner.formattedDistance,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        // Price
                        Text(
                          '${widget.partner.formattedHourlyRate}/h',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Partner Card - Grid style
class CompactPartnerCard extends StatelessWidget {
  final PartnerEntity partner;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double? height;

  const CompactPartnerCard({
    super.key,
    required this.partner,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/partner/${partner.id}'),
      child: Container(
        height: height ?? 240,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(partner.avatarUrl),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: context.appColors.background),
                      errorWidget: (_, __, ___) => Container(
                        color: context.appColors.background,
                        child: const Icon(Ionicons.person_outline),
                      ),
                    ),
                  ),
                  // Gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Online status
                  if (partner.isOnline)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.appColors.surface, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.appColors.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Ionicons.heart_outline,
                          size: 16,
                          color: isFavorite
                              ? AppColors.error
                              : context.appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.textPrimary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.starFilled,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            partner.rating.toStringAsFixed(1),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            partner.name,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (partner.isVerified)
                          const Icon(
                            Ionicons.checkmark_done_outline,
                            size: 16,
                            color: AppColors.info,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${partner.age} tuổi${partner.location != null ? ' • ${partner.location}' : ''}',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.appColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${partner.formattedHourlyRate}/h',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (partner.distance != null) ...[
                          const Spacer(),
                          Icon(
                            Ionicons.location_outline,
                            size: 12,
                            color: context.appColors.textHint,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            partner.formattedDistance,
                            style: AppTypography.labelSmall.copyWith(
                              color: context.appColors.textHint,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List Style Partner Card - Horizontal card for lists
class ListPartnerCard extends StatelessWidget {
  final PartnerEntity partner;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const ListPartnerCard({
    super.key,
    required this.partner,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/partner/${partner.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.border),
          boxShadow: [
            BoxShadow(
              color: context.appColors.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(partner.avatarUrl),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: context.appColors.background),
                      errorWidget: (_, __, ___) => Container(
                        color: context.appColors.background,
                        child: const Icon(Ionicons.person_outline),
                      ),
                    ),
                  ),
                ),
                if (partner.isOnline)
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${partner.name}, ${partner.age}',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (partner.isVerified)
                        const Icon(
                          Ionicons.checkmark_done_outline,
                          size: 16,
                          color: AppColors.info,
                        ),
                      if (partner.isPremium) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Ionicons.ribbon_outline,
                          size: 16,
                          color: Color(0xFFFFD700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.starFilled,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${partner.rating} (${partner.reviewCount})',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      if (partner.distance != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Ionicons.location_outline,
                          size: 12,
                          color: context.appColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          partner.formattedDistance,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Services
                  if (partner.services.isNotEmpty)
                    SizedBox(
                      height: 24,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: partner.services.take(3).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              partner.services[index],
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
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
                const SizedBox(height: 20),
                Text(
                  '${partner.formattedHourlyRate}/h',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
