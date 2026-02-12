import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/models/wallet_models.dart';
import '../../data/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

// Re-export events and states for backward compatibility
export 'wallet_event.dart';
export 'wallet_state.dart';

/// BLoC for wallet management
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _repository;
  static const int _pageSize = 20;

  WalletBloc({required WalletRepository repository})
    : _repository = repository,
      super(WalletInitial()) {
    on<LoadWallet>(_onLoadWallet);
    on<LoadTransactions>(_onLoadTransactions);
    on<RequestWithdraw>(_onRequestWithdraw);
    on<RequestTopUp>(_onRequestTopUp);
  }

  Future<void> _onLoadWallet(
    LoadWallet event,
    Emitter<WalletState> emit,
  ) async {
    try {
      if (!event.refresh && state is! WalletLoaded) {
        emit(WalletLoading());
      }

      final results = await Future.wait([
        _repository.getWallet(),
        _repository.getTransactions(page: 1, limit: _pageSize),
      ]);

      final wallet = results[0] as WalletModel;
      final transactionsResponse = results[1] as TransactionsResponse;

      emit(WalletLoaded(
        wallet: wallet,
        transactions: transactionsResponse.data,
        totalTransactions: transactionsResponse.total,
        currentPage: 1,
        hasMoreTransactions: transactionsResponse.hasMore,
      ));
    } catch (e) {
      emit(WalletError(getErrorMessage(e)));
    }
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WalletLoaded) return;

    if (event.loadMore) {
      if (currentState.isLoadingMore || !currentState.hasMoreTransactions) {
        return;
      }

      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final nextPage = currentState.currentPage + 1;
        final response = await _repository.getTransactions(
          page: nextPage,
          limit: _pageSize,
        );

        emit(currentState.copyWith(
          transactions: [...currentState.transactions, ...response.data],
          totalTransactions: response.total,
          currentPage: nextPage,
          hasMoreTransactions: response.hasMore,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    } else {
      // Refresh transactions
      try {
        final response = await _repository.getTransactions(
          page: 1,
          limit: _pageSize,
        );

        emit(currentState.copyWith(
          transactions: response.data,
          totalTransactions: response.total,
          currentPage: 1,
          hasMoreTransactions: response.hasMore,
        ));
      } catch (e) {
        // Keep current data on error
      }
    }
  }

  Future<void> _onRequestWithdraw(
    RequestWithdraw event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;

    emit(WithdrawLoading());

    try {
      final response = await _repository.requestWithdraw(
        amount: event.amount,
        bankName: event.bankName,
        bankAccountNo: event.bankAccountNo,
        bankAccountName: event.bankAccountName,
      );

      if (response.success) {
        emit(WithdrawSuccess(
          message: response.message,
          transaction: response.transaction,
        ));

        // Reload wallet after successful withdrawal
        add(const LoadWallet(refresh: true));
      } else {
        emit(WithdrawError(response.message));

        // Restore previous state
        if (currentState is WalletLoaded) {
          emit(currentState);
        }
      }
    } catch (e) {
      emit(WithdrawError(getErrorMessage(e)));

      // Restore previous state
      if (currentState is WalletLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onRequestTopUp(
    RequestTopUp event,
    Emitter<WalletState> emit,
  ) async {
    final currentState = state;

    emit(const TopUpLoading());

    try {
      final response = await _repository.topUp(
        amount: event.amount,
        paymentMethod: event.paymentMethod,
      );

      if (response.success) {
        emit(TopUpSuccess(
          message: response.message,
          transaction: response.transaction,
        ));

        // Reload wallet after successful top-up
        add(const LoadWallet(refresh: true));
      } else {
        emit(TopUpError(response.message));

        // Restore previous state
        if (currentState is WalletLoaded) {
          emit(currentState);
        }
      }
    } catch (e) {
      emit(TopUpError(getErrorMessage(e)));

      // Restore previous state
      if (currentState is WalletLoaded) {
        emit(currentState);
      }
    }
  }
}
