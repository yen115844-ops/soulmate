import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/image_utils.dart';

/// Booking Card - For bookings list
class BookingCard extends StatelessWidget {
  final String id;
  final String partnerName;
  final String partnerAvatar;
  final String service;
  final String date;
  final String time;
  final String status;
  final int totalAmount;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.id,
    required this.partnerName,
    required this.partnerAvatar,
    required this.service,
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
      case 'paid':
        return AppColors.info;
      case 'ongoing':
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String get _statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'paid':
        return 'Đã thanh toán';
      case 'ongoing':
      case 'in_progress':
        return 'Đang diễn ra';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return status;
    }
  }

  IconData get _statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
        return Ionicons.time_outline;
      case 'confirmed':
      case 'paid':
        return Ionicons.checkmark_circle_outline;
      case 'ongoing':
      case 'in_progress':
        return Ionicons.play_circle_outline;
      case 'completed':
        return Ionicons.checkmark_done_outline;
      case 'cancelled':
      case 'rejected':
        return Ionicons.close_circle_outline;
      default:
        return Ionicons.information_circle_outline;
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/booking/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon, size: 18, color: _statusColor),
                  const SizedBox(width: 8),
                  Text(
                    _statusText,
                    style: AppTypography.labelMedium.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${id.substring(0, 8).toUpperCase()}',
                    style: AppTypography.labelSmall.copyWith(
                      color: context.appColors.textHint,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Partner Info
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: ImageUtils.buildImageUrl(partnerAvatar),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: context.appColors.background,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: context.appColors.background,
                              child: const Icon(Ionicons.person_outline),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partnerName,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatPrice(totalAmount)}đ',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.appColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:   Icon(
                                Ionicons.calendar_outline,
                                size: 18,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: context.appColors.textHint,
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: context.appColors.border,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.appColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:   Icon(
                                Ionicons.time_outline,
                                size: 18,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thời gian',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: context.appColors.textHint,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}

/// Mini Booking Card - For upcoming booking on home
class MiniBookingCard extends StatelessWidget {
  final String id;
  final String partnerName;
  final String partnerAvatar;
  final String service;
  final String date;
  final String time;
  final VoidCallback? onTap;

  const MiniBookingCard({
    super.key,
    required this.id,
    required this.partnerName,
    required this.partnerAvatar,
    required this.service,
    required this.date,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/booking/$id'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Ionicons.calendar_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lịch hẹn sắp tới',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(partnerAvatar),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.white24,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white24,
                        child: const Icon(Ionicons.person_outline, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerName,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$service • $date • $time',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.appColors.surface.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Ionicons.chevron_forward_outline,
                    color: Colors.white,
                    size: 20,
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
