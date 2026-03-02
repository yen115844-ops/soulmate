import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/booking_repository.dart';
import '../../domain/entities/booking_entity.dart';

class BookingDetailPage extends StatefulWidget {
  final String? bookingId;

  const BookingDetailPage({super.key, this.bookingId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  BookingRepository get _bookingRepository => getIt<BookingRepository>();
  bool _isLoading = true;
  String? _errorMessage;
  BookingEntity? _booking;

  String get _statusText {
    if (_booking == null) return '';
    return _booking!.statusText;
  }

  Color get _statusColor {
    if (_booking == null) return context.appColors.textSecondary;
    switch (_booking!.status) {
      case 'PENDING':
        return AppColors.warning;
      case 'CONFIRMED':
        return AppColors.info;
      case 'PAID': // Legacy - now treated as confirmed
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
      case 'REJECTED':
        return AppColors.error;
      default:
        return context.appColors.textSecondary;
    }
  }

  IconData get _statusIcon {
    if (_booking == null) return Ionicons.information_circle_outline;
    switch (_booking!.status) {
      case 'PENDING':
        return Ionicons.time_outline;
      case 'CONFIRMED':
        return Ionicons.checkmark_circle_outline;
      case 'PAID': // Legacy - now treated as confirmed
        return Ionicons.checkmark_circle_outline;
      case 'IN_PROGRESS':
        return Ionicons.play_circle_outline;
      case 'COMPLETED':
        return Ionicons.checkmark_done_outline;
      case 'CANCELLED':
      case 'REJECTED':
        return Ionicons.close_circle_outline;
      default:
        return Ionicons.information_circle_outline;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _loadBookingDetail();
    }
  }

  Future<void> _loadBookingDetail() async {
    if (widget.bookingId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final booking = await _bookingRepository.getBookingById(widget.bookingId!);

      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading booking detail: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải thông tin hoạt động';
          _isLoading = false;
        });
      }
    }
  }

  int get _duration {
    if (_booking == null) return 0;
    return _booking!.endTime.difference(_booking!.startTime).inHours;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton(), title: const Text('Chi tiết hoạt động')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton(), title: const Text('Chi tiết hoạt động')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Ionicons.alert_circle_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Không tìm thấy hoạt động'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBookingDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking!;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: context.appColors.surface,
                leading: const AppBackButton(),
                title: Text(
                  'Chi tiết hoạt động',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Ionicons.ellipsis_horizontal_outline),
                    onPressed: () => _showOptionsMenu(),
                  ),
                ],
              ),

              // Status Banner
              SliverToBoxAdapter(
                child: Container(
                  margin: ResponsiveLayout.pagePadding(context),
                  padding: ResponsiveLayout.pagePadding(context),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _statusColor,
                        _statusColor.withAlpha(180),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withAlpha(50),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withAlpha(50),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _statusIcon,
                          color: AppColors.textWhite,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusText,
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.bookingCode != null
                                  ? 'Mã: ${booking.bookingCode}'
                                  : 'ID: #${booking.id.substring(0, 8).toUpperCase()}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textWhite.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Partner Info Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: booking.partnerAvatar != null
                              ? CachedNetworkImage(
                                  imageUrl: ImageUtils.buildImageUrl(booking.partnerAvatar!),
                                  fit: BoxFit.cover,
                                  placeholder: (_, placeholderUrl) => Container(
                                    color: AppColors.primary.withAlpha(50),
                                  ),
                                  errorWidget: (_, errorUrl, error) => Container(
                                    color: AppColors.primary.withAlpha(50),
                                    child: Icon(
                                      Ionicons.person_outline,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.primary.withAlpha(50),
                                  child: Icon(
                                    Ionicons.person_outline,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.partnerName,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Người tham gia',
                              style: AppTypography.labelSmall.copyWith(
                                color: context.appColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Row(
                        children: [
                          _CircleButton(
                            icon: Ionicons.call_outline,
                            onTap: () {},
                          ),
                          const SizedBox(width: 10),
                          _CircleButton(
                            icon: Ionicons.chatbubble_outline,
                            isPrimary: true,
                            onTap: () => context.push('/chat/user/${booking.partnerId}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Booking Details
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.appColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi tiết hoạt động',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Activity type
                      _DetailRow(
                        icon: Ionicons.cafe_outline,
                        label: 'Hoạt động',
                        value: booking.serviceType,
                      ),
                      const SizedBox(height: 16),

                      // Date
                      _DetailRow(
                        icon: Ionicons.calendar_outline,
                        label: 'Ngày',
                        value: booking.formattedDate,
                      ),
                      const SizedBox(height: 16),

                      // Time
                      _DetailRow(
                        icon: Ionicons.time_outline,
                        label: 'Thời gian',
                        value: '${booking.formattedTimeRange} ($_duration giờ)',
                      ),

                      // Location
                      if (booking.location != null) ...[
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Ionicons.location_outline,
                          label: 'Địa điểm',
                          value: booking.location!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Notes
              if (booking.note != null && booking.note!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(ResponsiveLayout.horizontalPadding(context), 20, ResponsiveLayout.horizontalPadding(context), 0),
                    padding: ResponsiveLayout.pagePadding(context),
                    decoration: BoxDecoration(
                      color: context.appColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Ionicons.document_text_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Ghi chú',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          booking.note!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Cancellation reason if cancelled
              if ((booking.status == 'CANCELLED' || booking.status == 'REJECTED') &&
                  booking.cancellationReason != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(ResponsiveLayout.horizontalPadding(context), 20, ResponsiveLayout.horizontalPadding(context), 0),
                    padding: ResponsiveLayout.pagePadding(context),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Ionicons.information_circle_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Lý do hủy',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          booking.cancellationReason!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom padding for action buttons
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // Action Buttons - Hoàn thành (user completes when IN_PROGRESS)
          if (booking.status == 'IN_PROGRESS')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveLayout.horizontalPadding(context),
                  16,
                  ResponsiveLayout.horizontalPadding(context),
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Nhắn tin',
                        isOutlined: true,
                        onPressed: () =>
                            context.push('/chat/user/${booking.partnerId}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: 'Hoàn thành',
                        icon: Ionicons.checkmark_circle_outline,
                        onPressed: () => _showCompleteDialog(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action Buttons - Cancel / Message
          if (booking.status == 'CONFIRMED' ||
              booking.status == 'PENDING')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveLayout.horizontalPadding(context),
                  16,
                  ResponsiveLayout.horizontalPadding(context),
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: AppButton(
                        text: 'Hủy',
                        isOutlined: true,
                        onPressed: () => _showCancelDialog(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Primary action - Message for CONFIRMED, Wait for PENDING
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: booking.status == 'PENDING'
                            ? 'Chờ xác nhận'
                            : 'Nhắn tin',
                        icon: booking.status == 'CONFIRMED'
                            ? Ionicons.chatbubble_outline
                            : null,
                        onPressed: booking.status == 'PENDING'
                            ? null
                            : () => context.push('/chat/user/${booking.partnerId}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Review button for completed bookings
          if (booking.status == 'COMPLETED')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveLayout.horizontalPadding(context),
                  16,
                  ResponsiveLayout.horizontalPadding(context),
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: AppButton(
                  text: 'Đánh giá',
                  icon: Ionicons.star_outline,
                  onPressed: () {
                    context.push('/booking/${_booking!.id}/review');
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ResponsiveLayout.horizontalPadding(ctx),
            16,
            ResponsiveLayout.horizontalPadding(ctx),
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Ionicons.share_social_outline),
                title: const Text('Chia sẻ'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Ionicons.copy_outline),
                title: const Text('Sao chép ID'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: Icon(Ionicons.alert_circle_outline, color: AppColors.error),
                title: Text('Báo cáo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy hoạt động'),
        content: const Text('Bạn có chắc chắn muốn hủy hoạt động này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelBooking();
            },
            child: Text('Hủy', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking() async {
    if (_booking == null) return;

    try {
      await _bookingRepository.cancelBooking(
        bookingId: _booking!.id,
        reason: 'Hủy bởi người dùng',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy hoạt động')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showReportDialog() {
    if (_booking == null) return;

    final reasons = [
      'Quấy rối hoặc lạm dụng',
      'Nội dung phản cảm',
      'Lừa đảo hoặc gian lận',
      'Vi phạm điều khoản cộng đồng',
    ];
    String selectedReason = reasons.first;
    final descriptionController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Báo cáo người dùng'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Lý do',
                    border: OutlineInputBorder(),
                  ),
                  items: reasons
                      .map(
                        (reason) => DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        ),
                      )
                      .toList(),
                  onChanged: isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setDialogState(() => selectedReason = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  enabled: !isSubmitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả thêm (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          await _bookingRepository.reportBooking(
                            reportedUserId: _booking!.partnerId,
                            bookingId: _booking!.id,
                            reason: selectedReason,
                            description: descriptionController.text.trim(),
                          );

                          if (!mounted || !ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã gửi báo cáo. Chúng tôi sẽ xem xét trong thời gian sớm nhất.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không thể gửi báo cáo: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gửi báo cáo'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompleteDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành hoạt động'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xác nhận bạn đã hoàn thành hoạt động. Bạn có thể thêm ghi chú (tùy chọn):',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeBooking(note: noteController.text.trim());
            },
            child: const Text('Xác nhận hoàn thành'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeBooking({String? note}) async {
    if (_booking == null) return;

    try {
      final updated = await _bookingRepository.completeBooking(
        bookingId: _booking!.id,
        note: note,
      );
      if (mounted) {
        setState(() => _booking = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu hoàn thành'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  // Payment dialog and payment flow removed - app now uses free activity model
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : context.appColors.background,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: context.appColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? AppColors.textWhite : context.appColors.textSecondary,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: context.appColors.textHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
