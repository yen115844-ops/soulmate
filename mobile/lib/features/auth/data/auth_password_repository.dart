import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class AuthPasswordRepository {
  final ApiClient _apiClient;

  AuthPasswordRepository(this._apiClient);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      AuthEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
