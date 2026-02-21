import 'package:equatable/equatable.dart';

import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

enum SubscriptionStateStatus {
  initial,
  loading,
  purchasing,
  restoring,
  success,
  error,
}

class SubscriptionState extends Equatable {
  final SubscriptionStateStatus status;
  final List<SubscriptionPlanEntity> plans;
  final PremiumStatusEntity? premiumStatus;
  final List<AdmirerEntity> admirers;
  final String? error;
  final String? purchasingPlanId;

  const SubscriptionState({
    this.status = SubscriptionStateStatus.initial,
    this.plans = const [],
    this.premiumStatus,
    this.admirers = const [],
    this.error,
    this.purchasingPlanId,
  });

  bool get isLoading =>
      status == SubscriptionStateStatus.loading ||
      status == SubscriptionStateStatus.purchasing ||
      status == SubscriptionStateStatus.restoring;

  bool get isPremium => premiumStatus?.isPremium ?? false;

  SubscriptionState copyWith({
    SubscriptionStateStatus? status,
    List<SubscriptionPlanEntity>? plans,
    PremiumStatusEntity? premiumStatus,
    List<AdmirerEntity>? admirers,
    String? error,
    String? purchasingPlanId,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      premiumStatus: premiumStatus ?? this.premiumStatus,
      admirers: admirers ?? this.admirers,
      error: error,
      purchasingPlanId: purchasingPlanId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        plans,
        premiumStatus,
        admirers,
        error,
        purchasingPlanId,
      ];
}
