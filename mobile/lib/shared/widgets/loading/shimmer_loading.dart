import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';

/// Shimmer Loading Widget for skeleton screens
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.backgroundLight,
      child: child,
    );
  }
}

/// Shimmer Box - Basic rectangular shimmer
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer Circle - For avatars
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Partner Card Shimmer
class PartnerCardShimmer extends StatelessWidget {
  const PartnerCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            const Center(child: ShimmerCircle(size: 80)),
            const SizedBox(height: 12),
            // Name
            const ShimmerBox(height: 16, width: 100),
            const SizedBox(height: 8),
            // Rating
            const ShimmerBox(height: 12, width: 60),
            const SizedBox(height: 8),
            // Price
            const ShimmerBox(height: 14, width: 80),
          ],
        ),
      ),
    );
  }
}

/// Partner List Item Shimmer
class PartnerListItemShimmer extends StatelessWidget {
  const PartnerListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const ShimmerCircle(size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 18, width: 120),
                  const SizedBox(height: 8),
                  const ShimmerBox(height: 14, width: 80),
                  const SizedBox(height: 8),
                  const ShimmerBox(height: 14, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Booking Card Shimmer
class BookingCardShimmer extends StatelessWidget {
  const BookingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerCircle(size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerBox(height: 16, width: 100),
                      const SizedBox(height: 6),
                      const ShimmerBox(height: 12, width: 70),
                    ],
                  ),
                ),
                const ShimmerBox(height: 24, width: 80, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 16),
            const ShimmerBox(height: 14),
            const SizedBox(height: 8),
            const ShimmerBox(height: 14, width: 200),
          ],
        ),
      ),
    );
  }
}

/// Chat Item Shimmer
class ChatItemShimmer extends StatelessWidget {
  const ChatItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const ShimmerCircle(size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 16, width: 120),
                  const SizedBox(height: 6),
                  const ShimmerBox(height: 12, width: 180),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const ShimmerBox(height: 10, width: 40),
                const SizedBox(height: 6),
                const ShimmerCircle(size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer List - Generates multiple shimmer items
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
