import 'package:equatable/equatable.dart';

/// Events for WalletBloc
abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Load wallet and transactions
class LoadWallet extends WalletEvent {
  final bool refresh;

  const LoadWallet({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// Load more transactions (pagination)
class LoadTransactions extends WalletEvent {
  final bool loadMore;

  const LoadTransactions({this.loadMore = false});

  @override
  List<Object?> get props => [loadMore];
}

/// Request withdrawal
class RequestWithdraw extends WalletEvent {
  final double amount;
  final String? bankName;
  final String? bankAccountNo;
  final String? bankAccountName;

  const RequestWithdraw({
    required this.amount,
    this.bankName,
    this.bankAccountNo,
    this.bankAccountName,
  });

  @override
  List<Object?> get props => [amount, bankName, bankAccountNo, bankAccountName];
}

/// Request top up
class RequestTopUp extends WalletEvent {
  final double amount;
  final String paymentMethod;

  const RequestTopUp({
    required this.amount,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [amount, paymentMethod];
}
