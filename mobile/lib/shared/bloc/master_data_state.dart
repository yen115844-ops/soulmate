import 'package:equatable/equatable.dart';

import '../data/models/master_data_models.dart';

/// Master Data States
abstract class MasterDataState extends Equatable {
  const MasterDataState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MasterDataInitial extends MasterDataState {
  const MasterDataInitial();
}

/// Loading state
class MasterDataLoading extends MasterDataState {
  const MasterDataLoading();
}

/// Profile master data loaded state
class MasterDataLoaded extends MasterDataState {
  final List<ProvinceModel> provinces;
  final List<InterestModel> interests;
  final List<TalentModel> talents;
  final List<LanguageModel> languages;
  final List<DistrictModel> districts;
  final String? selectedProvinceId;

  const MasterDataLoaded({
    required this.provinces,
    required this.interests,
    required this.talents,
    required this.languages,
    this.districts = const [],
    this.selectedProvinceId,
  });

  MasterDataLoaded copyWith({
    List<ProvinceModel>? provinces,
    List<InterestModel>? interests,
    List<TalentModel>? talents,
    List<LanguageModel>? languages,
    List<DistrictModel>? districts,
    String? selectedProvinceId,
  }) {
    return MasterDataLoaded(
      provinces: provinces ?? this.provinces,
      interests: interests ?? this.interests,
      talents: talents ?? this.talents,
      languages: languages ?? this.languages,
      districts: districts ?? this.districts,
      selectedProvinceId: selectedProvinceId ?? this.selectedProvinceId,
    );
  }

  @override
  List<Object?> get props => [
        provinces,
        interests,
        talents,
        languages,
        districts,
        selectedProvinceId,
      ];
}

/// Partner master data loaded state
class PartnerMasterDataLoaded extends MasterDataState {
  final List<ProvinceModel> provinces;
  final List<ServiceTypeModel> serviceTypes;
  final List<DistrictModel> districts;
  final String? selectedProvinceId;

  const PartnerMasterDataLoaded({
    required this.provinces,
    required this.serviceTypes,
    this.districts = const [],
    this.selectedProvinceId,
  });

  PartnerMasterDataLoaded copyWith({
    List<ProvinceModel>? provinces,
    List<ServiceTypeModel>? serviceTypes,
    List<DistrictModel>? districts,
    String? selectedProvinceId,
  }) {
    return PartnerMasterDataLoaded(
      provinces: provinces ?? this.provinces,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      districts: districts ?? this.districts,
      selectedProvinceId: selectedProvinceId ?? this.selectedProvinceId,
    );
  }

  @override
  List<Object?> get props => [
        provinces,
        serviceTypes,
        districts,
        selectedProvinceId,
      ];
}

/// Error state
class MasterDataError extends MasterDataState {
  final String message;

  const MasterDataError(this.message);

  @override
  List<Object?> get props => [message];
}
