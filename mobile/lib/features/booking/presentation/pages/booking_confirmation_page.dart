import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_button.dart';

/// Hiển thị sau khi tạo booking thành công
class BookingConfirmationPage extends StatelessWidget {
  /// Booking ID vừa tạo (từ extra khi navigate)
  final String? bookingId;
  final String? bookingCode;

  const BookingConfirmationPage({
    super.key,
    this.bookingId,
    this.bookingCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Ionicons.checkmark_circle_outline,
                  size: 64,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Đặt lịch thành công!',
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (bookingCode != null && bookingCode!.isNotEmpty)
                Text(
                  'Mã đặt lịch: $bookingCode',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Partner sẽ xác nhận lịch hẹn của bạn. Bạn có thể xem chi tiết và trạng thái trong mục Đặt lịch.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (bookingId != null && bookingId!.isNotEmpty)
                AppButton(
                  text: 'Xem chi tiết đặt lịch',
                  icon: Ionicons.document_text_outline,
                  onPressed: () => context.push('/booking/$bookingId'),
                ),
              if (bookingId != null && bookingId!.isNotEmpty) const SizedBox(height: 12),
              AppButton(
                text: 'Về trang chủ',
                isOutlined: true,
                onPressed: () => context.go(RouteNames.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
