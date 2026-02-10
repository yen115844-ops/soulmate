import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../auth/data/models/user_model.dart';
import '../presentation/bloc/profile_state.dart';

/// Profile Repository handles profile-related API calls
class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get current user profile (uses /auth/me which returns full user with profile)
  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(AuthEndpoints.me);
    final responseData = response.data as Map<String, dynamic>;
    
    // API returns {success, data: {user: {...}}, timestamp}
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    
    debugPrint('Profile API response user: $userData');
    return UserModel.fromJson(userData);
  }

  /// Update profile
  Future<UserModel> updateProfile({
    String? fullName,
    String? displayName,
    String? bio,
    String? gender,
    DateTime? dateOfBirth,
    int? heightCm,
    int? weightKg,
    String? city,
    String? district,
    String? address,
    List<String>? languages,
    List<String>? interests,
    List<String>? talents,
  }) async {
    final data = <String, dynamic>{};
    
    if (fullName != null) data['fullName'] = fullName;
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (gender != null) data['gender'] = gender;
    if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth.toIso8601String();
    if (heightCm != null) data['heightCm'] = heightCm;
    if (weightKg != null) data['weightKg'] = weightKg;
    if (city != null) data['city'] = city;
    if (district != null) data['district'] = district;
    if (address != null) data['address'] = address;
    if (languages != null) data['languages'] = languages;
    if (interests != null) data['interests'] = interests;
    if (talents != null) data['talents'] = talents;

    final response = await _apiClient.put(
      UserEndpoints.profile,
      data: data,
    );
    
    // Log response for debugging
    debugPrint('Update profile response: ${response.data}');
    
    // Backend returns profile object, reload full user after update
    return getProfile();
  }

  /// Update user location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    String? city,
    String? district,
  }) async {
    await _apiClient.put(
      UserEndpoints.location,
      data: {
        'currentLat': latitude,
        'currentLng': longitude,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
      },
    );
  }

  /// Get profile statistics
  Future<ProfileStats> getProfileStats() async {
    try {
      final response = await _apiClient.get('${UserEndpoints.profile}/stats');
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
      return ProfileStats.fromJson(data);
    } catch (e) {
      debugPrint('Profile stats error: $e');
      // Return default stats if endpoint doesn't exist yet
      return const ProfileStats();
    }
  }

  /// Upload avatar
  Future<String> uploadAvatar(String imagePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath, filename: 'avatar.jpg'),
    });
    
    final response = await _apiClient.post(
      '${UserEndpoints.profile}/avatar',
      data: formData,
    );
    
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    return data['avatarUrl'] as String? ?? '';
  }

  /// Upload photos
  Future<List<String>> uploadPhotos(List<String> imagePaths) async {
    final List<String> uploadedUrls = [];
    
    for (final path in imagePaths) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
      });
      
      final response = await _apiClient.post(
        '${UserEndpoints.profile}/photos',
        data: formData,
      );
      
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
      final url = data['photoUrl'] as String?;
      if (url != null) uploadedUrls.add(url);
    }
    
    return uploadedUrls;
  }

  /// Delete photo
  Future<void> deletePhoto(String photoUrl) async {
    await _apiClient.delete(
      '${UserEndpoints.profile}/photos',
      data: {'photoUrl': photoUrl},
    );
  }
}
