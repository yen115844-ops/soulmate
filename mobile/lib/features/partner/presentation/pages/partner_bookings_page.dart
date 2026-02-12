import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../data/partner_repository.dart';
import '../bloc/partner_bookings_bloc.dart';
import '../bloc/partner_bookings_event.dart';
import '../bloc/partner_bookings_state.dart';

class PartnerBookingsPage extends StatelessWidget {
  const PartnerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PartnerBookingsBloc(
        partnerRepository: getIt<PartnerRepository>(),
      )..add(const PartnerBookingsLoadRequested()),
      child: const _PartnerBookingsContent(),
    );
  }
}

class _PartnerBookingsContent extends StatefulWidget {
  const _PartnerBookingsContent();

  @override
  State<_PartnerBookingsContent> createState() => _PartnerBookingsContentState();
}

class _PartnerBookingsContentState extends State<_PartnerBookingsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    String? status;
    switch (_tabController.index) {
      case 0: // Upcoming
        status = 'PENDING,CONFIRMED,PAID';
        break;
      case 1: // Completed
        status = 'COMPLETED';
        break;
      case 2: // Cancelled
        status = 'CANCELLED';
        break;
    }
    context.read<PartnerBookingsBloc>().add(PartnerBookingsFilterChanged(status));
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text('Quản lý lịch hẹn'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            BlocBuilder<PartnerBookingsBloc, PartnerBookingsState>(
              builder: (context, state) {
                final upcomingCount = state is PartnerBookingsLoaded
                    ? state.upcomingBookings.length
                    : 0;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sắp tới'),
                      if (upcomingCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$upcomingCount',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Hoàn thành'),
            const Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: BlocConsumer<PartnerBookingsBloc, PartnerBookingsState>(
        listener: (context, state) {
          if (state is PartnerBookingsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is PartnerBookingsActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is PartnerBookingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PartnerBookingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PartnerBookingsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context
                    .read<PartnerBookingsBloc>()
                    .add(const PartnerBookingsLoadRequested());
              },
            );
          }

          if (state is PartnerBookingsLoaded ||
              state is PartnerBookingsActionInProgress ||
              state is PartnerBookingsActionSuccess ||
              state is PartnerBookingsActionError) {
            final loadedState = state is PartnerBookingsLoaded
                ? state
                : state is PartnerBookingsActionInProgress
                    ? state.previousState
                    : state is PartnerBookingsActionSuccess
                        ? state.previousState
                        : (state as PartnerBookingsActionError).previousState;
            final processingBookingId = state is PartnerBookingsActionInProgress
                ? state.bookingId
                : null;

            return TabBarView(
              controller: _tabController,
              children: [
                // Upcoming
                _BookingsList(
                  bookings: loadedState.upcomingBookings,
                  emptyMessage: 'Không có lịch hẹn sắp tới',
                  showActions: true,
                  processingBookingId: processingBookingId,
                  onRefresh: () async {
                    context
                        .read<PartnerBookingsBloc>()
                        .add(const PartnerBookingsRefreshRequested());
                  },
                ),
                // Completed
                _BookingsList(
                  bookings: loadedState.completedBookings,
                  emptyMessage: 'Chưa có lịch hẹn hoàn thành',
                  onRefresh: () async {
                    context
                        .read<PartnerBookingsBloc>()
                        .add(const PartnerBookingsRefreshRequested());
                  },
                ),
                // Cancelled
                _BookingsList(
                  bookings: loadedState.cancelledBookings,
                  emptyMessage: 'Không có lịch hẹn đã hủy',
                  onRefresh: () async {
                    context
                        .read<PartnerBookingsBloc>()
                        .add(const PartnerBookingsRefreshRequested());
                  },
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Icon(Ionicons.alert_circle_outline, size: 64, color: context.appColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Ionicons.refresh_outline),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<PartnerBooking> bookings;
  final String emptyMessage;
  final bool showActions;
  final String? processingBookingId;
  final Future<void> Function() onRefresh;

  const _BookingsList({
    required this.bookings,
    required this.emptyMessage,
    this.showActions = false,
    this.processingBookingId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Ionicons.calendar_outline, size: 64, color: context.appColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: AppTypography.bodyLarge.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PartnerBookingCard(
              booking: booking,
              showActions: showActions && booking.status == 'PENDING',
              isProcessing: processingBookingId == booking.id,
            ),
          );
        },
      ),
    );
  }
}

class _PartnerBookingCard extends StatelessWidget {
  final PartnerBooking booking;
  final bool showActions;
  final bool isProcessing;

  const _PartnerBookingCard({
    required this.booking,
    this.showActions = false,
    this.isProcessing = false,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'PAID':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'COMPLETED':
        return AppColors.info;
      case 'CANCELLED':
        return AppColors.error;
      case 'ONGOING':
        return AppColors.primary;
      default:
        return AppColors.textHint;
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final user = booking.user;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: context.appColors.shimmerBase,
                      backgroundImage: user?.avatarUrl != null
                          ? CachedNetworkImageProvider(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ?   Icon(Ionicons.person_outline, color: context.appColors.textHint)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Khách hàng',
                            style: AppTypography.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.statusText,
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatCurrency(booking.subtotal)}đ',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Details
                if (booking.activities.isNotEmpty)
                  _DetailRow(
                    icon: Ionicons.pricetag_outline,
                    label: 'Hoạt động',
                    value: booking.activities.join(', '),
                  ),
                if (booking.activities.isNotEmpty) const SizedBox(height: 12),
                _DetailRow(
                  icon: Ionicons.calendar_outline,
                  label: 'Ngày',
                  value: dateFormat.format(booking.date),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Ionicons.time_outline,
                  label: 'Thời gian',
                  value: '${booking.startTime} - ${booking.endTime}',
                ),
                if (booking.meetingLocation != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Ionicons.location_outline,
                    label: 'Địa điểm',
                    value: booking.meetingLocation!,
                  ),
                ],

                // User Note
                if (booking.userNote != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Ionicons.document_text_outline, color: AppColors.info, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.userNote!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions for PENDING bookings
          if (showActions)
            Container(
              padding: const EdgeInsets.all(16),
              decoration:   BoxDecoration(
                color: context.appColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: isProcessing
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showDeclineDialog(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<PartnerBookingsBloc>().add(
                                    PartnerBookingConfirmRequested(
                                      bookingId: booking.id,
                                    ),
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            child: const Text('Xác nhận'),
                          ),
                        ),
                      ],
                    ),
            ),

          // Chat + Start button for CONFIRMED/PAID bookings
          if (booking.status == 'CONFIRMED' || booking.status == 'PAID')
            Container(
              padding: const EdgeInsets.all(16),
              decoration:   BoxDecoration(
                color: context.appColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/chat/user/${booking.userId}');
                      },
                      icon: const Icon(Ionicons.chatbubble_outline),
                      label: const Text('Nhắn tin'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _startBooking(context, booking.id),
                      child: const Text('Bắt đầu'),
                    ),
                  ),
                ],
              ),
            ),

          // Complete button for IN_PROGRESS bookings
          if (booking.status == 'IN_PROGRESS')
            Container(
              padding: const EdgeInsets.all(16),
              decoration:   BoxDecoration(
                color: context.appColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/chat/user/${booking.userId}');
                      },
                      icon: const Icon(Ionicons.chatbubble_outline),
                      label: const Text('Nhắn tin'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showCompleteDialog(context, booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Hoàn thành'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _startBooking(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bắt đầu cuộc hẹn'),
        content: const Text(
          'Xác nhận bắt đầu cuộc hẹn với khách hàng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PartnerBookingsBloc>().add(
                PartnerBookingStartRequested(bookingId: bookingId),
              );
            },
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, String bookingId) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hoàn thành cuộc hẹn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ghi chú (tùy chọn):'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập ghi chú về cuộc hẹn...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final note = noteController.text.trim();
              context.read<PartnerBookingsBloc>().add(
                PartnerBookingCompleteRequested(
                  bookingId: bookingId,
                  note: note.isNotEmpty ? note : null,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối lịch hẹn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cho biết lý do từ chối:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              context.read<PartnerBookingsBloc>().add(
                    PartnerBookingCancelRequested(
                      bookingId: booking.id,
                      reason: reason,
                    ),
                  );
            },
            child: const Text('Từ chối', style: TextStyle(color: AppColors.error)),
          ),
        ],
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
        Icon(icon, size: 16, color: context.appColors.textHint),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.appColors.textHint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}
