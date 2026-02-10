import 'package:equatable/equatable.dart';

import '../../data/partner_repository.dart';

/// States for PartnerDashboardBloc
abstract class PartnerDashboardState extends Equatable {
  const PartnerDashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PartnerDashboardInitial extends PartnerDashboardState {
  const PartnerDashboardInitial();
}

/// Loading state
class PartnerDashboardLoading extends PartnerDashboardState {
  const PartnerDashboardLoading();
}

/// Loaded state with dashboard data
class PartnerDashboardLoaded extends PartnerDashboardState {
  final PartnerDashboardData dashboardData;
  final int unreadNotificationCount;
  final String?
  errorMessage; // For showing snackbar errors without changing state
  final DateTime lastRefreshTime;

  PartnerDashboardLoaded({
    required this.dashboardData,
    this.unreadNotificationCount = 0,
    this.errorMessage,
    DateTime? lastRefreshTime,
  }) : lastRefreshTime = lastRefreshTime ?? DateTime.now();

  // Convenience getters
  PartnerProfileResponse get profile => dashboardData.profile;
  PartnerStats get stats => dashboardData.stats;
  List<PartnerBooking> get upcomingBookings => dashboardData.upcomingBookings;
  PartnerUserInfo? get userInfo => dashboardData.userInfo;

  // Copy with method for updating state
  PartnerDashboardLoaded copyWith({
    PartnerDashboardData? dashboardData,
    int? unreadNotificationCount,
    String? errorMessage,
    DateTime? lastRefreshTime,
    bool clearError = false,
  }) {
    return PartnerDashboardLoaded(
      dashboardData: dashboardData ?? this.dashboardData,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
    );
  }

  @override
  List<Object?> get props => [
    dashboardData,
    unreadNotificationCount,
    errorMessage,
    lastRefreshTime,
  ];
}

/// Error state
class PartnerDashboardError extends PartnerDashboardState {
  final String message;

  const PartnerDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Availability updating state
class PartnerAvailabilityUpdating extends PartnerDashboardState {
  final PartnerDashboardData dashboardData;
  final int unreadNotificationCount;

  const PartnerAvailabilityUpdating({
    required this.dashboardData,
    this.unreadNotificationCount = 0,
  });

  @override
  List<Object?> get props => [dashboardData, unreadNotificationCount];
}

/// Availability toggle failed state (for showing error snackbar)
class PartnerAvailabilityToggleFailed extends PartnerDashboardState {
  final PartnerDashboardData dashboardData;
  final int unreadNotificationCount;
  final String errorMessage;

  const PartnerAvailabilityToggleFailed({
    required this.dashboardData,
    required this.errorMessage,
    this.unreadNotificationCount = 0,
  });

  @override
  List<Object?> get props => [
    dashboardData,
    errorMessage,
    unreadNotificationCount,
  ];
}
