// ==================== Wallet Models ====================

/// Wallet information
class WalletModel {
  final String id;
  final double balance;
  final double pendingBalance;
  final double totalEarnings;
  final double totalSpent;
  final String currency;
  final String? bankName;
  final String? bankAccountNo;
  final String? bankAccountName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WalletModel({
    required this.id,
    required this.balance,
    this.pendingBalance = 0,
    this.totalEarnings = 0,
    this.totalSpent = 0,
    this.currency = 'VND',
    this.bankName,
    this.bankAccountNo,
    this.bankAccountName,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id']?.toString() ?? '',
      balance: _parseDouble(json['balance']),
      pendingBalance: _parseDouble(json['pendingBalance']),
      totalEarnings: _parseDouble(json['totalEarnings']),
      totalSpent: _parseDouble(json['totalSpent']),
      currency: json['currency']?.toString() ?? 'VND',
      bankName: json['bankName'] is String ? json['bankName'] : null,
      bankAccountNo: json['bankAccountNo'] is String ? json['bankAccountNo'] : null,
      bankAccountName: json['bankAccountName'] is String ? json['bankAccountName'] : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Available balance for withdrawal
  double get availableBalance => balance - pendingBalance;
}

// ==================== Transaction Models ====================

/// Transaction types
enum TransactionType {
  deposit,
  withdrawal,
  escrowHold,
  escrowRelease,
  escrowRefund,
  serviceFee;

  static TransactionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DEPOSIT':
        return TransactionType.deposit;
      case 'WITHDRAWAL':
        return TransactionType.withdrawal;
      case 'ESCROW_HOLD':
        return TransactionType.escrowHold;
      case 'ESCROW_RELEASE':
        return TransactionType.escrowRelease;
      case 'ESCROW_REFUND':
        return TransactionType.escrowRefund;
      case 'SERVICE_FEE':
        return TransactionType.serviceFee;
      default:
        return TransactionType.deposit;
    }
  }

  String get value => name.toUpperCase();

  String get displayName {
    switch (this) {
      case TransactionType.deposit:
        return 'Nạp tiền';
      case TransactionType.withdrawal:
        return 'Rút tiền';
      case TransactionType.escrowHold:
        return 'Thanh toán booking';
      case TransactionType.escrowRelease:
        return 'Nhận tiền hoàn thành';
      case TransactionType.escrowRefund:
        return 'Hoàn tiền';
      case TransactionType.serviceFee:
        return 'Phí dịch vụ';
    }
  }

  bool get isPositive {
    switch (this) {
      case TransactionType.deposit:
      case TransactionType.escrowRelease:
      case TransactionType.escrowRefund:
        return true;
      case TransactionType.withdrawal:
      case TransactionType.escrowHold:
      case TransactionType.serviceFee:
        return false;
    }
  }
}

/// Transaction status
enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled;

  static TransactionStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return TransactionStatus.pending;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'CANCELLED':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Đang xử lý';
      case TransactionStatus.completed:
        return 'Hoàn thành';
      case TransactionStatus.failed:
        return 'Thất bại';
      case TransactionStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

/// Transaction model
class TransactionModel {
  final String id;
  final String transactionCode;
  final TransactionType type;
  final double amount;
  final double fee;
  final TransactionStatus status;
  final String? description;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.transactionCode,
    required this.type,
    required this.amount,
    this.fee = 0,
    required this.status,
    this.description,
    this.paymentMethod,
    required this.createdAt,
    this.completedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      transactionCode: json['transactionCode']?.toString() ?? '',
      type: TransactionType.fromString(json['type']?.toString() ?? 'DEPOSIT'),
      amount: WalletModel._parseDouble(json['amount']),
      fee: WalletModel._parseDouble(json['fee']),
      status: TransactionStatus.fromString(json['status']?.toString() ?? 'PENDING'),
      description: json['description'] is String ? json['description'] : null,
      paymentMethod: json['paymentMethod'] is String ? json['paymentMethod'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  /// Get display amount with sign
  String get displayAmount {
    final sign = type.isPositive ? '+' : '-';
    return '$sign${_formatCurrency(amount)}đ';
  }

  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

// ==================== Response Models ====================

/// Transactions list response with pagination
class TransactionsResponse {
  final List<TransactionModel> data;
  final int total;
  final int page;
  final int limit;

  TransactionsResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionsResponse(
      data: (json['data'] as List?)
              ?.map((e) => TransactionModel.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }

  int get totalPages => (total / limit).ceil();
  bool get hasMore => page < totalPages;
}

/// Withdraw response
class WithdrawResponse {
  final bool success;
  final String message;
  final TransactionModel? transaction;

  WithdrawResponse({
    required this.success,
    required this.message,
    this.transaction,
  });

  factory WithdrawResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      transaction: json['transaction'] != null
          ? TransactionModel.fromJson(json['transaction'])
          : null,
    );
  }
}

/// TopUp response
class TopUpResponse {
  final bool success;
  final String message;
  final TransactionModel? transaction;
  final String? paymentUrl;

  TopUpResponse({
    required this.success,
    required this.message,
    this.transaction,
    this.paymentUrl,
  });

  factory TopUpResponse.fromJson(Map<String, dynamic> json) {
    return TopUpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      transaction: json['transaction'] != null
          ? TransactionModel.fromJson(json['transaction'])
          : null,
      paymentUrl: json['paymentUrl'],
    );
  }
}
