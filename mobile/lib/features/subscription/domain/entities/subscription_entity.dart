import 'package:equatable/equatable.dart';

/// Subscription status enum
enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  gracePeriod;

  static SubscriptionStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      case 'CANCELLED':
        return SubscriptionStatus.cancelled;
      case 'GRACE_PERIOD':
        return SubscriptionStatus.gracePeriod;
      default:
        return SubscriptionStatus.expired;
    }
  }
}

/// Subscription plan entity
class SubscriptionPlanEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final String nameVi;
  final String? description;
  final int durationMonths;
  final int? durationDays; // For weekly plans (durationMonths = 0)
  final double priceVnd;
  final String? appleProductId;
  final String? googleProductId;
  final double? originalPrice;
  final int? discountPercent;
  final int sortOrder;

  const SubscriptionPlanEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.nameVi,
    this.description,
    required this.durationMonths,
    this.durationDays,
    required this.priceVnd,
    this.appleProductId,
    this.googleProductId,
    this.originalPrice,
    this.discountPercent,
    this.sortOrder = 0,
  });

  factory SubscriptionPlanEntity.fromJson(Map<String, dynamic> json) {
    // Helper to parse price (can be string or num from API)
    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return SubscriptionPlanEntity(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      nameVi: json['nameVi'] as String? ?? json['name'] as String,
      description: json['description'] as String?,
      durationMonths: json['durationMonths'] as int? ?? 0,
      durationDays: json['durationDays'] as int?,
      priceVnd: parsePrice(json['priceVnd']),
      appleProductId: json['appleProductId'] as String?,
      googleProductId: json['googleProductId'] as String?,
      originalPrice: parsePrice(json['originalPrice']),
      discountPercent: json['discountPercent'] as int?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// Get formatted price string
  String get formattedPrice {
    final formatter = priceVnd.toStringAsFixed(0);
    // Add thousand separators
    final buffer = StringBuffer();
    int count = 0;
    for (int i = formatter.length - 1; i >= 0; i--) {
      buffer.write(formatter[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()}đ';
  }

  /// Check if this is a weekly plan
  bool get isWeekly => durationMonths == 0 && (durationDays ?? 0) > 0;

  /// Get total duration in days
  int get totalDays {
    if (isWeekly) return durationDays ?? 7;
    return durationMonths * 30; // Approximate
  }

  /// Get monthly price for comparison (extrapolated for weekly)
  double get monthlyPrice {
    if (isWeekly) {
      // Weekly plan: extrapolate to monthly price
      return priceVnd * (30 / (durationDays ?? 7));
    }
    return priceVnd / durationMonths;
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        nameVi,
        description,
        durationMonths,
        durationDays,
        priceVnd,
        appleProductId,
        googleProductId,
        originalPrice,
        discountPercent,
        sortOrder,
      ];
}

/// Subscription entity
class SubscriptionEntity extends Equatable {
  final String id;
  final SubscriptionPlanEntity plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAutoRenew;

  const SubscriptionEntity({
    required this.id,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.isAutoRenew = true,
  });

  factory SubscriptionEntity.fromJson(Map<String, dynamic> json) {
    return SubscriptionEntity(
      id: json['id'] as String,
      plan: SubscriptionPlanEntity.fromJson(
        json['plan'] as Map<String, dynamic>,
      ),
      status: SubscriptionStatus.fromString(json['status'] as String?),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isAutoRenew: json['isAutoRenew'] == true,
    );
  }

  /// Check if subscription is active
  bool get isActive =>
      status == SubscriptionStatus.active && endDate.isAfter(DateTime.now());

  /// Days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        plan,
        status,
        startDate,
        endDate,
        isAutoRenew,
      ];
}

/// Premium status with subscription info
class PremiumStatusEntity extends Equatable {
  final bool isPremium;
  final DateTime? premiumUntil;
  final SubscriptionEntity? activeSubscription;

  const PremiumStatusEntity({
    this.isPremium = false,
    this.premiumUntil,
    this.activeSubscription,
  });

  factory PremiumStatusEntity.fromJson(Map<String, dynamic> json) {
    return PremiumStatusEntity(
      isPremium: json['isPremium'] == true,
      premiumUntil: json['premiumUntil'] != null
          ? DateTime.tryParse(json['premiumUntil'].toString())
          : null,
      activeSubscription: json['activeSubscription'] != null
          ? SubscriptionEntity.fromJson(
              json['activeSubscription'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [isPremium, premiumUntil, activeSubscription];
}
