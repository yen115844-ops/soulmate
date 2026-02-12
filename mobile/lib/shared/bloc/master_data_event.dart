import 'package:equatable/equatable.dart';

/// Master Data Events
abstract class MasterDataEvent extends Equatable {
  const MasterDataEvent();

  @override
  List<Object?> get props => [];
}

/// Load profile master data (provinces, interests, talents, languages)
class MasterDataLoadRequested extends MasterDataEvent {
  const MasterDataLoadRequested();
}

/// Load partner master data (provinces, service types)
class PartnerMasterDataLoadRequested extends MasterDataEvent {
  const PartnerMasterDataLoadRequested();
}

/// Load districts for a province
class DistrictsLoadRequested extends MasterDataEvent {
  final String provinceId;

  const DistrictsLoadRequested(this.provinceId);

  @override
  List<Object?> get props => [provinceId];
}

/// Reset master data state (on logout)
class MasterDataResetRequested extends MasterDataEvent {
  const MasterDataResetRequested();
}
