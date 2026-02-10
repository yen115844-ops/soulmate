import 'package:equatable/equatable.dart';

/// Events for PartnerBookingsBloc
abstract class PartnerBookingsEvent extends Equatable {
  const PartnerBookingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load bookings
class PartnerBookingsLoadRequested extends PartnerBookingsEvent {
  final String? status;
  final int page;

  const PartnerBookingsLoadRequested({
    this.status,
    this.page = 1,
  });

  @override
  List<Object?> get props => [status, page];
}

/// Load more bookings (pagination)
class PartnerBookingsLoadMoreRequested extends PartnerBookingsEvent {
  const PartnerBookingsLoadMoreRequested();
}

/// Refresh bookings
class PartnerBookingsRefreshRequested extends PartnerBookingsEvent {
  const PartnerBookingsRefreshRequested();
}

/// Confirm booking
class PartnerBookingConfirmRequested extends PartnerBookingsEvent {
  final String bookingId;
  final String? note;

  const PartnerBookingConfirmRequested({
    required this.bookingId,
    this.note,
  });

  @override
  List<Object?> get props => [bookingId, note];
}

/// Cancel/Reject booking
class PartnerBookingCancelRequested extends PartnerBookingsEvent {
  final String bookingId;
  final String reason;

  const PartnerBookingCancelRequested({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}

/// Start booking (begin meeting)
class PartnerBookingStartRequested extends PartnerBookingsEvent {
  final String bookingId;

  const PartnerBookingStartRequested({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

/// Complete booking
class PartnerBookingCompleteRequested extends PartnerBookingsEvent {
  final String bookingId;
  final String? note;

  const PartnerBookingCompleteRequested({
    required this.bookingId,
    this.note,
  });

  @override
  List<Object?> get props => [bookingId, note];
}

/// Change filter status
class PartnerBookingsFilterChanged extends PartnerBookingsEvent {
  final String? status;

  const PartnerBookingsFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}
