import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

/// Repository for fetching terms content from the public API.
/// These endpoints do NOT require authentication.
class TermsRepository {
  final ApiClient _apiClient;

  TermsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch Terms of Service content (Markdown string)
  Future<String> getTermsOfService() async {
    return _fetchTerms(TermsEndpoints.termsOfService);
  }

  /// Fetch Terms and Conditions content (Markdown string)
  Future<String> getTermsAndConditions() async {
    return _fetchTerms(TermsEndpoints.termsAndConditions);
  }

  Future<String> _fetchTerms(String endpoint) async {
    final response = await _apiClient.get(endpoint);
    final responseData = response.data as Map<String, dynamic>;

    // API may wrap in { data: { content: "..." } } or { content: "..." }
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    return (data['content'] as String?) ?? '';
  }
}
