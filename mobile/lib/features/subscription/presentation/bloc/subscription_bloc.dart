import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/subscription_repository.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;

  SubscriptionBloc({required SubscriptionRepository repository})
      : _repository = repository,
        super(const SubscriptionState()) {
    on<SubscriptionPlansRequested>(_onPlansRequested);
    on<SubscriptionStatusRequested>(_onStatusRequested);
    on<SubscriptionPurchaseRequested>(_onPurchaseRequested);
    on<SubscriptionPurchaseCompleted>(_onPurchaseCompleted);
    on<SubscriptionRestoreRequested>(_onRestoreRequested);
    on<SubscriptionAdmirersRequested>(_onAdmirersRequested);
  }

  Future<void> _onPlansRequested(
    SubscriptionPlansRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStateStatus.loading));

    try {
      final plans = await _repository.getPlans();
      emit(state.copyWith(
        status: SubscriptionStateStatus.success,
        plans: plans,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubscriptionStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onStatusRequested(
    SubscriptionStatusRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStateStatus.loading));

    try {
      final premiumStatus = await _repository.getStatus();
      emit(state.copyWith(
        status: SubscriptionStateStatus.success,
        premiumStatus: premiumStatus,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubscriptionStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onPurchaseRequested(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(
      status: SubscriptionStateStatus.purchasing,
      purchasingPlanId: event.planId,
    ));

    // The actual IAP flow will be handled by the IAP service
    // This event just marks the beginning of the purchase process
    // The SubscriptionPurchaseCompleted event will be triggered
    // after the IAP callback with the receipt data
  }

  Future<void> _onPurchaseCompleted(
    SubscriptionPurchaseCompleted event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final premiumStatus = await _repository.verifyPurchase(
        platform: event.platform,
        productId: event.productId,
        receiptData: event.receiptData,
        transactionId: event.transactionId,
      );
      emit(state.copyWith(
        status: SubscriptionStateStatus.success,
        premiumStatus: premiumStatus,
        purchasingPlanId: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubscriptionStateStatus.error,
        error: e.toString(),
        purchasingPlanId: null,
      ));
    }
  }

  Future<void> _onRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStateStatus.restoring));

    try {
      final premiumStatus = await _repository.restorePurchases(
        platform: event.platform,
        receiptData: event.receiptData,
      );
      emit(state.copyWith(
        status: SubscriptionStateStatus.success,
        premiumStatus: premiumStatus,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubscriptionStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAdmirersRequested(
    SubscriptionAdmirersRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStateStatus.loading));

    try {
      final admirers = await _repository.getAdmirers();
      emit(state.copyWith(
        status: SubscriptionStateStatus.success,
        admirers: admirers,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubscriptionStateStatus.error,
        error: e.toString(),
      ));
    }
  }
}
