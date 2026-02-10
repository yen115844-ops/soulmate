/// Model for a review
class ReviewModel {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final String reviewType;
  final int overallRating;
  final int? punctualityRating;
  final int? communicationRating;
  final int? attitudeRating;
  final int? appearanceRating;
  final int? serviceQualityRating;
  final String? comment;
  final List<String> photoUrls;
  final List<String> tags;
  final bool isVisible;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related user info
  final String? userName;
  final String? userAvatar;
  final String? partnerName;
  final String? partnerAvatar;
  final String? serviceType;
  final ReviewResponseModel? response;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.reviewType,
    required this.overallRating,
    this.punctualityRating,
    this.communicationRating,
    this.attitudeRating,
    this.appearanceRating,
    this.serviceQualityRating,
    this.comment,
    this.photoUrls = const [],
    this.tags = const [],
    this.isVisible = true,
    this.isAnonymous = false,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
    this.partnerName,
    this.partnerAvatar,
    this.serviceType,
    this.response,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    final reviewee = json['reviewee'] as Map<String, dynamic>?;
    final reviewerProfile = reviewer?['profile'] as Map<String, dynamic>?;
    final revieweeProfile = reviewee?['profile'] as Map<String, dynamic>?;
    final booking = json['booking'] as Map<String, dynamic>?;

    return ReviewModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      reviewerId: json['reviewerId'] ?? '',
      revieweeId: json['revieweeId'] ?? '',
      reviewType: json['reviewType'] ?? 'user_to_partner',
      overallRating: json['overallRating'] ?? 0,
      punctualityRating: json['punctualityRating'],
      communicationRating: json['communicationRating'],
      attitudeRating: json['attitudeRating'],
      appearanceRating: json['appearanceRating'],
      serviceQualityRating: json['serviceQualityRating'],
      comment: json['comment'],
      photoUrls: _parseList(json['photoUrls']),
      tags: _parseList(json['tags']),
      isVisible: json['isVisible'] ?? true,
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      userName: reviewerProfile?['fullName'] ?? reviewerProfile?['displayName'],
      userAvatar: reviewerProfile?['avatarUrl'],
      partnerName:
          revieweeProfile?['fullName'] ?? revieweeProfile?['displayName'],
      partnerAvatar: revieweeProfile?['avatarUrl'],
      serviceType: booking?['serviceType'],
      response: json['response'] != null
          ? ReviewResponseModel.fromJson(json['response'])
          : null,
    );
  }

  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  /// Get formatted date
  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    return '$day/$month/$year';
  }
}

/// Model for review response
class ReviewResponseModel {
  final String id;
  final String reviewId;
  final String responderId;
  final String response;
  final DateTime createdAt;

  const ReviewResponseModel({
    required this.id,
    required this.reviewId,
    required this.responderId,
    required this.response,
    required this.createdAt,
  });

  factory ReviewResponseModel.fromJson(Map<String, dynamic> json) {
    return ReviewResponseModel(
      id: json['id'] ?? '',
      reviewId: json['reviewId'] ?? '',
      responderId: json['responderId'] ?? '',
      response: json['response'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Response model for reviews list
class ReviewsListResponse {
  final List<ReviewModel> data;
  final int total;
  final int page;
  final int limit;

  const ReviewsListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ReviewsListResponse.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response: { success: true, data: { data: [...], meta: {...} } }
    Map<String, dynamic> actualData = json;
    if (json['data'] is Map<String, dynamic>) {
      actualData = json['data'] as Map<String, dynamic>;
    }

    final dataList = actualData['data'] as List? ?? [];
    final meta = actualData['meta'] as Map<String, dynamic>? ?? {};

    return ReviewsListResponse(
      data: dataList
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] ?? actualData['total'] ?? 0,
      page: meta['page'] ?? actualData['page'] ?? 1,
      limit: meta['limit'] ?? actualData['limit'] ?? 10,
    );
  }
}

/// Review stats model
class ReviewStatsModel {
  final double averageRating;
  final int totalReviews;
  final int fiveStars;
  final int fourStars;
  final int threeStars;
  final int twoStars;
  final int oneStar;

  const ReviewStatsModel({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.fiveStars = 0,
    this.fourStars = 0,
    this.threeStars = 0,
    this.twoStars = 0,
    this.oneStar = 0,
  });

  factory ReviewStatsModel.fromJson(Map<String, dynamic> json) {
    final distribution =
        json['ratingDistribution'] as Map<String, dynamic>? ?? {};
    return ReviewStatsModel(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      fiveStars: distribution['5'] ?? 0,
      fourStars: distribution['4'] ?? 0,
      threeStars: distribution['3'] ?? 0,
      twoStars: distribution['2'] ?? 0,
      oneStar: distribution['1'] ?? 0,
    );
  }
}
