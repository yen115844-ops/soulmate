import 'partner_stats_model.dart';

/// Partner review model
class PartnerReview {
  final String id;
  final String bookingId;
  final double overallRating;
  final double? punctualityRating;
  final double? communicationRating;
  final double? personalityRating;
  final String? comment;
  final ReviewerInfo reviewer;
  final DateTime createdAt;

  PartnerReview({
    required this.id,
    required this.bookingId,
    required this.overallRating,
    this.punctualityRating,
    this.communicationRating,
    this.personalityRating,
    this.comment,
    required this.reviewer,
    required this.createdAt,
  });

  factory PartnerReview.fromJson(Map<String, dynamic> json) {
    return PartnerReview(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      overallRating: PartnerStats.parseDouble(json['overallRating']),
      punctualityRating: json['punctualityRating'] != null
          ? PartnerStats.parseDouble(json['punctualityRating'])
          : null,
      communicationRating: json['communicationRating'] != null
          ? PartnerStats.parseDouble(json['communicationRating'])
          : null,
      personalityRating: json['personalityRating'] != null
          ? PartnerStats.parseDouble(json['personalityRating'])
          : null,
      comment: json['comment'] is String ? json['comment'] : null,
      reviewer: json['reviewer'] is Map<String, dynamic>
          ? ReviewerInfo.fromJson(json['reviewer'])
          : ReviewerInfo.empty(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}

/// Reviewer info
class ReviewerInfo {
  final String id;
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;

  ReviewerInfo({
    required this.id,
    this.fullName,
    this.displayName,
    this.avatarUrl,
  });

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return ReviewerInfo(
      id: json['id']?.toString() ?? '',
      fullName: profile?['fullName'] is String ? profile!['fullName'] : null,
      displayName:
          profile?['displayName'] is String ? profile!['displayName'] : null,
      avatarUrl:
          profile?['avatarUrl'] is String ? profile!['avatarUrl'] : null,
    );
  }

  factory ReviewerInfo.empty() => ReviewerInfo(id: '');

  String get name => displayName ?? fullName ?? 'Ẩn danh';
}

/// Partner reviews response
class PartnerReviewsResponse {
  final List<PartnerReview> reviews;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PartnerReviewsResponse({
    required this.reviews,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PartnerReviewsResponse.fromPartnerData(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final reviewsList = user?['reviewsReceived'] as List? ?? [];

    return PartnerReviewsResponse(
      reviews: reviewsList
          .map((e) => PartnerReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: reviewsList.length,
      page: 1,
      limit: 10,
      totalPages: 1,
    );
  }

  factory PartnerReviewsResponse.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    return PartnerReviewsResponse(
      reviews: (json['data'] as List?)
              ?.map((e) => PartnerReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: meta['total'] ?? 0,
      page: meta['page'] ?? 1,
      limit: meta['limit'] ?? 10,
      totalPages: meta['totalPages'] ?? 1,
    );
  }
}

/// Review statistics
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final int rating5Count;
  final int rating4Count;
  final int rating3Count;
  final int rating2Count;
  final int rating1Count;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.rating5Count,
    required this.rating4Count,
    required this.rating3Count,
    required this.rating2Count,
    required this.rating1Count,
  });

  /// Calculate percentage for a star count
  double getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    int count;
    switch (stars) {
      case 5:
        count = rating5Count;
        break;
      case 4:
        count = rating4Count;
        break;
      case 3:
        count = rating3Count;
        break;
      case 2:
        count = rating2Count;
        break;
      case 1:
        count = rating1Count;
        break;
      default:
        count = 0;
    }
    return count / totalReviews;
  }
}
