import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'models/kyc_model.dart';

class KycRepository {
  final ApiClient _apiClient;

  KycRepository(this._apiClient);

  /// Get current KYC status
  Future<KycStatusModel> getKycStatus() async {
    final response = await _apiClient.get(UserEndpoints.kyc);
    final data = response.data as Map<String, dynamic>;
    return KycStatusModel.fromJson(data['data'] ?? data);
  }

  /// Submit KYC verification
  Future<void> submitKyc(KycSubmitRequest request) async {
    await _apiClient.post(UserEndpoints.kyc, data: request.toJson());
  }

  /// Upload KYC image (front, back, or selfie)
  /// Returns the URL of the uploaded image
  Future<String> uploadKycImage(File imageFile, String type) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      'type': type,
    });

    final response = await _apiClient.upload('/upload/kyc', formData: formData);
    final data = response.data as Map<String, dynamic>;
    return data['url'] ?? data['data']?['url'] ?? '';
  }
}
