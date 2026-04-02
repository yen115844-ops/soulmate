import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/service_type_display_resolver.dart';
import '../../../../shared/data/repositories/master_data_repository.dart';
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
  MasterDataRepository get _masterDataRepository =>
      getIt<MasterDataRepository>();
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool _isLoading = true;
  String? _errorMessage;
  BookingEntity? _booking;

  bool get _hasValidBookingId {
    final bookingId = widget.bookingId;
    return bookingId != null && bookingId.trim().isNotEmpty;
  }

  String get _statusText {
    if (_booking == null) return '';
    return _booking!.statusText;
  }

  String get _displayServiceType {
    if (_booking == null) return '';
    return ServiceTypeDisplayResolver.resolveName(_booking!.serviceType);
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
    if (_hasValidBookingId) {
      _loadBookingDetail();
    } else {
      _isLoading = false;
      _errorMessage = 'Không tìm thấy mã hoạt động hợp lệ';
    }
  }

  Future<void> _loadBookingDetail() async {
    if (!_hasValidBookingId) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không tìm thấy mã hoạt động hợp lệ';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _warmupServiceTypes();
      final booking = await _bookingRepository.getBookingById(
        widget.bookingId!.trim(),
      );

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

  Future<void> _warmupServiceTypes() async {
    try {
      final serviceTypes = await _masterDataRepository.getServiceTypes();
      ServiceTypeDisplayResolver.seedFromApi(serviceTypes);
    } catch (_) {
      // Keep detail page usable even when master-data request fails.
    }
  }

  String get _durationText {
    if (_booking == null) return '0 phút';

    final totalMinutes = _booking!.endTime
        .difference(_booking!.startTime)
        .inMinutes
        .abs();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) return '$minutes phút';
    if (minutes == 0) return '$hours giờ';
    return '$hours giờ $minutes phút';
  }

  String get _formattedTotalAmount {
    if (_booking == null) return '0 đ';
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    ).format(_booking!.totalAmount);
  }

  String _formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  String _nonEmptyOrFallback(
    String? value, {
    String fallback = 'Chưa cập nhật',
  }) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return fallback;
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Chi tiết hoạt động'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Chi tiết hoạt động'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.alert_circle_outline,
                size: 64,
                color: AppColors.error,
              ),
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
          RefreshIndicator(
            onRefresh: _loadBookingDetail,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: _statusColor,
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
                // sizedbox heigth
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

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
                                    imageUrl: ImageUtils.buildImageUrl(
                                      booking.partnerAvatar!,
                                    ),
                                    fit: BoxFit.cover,
                                    placeholder: (_, placeholderUrl) =>
                                        Container(
                                          color: AppColors.primary.withAlpha(
                                            50,
                                          ),
                                        ),
                                    errorWidget: (_, errorUrl, error) =>
                                        Container(
                                          color: AppColors.primary.withAlpha(
                                            50,
                                          ),
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
                        _CircleButton(
                          icon: Ionicons.chatbubble_outline,
                          isPrimary: true,
                          onTap: () =>
                              context.push('/chat/user/${booking.partnerId}'),
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
                          value: _displayServiceType,
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
                          value:
                              '${booking.formattedTimeRange} ($_durationText)',
                        ),
                        const SizedBox(height: 16),

                        _DetailRow(
                          icon: Ionicons.cash_outline,
                          label: 'Chi phí',
                          value: _formattedTotalAmount,
                        ),
                        const SizedBox(height: 16),

                        _DetailRow(
                          icon: Ionicons.time_outline,
                          label: 'Tạo lúc',
                          value: _formatDateTime(booking.createdAt),
                        ),
                        const SizedBox(height: 16),

                        _DetailRow(
                          icon: Ionicons.refresh_outline,
                          label: 'Cập nhật lúc',
                          value: _formatDateTime(booking.updatedAt),
                        ),

                        // Location
                        if (_nonEmptyOrFallback(
                          booking.location,
                          fallback: '',
                        ).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _DetailRow(
                            icon: Ionicons.location_outline,
                            label: 'Địa điểm',
                            value: _nonEmptyOrFallback(booking.location),
                          ),
                        ],

                        if ((booking.status == 'CANCELLED' ||
                                booking.status == 'REJECTED') &&
                            _nonEmptyOrFallback(
                              booking.cancelledBy,
                              fallback: '',
                            ).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _DetailRow(
                            icon: Ionicons.person_remove_outline,
                            label: 'Người hủy',
                            value: _nonEmptyOrFallback(booking.cancelledBy),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Notes
                if (_nonEmptyOrFallback(booking.note, fallback: '').isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        ResponsiveLayout.horizontalPadding(context),
                        20,
                        ResponsiveLayout.horizontalPadding(context),
                        0,
                      ),
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
                            _nonEmptyOrFallback(booking.note),
                            style: AppTypography.bodyMedium.copyWith(
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Cancellation reason if cancelled
                if ((booking.status == 'CANCELLED' ||
                        booking.status == 'REJECTED') &&
                    booking.cancellationReason != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        ResponsiveLayout.horizontalPadding(context),
                        20,
                        ResponsiveLayout.horizontalPadding(context),
                        0,
                      ),
                      padding: ResponsiveLayout.pagePadding(context),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withAlpha(50),
                        ),
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
          if (booking.status == 'CONFIRMED' || booking.status == 'PENDING')
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
                            : () => context.push(
                                '/chat/user/${booking.partnerId}',
                              ),
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
                        text: 'Đánh giá',
                        icon: Ionicons.star_outline,
                        onPressed: () {
                          context.push('/booking/${_booking!.id}/review');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (booking.status == 'CANCELLED' || booking.status == 'REJECTED')
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
                        text: 'Đặt lại',
                        icon: Ionicons.refresh_outline,
                        onPressed: () => context.push(
                          '/booking/create?partnerId=${booking.partnerId}',
                        ),
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
                leading: const Icon(Ionicons.copy_outline),
                title: const Text(
                  'Sao chép ID',
                  style: TextStyle(color: AppColors.primary),
                ),
                onTap: () {
                  final booking = _booking;
                  Navigator.pop(ctx);
                  if (booking == null) return;

                  Clipboard.setData(ClipboardData(text: booking.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép ID hoạt động')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Ionicons.pricetag_outline),
                title: const Text(
                  'Sao chép mã hoạt động',
                  style: TextStyle(color: AppColors.primary),
                ),
                onTap: () {
                  final booking = _booking;
                  Navigator.pop(ctx);
                  if (booking == null) return;

                  final text = booking.bookingCode?.trim().isNotEmpty == true
                      ? booking.bookingCode!
                      : booking.id;

                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã hoạt động')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Ionicons.hand_left_outline,
                  color: AppColors.error,
                ),
                title: Text(
                  'Chặn người dùng',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBlockUserDialog();
                },
              ),
              ListTile(
                leading: Icon(
                  Ionicons.alert_circle_outline,
                  color: AppColors.error,
                ),
                title: Text(
                  'Báo cáo',
                  style: TextStyle(color: AppColors.error),
                ),
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

  void _showBlockUserDialog() {
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
          builder: (ctx, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chặn người dùng',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Người dùng này sẽ bị chặn và nội dung liên quan sẽ không còn hiển thị với bạn.',
                    style: TextStyle(color: context.appColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setDialogState(() => isSubmitting = true);

                                try {
                                  await _bookingRepository.reportBooking(
                                    reportedUserId: _booking!.partnerId,
                                    bookingId: _booking!.id,
                                    reason: selectedReason,
                                    description: descriptionController.text
                                        .trim(),
                                  );
                                } catch (_) {
                                  // Cho phép tiếp tục chặn kể cả khi báo cáo đã tồn tại.
                                }

                                try {
                                  await _bookingRepository.blockUser(
                                    blockedUserId: _booking!.partnerId,
                                  );

                                  if (!mounted || !ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đã chặn người dùng và gửi báo cáo cho hệ thống.',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );

                                  context.go(RouteNames.bookings);
                                } catch (e) {
                                  if (!mounted) return;
                                  setDialogState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Không thể chặn người dùng: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Chặn và gửi báo cáo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController(
      text: 'Thay đổi kế hoạch cá nhân',
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hủy hoạt động',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text('Bạn có chắc chắn muốn hủy hoạt động này không?'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lý do hủy',
                  hintText: 'Nhập lý do hủy để đối phương nắm thông tin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Không'),
                  ),
                  TextButton(
                    onPressed: () {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập lý do hủy hoạt động'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      _cancelBooking(reason: reason);
                    },
                    child: Text(
                      'Hủy',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelBooking({required String reason}) async {
    if (_booking == null) return;

    try {
      await _bookingRepository.cancelBooking(
        bookingId: _booking!.id,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy hoạt động')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
          builder: (ctx, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Báo cáo người dùng',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(ctx),
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
                                    description: descriptionController.text
                                        .trim(),
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
                                      content: Text(
                                        'Không thể gửi báo cáo: $e',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Gửi báo cáo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCompleteDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hoàn thành hoạt động',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
            ],
          ),
        ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
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
          border: isPrimary
              ? null
              : Border.all(color: context.appColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary
              ? AppColors.textWhite
              : context.appColors.textSecondary,
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
          child: Icon(icon, color: AppColors.primary, size: 18),
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
