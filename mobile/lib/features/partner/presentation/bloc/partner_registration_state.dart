import 'package:equatable/equatable.dart';

import '../../data/partner_repository.dart';

/// States for PartnerRegistrationBloc
abstract class PartnerRegistrationState extends Equatable {
  const PartnerRegistrationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PartnerRegistrationInitial extends PartnerRegistrationState {
  const PartnerRegistrationInitial();
}

/// Loading state
class PartnerRegistrationLoading extends PartnerRegistrationState {
  final String message;

  const PartnerRegistrationLoading({this.message = 'Đang xử lý...'});

  @override
  List<Object?> get props => [message];
}

/// Uploading photos state
class PartnerRegistrationUploadingPhotos extends PartnerRegistrationState {
  final int current;
  final int total;

  const PartnerRegistrationUploadingPhotos({
    required this.current,
    required this.total,
  });

  String get message => 'Đang tải ảnh ($current/$total)...';

  @override
  List<Object?> get props => [current, total];
}

/// Success state
class PartnerRegistrationSuccess extends PartnerRegistrationState {
  final PartnerProfileResponse profile;

  const PartnerRegistrationSuccess(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Failure state
class PartnerRegistrationFailure extends PartnerRegistrationState {
  final String error;
  final bool isAlreadyPartner;

  const PartnerRegistrationFailure({
    required this.error,
    this.isAlreadyPartner = false,
  });

  @override
  List<Object?> get props => [error, isAlreadyPartner];
}
