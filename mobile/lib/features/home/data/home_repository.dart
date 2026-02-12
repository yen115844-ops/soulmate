import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/base_repository.dart';
import '../../../core/utils/image_utils.dart';
import '../../partner/domain/entities/partner_entity.dart';

/// Repository for Home feature - handles partner search and discovery
class HomeRepository with BaseRepositoryMixin {
  final ApiClient _apiClient;

  HomeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Search partners with filters
  Future<HomePartnersResponse> searchPartners({
    int page = 1,
    int limit = 20,
    String? query,
    String? serviceType,
    String? gender,
    int? minAge,
    int? maxAge,
    int? minRate,
    int? maxRate,
    double? lat,
    double? lng,
    int? radius,
    String? city,
    String? district,
    bool? verifiedOnly,
    bool? availableNow,
    String? sortBy,
  }) async {
    try {
      final response = await _apiClient.get(
        '/partners/search',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (query != null && query.isNotEmpty) 'q': query,
          if (serviceType != null) 'serviceType': serviceType,
          if (gender != null) 'gender': gender,
          if (minAge != null) 'minAge': minAge,
          if (maxAge != null) 'maxAge': maxAge,
          if (minRate != null) 'minRate': minRate,
          if (maxRate != null) 'maxRate': maxRate,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (radius != null) 'radius': radius,
          if (city != null) 'city': city,
          if (district != null) 'district': district,
          if (verifiedOnly != null) 'verifiedOnly': verifiedOnly,
          if (availableNow != null) 'availableNow': availableNow,
          if (sortBy != null) 'sortBy': sortBy,
        },
      );

      return HomePartnersResponse.fromJson(extractRawData(response.data));
    } catch (e) {
      debugPrint('Search partners error: $e');
      rethrow;
    }
  }

  /// Get partner by ID for detail view
  Future<PartnerEntity> getPartnerById(String partnerId) async {
    try {
      final response = await _apiClient.get('/partners/$partnerId');
      final data = extractRawData(response.data) as Map<String, dynamic>;
      return HomePartnersResponse._mapToPartnerEntity(data);
    } catch (e) {
      debugPrint('Get partner error: $e');
      rethrow;
    }
  }
}

/// Default avatar placeholder URL
const _kDefaultAvatarUrl = 'https://via.placeholder.com/400';

