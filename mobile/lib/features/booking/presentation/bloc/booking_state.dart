import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_entity.dart';

/// Booking state
abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BookingInitial extends BookingState {
  const BookingInitial();
}

/// Loading state
class BookingLoading extends BookingState {
  const BookingLoading();
}

/// Loaded state with bookings
class BookingLoaded extends BookingState {
  final List<BookingEntity> upcomingBookings;
  final List<BookingEntity> pastBookings;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;
  final String? currentFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? dateFilterType;

  const BookingLoaded({
    required this.upcomingBookings,
    required this.pastBookings,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentFilter,
    this.startDate,
    this.endDate,
    this.dateFilterType,
  });

  /// Get all bookings
  List<BookingEntity> get allBookings => [...upcomingBookings, ...pastBookings];

  BookingLoaded copyWith({
    List<BookingEntity>? upcomingBookings,
    List<BookingEntity>? pastBookings,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
    String? currentFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? dateFilterType,
    bool clearDateFilter = false,
  }) {
    return BookingLoaded(
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      pastBookings: pastBookings ?? this.pastBookings,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentFilter: currentFilter ?? this.currentFilter,
      startDate: clearDateFilter ? null : (startDate ?? this.startDate),
      endDate: clearDateFilter ? null : (endDate ?? this.endDate),
      dateFilterType: clearDateFilter ? null : (dateFilterType ?? this.dateFilterType),
    );
  }

  @override
  List<Object?> get props => [
        upcomingBookings,
        pastBookings,
        currentPage,
        totalPages,
        hasMore,
        isLoadingMore,
        currentFilter,
        startDate,
        endDate,
        dateFilterType,
      ];
}

/// Error state
class BookingError extends BookingState {
  final String message;

  const BookingError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Booking action success (cancel, etc.)
class BookingActionSuccess extends BookingState {
  final String message;
  final BookingLoaded previousState;

  const BookingActionSuccess({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}
