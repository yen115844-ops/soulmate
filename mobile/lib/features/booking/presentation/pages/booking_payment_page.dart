import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/booking_repository.dart';
import '../../domain/entities/booking_entity.dart';

/// Thanh toán cho booking (ví, v.v.)
class BookingPaymentPage extends StatefulWidget {
  final String bookingId;

  const BookingPaymentPage({super.key, required this.bookingId});

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  BookingEntity? _booking;
  bool _isLoading = true;
  String? _errorMessage;

  BookingRepository get _bookingRepository => getIt<BookingRepository>();

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final b = await _bookingRepository.getBookingById(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = b;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải thông tin lịch hẹn';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Thanh toán'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Thanh toán'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Ionicons.alert_circle_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Không tìm thấy lịch hẹn'),
              const SizedBox(height: 16),
              AppButton(text: 'Thử lại', onPressed: _loadBooking),
            ],
          ),
        ),
      );
    }

    final b = _booking!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Thanh toán'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.partnerName, style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(b.serviceType, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '${dateFormat.format(b.startTime)} • ${timeFormat.format(b.startTime)} - ${timeFormat.format(b.endTime)}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng thanh toán', style: AppTypography.titleMedium),
                Text(
                  _formatCurrency(b.totalAmount),
                  style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Thanh toán bằng ví',
              icon: Ionicons.wallet_outline,
              onPressed: () {
                context.push(RouteNames.wallet);
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Quay lại chi tiết lịch hẹn',
              isOutlined: true,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
