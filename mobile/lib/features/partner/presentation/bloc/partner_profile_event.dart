import 'package:equatable/equatable.dart';

/// Events for PartnerProfileBloc
abstract class PartnerProfileEvent extends Equatable {
  const PartnerProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load partner profile
class PartnerProfileLoadRequested extends PartnerProfileEvent {
  const PartnerProfileLoadRequested();
}

/// Refresh partner profile
class PartnerProfileRefreshRequested extends PartnerProfileEvent {
  const PartnerProfileRefreshRequested();
}

/// Update partner profile
class PartnerProfileUpdateRequested extends PartnerProfileEvent {
  final List<String>? serviceTypes;
  final int? hourlyRate;
  final String? introduction;
  final int? minimumHours;
  final bool? isAvailable;

  const PartnerProfileUpdateRequested({
    this.serviceTypes,
    this.hourlyRate,
    this.introduction,
    this.minimumHours,
    this.isAvailable,
  });

  @override
  List<Object?> get props => [serviceTypes, hourlyRate, introduction, minimumHours, isAvailable];
}

/// Toggle availability
class PartnerAvailabilityToggleRequested extends PartnerProfileEvent {
  final bool isAvailable;

  const PartnerAvailabilityToggleRequested({required this.isAvailable});

  @override
  List<Object?> get props => [isAvailable];
}
