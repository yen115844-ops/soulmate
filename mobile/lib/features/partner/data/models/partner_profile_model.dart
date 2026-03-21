/// Partner Profile Response Model
class PartnerProfileResponse {
  final String id;
  final String userId;
  final double hourlyRate;
  final int minimumHours;
  final String currency;
  final List<String> serviceTypes;
  final String? introduction;
  final int? experienceYears;
  final bool isVerified;
  final String? verificationBadge;
  final bool isAvailable;
  final double averageRating;
  final int totalReviews;
  final int totalBookings;
  final int completedBookings;
  final DateTime createdAt;

  PartnerProfileResponse({
    required this.id,
    required this.userId,
    required this.hourlyRate,
    required this.minimumHours,
    required this.currency,
    required this.serviceTypes,
    this.introduction,
    this.experienceYears,
    required this.isVerified,
    this.verificationBadge,
    required this.isAvailable,
    required this.averageRating,
    required this.totalReviews,
    required this.totalBookings,
    required this.completedBookings,
    required this.createdAt,
  });

  factory PartnerProfileResponse.fromJson(Map<String, dynamic> json) {
    return PartnerProfileResponse(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      hourlyRate: _parseDouble(json['hourlyRate']),
      minimumHours: json['minimumHours'] is int ? json['minimumHours'] : 3,
      currency: json['currency']?.toString() ?? 'VND',
      serviceTypes: (json['serviceTypes'] is List)
          ? List<String>.from(
              (json['serviceTypes'] as List).map((e) => e.toString()),
            )
          : <String>[],
      introduction: json['introduction'] is String
          ? json['introduction']
          : null,
      experienceYears: json['experienceYears'] is int
          ? json['experienceYears']
          : null,
      isVerified: json['isVerified'] == true,
      verificationBadge: json['verificationBadge'] is String
          ? json['verificationBadge']
          : null,
      isAvailable: json['isAvailable'] == true,
      averageRating: _parseDouble(json['averageRating']),
      totalReviews: json['totalReviews'] is int ? json['totalReviews'] : 0,
      totalBookings: json['totalBookings'] is int ? json['totalBookings'] : 0,
      completedBookings: json['completedBookings'] is int
          ? json['completedBookings']
          : 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  /// Helper to parse double from various types (String, int, double)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Partner search response
class PartnerSearchResponse {
  final List<PartnerProfileResponse> partners;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PartnerSearchResponse({
    required this.partners,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PartnerSearchResponse.fromJson(Map<String, dynamic> json) {
    return PartnerSearchResponse(
      partners:
          (json['data'] as List?)
              ?.map((e) => PartnerProfileResponse.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

/// Partner user info for dashboard display
class PartnerUserInfo {
  final String? displayName;
  final String? fullName;
  final String? avatarUrl;
  final String? email;

  PartnerUserInfo({
    this.displayName,
    this.fullName,
    this.avatarUrl,
    this.email,
  });

  /// Get best display name
  String get name =>
      displayName ?? fullName ?? email?.split('@').first ?? 'Partner';

  factory PartnerUserInfo.fromJson(Map<String, dynamic> json) {
    // Extract from user.profile or directly from profile
    final profile = json['profile'] as Map<String, dynamic>? ?? json;
    return PartnerUserInfo(
      displayName: profile['displayName'] as String?,
      fullName: profile['fullName'] as String?,
      avatarUrl: profile['avatarUrl'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Partner profile with full user info response
class PartnerProfileFullResponse {
  final PartnerProfileResponse profile;
  final PartnerUserProfileInfo? userProfile;

  PartnerProfileFullResponse({required this.profile, this.userProfile});
}

/// User profile info from partner profile response
class PartnerUserProfileInfo {
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final String? dateOfBirth;
  final int? heightCm;
  final int? weightKg;
  final String? city;
  final String? district;
  final List<String> photos;
  final List<String> languages;
  final List<String> interests;
  final List<String> talents;
  final List<Map<String, dynamic>> interestsDetail;
  final List<Map<String, dynamic>> talentsDetail;

  PartnerUserProfileInfo({
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.city,
    this.district,
    this.photos = const [],
    this.languages = const [],
    this.interests = const [],
    this.talents = const [],
    this.interestsDetail = const [],
    this.talentsDetail = const [],
  });

  /// Calculate age from dateOfBirth
  int? get age {
    if (dateOfBirth == null) return null;
    try {
      final dob = DateTime.parse(dateOfBirth!);
      final now = DateTime.now();
      int years = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        years--;
      }
      return years;
    } catch (_) {
      return null;
    }
  }

  factory PartnerUserProfileInfo.fromJson(Map<String, dynamic> json) {
    return PartnerUserProfileInfo(
      fullName: json['fullName'] is String ? json['fullName'] : null,
      displayName: json['displayName'] is String ? json['displayName'] : null,
      avatarUrl: json['avatarUrl'] is String ? json['avatarUrl'] : null,
      bio: json['bio'] is String ? json['bio'] : null,
      gender: json['gender'] is String ? json['gender'] : null,
      dateOfBirth:
          json['dateOfBirth'] is String ? json['dateOfBirth'] : null,
      heightCm: json['heightCm'] is int ? json['heightCm'] : null,
      weightKg: json['weightKg'] is int ? json['weightKg'] : null,
      city: json['city'] is String ? json['city'] : null,
      district: json['district'] is String ? json['district'] : null,
      photos: (json['photos'] is List)
          ? List<String>.from((json['photos'] as List).map((e) => e.toString()))
          : <String>[],
      languages: (json['languages'] is List)
          ? List<String>.from(
              (json['languages'] as List).map((e) => e.toString()),
            )
          : <String>[],
      interests: (json['interests'] is List)
          ? List<String>.from(
              (json['interests'] as List).map((e) => e.toString()),
            )
          : <String>[],
      talents: (json['talents'] is List)
          ? List<String>.from(
              (json['talents'] as List).map((e) => e.toString()),
            )
          : <String>[],
      interestsDetail: (json['interestsDetail'] is List)
          ? (json['interestsDetail'] as List)
              .whereType<Map<String, dynamic>>()
              .toList()
          : <Map<String, dynamic>>[],
      talentsDetail: (json['talentsDetail'] is List)
          ? (json['talentsDetail'] as List)
              .whereType<Map<String, dynamic>>()
              .toList()
          : <Map<String, dynamic>>[],
    );
  }
}

/// Partner detail response with full user info (for booking, profile view)
class PartnerDetailResponse {
  final PartnerProfileResponse profile;
  final String? userId;
  final PartnerUserInfo? userInfo;
  final PartnerUserProfileInfo? userProfile;
  final List<Map<String, dynamic>> serviceTypesDetail;
  final PartnerReviewStats? reviewStats;

  PartnerDetailResponse({
    required this.profile,
    this.userId,
    this.userInfo,
    this.userProfile,
    this.serviceTypesDetail = const [],
    this.reviewStats,
  });

  /// Get display name
  String get displayName =>
      userProfile?.displayName ??
      userProfile?.fullName ??
      userInfo?.name ??
      'Partner';

  /// Get avatar URL
  String? get avatarUrl => userProfile?.avatarUrl ?? userInfo?.avatarUrl;

  /// Get bio
  String? get bio => userProfile?.bio ?? profile.introduction;

  /// Get location string
  String? get location {
    final parts = <String>[];
    if (userProfile?.district != null) parts.add(userProfile!.district!);
    if (userProfile?.city != null) parts.add(userProfile!.city!);
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Get photos list
  List<String> get photos => userProfile?.photos ?? [];

  /// Get languages list
  List<String> get languages => userProfile?.languages ?? [];

  /// Get interests list
  List<String> get interests => userProfile?.interests ?? [];

  /// Get interests detail (with icon, name, etc.)
  List<Map<String, dynamic>> get interestsDetail =>
      userProfile?.interestsDetail ?? [];

  /// Get talents detail (with icon, name, etc.)
  List<Map<String, dynamic>> get talentsDetail =>
      userProfile?.talentsDetail ?? [];

  /// Get height
  int? get heightCm => userProfile?.heightCm;

  /// Get weight
  int? get weightKg => userProfile?.weightKg;

  /// Get age
  int? get age => userProfile?.age;

  /// Get gender
  String? get gender => userProfile?.gender;

  factory PartnerDetailResponse.fromJson(Map<String, dynamic> json) {
    final profile = PartnerProfileResponse.fromJson(json);

    // Extract user info
    PartnerUserInfo? userInfo;
    PartnerUserProfileInfo? userProfile;

    if (json['user'] is Map<String, dynamic>) {
      final userData = json['user'] as Map<String, dynamic>;
      userInfo = PartnerUserInfo.fromJson(userData);

      if (userData['profile'] is Map<String, dynamic>) {
        userProfile = PartnerUserProfileInfo.fromJson(
          userData['profile'] as Map<String, dynamic>,
        );
      }
    }

    // Parse serviceTypesDetail from top-level
    final serviceTypesDetail = (json['serviceTypesDetail'] is List)
        ? (json['serviceTypesDetail'] as List)
            .whereType<Map<String, dynamic>>()
            .toList()
        : <Map<String, dynamic>>[];

    return PartnerDetailResponse(
      profile: profile,
      userId: json['user'] is Map<String, dynamic>
          ? (json['user'] as Map<String, dynamic>)['id'] as String?
          : null,
      userInfo: userInfo,
      userProfile: userProfile,
      serviceTypesDetail: serviceTypesDetail,
      reviewStats: json['reviewStats'] is Map<String, dynamic>
          ? PartnerReviewStats.fromJson(json['reviewStats'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PartnerReviewStats {
  final double averageRating;
  final int totalReviews;
  final int rating1Count;
  final int rating2Count;
  final int rating3Count;
  final int rating4Count;
  final int rating5Count;

  PartnerReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.rating1Count,
    required this.rating2Count,
    required this.rating3Count,
    required this.rating4Count,
    required this.rating5Count,
  });

  factory PartnerReviewStats.fromJson(Map<String, dynamic> json) {
    final distribution = json['ratingDistribution'] as Map<String, dynamic>?;
    return PartnerReviewStats(
      averageRating: PartnerProfileResponse._parseDouble(json['averageRating']),
      totalReviews: json['totalReviews'] is int ? json['totalReviews'] as int : 0,
      rating1Count: distribution?['1'] is int ? distribution!['1'] as int : 0,
      rating2Count: distribution?['2'] is int ? distribution!['2'] as int : 0,
      rating3Count: distribution?['3'] is int ? distribution!['3'] as int : 0,
      rating4Count: distribution?['4'] is int ? distribution!['4'] as int : 0,
      rating5Count: distribution?['5'] is int ? distribution!['5'] as int : 0,
    );
  }

  double getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    int count = 0;
    if (stars == 5) count = rating5Count;
    if (stars == 4) count = rating4Count;
    if (stars == 3) count = rating3Count;
    if (stars == 2) count = rating2Count;
    if (stars == 1) count = rating1Count;
    return count / totalReviews;
  }
}
