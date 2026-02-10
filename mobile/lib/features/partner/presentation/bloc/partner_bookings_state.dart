import 'package:equatable/equatable.dart';

import '../../data/partner_repository.dart';

/// States for PartnerBookingsBloc
abstract class PartnerBookingsState extends Equatable {
  const PartnerBookingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PartnerBookingsInitial extends PartnerBookingsState {
  const PartnerBookingsInitial();
}

/// Loading state
class PartnerBookingsLoading extends PartnerBookingsState {
  const PartnerBookingsLoading();
}

/// Loaded state with bookings data
class PartnerBookingsLoaded extends PartnerBookingsState {
  final List<PartnerBooking> bookings;
  final int total;
  final int page;
  final int totalPages;
  final bool hasNextPage;
  final String? currentFilter;
  final bool isLoadingMore;

  const PartnerBookingsLoaded({
    required this.bookings,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasNextPage,
    this.currentFilter,
    this.isLoadingMore = false,
  });

  /// Get upcoming bookings
  List<PartnerBooking> get upcomingBookings =>
      bookings.where((b) => b.isUpcoming).toList();

  /// Get completed bookings
  List<PartnerBooking> get completedBookings =>
      bookings.where((b) => b.isCompleted).toList();

  /// Get cancelled bookings
  List<PartnerBooking> get cancelledBookings =>
      bookings.where((b) => b.isCancelled).toList();

  /// Copy with new values
  PartnerBookingsLoaded copyWith({
    List<PartnerBooking>? bookings,
    int? total,
    int? page,
    int? totalPages,
    bool? hasNextPage,
    String? currentFilter,
    bool? isLoadingMore,
  }) {
    return PartnerBookingsLoaded(
      bookings: bookings ?? this.bookings,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentFilter: currentFilter ?? this.currentFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        bookings,
        total,
        page,
        totalPages,
        hasNextPage,
        currentFilter,
        isLoadingMore,
      ];
}

/// Error state
class PartnerBookingsError extends PartnerBookingsState {
  final String message;

  const PartnerBookingsError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Action in progress (confirm/cancel)
class PartnerBookingsActionInProgress extends PartnerBookingsState {
  final PartnerBookingsLoaded previousState;
  final String bookingId;

  const PartnerBookingsActionInProgress({
    required this.previousState,
    required this.bookingId,
  });

  @override
  List<Object?> get props => [previousState, bookingId];
}

/// Action success (confirm/cancel done)
class PartnerBookingsActionSuccess extends PartnerBookingsState {
  final PartnerBookingsLoaded previousState;
  final String message;

  const PartnerBookingsActionSuccess({
    required this.previousState,
    required this.message,
  });

  @override
  List<Object?> get props => [previousState, message];
}

/// Action error (confirm/cancel/start/complete failed) - keeps previous state
class PartnerBookingsActionError extends PartnerBookingsState {
  final PartnerBookingsLoaded previousState;
  final String message;

  const PartnerBookingsActionError({
    required this.previousState,
    required this.message,
  });

  @override
  List<Object?> get props => [previousState, message];
}
