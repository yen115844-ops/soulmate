import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/partner_repository.dart';
import 'partner_bookings_event.dart';
import 'partner_bookings_state.dart';

class PartnerBookingsBloc
    extends Bloc<PartnerBookingsEvent, PartnerBookingsState> {
  final PartnerRepository _partnerRepository;

  PartnerBookingsBloc({required PartnerRepository partnerRepository})
      : _partnerRepository = partnerRepository,
        super(const PartnerBookingsInitial()) {
    on<PartnerBookingsLoadRequested>(_onLoadRequested);
    on<PartnerBookingsLoadMoreRequested>(_onLoadMoreRequested);
    on<PartnerBookingsRefreshRequested>(_onRefreshRequested);
    on<PartnerBookingConfirmRequested>(_onConfirmRequested);
    on<PartnerBookingCancelRequested>(_onCancelRequested);
    on<PartnerBookingStartRequested>(_onStartRequested);
    on<PartnerBookingCompleteRequested>(_onCompleteRequested);
    on<PartnerBookingsFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoadRequested(
    PartnerBookingsLoadRequested event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    emit(const PartnerBookingsLoading());

    try {
      final response = await _partnerRepository.getPartnerBookings(
        page: event.page,
        status: event.status,
      );

      emit(PartnerBookingsLoaded(
        bookings: response.bookings,
        total: response.total,
        page: response.page,
        totalPages: response.totalPages,
        hasNextPage: response.hasNextPage,
        currentFilter: event.status,
      ));
    } catch (e) {
      debugPrint('Partner bookings load error: $e');
      emit(PartnerBookingsError(message: getErrorMessage(e)));
    }
  }

  Future<void> _onLoadMoreRequested(
    PartnerBookingsLoadMoreRequested event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    if (state is! PartnerBookingsLoaded) return;

    final currentState = state as PartnerBookingsLoaded;
    if (!currentState.hasNextPage || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _partnerRepository.getPartnerBookings(
        page: currentState.page + 1,
        status: currentState.currentFilter,
      );

      emit(PartnerBookingsLoaded(
        bookings: [...currentState.bookings, ...response.bookings],
        total: response.total,
        page: response.page,
        totalPages: response.totalPages,
        hasNextPage: response.hasNextPage,
        currentFilter: currentState.currentFilter,
      ));
    } catch (e) {
      debugPrint('Partner bookings load more error: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onRefreshRequested(
    PartnerBookingsRefreshRequested event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    final currentFilter =
        state is PartnerBookingsLoaded ? (state as PartnerBookingsLoaded).currentFilter : null;

    try {
      final response = await _partnerRepository.getPartnerBookings(
        page: 1,
        status: currentFilter,
      );

      emit(PartnerBookingsLoaded(
        bookings: response.bookings,
        total: response.total,
        page: response.page,
        totalPages: response.totalPages,
        hasNextPage: response.hasNextPage,
        currentFilter: currentFilter,
      ));
    } catch (e) {
      debugPrint('Partner bookings refresh error: $e');
      // Keep current state on refresh error
    }
  }

  Future<void> _onConfirmRequested(
    PartnerBookingConfirmRequested event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    if (state is! PartnerBookingsLoaded) return;

    final currentState = state as PartnerBookingsLoaded;
    emit(PartnerBookingsActionInProgress(
      previousState: currentState,
      bookingId: event.bookingId,
    ));

    try {
      final updatedBooking = await _partnerRepository.confirmBooking(
        event.bookingId,
        note: event.note,
      );

      // Update booking in list
      final updatedBookings = currentState.bookings.map((booking) {
        if (booking.id == event.bookingId) {
          return updatedBooking;
        }
        return booking;
      }).toList();

      final newState = currentState.copyWith(bookings: updatedBookings);
      emit(PartnerBookingsActionSuccess(
        previousState: newState,
        message: 'Đã xác nhận lịch hẹn',
      ));
    } catch (e) {
      debugPrint('Confirm booking error: $e');
      emit(PartnerBookingsActionError(
        previousState: currentState,
        message: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onCancelRequested(
    PartnerBookingCancelRequested event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    if (state is! PartnerBookingsLoaded) return;

    final currentState = state as PartnerBookingsLoaded;
    emit(PartnerBookingsActionInProgress(
      previousState: currentState,
      bookingId: event.bookingId,
    ));

    try {
      final updatedBooking = await _partnerRepository.cancelBooking(
        event.bookingId,
        event.reason,
      );

      // Update booking in list
      final updatedBookings = currentState.bookings.map((booking) {
        if (booking.id == event.bookingId) {
          return updatedBooking;
        }
        return booking;
      }).toList();

      final newState = currentState.copyWith(bookings: updatedBookings);
      emit(PartnerBookingsActionSuccess(
        previousState: newState,
        message: 'Đã từ chối lịch hẹn',
      ));
    } catch (e) {
      debugPrint('Cancel booking error: $e');
      emit(PartnerBookingsActionError(
        previousState: currentState,
        message: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onStartRequested(
    PartnerBookingStartRequested event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    if (state is! PartnerBookingsLoaded) return;

    final currentState = state as PartnerBookingsLoaded;
    emit(PartnerBookingsActionInProgress(
      previousState: currentState,
      bookingId: event.bookingId,
    ));

    try {
      final updatedBooking = await _partnerRepository.startBooking(
        event.bookingId,
      );

      // Update booking in list
      final updatedBookings = currentState.bookings.map((booking) {
        if (booking.id == event.bookingId) {
          return updatedBooking;
        }
        return booking;
      }).toList();

      final newState = currentState.copyWith(bookings: updatedBookings);
      emit(PartnerBookingsActionSuccess(
        previousState: newState,
        message: 'Đã bắt đầu cuộc hẹn',
      ));
    } catch (e) {
      debugPrint('Start booking error: $e');
      emit(PartnerBookingsActionError(
        previousState: currentState,
        message: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onCompleteRequested(
    PartnerBookingCompleteRequested event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    if (state is! PartnerBookingsLoaded) return;

    final currentState = state as PartnerBookingsLoaded;
    emit(PartnerBookingsActionInProgress(
      previousState: currentState,
      bookingId: event.bookingId,
    ));

    try {
      final updatedBooking = await _partnerRepository.completeBooking(
        event.bookingId,
        note: event.note,
      );

      // Update booking in list
      final updatedBookings = currentState.bookings.map((booking) {
        if (booking.id == event.bookingId) {
          return updatedBooking;
        }
        return booking;
      }).toList();

      final newState = currentState.copyWith(bookings: updatedBookings);
      emit(PartnerBookingsActionSuccess(
        previousState: newState,
        message: 'Đã hoàn thành cuộc hẹn',
      ));
    } catch (e) {
      debugPrint('Complete booking error: $e');
      emit(PartnerBookingsActionError(
        previousState: currentState,
        message: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onFilterChanged(
    PartnerBookingsFilterChanged event,
    Emitter<PartnerBookingsState> emit,
  ) async {
    add(PartnerBookingsLoadRequested(status: event.status));
  }
}
