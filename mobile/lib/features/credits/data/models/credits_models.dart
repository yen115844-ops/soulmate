import 'package:equatable/equatable.dart';

/// Exchange rate: 1 Credit = 1,000 VND (100 credits = 100K)
const int creditToVndRate = 1000;

/// Convert credits to VND
int creditsToVnd(int credits) => credits * creditToVndRate;

/// Credit Package - IAP Consumable product
class CreditPackage extends Equatable {
  final String id;
  final String code;
  final String name;
  final String nameVi;
  final String? description;
  final int creditAmount;
  final int bonusCredits;
  final double priceVnd;
  final String? appleProductId;
  final String? googleProductId;
  final double? originalPrice;
  final int? discountPercent;
  final bool isBestValue;
  final int sortOrder;

  const CreditPackage({
    required this.id,
    required this.code,
    required this.name,
    required this.nameVi,
    this.description,
    required this.creditAmount,
    required this.bonusCredits,
    required this.priceVnd,
    this.appleProductId,
    this.googleProductId,
    this.originalPrice,
    this.discountPercent,
    this.isBestValue = false,
    this.sortOrder = 0,
  });

  factory CreditPackage.fromJson(Map<String, dynamic> json) {
    return CreditPackage(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      nameVi: json['nameVi'] as String,
      description: json['description'] as String?,
      creditAmount: json['creditAmount'] as int? ?? 0,
      bonusCredits: json['bonusCredits'] as int? ?? 0,
      priceVnd: _parseDouble(json['priceVnd']),
      appleProductId: json['appleProductId'] as String?,
      googleProductId: json['googleProductId'] as String?,
      originalPrice: json['originalPrice'] != null
          ? _parseDouble(json['originalPrice'])
          : null,
      discountPercent: json['discountPercent'] as int?,
      isBestValue: json['isBestValue'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// Total credits including bonus
  int get totalCredits => creditAmount + bonusCredits;

  @override
  List<Object?> get props => [id, code, creditAmount, bonusCredits, priceVnd];
}

/// User's Credit Wallet
class CreditWallet extends Equatable {
  final String id;
  final int balance;
  final int pendingBalance;
  final int totalEarnings;
  final int totalSpent;
  final BankInfo? bankInfo;
  final int exchangeRate;
  final int balanceInVnd;

  const CreditWallet({
    required this.id,
    required this.balance,
    required this.pendingBalance,
    required this.totalEarnings,
    required this.totalSpent,
    this.bankInfo,
    required this.exchangeRate,
    required this.balanceInVnd,
  });

  factory CreditWallet.fromJson(Map<String, dynamic> json) {
    return CreditWallet(
      id: json['id'] as String,
      balance: json['balance'] as int? ?? 0,
      pendingBalance: json['pendingBalance'] as int? ?? 0,
      totalEarnings: json['totalEarnings'] as int? ?? 0,
      totalSpent: json['totalSpent'] as int? ?? 0,
      bankInfo: json['bankInfo'] != null
          ? BankInfo.fromJson(json['bankInfo'] as Map<String, dynamic>)
          : null,
      exchangeRate: json['exchangeRate'] as int? ?? creditToVndRate,
      balanceInVnd: json['balanceInVnd'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, balance, pendingBalance, totalEarnings, totalSpent];
}

/// Bank account info for withdrawals
class BankInfo extends Equatable {
  final String bankName;
  final String? bankAccountNo;
  final String? bankAccountName;

  const BankInfo({
    required this.bankName,
    this.bankAccountNo,
    this.bankAccountName,
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      bankName: json['bankName'] as String,
      bankAccountNo: json['bankAccountNo'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
    );
  }

  @override
  List<Object?> get props => [bankName, bankAccountNo, bankAccountName];
}

/// Credit Transaction
class CreditTransaction extends Equatable {
  final String id;
  final String code;
  final String type;
  final int amount;
  final String status;
  final String? description;
  final int? balanceBefore;
  final int? balanceAfter;
  final DateTime createdAt;

  const CreditTransaction({
    required this.id,
    required this.code,
    required this.type,
    required this.amount,
    required this.status,
    this.description,
    this.balanceBefore,
    this.balanceAfter,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String,
      code: json['code'] as String,
      type: json['type'] as String,
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String,
      description: json['description'] as String?,
      balanceBefore: json['balanceBefore'] as int?,
      balanceAfter: json['balanceAfter'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Check if transaction is income (positive)
  bool get isIncome =>
      type == 'CREDIT_PURCHASE' ||
      type == 'PARTNER_EARNING' ||
      type == 'ESCROW_REFUND';

  /// Get display type in Vietnamese
  String get typeText {
    switch (type) {
      case 'CREDIT_PURCHASE':
        return 'Mua xu';
      case 'BOOKING_PAYMENT':
        return 'Thanh toán booking';
      case 'PARTNER_EARNING':
        return 'Thu nhập booking';
      case 'WITHDRAWAL':
        return 'Rút tiền';
      case 'ESCROW_HOLD':
        return 'Giữ escrow';
      case 'ESCROW_RELEASE':
        return 'Giải phóng escrow';
      case 'ESCROW_REFUND':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [id, code, type, amount, status, createdAt];
}

/// Helper to parse double from various types
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
