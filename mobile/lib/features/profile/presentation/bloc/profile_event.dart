import 'package:equatable/equatable.dart';

/// Profile Events for ProfileBloc
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load profile data
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

/// Event to refresh profile data
class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}

/// Event to update profile
class ProfileUpdateRequested extends ProfileEvent {
  final String? fullName;
  final String? displayName;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final int? heightCm;
  final int? weightKg;
  final String? provinceId;
  final String? districtId;
  final String? city;
  final String? district;
  final String? address;
  final List<String>? languages;
  final List<String>? interests;
  final List<String>? talents;

  const ProfileUpdateRequested({
    this.fullName,
    this.displayName,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.provinceId,
    this.districtId,
    this.city,
    this.district,
    this.address,
    this.languages,
    this.interests,
    this.talents,
  });

  @override
  List<Object?> get props => [
        fullName,
        displayName,
        bio,
        gender,
        dateOfBirth,
        heightCm,
        weightKg,
        provinceId,
        districtId,
        city,
        district,
        address,
        languages,
        interests,
        talents,
      ];
}

/// Event to update avatar
class ProfileAvatarUpdateRequested extends ProfileEvent {
  final String imagePath;

  const ProfileAvatarUpdateRequested({required this.imagePath});

  @override
  List<Object?> get props => [imagePath];
}

/// Event to upload photos
class ProfilePhotosUploadRequested extends ProfileEvent {
  final List<String> imagePaths;

  const ProfilePhotosUploadRequested({required this.imagePaths});

  @override
  List<Object?> get props => [imagePaths];
}

/// Event to delete photo
class ProfilePhotoDeleteRequested extends ProfileEvent {
  final String photoUrl;

  const ProfilePhotoDeleteRequested({required this.photoUrl});

  @override
  List<Object?> get props => [photoUrl];
}

/// Event to update location
class ProfileLocationUpdateRequested extends ProfileEvent {
  final double latitude;
  final double longitude;
  final String? provinceId;
  final String? districtId;
  final String? city;
  final String? district;

  const ProfileLocationUpdateRequested({
    required this.latitude,
    required this.longitude,
    this.provinceId,
    this.districtId,
    this.city,
    this.district,
  });

  @override
  List<Object?> get props => [latitude, longitude, provinceId, districtId, city, district];
}

/// Event to reset profile state (used when user logs out)
class ProfileResetRequested extends ProfileEvent {
  const ProfileResetRequested();
}
