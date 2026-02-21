import '../entities/subscription_entity.dart';

/// Subscription repository interface - Domain layer
abstract class SubscriptionRepository {
  /// Get all available subscription plans
  Future<List<SubscriptionPlanEntity>> getPlans();

  /// Get current subscription status
  Future<PremiumStatusEntity> getStatus();

  /// Verify purchase and activate subscription
  Future<PremiumStatusEntity> verifyPurchase({
    required String platform,
    required String productId,
    required String receiptData,
  });

  /// Restore previous purchases
  Future<PremiumStatusEntity> restorePurchases({
    required String platform,
    required String receiptData,
  });

  /// Check if user can send message (free limit)
  Future<MessageLimitStatus> canSendMessage();

  /// Get list of users who favorited (Premium only)
  Future<List<AdmirerEntity>> getAdmirers();
}

/// Message limit status for free users
class MessageLimitStatus {
  final bool allowed;
  final int? remaining;
  final String? reason;

  const MessageLimitStatus({
    required this.allowed,
    this.remaining,
    this.reason,
  });

  factory MessageLimitStatus.fromJson(Map<String, dynamic> json) {
    return MessageLimitStatus(
      allowed: json['allowed'] == true,
      remaining: json['remaining'] as int?,
      reason: json['reason'] as String?,
    );
  }
}

/// Admirer entity (who favorited this user)
class AdmirerEntity {
  final String id;
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;
  final DateTime favoritedAt;

  const AdmirerEntity({
    required this.id,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    required this.favoritedAt,
  });

  String get name => displayName ?? fullName ?? 'Unknown';

  factory AdmirerEntity.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final profile = user?['profile'] as Map<String, dynamic>?;
    
    return AdmirerEntity(
      id: user?['id'] as String? ?? '',
      fullName: profile?['fullName'] as String?,
      displayName: profile?['displayName'] as String?,
      avatarUrl: profile?['avatarUrl'] as String?,
      favoritedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}
