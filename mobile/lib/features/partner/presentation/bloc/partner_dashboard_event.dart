import 'package:equatable/equatable.dart';

/// Events for PartnerDashboardBloc
abstract class PartnerDashboardEvent extends Equatable {
  const PartnerDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Load dashboard data
class PartnerDashboardLoadRequested extends PartnerDashboardEvent {
  const PartnerDashboardLoadRequested();
}

/// Refresh dashboard data (pull to refresh)
class PartnerDashboardRefreshRequested extends PartnerDashboardEvent {
  const PartnerDashboardRefreshRequested();
}

/// Refresh dashboard after action (confirm/cancel booking, etc.)
/// This ensures stats are updated after actions in other pages
class PartnerDashboardRefreshAfterAction extends PartnerDashboardEvent {
  const PartnerDashboardRefreshAfterAction();
}

/// Toggle partner availability
class PartnerAvailabilityToggled extends PartnerDashboardEvent {
  final bool isAvailable;

  const PartnerAvailabilityToggled(this.isAvailable);

  @override
  List<Object?> get props => [isAvailable];
}

/// Clear any error message in the state
class PartnerDashboardClearError extends PartnerDashboardEvent {
  const PartnerDashboardClearError();
}

/// Update notification count
class PartnerNotificationCountUpdated extends PartnerDashboardEvent {
  final int count;

  const PartnerNotificationCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}
