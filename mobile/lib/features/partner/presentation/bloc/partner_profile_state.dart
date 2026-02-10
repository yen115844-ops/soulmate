import 'package:equatable/equatable.dart';

import '../../data/partner_repository.dart';

/// States for PartnerProfileBloc
abstract class PartnerProfileState extends Equatable {
  const PartnerProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PartnerProfileInitial extends PartnerProfileState {
  const PartnerProfileInitial();
}

/// Loading state
class PartnerProfileLoading extends PartnerProfileState {
  const PartnerProfileLoading();
}

/// Loaded state with profile data
class PartnerProfileLoaded extends PartnerProfileState {
  final PartnerProfileResponse profile;
  final PartnerUserProfileInfo? userProfile;

  const PartnerProfileLoaded({
    required this.profile,
    this.userProfile,
  });

  @override
  List<Object?> get props => [profile, userProfile];
}

/// Error state
class PartnerProfileError extends PartnerProfileState {
  final String message;

  const PartnerProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Updating state (while saving)
class PartnerProfileUpdating extends PartnerProfileState {
  final PartnerProfileResponse profile;
  final PartnerUserProfileInfo? userProfile;

  const PartnerProfileUpdating({
    required this.profile,
    this.userProfile,
  });

  @override
  List<Object?> get props => [profile, userProfile];
}
