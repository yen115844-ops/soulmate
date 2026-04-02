import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/base_repository.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/data/models/master_data_models.dart';
import '../../partner/domain/entities/partner_entity.dart';

/// Repository for Home feature - handles partner search and discovery
class HomeRepository with BaseRepositoryMixin {
  final ApiClient _apiClient;

  HomeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Load all provinces from master data
  Future<List<ProvinceModel>> getProvinces() async {
    try {
      final response = await _apiClient.get('/master-data/provinces');
      final data = extractRawData(response.data);
      if (data is List) {
        return data
            .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('HomeRepository: Load provinces error: $e');
      return [];
    }
  }

  /// Load all service types from master data
  Future<List<ServiceTypeModel>> getServiceTypes() async {
    try {
      final response = await _apiClient.get('/master-data/service-types');
      final data = extractRawData(response.data);
      if (data is List) {
        return data
            .map((e) => ServiceTypeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('HomeRepository: Load service types error: $e');
      return [];
    }
  }

  /// Load districts for a province
  Future<List<DistrictModel>> getDistrictsByProvinceId(
    String provinceId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/master-data/provinces/$provinceId/districts',
      );
      final data = extractRawData(response.data);
      if (data is List) {
        return data
            .map((e) => DistrictModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('HomeRepository: Load districts error: $e');
      return [];
    }
  }

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
    String? provinceId,
    String? districtId,
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
          if (provinceId != null) 'cityId': provinceId,
          if (districtId != null) 'districtId': districtId,
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

  /// Persist current user location so other users can discover nearby.
  Future<void> updateCurrentLocation({
    required double latitude,
    required double longitude,
    String? provinceId,
    String? districtId,
    String? city,
    String? district,
  }) async {
    await _apiClient.put(
      UserEndpoints.location,
      data: {
        'currentLat': latitude,
        'currentLng': longitude,
        if (provinceId != null) 'provinceId': provinceId,
        if (districtId != null) 'districtId': districtId,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
      },
    );
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

    // Gallery now supports both legacy string and rich object {url,width,height,aspectRatio}
    final photos = _extractProfilePhotoUrls(profile?['photos']);
    final bestCardPhotoUrl = _pickBestCardPhotoUrl(profile?['photos']);
    final coverFromProfile = _normalizeImagePath(profile?['coverPhotoUrl']);
    final coverUrl = coverFromProfile ?? bestCardPhotoUrl ?? (photos.isNotEmpty ? photos.first : null);
    final cardImageAspectRatio = _aspectRatioForCoverUrl(coverUrl, profile?['photos']);

    final interests = <String>[];
    if (profile?['interests'] is List) {
      interests.addAll(
        (profile!['interests'] as List).map((e) => e.toString()),
      );
    }

    final talents = <String>[];
    if (profile?['talents'] is List) {
      talents.addAll((profile!['talents'] as List).map((e) => e.toString()));
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
      services.addAll((data['serviceTypes'] as List).map((e) => e.toString()));
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
          reviews.add(
            ReviewEntity(
              id: reviewData['id']?.toString() ?? '',
              userName:
                  reviewerProfile?['fullName']?.toString() ??
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
            ),
          );
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

    final avatarUrl = _normalizeImagePath(profile?['avatarUrl']) ?? _kDefaultAvatarUrl;

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
    final isOnline =
        lastActive != null &&
        DateTime.now().difference(lastActive).inMinutes <
            AppConstants.onlineThresholdMinutes;

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
      name:
          profile?['displayName']?.toString() ??
          profile?['fullName']?.toString() ??
          user?['email']?.toString().split('@').first ??
          'Partner',
      age: age,
      avatarUrl: avatarUrl,
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
      distance: _parseNullableDouble(data['distanceKm']),
      services: services,
      interests: interests,
      talents: talents,
      languages: languages.isNotEmpty ? languages : ['Tiếng Việt'],
      gallery: photos,
      cardImageAspectRatio: cardImageAspectRatio,
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

  static List<String> _extractProfilePhotoUrls(dynamic rawPhotos) {
    if (rawPhotos is! List) return const [];
    final out = <String>[];
    final seen = <String>{};
    for (final item in rawPhotos) {
      final normalized = _normalizeImagePath(item is Map ? item['url'] : item);
      if (normalized == null || normalized.isEmpty) continue;
      if (seen.add(normalized)) {
        out.add(normalized);
      }
    }
    return out;
  }

  /// So khớp URL tương đối/absolute (buildImageUrl) khi tìm metadata ảnh.
  static bool _sameImageUrlForAspect(String a, String b) {
    if (a == b) return true;
    final fa = ImageUtils.buildImageUrl(a);
    final fb = ImageUtils.buildImageUrl(b);
    if (fa == fb) return true;
    final ua = Uri.tryParse(fa);
    final ub = Uri.tryParse(fb);
    if (ua == null || ub == null) return false;
    if (ua.path.isNotEmpty && ua.path == ub.path) {
      if (!ua.hasAuthority || !ub.hasAuthority) return true;
      return ua.authority == ub.authority;
    }
    return false;
  }

  /// aspectRatio từ API = width/height; khớp URL cover/gallery để card home không bóp ảnh.
  static double? _aspectRatioForCoverUrl(String? coverUrl, dynamic rawPhotos) {
    if (coverUrl == null || rawPhotos is! List) return null;
    final target = _normalizeImagePath(coverUrl);
    if (target == null || target.isEmpty) return null;

    for (final item in rawPhotos) {
      final url = _normalizeImagePath(item is Map ? item['url'] : item);
      if (url == null || url.isEmpty || !_sameImageUrlForAspect(target, url)) {
        continue;
      }

      if (item is Map) {
        final v = item['aspectRatio'];
        if (v is num) {
          final ar = v.toDouble();
          if (ar > 0 && ar.isFinite) return ar;
        }
        if (item['width'] is num && item['height'] is num) {
          final w = (item['width'] as num).toDouble();
          final h = (item['height'] as num).toDouble();
          if (h > 0) {
            final ar = w / h;
            if (ar > 0 && ar.isFinite) return ar;
          }
        }
      }
    }
    return null;
  }

  /// Picks the best photo URL for Home card (portrait-ish) using aspectRatio when available.
  /// target AR ~ 4/5 (0.8). Lower score is better.
  static String? _pickBestCardPhotoUrl(dynamic rawPhotos) {
    if (rawPhotos is! List || rawPhotos.isEmpty) return null;

    const targetAr = 4 / 5;
    String? bestUrl;
    double bestScore = double.infinity;

    for (final item in rawPhotos) {
      final url = _normalizeImagePath(item is Map ? item['url'] : item);
      if (url == null || url.isEmpty) continue;

      double? ar;
      if (item is Map) {
        final v = item['aspectRatio'];
        if (v is num) ar = v.toDouble();
        if (ar == null && item['width'] is num && item['height'] is num) {
          final w = (item['width'] as num).toDouble();
          final h = (item['height'] as num).toDouble();
          if (h > 0) ar = w / h;
        }
      }

      // Prefer items with known AR close to target; otherwise keep but deprioritize.
      final score = (ar != null && ar.isFinite && ar > 0)
          ? (ar - targetAr).abs()
          : 10.0;

      if (score < bestScore) {
        bestScore = score;
        bestUrl = url;
      }
    }

    return bestUrl;
  }

  static String? _normalizeImagePath(dynamic value) {
    if (value == null) return null;
    final url = value.toString().trim();
    if (url.isEmpty) return null;
    return url;
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

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
