import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/entities/verification_entity.dart';
import '../../domain/repositories/verification_repository.dart';

/// Verification repository implementation - Data layer
class VerificationRepositoryImpl implements VerificationRepository {
  final ApiClient _apiClient;

  VerificationRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<VerificationEntity> submitSelfie(
    File selfieFile, {
    String? deviceInfo,
  }) async {
    final formData = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(
        selfieFile.path,
        filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    });

    final response = await _apiClient.post(
      '${ApiConfig.baseUrl}/verification/submit-selfie',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final responseData = response.data as Map<String, dynamic>;
    // API returns {success, data: {...}, timestamp}
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    return VerificationEntity.fromJson(data);
  }

  @override
  Future<VerificationEntity> getStatus() async {
    final response = await _apiClient.get(
      '${ApiConfig.baseUrl}/verification/status',
    );

    final responseData = response.data as Map<String, dynamic>;
    // API returns {success, data: {...}, timestamp}
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    return VerificationEntity.fromJson(data);
  }
}
