import 'package:equatable/equatable.dart';

abstract class CreditsEvent extends Equatable {
  const CreditsEvent();

  @override
  List<Object?> get props => [];
}

/// Load wallet and packages
class LoadCredits extends CreditsEvent {
  const LoadCredits();
}

/// Load transaction history
class LoadTransactions extends CreditsEvent {
  final int page;

  const LoadTransactions({this.page = 1});

  @override
  List<Object?> get props => [page];
}

/// Purchase credits via IAP
class PurchaseCredits extends CreditsEvent {
  final String packageId;

  const PurchaseCredits({required this.packageId});

  @override
  List<Object?> get props => [packageId];
}

/// Verify IAP purchase with backend
class VerifyPurchase extends CreditsEvent {
  final String platform;
  final String productId;
  final String transactionId;
  final String receiptData;

  const VerifyPurchase({
    required this.platform,
    required this.productId,
    required this.transactionId,
    required this.receiptData,
  });

  @override
  List<Object?> get props => [platform, productId, transactionId];
}

/// Request withdrawal
class RequestWithdrawal extends CreditsEvent {
  final int amount;
  final String? note;

  const RequestWithdrawal({required this.amount, this.note});

  @override
  List<Object?> get props => [amount, note];
}

/// Update bank info
class UpdateBankInfo extends CreditsEvent {
  final String bankName;
  final String bankAccountNo;
  final String bankAccountName;

  const UpdateBankInfo({
    required this.bankName,
    required this.bankAccountNo,
    required this.bankAccountName,
  });

  @override
  List<Object?> get props => [bankName, bankAccountNo, bankAccountName];
}

/// Refresh wallet balance
class RefreshWallet extends CreditsEvent {
  const RefreshWallet();
}

// Internal events for IAP callbacks
class IAPPurchaseCompleted extends CreditsEvent {
  final int creditsReceived;
  final int newBalance;

  const IAPPurchaseCompleted({required this.creditsReceived, required this.newBalance});

  @override
  List<Object?> get props => [creditsReceived, newBalance];
}

class IAPPurchaseFailed extends CreditsEvent {
  final String error;

  const IAPPurchaseFailed({required this.error});

  @override
  List<Object?> get props => [error];
}

class IAPPurchaseCancelled extends CreditsEvent {
  const IAPPurchaseCancelled();
}
