import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Subscription repository implementation - Data layer
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// Helper to extract data from API response wrapper
  dynamic _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // API returns {success, data, timestamp} wrapper
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  @override
  Future<List<SubscriptionPlanEntity>> getPlans() async {
    final response = await _apiClient.get(
      '${ApiConfig.baseUrl}/subscriptions/plans',
    );

    final rawData = _extractData(response.data);
    final data = rawData as List<dynamic>;
    return data
        .map((json) =>
            SubscriptionPlanEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PremiumStatusEntity> getStatus() async {
    final response = await _apiClient.get(
      '${ApiConfig.baseUrl}/subscriptions/status',
    );

    final data = _extractData(response.data) as Map<String, dynamic>;
    return PremiumStatusEntity.fromJson(data);
  }

  @override
  Future<PremiumStatusEntity> verifyPurchase({
    required String platform,
    required String productId,
    required String receiptData,
    String? transactionId,
  }) async {
    final body = <String, dynamic>{
      'platform': platform,
      'productId': productId,
      'receiptData': receiptData,
    };
    if (transactionId != null && transactionId.isNotEmpty) {
      body['transactionId'] = transactionId;
    }
    await _apiClient.post(
      '${ApiConfig.baseUrl}/subscriptions/verify-purchase',
      data: body,
    );

    return getStatus();
  }

  @override
  Future<PremiumStatusEntity> restorePurchases({
    required String platform,
    required String receiptData,
  }) async {
    await _apiClient.post(
      '${ApiConfig.baseUrl}/subscriptions/restore',
      data: {
        'platform': platform,
        'receiptData': receiptData,
      },
    );

    // After restore, get updated status
    return getStatus();
  }

  @override
  Future<MessageLimitStatus> canSendMessage() async {
    final response = await _apiClient.get(
      '${ApiConfig.baseUrl}/subscriptions/can-send-message',
    );

    final data = _extractData(response.data) as Map<String, dynamic>;
    return MessageLimitStatus.fromJson(data);
  }

  @override
  Future<List<AdmirerEntity>> getAdmirers() async {
    final response = await _apiClient.get(
      '${ApiConfig.baseUrl}/subscriptions/admirers',
    );

    final rawData = _extractData(response.data);
    final data = rawData as List<dynamic>;
    return data
        .map((json) => AdmirerEntity.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
