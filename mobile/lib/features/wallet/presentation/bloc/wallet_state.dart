import 'package:equatable/equatable.dart';

import '../../data/models/wallet_models.dart';

/// States for WalletBloc
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WalletInitial extends WalletState {}

/// Loading state
class WalletLoading extends WalletState {}

/// Loaded state with wallet data
class WalletLoaded extends WalletState {
  final WalletModel wallet;
  final List<TransactionModel> transactions;
  final int totalTransactions;
  final int currentPage;
  final bool hasMoreTransactions;
  final bool isLoadingMore;
  final String? withdrawMessage;
  final bool? withdrawSuccess;

  const WalletLoaded({
    required this.wallet,
    this.transactions = const [],
    this.totalTransactions = 0,
    this.currentPage = 1,
    this.hasMoreTransactions = false,
    this.isLoadingMore = false,
    this.withdrawMessage,
    this.withdrawSuccess,
  });

  @override
  List<Object?> get props => [
        wallet,
        transactions,
        totalTransactions,
        currentPage,
        hasMoreTransactions,
        isLoadingMore,
        withdrawMessage,
        withdrawSuccess,
      ];

  WalletLoaded copyWith({
    WalletModel? wallet,
    List<TransactionModel>? transactions,
    int? totalTransactions,
    int? currentPage,
    bool? hasMoreTransactions,
    bool? isLoadingMore,
    String? withdrawMessage,
    bool? withdrawSuccess,
  }) {
    return WalletLoaded(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      currentPage: currentPage ?? this.currentPage,
      hasMoreTransactions: hasMoreTransactions ?? this.hasMoreTransactions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      withdrawMessage: withdrawMessage,
      withdrawSuccess: withdrawSuccess,
    );
  }
}

/// Error state
class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Withdrawal loading state
class WithdrawLoading extends WalletState {}

/// Withdrawal success state
class WithdrawSuccess extends WalletState {
  final String message;
  final TransactionModel? transaction;

  const WithdrawSuccess({required this.message, this.transaction});

  @override
  List<Object?> get props => [message, transaction];
}

/// Withdrawal error state
class WithdrawError extends WalletState {
  final String message;

  const WithdrawError(this.message);

  @override
  List<Object?> get props => [message];
}

/// TopUp loading state
class TopUpLoading extends WalletState {
  const TopUpLoading();
}

/// TopUp success state
class TopUpSuccess extends WalletState {
  final String message;
  final dynamic transaction;

  const TopUpSuccess({required this.message, this.transaction});

  @override
  List<Object?> get props => [message, transaction];
}

/// TopUp error state
class TopUpError extends WalletState {
  final String message;

  const TopUpError(this.message);

  @override
  List<Object?> get props => [message];
}
