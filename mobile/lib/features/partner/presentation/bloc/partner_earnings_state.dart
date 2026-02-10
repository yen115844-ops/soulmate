import 'package:equatable/equatable.dart';

import '../../data/partner_repository.dart';

/// States for PartnerEarningsBloc
abstract class PartnerEarningsState extends Equatable {
  const PartnerEarningsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PartnerEarningsInitial extends PartnerEarningsState {
  const PartnerEarningsInitial();
}

/// Loading state
class PartnerEarningsLoading extends PartnerEarningsState {
  const PartnerEarningsLoading();
}

/// Loaded state
class PartnerEarningsLoaded extends PartnerEarningsState {
  final PartnerEarningsData earningsData;
  final String currentPeriod;

  const PartnerEarningsLoaded({
    required this.earningsData,
    required this.currentPeriod,
  });

  /// Copy with new values
  PartnerEarningsLoaded copyWith({
    PartnerEarningsData? earningsData,
    String? currentPeriod,
  }) {
    return PartnerEarningsLoaded(
      earningsData: earningsData ?? this.earningsData,
      currentPeriod: currentPeriod ?? this.currentPeriod,
    );
  }

  @override
  List<Object?> get props => [earningsData, currentPeriod];
}

/// Withdrawal in progress
class PartnerEarningsWithdrawInProgress extends PartnerEarningsState {
  final PartnerEarningsData earningsData;

  const PartnerEarningsWithdrawInProgress({required this.earningsData});

  @override
  List<Object?> get props => [earningsData];
}

/// Withdrawal success
class PartnerEarningsWithdrawSuccess extends PartnerEarningsState {
  final String message;
  final PartnerEarningsData earningsData;

  const PartnerEarningsWithdrawSuccess({
    required this.message,
    required this.earningsData,
  });

  @override
  List<Object?> get props => [message, earningsData];
}

/// Error state
class PartnerEarningsError extends PartnerEarningsState {
  final String message;

  const PartnerEarningsError({required this.message});

  @override
  List<Object?> get props => [message];
}
