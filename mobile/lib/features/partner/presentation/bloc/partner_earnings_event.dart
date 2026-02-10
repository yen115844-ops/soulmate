import 'package:equatable/equatable.dart';

/// Events for PartnerEarningsBloc
abstract class PartnerEarningsEvent extends Equatable {
  const PartnerEarningsEvent();

  @override
  List<Object?> get props => [];
}

/// Load earnings data
class PartnerEarningsLoadRequested extends PartnerEarningsEvent {
  final String period; // week, month, year, all

  const PartnerEarningsLoadRequested({this.period = 'month'});

  @override
  List<Object?> get props => [period];
}

/// Refresh earnings
class PartnerEarningsRefreshRequested extends PartnerEarningsEvent {
  const PartnerEarningsRefreshRequested();
}

/// Change period filter
class PartnerEarningsPeriodChanged extends PartnerEarningsEvent {
  final String period;

  const PartnerEarningsPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

/// Request withdrawal
class PartnerEarningsWithdrawRequested extends PartnerEarningsEvent {
  final double amount;
  final String? note;

  const PartnerEarningsWithdrawRequested({
    required this.amount,
    this.note,
  });

  @override
  List<Object?> get props => [amount, note];
}
