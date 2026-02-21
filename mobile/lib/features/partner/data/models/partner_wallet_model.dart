import 'partner_stats_model.dart';

/// Credit exchange rate: 1 credit = 1,000 VND (100 credits = 100K)
const int creditsExchangeRate = 1000;

/// Wallet transaction model (now in credits, not VND)
class WalletTransaction {
  final String id;
  final String? code;
  final String type; // CREDIT_PURCHASE, BOOKING_PAYMENT, PARTNER_EARNING, ESCROW_*, WITHDRAWAL
  final int amount; // Changed to int for credits
  final int? balanceBefore;
  final int? balanceAfter;
  final String status; // PENDING, COMPLETED, FAILED, CANCELLED
  final String? description;
  final String? bookingId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    this.code,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    required this.status,
    this.description,
    this.bookingId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      code: json['code'] is String ? json['code'] : null,
      type: json['type']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceBefore: json['balanceBefore'] != null 
          ? (json['balanceBefore'] as num).toInt() 
          : null,
      balanceAfter: json['balanceAfter'] != null
          ? (json['balanceAfter'] as num).toInt()
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
  bool get isIncome => 
      type == 'PARTNER_EARNING' || 
      type == 'ESCROW_RELEASE' || 
      type == 'CREDIT_PURCHASE' ||
      type == 'ESCROW_REFUND';

  /// Check if transaction is negative (expense)
  bool get isExpense => 
      type == 'WITHDRAWAL' || 
      type == 'BOOKING_PAYMENT' ||
      type == 'ESCROW_HOLD';

  /// Get display text for type
  String get typeText {
    switch (type) {
      case 'CREDIT_PURCHASE':
        return 'Nạp credits';
      case 'BOOKING_PAYMENT':
        return 'Thanh toán booking';
      case 'PARTNER_EARNING':
        return 'Thu nhập';
      case 'ESCROW_HOLD':
        return 'Giữ tiền';
      case 'ESCROW_RELEASE':
        return 'Giải phóng tiền';
      case 'ESCROW_REFUND':
        return 'Hoàn tiền';
      case 'WITHDRAWAL':
        return 'Rút tiền';
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
  
  /// Get amount in VND (for display)
  int get amountInVnd => amount * creditsExchangeRate;
}

/// Wallet info from /credits/wallet (now in credits, not VND)
class PartnerWalletInfo {
  final String id;
  final int balance;        // Credits
  final int pendingBalance; // Credits held in escrow
  final int totalEarnings;  // Total credits earned
  final int totalSpent;     // Total credits spent
  final int exchangeRate;   // Credits to VND rate
  final int balanceInVnd;   // Balance converted to VND
  final String? bankName;
  final String? bankAccountNo;
  final String? bankAccountName;

  PartnerWalletInfo({
    required this.id,
    required this.balance,
    this.pendingBalance = 0,
    this.totalEarnings = 0,
    this.totalSpent = 0,
    this.exchangeRate = 1000,
    this.balanceInVnd = 0,
    this.bankName,
    this.bankAccountNo,
    this.bankAccountName,
  });

  factory PartnerWalletInfo.fromJson(Map<String, dynamic> json) {
    // Bank info can be nested object or flat fields
    final bankInfo = json['bankInfo'] as Map<String, dynamic>?;
    
    return PartnerWalletInfo(
      id: json['id']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      pendingBalance: (json['pendingBalance'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      exchangeRate: (json['exchangeRate'] as num?)?.toInt() ?? 1000,
      balanceInVnd: (json['balanceInVnd'] as num?)?.toInt() ?? 0,
      bankName: bankInfo?['bankName'] ?? (json['bankName'] is String ? json['bankName'] : null),
      bankAccountNo: bankInfo?['bankAccountNo'] ?? (json['bankAccountNo'] is String ? json['bankAccountNo'] : null),
      bankAccountName: bankInfo?['bankAccountName'] ?? (json['bankAccountName'] is String ? json['bankAccountName'] : null),
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
