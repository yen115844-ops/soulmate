import '../../../core/network/api_client.dart';
import '../../../core/network/base_repository.dart';
import 'models/credits_models.dart';

/// Repository for Credits/Wallet operations
class CreditsRepository with BaseRepositoryMixin {
  final ApiClient _apiClient;

  CreditsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get available credit packages
  Future<List<CreditPackage>> getPackages() async {
    final response = await _apiClient.get('/credits/packages');
    final data = extractRawData(response.data);
    final packages = (data['packages'] as List? ?? [])
        .map((p) => CreditPackage.fromJson(p as Map<String, dynamic>))
        .toList();
    return packages;
  }

  /// Get user's wallet/balance
  Future<CreditWallet> getWallet() async {
    final response = await _apiClient.get('/credits/wallet');
    final data = extractRawData(response.data);
    return CreditWallet.fromJson(data as Map<String, dynamic>);
  }

  /// Get transaction history
  Future<({List<CreditTransaction> transactions, int total})> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/credits/transactions',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    final responseData = response.data as Map<String, dynamic>;
    final wrapper = responseData['data'] as Map<String, dynamic>? ?? {};
    final data = wrapper['data'] as List? ?? [];
    final transactions = data
        .map((t) => CreditTransaction.fromJson(t as Map<String, dynamic>))
        .toList();
    final pagination = wrapper['pagination'] as Map<String, dynamic>? ?? {};
    return (
      transactions: transactions,
      total: pagination['total'] as int? ?? 0,
    );
  }

  /// Purchase credits via IAP
  Future<({bool success, int creditsReceived, int newBalance})> purchaseCredits({
    required String platform,
    required String productId,
    required String transactionId,
    required String receiptData,
  }) async {
    final response = await _apiClient.post('/credits/purchase', data: {
      'platform': platform,
      'productId': productId,
      'transactionId': transactionId,
      'receiptData': receiptData,
    });
    final data = extractRawData(response.data) as Map<String, dynamic>? ?? {};
    return (
      success: data['success'] as bool? ?? false,
      creditsReceived: data['creditsReceived'] as int? ?? 0,
      newBalance: data['newBalance'] as int? ?? 0,
    );
  }

  /// Request withdrawal (convert credits to VND)
  Future<({bool success, String message, String transactionId})> requestWithdrawal({
    required int amount,
    String? note,
  }) async {
    final response = await _apiClient.post('/credits/withdraw', data: {
      'amount': amount,
      if (note != null) 'note': note,
    });
    final data = extractRawData(response.data) as Map<String, dynamic>? ?? {};
    return (
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? '',
      transactionId: data['transactionId'] as String? ?? '',
    );
  }

  /// Update bank account info
  Future<void> updateBankInfo({
    required String bankName,
    required String bankAccountNo,
    required String bankAccountName,
  }) async {
    await _apiClient.put('/credits/bank-info', data: {
      'bankName': bankName,
      'bankAccountNo': bankAccountNo,
      'bankAccountName': bankAccountName,
    });
  }
}
