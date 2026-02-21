import 'package:equatable/equatable.dart';

import '../../data/models/credits_models.dart';

abstract class CreditsState extends Equatable {
  const CreditsState();

  @override
  List<Object?> get props => [];
}

class CreditsInitial extends CreditsState {
  const CreditsInitial();
}

class CreditsLoading extends CreditsState {
  const CreditsLoading();
}

class CreditsLoaded extends CreditsState {
  final CreditWallet wallet;
  final List<CreditPackage> packages;

  const CreditsLoaded({
    required this.wallet,
    required this.packages,
  });

  @override
  List<Object?> get props => [wallet, packages];
}

class TransactionsLoaded extends CreditsState {
  final List<CreditTransaction> transactions;
  final int total;
  final int page;

  const TransactionsLoaded({
    required this.transactions,
    required this.total,
    required this.page,
  });

  @override
  List<Object?> get props => [transactions, total, page];
}

class CreditsPurchasing extends CreditsState {
  const CreditsPurchasing();
}

class CreditsPurchaseSuccess extends CreditsState {
  final int creditsReceived;
  final int newBalance;

  const CreditsPurchaseSuccess({
    required this.creditsReceived,
    required this.newBalance,
  });

  @override
  List<Object?> get props => [creditsReceived, newBalance];
}

class CreditsWithdrawing extends CreditsState {
  const CreditsWithdrawing();
}

class CreditsWithdrawalSuccess extends CreditsState {
  final String message;

  const CreditsWithdrawalSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class CreditsError extends CreditsState {
  final String message;
  final CreditWallet? wallet;
  final List<CreditPackage> packages;

  const CreditsError({
    required this.message,
    this.wallet,
    this.packages = const [],
  });

  @override
  List<Object?> get props => [message, wallet, packages];
}

class BankInfoUpdated extends CreditsState {
  const BankInfoUpdated();
}
