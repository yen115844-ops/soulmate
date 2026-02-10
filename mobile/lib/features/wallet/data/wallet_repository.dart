import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'models/wallet_models.dart';

class WalletRepository {
  final ApiClient _apiClient;

  WalletRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Extract data from wrapped response {success, data, ...}
  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response['data'] ?? response;
    }
    return response;
  }

  /// Get wallet info
  Future<WalletModel> getWallet() async {
    try {
      final response = await _apiClient.get('/wallet');
      final data = _extractData(response.data);
      return WalletModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Get wallet error: $e');
      rethrow;
    }
  }

  /// Get transactions with pagination
  Future<TransactionsResponse> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallet/transactions',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final data = _extractData(response.data);
      return TransactionsResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Get transactions error: $e');
      rethrow;
    }
  }

  /// Request withdrawal
  Future<WithdrawResponse> requestWithdraw({
    required double amount,
    String? bankName,
    String? bankAccountNo,
    String? bankAccountName,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'amount': amount,
      };

      if (bankName != null && bankAccountNo != null && bankAccountName != null) {
        requestData['bankInfo'] = {
          'bankName': bankName,
          'bankAccountNo': bankAccountNo,
          'bankAccountName': bankAccountName,
        };
      }

      final response = await _apiClient.post(
        '/wallet/withdraw',
        data: requestData,
      );
      final data = _extractData(response.data);
      return WithdrawResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Withdraw error: $e');
      rethrow;
    }
  }

  /// Top up wallet - initiate payment
  /// Returns TopUpResponse with payment URL for redirect
  Future<TopUpResponse> topUp({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        '/wallet/topup',
        data: {
          'amount': amount,
          'paymentMethod': paymentMethod,
        },
      );
      final data = _extractData(response.data);
      return TopUpResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TopUp error: $e');
      rethrow;
    }
  }
}
