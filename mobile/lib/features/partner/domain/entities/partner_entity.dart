import 'package:equatable/equatable.dart';

/// Partner Entity - Represents a partner/companion in the app
class PartnerEntity extends Equatable {
  final String id;
  final String name;
  final int age;
  final String avatarUrl;
  final String? coverPhotoUrl;
  final double rating;
  final int reviewCount;
  final int hourlyRate;
  final bool isOnline;
  final bool isVerified;
  final bool isPremium;
  final String? bio;
  final String? location;
  final double? distance;
  final List<String> services;
  final List<String> interests;
  final List<String> talents;
  final List<String> languages;
  final List<String> gallery;
  /// Chi tiết từ API (name, icon) - ưu tiên dùng cho hiển thị
  final List<Map<String, dynamic>>? serviceTypesDetail;
  final List<Map<String, dynamic>>? interestsDetail;
  final List<Map<String, dynamic>>? talentsDetail;
  final int responseRate;
  final int completedBookings;
  final String? workingHours;
  final DateTime? lastActive;
  final PartnerEntityStats? stats;
  final List<ReviewEntity> reviews;
  /// Năm kinh nghiệm (từ API introduction/experienceYears)
  final int? experienceYears;
  /// Số giờ đặt tối thiểu (từ API minimumHours)
  final int? minimumHours;
  /// Mã tiền tệ (từ API currency, ví dụ "VND")
  final String? currency;
  /// User ID dùng cho chat (từ API user.id / userId)
  final String? userId;

  const PartnerEntity({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarUrl,
    this.coverPhotoUrl,
    required this.rating,
    required this.reviewCount,
    required this.hourlyRate,
    this.isOnline = false,
    this.isVerified = false,
    this.isPremium = false,
    this.bio,
    this.location,
    this.distance,
    this.services = const [],
    this.interests = const [],
    this.talents = const [],
    this.languages = const ['Tiếng Việt'],
    this.gallery = const [],
    this.serviceTypesDetail,
    this.interestsDetail,
    this.talentsDetail,
    this.responseRate = 0,
    this.completedBookings = 0,
    this.workingHours,
    this.lastActive,
    this.stats,
    this.reviews = const [],
    this.experienceYears,
    this.minimumHours,
    this.currency,
    this.userId,
  });

  /// Format hourly rate as Vietnamese currency
  String get formattedHourlyRate {
    if (hourlyRate >= 1000000) {
      return '${(hourlyRate / 1000000).toStringAsFixed(1)}M';
    } else if (hourlyRate >= 1000) {
      return '${(hourlyRate / 1000).toStringAsFixed(0)}K';
    }
    return hourlyRate.toString();
  }

  /// Format distance
  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)}m';
    }
    return '${distance!.toStringAsFixed(1)} km';
  }

  /// Get online status text
  String get onlineStatusText {
    if (isOnline) return 'Online';
    if (lastActive != null) {
      final diff = DateTime.now().difference(lastActive!);
      if (diff.inMinutes < 60) {
        return 'Online ${diff.inMinutes}p trước';
      } else if (diff.inHours < 24) {
        return 'Online ${diff.inHours}h trước';
      }
      return 'Online ${diff.inDays}d trước';
    }
    return 'Offline';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        avatarUrl,
        coverPhotoUrl,
        rating,
        reviewCount,
        hourlyRate,
        isOnline,
        isVerified,
        isPremium,
        bio,
        location,
        distance,
        services,
        interests,
        talents,
        languages,
        serviceTypesDetail,
        interestsDetail,
        talentsDetail,
        gallery,
        responseRate,
        completedBookings,
        workingHours,
        lastActive,
        stats,
        reviews,
        experienceYears,
        minimumHours,
        currency,
        userId,
      ];

  PartnerEntity copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarUrl,
    String? coverPhotoUrl,
    double? rating,
    int? reviewCount,
    int? hourlyRate,
    bool? isOnline,
    bool? isVerified,
    bool? isPremium,
    String? bio,
    String? location,
    double? distance,
    List<String>? services,
    List<String>? interests,
    List<String>? talents,
    List<String>? languages,
    List<Map<String, dynamic>>? serviceTypesDetail,
    List<Map<String, dynamic>>? interestsDetail,
    List<Map<String, dynamic>>? talentsDetail,
    List<String>? gallery,
    int? responseRate,
    int? completedBookings,
    String? workingHours,
    DateTime? lastActive,
    PartnerEntityStats? stats,
    List<ReviewEntity>? reviews,
    int? experienceYears,
    int? minimumHours,
    String? currency,
    String? userId,
  }) {
    return PartnerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      services: services ?? this.services,
      interests: interests ?? this.interests,
      talents: talents ?? this.talents,
      languages: languages ?? this.languages,
      serviceTypesDetail: serviceTypesDetail ?? this.serviceTypesDetail,
      interestsDetail: interestsDetail ?? this.interestsDetail,
      talentsDetail: talentsDetail ?? this.talentsDetail,
      gallery: gallery ?? this.gallery,
      responseRate: responseRate ?? this.responseRate,
      completedBookings: completedBookings ?? this.completedBookings,
      workingHours: workingHours ?? this.workingHours,
      lastActive: lastActive ?? this.lastActive,
      stats: stats ?? this.stats,
      reviews: reviews ?? this.reviews,
      experienceYears: experienceYears ?? this.experienceYears,
      minimumHours: minimumHours ?? this.minimumHours,
      currency: currency ?? this.currency,
      userId: userId ?? this.userId,
    );
  }
}

/// Partner statistics for entity display
class PartnerEntityStats extends Equatable {
  final int totalViews;
  final int totalBookings;
  final int repeatClients;
  final double acceptanceRate;
  final int avgResponseTime; // in minutes

  const PartnerEntityStats({
    this.totalViews = 0,
    this.totalBookings = 0,
    this.repeatClients = 0,
    this.acceptanceRate = 0,
    this.avgResponseTime = 0,
  });

  @override
  List<Object?> get props => [
        totalViews,
        totalBookings,
        repeatClients,
        acceptanceRate,
        avgResponseTime,
      ];
}

/// Review Entity
class ReviewEntity extends Equatable {
  final String id;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? serviceName;
  final List<String>? images;
  final int helpfulCount;
  final String? reply;
  final DateTime? replyAt;

  const ReviewEntity({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.serviceName,
    this.images,
    this.helpfulCount = 0,
    this.reply,
    this.replyAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} tuần trước';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} tháng trước';
    }
    return '${(diff.inDays / 365).floor()} năm trước';
  }

  @override
  List<Object?> get props => [
        id,
        userName,
        userAvatar,
        rating,
        comment,
        createdAt,
        serviceName,
        images,
        helpfulCount,
        reply,
        replyAt,
      ];
}

/// Service Category
class ServiceCategory extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final int color;
  final String? iconName;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.iconName,
  });

  @override
  List<Object?> get props => [id, name, emoji, color, iconName];
}
