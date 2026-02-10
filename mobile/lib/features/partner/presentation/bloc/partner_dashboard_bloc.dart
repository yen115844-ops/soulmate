import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/repositories/notification_repository.dart';
import '../../data/partner_repository.dart';
import 'partner_dashboard_event.dart';
import 'partner_dashboard_state.dart';

class PartnerDashboardBloc
    extends Bloc<PartnerDashboardEvent, PartnerDashboardState> {
  final PartnerRepository _partnerRepository;
  final NotificationRepository? _notificationRepository;

  PartnerDashboardBloc({
    required PartnerRepository partnerRepository,
    NotificationRepository? notificationRepository,
  }) : _partnerRepository = partnerRepository,
       _notificationRepository = notificationRepository,
       super(const PartnerDashboardInitial()) {
    on<PartnerDashboardLoadRequested>(_onLoadRequested);
    on<PartnerDashboardRefreshRequested>(_onRefreshRequested);
    on<PartnerDashboardRefreshAfterAction>(_onRefreshAfterAction);
    on<PartnerAvailabilityToggled>(_onAvailabilityToggled);
    on<PartnerDashboardClearError>(_onClearError);
    on<PartnerNotificationCountUpdated>(_onNotificationCountUpdated);
  }

  Future<void> _onLoadRequested(
    PartnerDashboardLoadRequested event,
    Emitter<PartnerDashboardState> emit,
  ) async {
    emit(const PartnerDashboardLoading());

    try {
      // Fetch dashboard data and notification count in parallel
      final results = await Future.wait([
        _partnerRepository.getPartnerDashboard(),
        _fetchNotificationCount(),
      ]);

      final dashboardData = results[0] as PartnerDashboardData;
      final notificationCount = results[1] as int;

      emit(
        PartnerDashboardLoaded(
          dashboardData: dashboardData,
          unreadNotificationCount: notificationCount,
        ),
      );
    } catch (e) {
      debugPrint('Partner dashboard load error: $e');
      emit(
        PartnerDashboardError(
          message: 'Không thể tải dữ liệu. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    PartnerDashboardRefreshRequested event,
    Emitter<PartnerDashboardState> emit,
  ) async {
    // Keep current data while refreshing
    final currentNotificationCount = _getCurrentNotificationCount();

    try {
      final results = await Future.wait([
        _partnerRepository.getPartnerDashboard(),
        _fetchNotificationCount(),
      ]);

      final dashboardData = results[0] as PartnerDashboardData;
      final notificationCount = results[1] as int;

      emit(
        PartnerDashboardLoaded(
          dashboardData: dashboardData,
          unreadNotificationCount: notificationCount,
        ),
      );
    } catch (e) {
      debugPrint('Partner dashboard refresh error: $e');
      // Keep current state on refresh error, but show error message
      if (state is PartnerDashboardLoaded) {
        final currentState = state as PartnerDashboardLoaded;
        emit(
          currentState.copyWith(errorMessage: 'Không thể cập nhật dữ liệu.'),
        );
      } else if (state is PartnerAvailabilityUpdating) {
        final currentState = state as PartnerAvailabilityUpdating;
        emit(
          PartnerDashboardLoaded(
            dashboardData: currentState.dashboardData,
            unreadNotificationCount: currentNotificationCount,
            errorMessage: 'Không thể cập nhật dữ liệu.',
          ),
        );
      }
    }
  }

  Future<void> _onRefreshAfterAction(
    PartnerDashboardRefreshAfterAction event,
    Emitter<PartnerDashboardState> emit,
  ) async {
    // Silent refresh after action (confirm/cancel booking)
    try {
      final results = await Future.wait([
        _partnerRepository.getPartnerDashboard(),
        _fetchNotificationCount(),
      ]);

      final dashboardData = results[0] as PartnerDashboardData;
      final notificationCount = results[1] as int;

      emit(
        PartnerDashboardLoaded(
          dashboardData: dashboardData,
          unreadNotificationCount: notificationCount,
        ),
      );
    } catch (e) {
      debugPrint('Partner dashboard refresh after action error: $e');
      // Silent fail - don't show error for background refresh
    }
  }

  Future<void> _onAvailabilityToggled(
    PartnerAvailabilityToggled event,
    Emitter<PartnerDashboardState> emit,
  ) async {
    if (state is! PartnerDashboardLoaded &&
        state is! PartnerAvailabilityToggleFailed) {
      return;
    }

    final currentData = _getCurrentDashboardData();
    final currentNotificationCount = _getCurrentNotificationCount();

    if (currentData == null) return;

    emit(
      PartnerAvailabilityUpdating(
        dashboardData: currentData,
        unreadNotificationCount: currentNotificationCount,
      ),
    );

    try {
      final updatedProfile = await _partnerRepository.toggleAvailability(
        event.isAvailable,
      );

      // Update profile in dashboard data
      final newDashboardData = PartnerDashboardData(
        profile: updatedProfile,
        stats: currentData.stats,
        upcomingBookings: currentData.upcomingBookings,
        userInfo: currentData.userInfo,
      );

      emit(
        PartnerDashboardLoaded(
          dashboardData: newDashboardData,
          unreadNotificationCount: currentNotificationCount,
        ),
      );
    } catch (e) {
      debugPrint('Toggle availability error: $e');
      // Emit failed state with error message for snackbar
      emit(
        PartnerAvailabilityToggleFailed(
          dashboardData: currentData,
          errorMessage: 'Không thể cập nhật trạng thái. Vui lòng thử lại.',
          unreadNotificationCount: currentNotificationCount,
        ),
      );

      // Then immediately emit loaded state to restore UI
      await Future.delayed(const Duration(milliseconds: 100));
      emit(
        PartnerDashboardLoaded(
          dashboardData: currentData,
          unreadNotificationCount: currentNotificationCount,
        ),
      );
    }
  }

  void _onClearError(
    PartnerDashboardClearError event,
    Emitter<PartnerDashboardState> emit,
  ) {
    if (state is PartnerDashboardLoaded) {
      final currentState = state as PartnerDashboardLoaded;
      emit(currentState.copyWith(clearError: true));
    }
  }

  void _onNotificationCountUpdated(
    PartnerNotificationCountUpdated event,
    Emitter<PartnerDashboardState> emit,
  ) {
    if (state is PartnerDashboardLoaded) {
      final currentState = state as PartnerDashboardLoaded;
      emit(currentState.copyWith(unreadNotificationCount: event.count));
    }
  }

  /// Fetch notification count, return 0 if fails
  Future<int> _fetchNotificationCount() async {
    if (_notificationRepository == null) return 0;
    try {
      return await _notificationRepository.getUnreadCount();
    } catch (e) {
      debugPrint('Fetch notification count error: $e');
      return 0;
    }
  }

  /// Get current notification count from state
  int _getCurrentNotificationCount() {
    if (state is PartnerDashboardLoaded) {
      return (state as PartnerDashboardLoaded).unreadNotificationCount;
    } else if (state is PartnerAvailabilityUpdating) {
      return (state as PartnerAvailabilityUpdating).unreadNotificationCount;
    } else if (state is PartnerAvailabilityToggleFailed) {
      return (state as PartnerAvailabilityToggleFailed).unreadNotificationCount;
    }
    return 0;
  }

  /// Get current dashboard data from state
  PartnerDashboardData? _getCurrentDashboardData() {
    if (state is PartnerDashboardLoaded) {
      return (state as PartnerDashboardLoaded).dashboardData;
    } else if (state is PartnerAvailabilityUpdating) {
      return (state as PartnerAvailabilityUpdating).dashboardData;
    } else if (state is PartnerAvailabilityToggleFailed) {
      return (state as PartnerAvailabilityToggleFailed).dashboardData;
    }
    return null;
  }
}
