import 'dart:io';

import 'package:equatable/equatable.dart';

/// Events for PartnerRegistrationBloc
abstract class PartnerRegistrationEvent extends Equatable {
  const PartnerRegistrationEvent();

  @override
  List<Object?> get props => [];
}

/// Submit partner registration event
class PartnerRegistrationSubmitted extends PartnerRegistrationEvent {
  final List<String> serviceTypes;
  final int hourlyRate;
  final String introduction;
  final String bio;
  final String bankName;
  final String bankAccountNo;
  final String bankAccountName;
  final List<File> photos;
  final int? minimumHours;
  final int? experienceYears;

  const PartnerRegistrationSubmitted({
    required this.serviceTypes,
    required this.hourlyRate,
    required this.introduction,
    required this.bio,
    required this.bankName,
    required this.bankAccountNo,
    required this.bankAccountName,
    required this.photos,
    this.minimumHours,
    this.experienceYears,
  });

  @override
  List<Object?> get props => [
        serviceTypes,
        hourlyRate,
        introduction,
        bio,
        bankName,
        bankAccountNo,
        bankAccountName,
        photos,
        minimumHours,
        experienceYears,
      ];
}

/// Reset partner registration event
class PartnerRegistrationReset extends PartnerRegistrationEvent {
  const PartnerRegistrationReset();
}
