import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/base_repository.dart';
import 'models/wallet_models.dart';

class WalletRepository with BaseRepositoryMixin {
  final ApiClient _apiClient;

  WalletRepository({required ApiClient apiClient}) : _apiClient = apiClient;


  /// Get wallet info
  Future<WalletModel> getWallet() async {
    try {
      final response = await _apiClient.get('/wallet');
      final data = extractRawData(response.data);
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
      final data = extractRawData(response.data);
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
      final data = extractRawData(response.data);
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
      final data = extractRawData(response.data);
      return TopUpResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TopUp error: $e');
      rethrow;
    }
  }
}
