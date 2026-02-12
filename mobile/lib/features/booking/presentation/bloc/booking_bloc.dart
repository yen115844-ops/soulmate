import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/error_utils.dart';
import '../../data/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

/// Booking BLoC - Manages user bookings
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;
  static const int _pageSize = AppConstants.defaultPageSize;

  BookingBloc({required BookingRepository bookingRepository})
    : _bookingRepository = bookingRepository,
      super(const BookingInitial()) {
    on<BookingLoadRequested>(_onLoadRequested);
    on<BookingLoadMoreRequested>(_onLoadMoreRequested);
    on<BookingRefreshRequested>(_onRefreshRequested);
    on<BookingCancelRequested>(_onCancelRequested);
    on<BookingFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoadRequested(
    BookingLoadRequested event,
    Emitter<BookingState> emit,
  ) async {
    if (!event.refresh) {
      emit(const BookingLoading());
    }

    try {
      String? startDateStr;
      String? endDateStr;
      if (event.startDate != null && event.endDate != null) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        startDateStr = dateFormat.format(event.startDate!);
        endDateStr = dateFormat.format(event.endDate!);
      }

      final response = await _bookingRepository.getUserBookings(
        page: 1,
        limit: _pageSize,
        status: event.status,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      // Separate bookings into upcoming and past
      final upcoming = response.bookings.where((b) => b.isUpcoming).toList();
      final past = response.bookings.where((b) => b.isPast).toList();

      emit(
        BookingLoaded(
          upcomingBookings: upcoming,
          pastBookings: past,
          currentPage: response.page,
          totalPages: response.totalPages,
          hasMore: response.hasNextPage,
          currentFilter: event.status,
          startDate: event.startDate,
          endDate: event.endDate,
          dateFilterType: event.dateFilterType,
        ),
      );
    } catch (e) {
      debugPrint('Booking load error: $e');
      emit(
        BookingError(
          message: 'Không thể tải danh sách lịch hẹn. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> _onLoadMoreRequested(
    BookingLoadMoreRequested event,
    Emitter<BookingState> emit,
  ) async {
    if (state is! BookingLoaded) return;

    final currentState = state as BookingLoaded;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      String? startDateStr;
      String? endDateStr;
      if (currentState.startDate != null && currentState.endDate != null) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        startDateStr = dateFormat.format(currentState.startDate!);
        endDateStr = dateFormat.format(currentState.endDate!);
      }

      final nextPage = currentState.currentPage + 1;
      final response = await _bookingRepository.getUserBookings(
        page: nextPage,
        limit: _pageSize,
        status: currentState.currentFilter,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      final upcoming = response.bookings.where((b) => b.isUpcoming).toList();
      final past = response.bookings.where((b) => b.isPast).toList();

      emit(
        currentState.copyWith(
          upcomingBookings: [...currentState.upcomingBookings, ...upcoming],
          pastBookings: [...currentState.pastBookings, ...past],
          currentPage: response.page,
          totalPages: response.totalPages,
          hasMore: response.hasNextPage,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      debugPrint('Booking load more error: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onRefreshRequested(
    BookingRefreshRequested event,
    Emitter<BookingState> emit,
  ) async {
    final loaded = state is BookingLoaded ? state as BookingLoaded : null;
    add(BookingLoadRequested(
      status: loaded?.currentFilter,
      refresh: true,
      startDate: loaded?.startDate,
      endDate: loaded?.endDate,
      dateFilterType: loaded?.dateFilterType,
    ));
  }

  Future<void> _onCancelRequested(
    BookingCancelRequested event,
    Emitter<BookingState> emit,
  ) async {
    if (state is! BookingLoaded) return;

    final currentState = state as BookingLoaded;

    try {
      await _bookingRepository.cancelBooking(
        bookingId: event.bookingId,
        reason: event.reason,
      );

      emit(
        BookingActionSuccess(
          message: 'Đã hủy lịch hẹn thành công',
          previousState: currentState,
        ),
      );

      // Reload bookings
      add(const BookingRefreshRequested());
    } catch (e) {
      debugPrint('Booking cancel error: $e');
      emit(BookingError(message: getErrorMessage(e)));
      emit(currentState);
    }
  }

  Future<void> _onFilterChanged(
    BookingFilterChanged event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      String? startDateStr;
      String? endDateStr;

      // Calculate date range based on filter type
      if (event.dateFilterType != null) {
        final now = DateTime.now();
        DateTime startDate;
        DateTime endDate;

        switch (event.dateFilterType) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
            break;
          case 'week':
            // Start from beginning of current week (Monday)
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            startDate = DateTime(
              weekStart.year,
              weekStart.month,
              weekStart.day,
            );
            endDate = startDate.add(
              const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
            );
            break;
          case 'month':
            startDate = DateTime(now.year, now.month, 1);
            endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            break;
          case 'custom':
            startDate = event.startDate ?? now;
            endDate = event.endDate ?? now;
            break;
          default:
            startDate = now;
            endDate = now;
        }

        startDateStr = dateFormat.format(startDate);
        endDateStr = dateFormat.format(endDate);
      } else if (event.startDate != null && event.endDate != null) {
        startDateStr = dateFormat.format(event.startDate!);
        endDateStr = dateFormat.format(event.endDate!);
      }

      final response = await _bookingRepository.getUserBookings(
        page: 1,
        limit: _pageSize,
        status: event.status,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      final upcoming = response.bookings.where((b) => b.isUpcoming).toList();
      final past = response.bookings.where((b) => b.isPast).toList();

      // Keep computed date range in state for refresh/load more
      DateTime? stateStartDate = event.startDate;
      DateTime? stateEndDate = event.endDate;
      if (event.dateFilterType != null && stateStartDate == null && event.dateFilterType != 'custom') {
        final now = DateTime.now();
        switch (event.dateFilterType) {
          case 'today':
            stateStartDate = DateTime(now.year, now.month, now.day);
            stateEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
            break;
          case 'week': {
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
            stateStartDate = weekStartDate;
            stateEndDate = weekStartDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
            break;
          }
          case 'month':
            stateStartDate = DateTime(now.year, now.month, 1);
            stateEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
            break;
          default:
            break;
        }
      } else if (event.dateFilterType == 'custom') {
        stateStartDate = event.startDate;
        stateEndDate = event.endDate;
      }

      emit(
        BookingLoaded(
          upcomingBookings: upcoming,
          pastBookings: past,
          currentPage: response.page,
          totalPages: response.totalPages,
          hasMore: response.hasNextPage,
          currentFilter: event.status,
          startDate: stateStartDate,
          endDate: stateEndDate,
          dateFilterType: event.dateFilterType,
        ),
      );
    } catch (e) {
      debugPrint('Booking filter error: $e');
      emit(
        BookingError(
          message: 'Không thể tải danh sách lịch hẹn. Vui lòng thử lại.',
        ),
      );
    }
  }
}
