import 'dart:developer';

import 'package:mobile/core/constants/app_constants.dart';
import '../../../partner/domain/entities/partner_entity.dart';

/// Model for favorite partner from API response
class FavoritePartnerModel {
  final String id;
  final String partnerId;
  final PartnerEntity partner;
  final DateTime createdAt;

  const FavoritePartnerModel({
    required this.id,
    required this.partnerId,
    required this.partner,
    required this.createdAt,
  });

  factory FavoritePartnerModel.fromJson(Map<String, dynamic> json) {
    final partnerData = json['partner'] ?? {};
    final profile = partnerData['profile'] ?? {};
    final partnerProfile = partnerData['partnerProfile'] ?? {};
    log('Parsing FavoritePartnerModel from JSON: $json');

    return FavoritePartnerModel(
      id: json['id'] ?? '',
      partnerId: json['partnerId'] ?? partnerData['id'] ?? '',
      partner: PartnerEntity(
        id: partnerData['id'] ?? '',
        name: profile['fullName'] ?? profile['displayName'] ?? 'Partner',
        age: _calculateAge(profile['dateOfBirth']),
        avatarUrl: profile['avatarUrl'] ?? '',
        coverPhotoUrl: profile['coverPhotoUrl'],
        rating: _parseDouble(partnerProfile['averageRating']),
        reviewCount: _parseInt(partnerProfile['totalReviews']),
        hourlyRate: _parseInt(partnerProfile['hourlyRate']),
        isOnline: _isOnline(partnerProfile['lastActiveAt']),
        isVerified: partnerProfile['isVerified'] ?? false,
        isPremium: partnerProfile['verificationBadge'] == 'gold',
        bio: profile['bio'],
        location: profile['city'] != null
            ? '${profile['district'] ?? ''}, ${profile['city']}'
            : null,
        services: _parseList(partnerProfile['serviceTypes']),
        interests: _parseList(profile['interests']),
        languages: _parseList(profile['languages']),
        gallery: _parseList(profile['photos']),
        responseRate: _parseInt(partnerProfile['responseRate']),
        completedBookings: partnerProfile['completedBookings'] ?? 0,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 0;
    try {
      final dob = DateTime.parse(dateOfBirth);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  /// Online = có hoạt động trong N phút (tính từ lúc đăng nhập). Dùng chung threshold với Home.
  static bool _isOnline(String? lastActiveAt) {
    if (lastActiveAt == null) return false;
    try {
      final lastActive = DateTime.parse(lastActiveAt);
      return DateTime.now().difference(lastActive).inMinutes <
          AppConstants.onlineThresholdMinutes;
    } catch (e) {
      return false;
    }
  }

  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Response model for favorites list
class FavoritesResponse {
  final List<FavoritePartnerModel> data;
  final int total;
  final int page;
  final int limit;

  const FavoritesResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response: { success: true, data: { data: [...], meta: {...} } }
    Map<String, dynamic> actualData = json;
    if (json['data'] is Map<String, dynamic>) {
      actualData = json['data'] as Map<String, dynamic>;
    }

    final dataList = actualData['data'] as List? ?? [];
    final meta = actualData['meta'] as Map<String, dynamic>? ?? {};

    return FavoritesResponse(
      data: dataList
          .map((e) => FavoritePartnerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] ?? actualData['total'] ?? 0,
      page: meta['page'] ?? actualData['page'] ?? 1,
      limit: meta['limit'] ?? actualData['limit'] ?? 10,
    );
  }
}
