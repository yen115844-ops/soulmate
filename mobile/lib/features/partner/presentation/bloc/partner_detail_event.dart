import 'package:equatable/equatable.dart';

/// Partner Detail Events
abstract class PartnerDetailEvent extends Equatable {
  const PartnerDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Load partner detail by ID
class LoadPartnerDetail extends PartnerDetailEvent {
  final String partnerId;

  const LoadPartnerDetail({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

/// Refresh partner detail
class RefreshPartnerDetail extends PartnerDetailEvent {
  final String partnerId;

  const RefreshPartnerDetail({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}
