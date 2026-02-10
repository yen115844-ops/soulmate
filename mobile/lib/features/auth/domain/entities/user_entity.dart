import 'package:equatable/equatable.dart';

import '../../data/models/user_enums.dart';

/// User Entity - Core domain entity representing a user
/// This is a pure domain entity without any data layer dependencies
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final KycStatus kycStatus;
  final ProfileEntity? profile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.phone,
    this.role = UserRole.user,
    this.status = UserStatus.pending,
    this.kycStatus = KycStatus.notSubmitted,
    this.profile,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if user is a partner
  bool get isPartner => role == UserRole.partner;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is verified (KYC approved)
  bool get isVerified => kycStatus == KycStatus.approved;

  /// Check if user account is active
  bool get isActive => status == UserStatus.active;

  UserEntity copyWith({
    String? id,
    String? email,
    String? phone,
    UserRole? role,
    UserStatus? status,
    KycStatus? kycStatus,
    ProfileEntity? profile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        role,
        status,
        kycStatus,
        profile,
        createdAt,
        updatedAt,
      ];
}

/// Profile Entity - Core domain entity for user profile
class ProfileEntity extends Equatable {
  final String? id;
  final String? name;
  final String? displayName;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? photoUrl;
  final double? heightCm;
  final double? weightKg;
  final String? city;
  final String? district;
  final String? address;
  final List<String> languages;
  final List<String> interests;
  final List<String> talents;
  final List<String> photos;

  const ProfileEntity({
    this.id,
    this.name,
    this.displayName,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.photoUrl,
    this.heightCm,
    this.weightKg,
    this.city,
    this.district,
    this.address,
    this.languages = const [],
    this.interests = const [],
    this.talents = const [],
    this.photos = const [],
  });

  /// Get age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  ProfileEntity copyWith({
    String? id,
    String? name,
    String? displayName,
    String? bio,
    String? gender,
    DateTime? dateOfBirth,
    String? photoUrl,
    double? heightCm,
    double? weightKg,
    String? city,
    String? district,
    String? address,
    List<String>? languages,
    List<String>? interests,
    List<String>? talents,
    List<String>? photos,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: photoUrl ?? this.photoUrl,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      city: city ?? this.city,
      district: district ?? this.district,
      address: address ?? this.address,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      talents: talents ?? this.talents,
      photos: photos ?? this.photos,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        bio,
        gender,
        dateOfBirth,
        photoUrl,
        heightCm,
        weightKg,
        city,
        district,
        address,
        languages,
        interests,
        talents,
        photos,
      ];
}