/// Response model for home partners search
class HomePartnersResponse {
  final List<PartnerEntity> partners;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  HomePartnersResponse({
    required this.partners,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory HomePartnersResponse.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    final dataList = json['data'] as List? ?? [];

    return HomePartnersResponse(
      partners: dataList.map((e) {
        return _mapToPartnerEntity(e as Map<String, dynamic>);
      }).toList(),
      total: meta['total'] ?? dataList.length,
      page: meta['page'] ?? 1,
      limit: meta['limit'] ?? 20,
      totalPages: meta['totalPages'] ?? 1,
      hasNextPage: meta['hasNextPage'] ?? false,
      hasPreviousPage: meta['hasPreviousPage'] ?? false,
    );
  }

  /// Map API response to PartnerEntity (theo đúng cấu trúc API backend)
  static PartnerEntity _mapToPartnerEntity(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>?;
    final profile = user?['profile'] as Map<String, dynamic>?;

    // Gallery: profile.photos (backend đã normalize thành string[])
    final photos = <String>[];
    if (profile?['photos'] is List) {
      for (final e in profile!['photos'] as List) {
        final url = e is Map ? (e['url'] ?? e.toString()).toString() : e.toString();
        if (url.isNotEmpty) {
          photos.add(url.startsWith('http') ? url : ImageUtils.buildImageUrl(url));
        }
      }
    }
    final coverFromProfile = profile?['coverPhotoUrl']?.toString();
    final coverUrl = (coverFromProfile != null && coverFromProfile.isNotEmpty)
        ? (coverFromProfile.startsWith('http')
            ? coverFromProfile
            : ImageUtils.buildImageUrl(coverFromProfile))
        : (photos.isNotEmpty ? photos.first : null);

    final interests = <String>[];
    if (profile?['interests'] is List) {
      interests.addAll(
        (profile!['interests'] as List).map((e) => e.toString()),
      );
    }

    final talents = <String>[];
    if (profile?['talents'] is List) {
      talents.addAll(
        (profile!['talents'] as List).map((e) => e.toString()),
      );
    }

    // interestsDetail, talentsDetail từ API (name, icon)
    final interestsDetail = profile?['interestsDetail'] is List
        ? List<Map<String, dynamic>>.from(
            (profile!['interestsDetail'] as List)
                .whereType<Map<String, dynamic>>(),
          )
        : null;
    final talentsDetail = profile?['talentsDetail'] is List
        ? List<Map<String, dynamic>>.from(
            (profile!['talentsDetail'] as List)
                .whereType<Map<String, dynamic>>(),
          )
        : null;

    final languages = <String>[];
    if (profile?['languages'] is List) {
      languages.addAll(
        (profile!['languages'] as List).map((e) => e.toString()),
      );
    }

    // serviceTypes từ API
    final services = <String>[];
    if (data['serviceTypes'] is List) {
      services.addAll(
        (data['serviceTypes'] as List).map((e) => e.toString()),
      );
    }
    final serviceTypesDetail = data['serviceTypesDetail'] is List
        ? List<Map<String, dynamic>>.from(
            (data['serviceTypesDetail'] as List)
                .whereType<Map<String, dynamic>>(),
          )
        : null;

    final reviews = <ReviewEntity>[];
    if (user?['reviewsReceived'] is List) {
      for (final reviewData in user!['reviewsReceived'] as List) {
        if (reviewData is Map<String, dynamic>) {
          final reviewer = reviewData['reviewer'] as Map<String, dynamic>?;
          final reviewerProfile = reviewer?['profile'] as Map<String, dynamic>?;
          final avatar = reviewerProfile?['avatarUrl']?.toString();
          reviews.add(ReviewEntity(
            id: reviewData['id']?.toString() ?? '',
            userName: reviewerProfile?['fullName']?.toString() ??
                reviewerProfile?['displayName']?.toString() ??
                'Người dùng',
            userAvatar: avatar != null && avatar.isNotEmpty
                ? (avatar.startsWith('http')
                    ? avatar
                    : ImageUtils.buildImageUrl(avatar))
                : null,
            rating: _parseDouble(reviewData['rating']),
            comment: reviewData['comment']?.toString() ?? '',
            createdAt: reviewData['createdAt'] != null
                ? DateTime.tryParse(reviewData['createdAt'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
            serviceName: reviewData['serviceType']?.toString(),
          ));
        }
      }
    }

    int age = 25;
    if (profile?['dateOfBirth'] != null) {
      try {
        final dob = DateTime.parse(profile!['dateOfBirth'].toString());
        final now = DateTime.now();
        age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
      } catch (_) {}
    }

    final avatarUrl = profile?['avatarUrl']?.toString();
    final fullAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty
        ? (avatarUrl.startsWith('http')
            ? avatarUrl
            : ImageUtils.buildImageUrl(avatarUrl))
        : _kDefaultAvatarUrl;

    // introduction (API) ưu tiên hơn profile.bio
    final introduction = data['introduction']?.toString();
    final bio = introduction ?? profile?['bio']?.toString();

    // verificationBadge: "gold" | "PREMIUM" | ...
    final badge = data['verificationBadge']?.toString().toLowerCase();
    final isPremium = badge == 'gold' || badge == 'premium';

    // lastActiveAt ở top level (API) – backend cập nhật khi user đăng nhập / có hoạt động
    DateTime? lastActive;
    if (data['lastActiveAt'] != null) {
      lastActive = DateTime.tryParse(data['lastActiveAt'].toString());
    } else if (user?['lastActiveAt'] != null) {
      lastActive = DateTime.tryParse(user!['lastActiveAt'].toString());
    }
    // Online = có hoạt động trong N phút (tính từ lúc đăng nhập), không dùng isAvailable
    final isOnline = lastActive != null &&
        DateTime.now().difference(lastActive).inMinutes < AppConstants.onlineThresholdMinutes;

    // Stats từ API: totalBookings, completedBookings, responseTime (phút)
    PartnerEntityStats? stats;
    final totalBookings = data['totalBookings'] is int
        ? data['totalBookings'] as int
        : (data['totalBookings'] != null
            ? int.tryParse(data['totalBookings'].toString())
            : null);
    final responseTime = data['responseTime'];
    if (totalBookings != null || responseTime != null) {
      stats = PartnerEntityStats(
        totalBookings: totalBookings ?? 0,
        avgResponseTime: responseTime is int
            ? responseTime
            : (responseTime != null
                ? int.tryParse(responseTime.toString()) ?? 0
                : 0),
      );
    }

    // Backend GET /partners/:id expects userId, not PartnerProfile.id
    return PartnerEntity(
      id: data['userId']?.toString() ?? data['id']?.toString() ?? '',
      userId: data['userId']?.toString(),
      name: profile?['displayName']?.toString() ??
          profile?['fullName']?.toString() ??
          user?['email']?.toString().split('@').first ??
          'Partner',
      age: age,
      avatarUrl: fullAvatarUrl,
      coverPhotoUrl: coverUrl,
      rating: _parseDouble(data['averageRating']),
      reviewCount: (data['totalReviews'] is int)
          ? data['totalReviews'] as int
          : (data['totalReviews'] != null
              ? int.tryParse(data['totalReviews'].toString()) ?? 0
              : 0),
      hourlyRate: _parseDouble(data['hourlyRate']).round(),
      isOnline: isOnline,
      isVerified: data['isVerified'] == true,
      isPremium: isPremium,
      bio: bio,
      location: _buildLocation(profile),
      distance: null,
      services: services,
      interests: interests,
      talents: talents,
      languages: languages.isNotEmpty ? languages : ['Tiếng Việt'],
      gallery: photos,
      serviceTypesDetail: serviceTypesDetail,
      interestsDetail: interestsDetail,
      talentsDetail: talentsDetail,
      responseRate: _parseDouble(data['responseRate']).round(),
      completedBookings: (data['completedBookings'] is int)
          ? data['completedBookings'] as int
          : (data['completedBookings'] != null
              ? int.tryParse(data['completedBookings'].toString()) ?? 0
              : 0),
      workingHours: null,
      lastActive: lastActive,
      stats: stats,
      reviews: reviews,
      experienceYears: data['experienceYears'] is int
          ? data['experienceYears'] as int
          : (data['experienceYears'] != null
              ? int.tryParse(data['experienceYears'].toString())
              : null),
      minimumHours: data['minimumHours'] is int
          ? data['minimumHours'] as int
          : (data['minimumHours'] != null
              ? int.tryParse(data['minimumHours'].toString())
              : null),
      currency: data['currency']?.toString(),
    );
  }

  static String? _buildLocation(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final district = profile['district']?.toString();
    final city = profile['city']?.toString();
    if (district != null && city != null) {
      return '$district, $city';
    }
    return city ?? district;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
