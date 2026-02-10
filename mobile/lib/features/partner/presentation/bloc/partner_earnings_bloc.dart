import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/partner_repository.dart';
import 'partner_earnings_event.dart';
import 'partner_earnings_state.dart';

class PartnerEarningsBloc
    extends Bloc<PartnerEarningsEvent, PartnerEarningsState> {
  final PartnerRepository _partnerRepository;

  PartnerEarningsBloc({required PartnerRepository partnerRepository})
      : _partnerRepository = partnerRepository,
        super(const PartnerEarningsInitial()) {
    on<PartnerEarningsLoadRequested>(_onLoadRequested);
    on<PartnerEarningsRefreshRequested>(_onRefreshRequested);
    on<PartnerEarningsPeriodChanged>(_onPeriodChanged);
    on<PartnerEarningsWithdrawRequested>(_onWithdrawRequested);
  }

  Future<void> _onLoadRequested(
    PartnerEarningsLoadRequested event,
    Emitter<PartnerEarningsState> emit,
  ) async {
    emit(const PartnerEarningsLoading());

    try {
      final data = await _partnerRepository.getPartnerEarnings(
        period: event.period,
      );
      emit(PartnerEarningsLoaded(
        earningsData: data,
        currentPeriod: event.period,
      ));
    } catch (e) {
      debugPrint('Partner earnings load error: $e');
      emit(PartnerEarningsError(message: 'Không thể tải thu nhập. $e'));
    }
  }

  Future<void> _onRefreshRequested(
    PartnerEarningsRefreshRequested event,
    Emitter<PartnerEarningsState> emit,
  ) async {
    final currentPeriod =
        state is PartnerEarningsLoaded ? (state as PartnerEarningsLoaded).currentPeriod : 'month';

    try {
      final data = await _partnerRepository.getPartnerEarnings(
        period: currentPeriod,
      );
      emit(PartnerEarningsLoaded(
        earningsData: data,
        currentPeriod: currentPeriod,
      ));
    } catch (e) {
      debugPrint('Partner earnings refresh error: $e');
      // Keep current state on refresh error
    }
  }

  Future<void> _onPeriodChanged(
    PartnerEarningsPeriodChanged event,
    Emitter<PartnerEarningsState> emit,
  ) async {
    add(PartnerEarningsLoadRequested(period: event.period));
  }

  Future<void> _onWithdrawRequested(
    PartnerEarningsWithdrawRequested event,
    Emitter<PartnerEarningsState> emit,
  ) async {
    if (state is! PartnerEarningsLoaded) return;

    final currentState = state as PartnerEarningsLoaded;
    emit(PartnerEarningsWithdrawInProgress(
      earningsData: currentState.earningsData,
    ));

    try {
      // Call API to request withdrawal
      await _partnerRepository.requestWithdrawal(
        amount: event.amount,
        note: event.note,
      );

      // Refresh data
      final updatedData = await _partnerRepository.getPartnerEarnings(
        period: currentState.currentPeriod,
      );

      emit(PartnerEarningsWithdrawSuccess(
        message: 'Yêu cầu rút tiền đã được gửi',
        earningsData: updatedData,
      ));
    } catch (e) {
      debugPrint('Withdraw request error: $e');
      emit(PartnerEarningsError(message: 'Không thể gửi yêu cầu rút tiền. $e'));
    }
  }
}
