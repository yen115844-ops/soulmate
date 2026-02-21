import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Verified badge styles
enum VerifiedBadgeStyle {
  /// Small icon only
  icon,
  /// Icon with "Đã xác thực" text
  iconWithText,
  /// Compact badge
  compact,
}

/// Verified Badge Widget - Blue tick for verified users
class VerifiedBadge extends StatelessWidget {
  final VerifiedBadgeStyle style;
  final double? iconSize;

  const VerifiedBadge({
    super.key,
    this.style = VerifiedBadgeStyle.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case VerifiedBadgeStyle.icon:
        return _buildIcon();
      case VerifiedBadgeStyle.iconWithText:
        return _buildIconWithText();
      case VerifiedBadgeStyle.compact:
        return _buildCompact();
    }
  }

  Widget _buildIcon() {
    return Icon(
      Ionicons.checkmark_circle,
      size: iconSize ?? 16,
      color: AppColors.verified,
    );
  }

  Widget _buildIconWithText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Ionicons.checkmark_circle,
          size: iconSize ?? 14,
          color: AppColors.verified,
        ),
        const SizedBox(width: 4),
        Text(
          'Đã xác thực',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.verified,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.verified.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Ionicons.shield_checkmark,
            size: iconSize ?? 12,
            color: AppColors.verified,
          ),
          const SizedBox(width: 4),
          Text(
            'Xác thực',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.verified,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Badge Widget - Gold crown for premium users
class PremiumBadge extends StatelessWidget {
  final PremiumBadgeStyle style;
  final double? iconSize;

  const PremiumBadge({
    super.key,
    this.style = PremiumBadgeStyle.icon,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case PremiumBadgeStyle.icon:
        return _buildIcon();
      case PremiumBadgeStyle.iconWithText:
        return _buildIconWithText();
      case PremiumBadgeStyle.compact:
        return _buildCompact();
      case PremiumBadgeStyle.banner:
        return _buildBanner();
    }
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.workspace_premium_rounded,
        size: iconSize ?? 12,
        color: Colors.white,
      ),
    );
  }

  Widget _buildIconWithText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(),
        const SizedBox(width: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ).createShader(bounds),
          child: Text(
            'Premium',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: iconSize ?? 10,
            color: Colors.white,
          ),
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
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: iconSize ?? 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'Premium',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium badge styles
enum PremiumBadgeStyle {
  /// Small icon only
  icon,
  /// Icon with "Premium" text
  iconWithText,
  /// Compact badge
  compact,
  /// Banner style
  banner,
}
