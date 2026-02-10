import 'package:equatable/equatable.dart';

import '../../../auth/data/models/user_model.dart';

/// Profile States for ProfileBloc
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Updating state (for profile updates, avatar uploads, etc.)
class ProfileUpdating extends ProfileState {
  const ProfileUpdating();
}

/// Loaded state with user data
class ProfileLoaded extends ProfileState {
  final UserModel user;
  final ProfileStats stats;

  const ProfileLoaded({
    required this.user,
    required this.stats,
  });

  /// Get display name
  String get displayName =>
      user.profile?.displayName ??
      user.profile?.fullName ??
      user.email.split('@').first;

  /// Get avatar URL
  String? get avatarUrl => user.profile?.avatarUrl;

  /// Get role display text
  String get roleText {
    switch (user.role) {
      case 'PARTNER':
        return 'Partner';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Người dùng';
    }
  }

  /// Get KYC status text
  String get kycStatusText {
    switch (user.kycStatus) {
      case 'VERIFIED':
        return 'Đã xác minh';
      case 'PENDING':
        return 'Đang xác minh';
      case 'REJECTED':
        return 'Bị từ chối';
      default:
        return 'Chưa xác minh';
    }
  }

  /// Check if KYC is verified
  bool get isKycVerified => user.kycStatus == 'VERIFIED';

  @override
  List<Object?> get props => [user, stats];
}

/// Error state
class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Profile update success state
class ProfileUpdateSuccess extends ProfileState {
  final UserModel user;

  const ProfileUpdateSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Avatar update success state
class ProfileAvatarUpdateSuccess extends ProfileState {
  final String avatarUrl;

  const ProfileAvatarUpdateSuccess({required this.avatarUrl});

  @override
  List<Object?> get props => [avatarUrl];
}

/// Photos update success state
class ProfilePhotosUpdateSuccess extends ProfileState {
  const ProfilePhotosUpdateSuccess();
}

/// Profile statistics model
class ProfileStats extends Equatable {
  final int totalBookings;
  final int totalReviews;
  final double averageRating;
  final double walletBalance;
  final bool isPartner;
  final PartnerStatus? partnerStatus;

  const ProfileStats({
    this.totalBookings = 0,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    this.walletBalance = 0.0,
    this.isPartner = false,
    this.partnerStatus,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalBookings: json['totalBookings'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      averageRating: _parseDouble(json['averageRating']),
      walletBalance: _parseDouble(json['walletBalance']),
      isPartner: json['isPartner'] as bool? ?? false,
      partnerStatus: json['partnerStatus'] != null
          ? PartnerStatus.fromJson(json['partnerStatus'])
          : null,
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

  @override
  List<Object?> get props => [
        totalBookings,
        totalReviews,
        averageRating,
        walletBalance,
        isPartner,
        partnerStatus,
      ];
}

/// Partner status model
class PartnerStatus extends Equatable {
  final bool isVerified;
  final bool isAvailable;
  final String? verificationBadge;
  final int totalBookings;
  final int completedBookings;
  final double averageRating;
  final int totalReviews;

  const PartnerStatus({
    this.isVerified = false,
    this.isAvailable = true,
    this.verificationBadge,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  factory PartnerStatus.fromJson(Map<String, dynamic> json) {
    return PartnerStatus(
      isVerified: json['isVerified'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      verificationBadge: json['verificationBadge'] as String?,
      totalBookings: json['totalBookings'] as int? ?? 0,
      completedBookings: json['completedBookings'] as int? ?? 0,
      averageRating: ProfileStats._parseDouble(json['averageRating']),
      totalReviews: json['totalReviews'] as int? ?? 0,
    );
  }

  /// Get status text for display
  String get statusText {
    if (isVerified) {
      return 'Đã xác minh';
    }
    return 'Đang chờ duyệt';
  }

  @override
  List<Object?> get props => [
        isVerified,
        isAvailable,
        verificationBadge,
        totalBookings,
        completedBookings,
        averageRating,
        totalReviews,
      ];
}
