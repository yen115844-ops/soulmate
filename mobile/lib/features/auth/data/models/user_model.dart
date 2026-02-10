import 'package:equatable/equatable.dart';

/// User Model representing the authenticated user
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final String? role;
  final String? status;
  final String? kycStatus;
  final ProfileModel? profile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.role,
    this.status,
    this.kycStatus,
    this.profile,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      kycStatus: json['kycStatus']?.toString(),
      profile: json['profile'] != null
          ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'kycStatus': kycStatus,
      'profile': profile?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? kycStatus,
    ProfileModel? profile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
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

  // Helper getters for display
  String get displayRole => role ?? 'USER';
  String get displayStatus => status ?? 'PENDING';

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

/// Profile Model for user profile details
class ProfileModel extends Equatable {
  final String id;
  final String? userId;
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final int? heightCm;
  final int? weightKg;
  final double? currentLat;
  final double? currentLng;
  final String? city;
  final String? district;
  final String? address;
  final List<String> languages;
  final List<String> interests;
  final List<String> talents;
  final List<String> photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    this.userId,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.currentLat,
    this.currentLng,
    this.city,
    this.district,
    this.address,
    this.languages = const [],
    this.interests = const [],
    this.talents = const [],
    this.photos = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      fullName: json['fullName']?.toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      coverPhotoUrl: json['coverPhotoUrl']?.toString(),
      bio: json['bio']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      heightCm: json['heightCm'] != null ? int.tryParse(json['heightCm'].toString()) : null,
      weightKg: json['weightKg'] != null ? int.tryParse(json['weightKg'].toString()) : null,
      currentLat: json['currentLat'] != null ? double.tryParse(json['currentLat'].toString()) : null,
      currentLng: json['currentLng'] != null ? double.tryParse(json['currentLng'].toString()) : null,
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      address: json['address']?.toString(),
      languages: _parseStringList(json['languages']),
      interests: _parseStringList(json['interests']),
      talents: _parseStringList(json['talents']),
      photos: _parseStringList(json['photos']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'bio': bio,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'city': city,
      'district': district,
      'address': address,
      'languages': languages,
      'interests': interests,
      'talents': talents,
      'photos': photos,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Get display name or full name
  String get name => displayName ?? fullName ?? '';

  /// Get avatar URL or empty string
  String get avatar => avatarUrl ?? '';

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? displayName,
    String? avatarUrl,
    String? coverPhotoUrl,
    String? bio,
    String? gender,
    DateTime? dateOfBirth,
    int? heightCm,
    int? weightKg,
    double? currentLat,
    double? currentLng,
    String? city,
    String? district,
    String? address,
    List<String>? languages,
    List<String>? interests,
    List<String>? talents,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      city: city ?? this.city,
      district: district ?? this.district,
      address: address ?? this.address,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      talents: talents ?? this.talents,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        displayName,
        avatarUrl,
        coverPhotoUrl,
        bio,
        gender,
        dateOfBirth,
        heightCm,
        weightKg,
        currentLat,
        currentLng,
        city,
        district,
        address,
        languages,
        interests,
        talents,
        photos,
        createdAt,
        updatedAt,
      ];
}
