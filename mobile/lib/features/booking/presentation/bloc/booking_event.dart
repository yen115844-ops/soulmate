import 'package:equatable/equatable.dart';

/// Booking events
abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Load user bookings
class BookingLoadRequested extends BookingEvent {
  final String? status;
  final bool refresh;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? dateFilterType;

  const BookingLoadRequested({
    this.status,
    this.refresh = false,
    this.startDate,
    this.endDate,
    this.dateFilterType,
  });

  @override
  List<Object?> get props => [status, refresh, startDate, endDate, dateFilterType];
}

/// Load more bookings (pagination)
class BookingLoadMoreRequested extends BookingEvent {
  const BookingLoadMoreRequested();
}

/// Refresh bookings
class BookingRefreshRequested extends BookingEvent {
  const BookingRefreshRequested();
}

/// Cancel booking
class BookingCancelRequested extends BookingEvent {
  final String bookingId;
  final String reason;

  const BookingCancelRequested({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}

/// Filter changed
class BookingFilterChanged extends BookingEvent {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? dateFilterType; // 'today', 'week', 'month', 'custom'

  const BookingFilterChanged({
    this.status,
    this.startDate,
    this.endDate,
    this.dateFilterType,
  });

  @override
  List<Object?> get props => [status, startDate, endDate, dateFilterType];
}
