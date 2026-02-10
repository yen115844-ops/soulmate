import 'package:equatable/equatable.dart';

/// Profile Entity - Domain entity for user profile
class ProfileEntity extends Equatable {
  final String? id;
  final String? name;
  final String? displayName;
  final String? bio;
  final Gender? gender;
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
    int calculatedAge = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  /// Check if profile is complete (has essential info)
  bool get isComplete {
    return name != null &&
        name!.isNotEmpty &&
        dateOfBirth != null &&
        gender != null;
  }

  /// Get display location
  String? get location {
    if (city == null && district == null) return null;
    if (district != null && city != null) return '$district, $city';
    return city ?? district;
  }

  ProfileEntity copyWith({
    String? id,
    String? name,
    String? displayName,
    String? bio,
    Gender? gender,
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

/// Gender enum
enum Gender {
  male,
  female,
  other;

  static Gender? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'MALE':
        return Gender.male;
      case 'FEMALE':
        return Gender.female;
      case 'OTHER':
        return Gender.other;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
    }
  }

  String get apiValue {
    switch (this) {
      case Gender.male:
        return 'MALE';
      case Gender.female:
        return 'FEMALE';
      case Gender.other:
        return 'OTHER';
    }
  }
}

/// Profile Stats Entity
class ProfileStatsEntity extends Equatable {
  final int totalBookings;
  final int completedBookings;
  final int totalReviews;
  final double averageRating;
  final int totalSpent;
  final int favoritePartnersCount;

  const ProfileStatsEntity({
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    this.totalSpent = 0,
    this.favoritePartnersCount = 0,
  });

  @override
  List<Object?> get props => [
        totalBookings,
        completedBookings,
        totalReviews,
        averageRating,
        totalSpent,
        favoritePartnersCount,
      ];
}
