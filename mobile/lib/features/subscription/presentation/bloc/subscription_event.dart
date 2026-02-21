import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Load subscription plans
class SubscriptionPlansRequested extends SubscriptionEvent {
  const SubscriptionPlansRequested();
}

/// Load current subscription status
class SubscriptionStatusRequested extends SubscriptionEvent {
  const SubscriptionStatusRequested();
}

/// Purchase a subscription plan
class SubscriptionPurchaseRequested extends SubscriptionEvent {
  final String planId;
  final String productId;

  const SubscriptionPurchaseRequested({
    required this.planId,
    required this.productId,
  });

  @override
  List<Object?> get props => [planId, productId];
}

/// Purchase completed (from IAP callback)
class SubscriptionPurchaseCompleted extends SubscriptionEvent {
  final String platform;
  final String productId;
  final String receiptData;

  const SubscriptionPurchaseCompleted({
    required this.platform,
    required this.productId,
    required this.receiptData,
  });

  @override
  List<Object?> get props => [platform, productId, receiptData];
}

/// Restore purchases
class SubscriptionRestoreRequested extends SubscriptionEvent {
  final String platform;
  final String receiptData;

  const SubscriptionRestoreRequested({
    required this.platform,
    required this.receiptData,
  });

  @override
  List<Object?> get props => [platform, receiptData];
}

/// Load admirers list (who favorited me)
class SubscriptionAdmirersRequested extends SubscriptionEvent {
  const SubscriptionAdmirersRequested();
}
