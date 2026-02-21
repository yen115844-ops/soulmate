import 'package:equatable/equatable.dart';

import '../../data/models/partner_models.dart';

/// Partner Detail States
abstract class PartnerDetailState extends Equatable {
  const PartnerDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PartnerDetailInitial extends PartnerDetailState {}

/// Loading state
class PartnerDetailLoading extends PartnerDetailState {}

/// Loaded state with full partner data
class PartnerDetailLoaded extends PartnerDetailState {
  final PartnerDetailResponse detail;

  const PartnerDetailLoaded({required this.detail});

  @override
  List<Object?> get props => [detail];
}

/// Error state
class PartnerDetailError extends PartnerDetailState {
  final String message;

  const PartnerDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
