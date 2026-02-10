import 'partner_stats_model.dart';

/// Wallet transaction model
class WalletTransaction {
  final String id;
  final String type; // EARNING, WITHDRAWAL, REFUND, etc.
  final double amount;
  final double? balanceAfter;
  final String status; // PENDING, COMPLETED, FAILED, CANCELLED
  final String? description;
  final String? bookingId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.balanceAfter,
    required this.status,
    this.description,
    this.bookingId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: PartnerStats.parseDouble(json['amount']),
      balanceAfter: json['balanceAfter'] != null
          ? PartnerStats.parseDouble(json['balanceAfter'])
          : null,
      status: json['status']?.toString() ?? '',
      description: json['description'] is String ? json['description'] : null,
      bookingId: json['bookingId'] is String ? json['bookingId'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  /// Check if transaction is positive (income)
  bool get isIncome => type == 'EARNING' || type == 'REFUND';

  /// Check if transaction is negative (expense)
  bool get isExpense => type == 'WITHDRAWAL';

  /// Get display text for type
  String get typeText {
    switch (type) {
      case 'EARNING':
        return 'Thu nhập';
      case 'WITHDRAWAL':
        return 'Rút tiền';
      case 'REFUND':
        return 'Hoàn tiền';
      default:
        return type;
    }
  }

  /// Get status text
  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'FAILED':
        return 'Thất bại';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

/// Wallet info from /wallet
class PartnerWalletInfo {
  final String id;
  final double balance;
  final double pendingBalance;
  final double totalEarnings;
  final double totalSpent;
  final String currency;
  final String? bankName;
  final String? bankAccountNo;
  final String? bankAccountName;

  PartnerWalletInfo({
    required this.id,
    required this.balance,
    this.pendingBalance = 0,
    this.totalEarnings = 0,
    this.totalSpent = 0,
    this.currency = 'VND',
    this.bankName,
    this.bankAccountNo,
    this.bankAccountName,
  });

  factory PartnerWalletInfo.fromJson(Map<String, dynamic> json) {
    return PartnerWalletInfo(
      id: json['id']?.toString() ?? '',
      balance: PartnerStats.parseDouble(json['balance']),
      pendingBalance: PartnerStats.parseDouble(json['pendingBalance']),
      totalEarnings: PartnerStats.parseDouble(json['totalEarnings']),
      totalSpent: PartnerStats.parseDouble(json['totalSpent']),
      currency: json['currency']?.toString() ?? 'VND',
      bankName: json['bankName'] is String ? json['bankName'] : null,
      bankAccountNo:
          json['bankAccountNo'] is String ? json['bankAccountNo'] : null,
      bankAccountName:
          json['bankAccountName'] is String ? json['bankAccountName'] : null,
    );
  }

  /// Check if bank info is complete
  bool get hasBankInfo =>
      bankName != null && bankAccountNo != null && bankAccountName != null;
}

/// Partner earnings aggregated data
class PartnerEarningsData {
  final PartnerStats stats;
  final PartnerWalletInfo wallet;
  final List<WalletTransaction> transactions;

  PartnerEarningsData({
    required this.stats,
    required this.wallet,
    this.transactions = const [],
  });
}

/// Bank account information
class BankAccountInfo {
  final String bankName;
  final String bankAccountNo;
  final String bankAccountName;

  BankAccountInfo({
    required this.bankName,
    required this.bankAccountNo,
    required this.bankAccountName,
  });

  factory BankAccountInfo.fromJson(Map<String, dynamic> json) {
    return BankAccountInfo(
      bankName: json['bankName']?.toString() ?? '',
      bankAccountNo: json['bankAccountNo']?.toString() ?? '',
      bankAccountName: json['bankAccountName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'bankAccountNo': bankAccountNo,
      'bankAccountName': bankAccountName,
    };
  }

  bool get isEmpty =>
      bankName.isEmpty && bankAccountNo.isEmpty && bankAccountName.isEmpty;
  bool get isComplete =>
      bankName.isNotEmpty &&
      bankAccountNo.isNotEmpty &&
      bankAccountName.isNotEmpty;
}
