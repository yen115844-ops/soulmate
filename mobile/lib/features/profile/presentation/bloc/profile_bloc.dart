import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// Profile BLoC handles profile-related business logic
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileRefreshRequested>(_onRefreshRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfileLocationUpdateRequested>(_onLocationUpdateRequested);
    on<ProfileAvatarUpdateRequested>(_onAvatarUpdateRequested);
    on<ProfilePhotosUploadRequested>(_onPhotosUploadRequested);
    on<ProfilePhotoDeleteRequested>(_onPhotoDeleteRequested);
    on<ProfileResetRequested>(_onResetRequested);
  }

  /// Load profile data
  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _profileRepository.getProfileStats(),
      ]);

      final user = results[0] as UserModel;
      final stats = results[1] as ProfileStats;

      emit(ProfileLoaded(user: user, stats: stats));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
    } catch (e) {
      debugPrint('Profile load error: $e');
      emit(ProfileError(message: 'Không thể tải thông tin. Vui lòng thử lại.'));
    }
  }

  /// Refresh profile data
  Future<void> _onRefreshRequested(
    ProfileRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _profileRepository.getProfileStats(),
      ]);

      final user = results[0] as UserModel;
      final stats = results[1] as ProfileStats;

      emit(ProfileLoaded(user: user, stats: stats));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
    } catch (e) {
      debugPrint('Profile refresh error: $e');
      emit(ProfileError(message: 'Không thể làm mới thông tin.'));
    }
  }

  /// Update profile
  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    emit(const ProfileUpdating());

    try {
      final user = await _profileRepository.updateProfile(
        fullName: event.fullName,
        displayName: event.displayName,
        bio: event.bio,
        gender: event.gender,
        dateOfBirth: event.dateOfBirth,
        heightCm: event.heightCm,
        weightKg: event.weightKg,
        city: event.city,
        district: event.district,
        address: event.address,
        languages: event.languages,
        interests: event.interests,
        talents: event.talents,
      );

      emit(ProfileUpdateSuccess(user: user));

      // Reload full profile with stats
      final stats = await _profileRepository.getProfileStats();
      emit(ProfileLoaded(user: user, stats: stats));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
      // Restore previous state
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    } catch (e) {
      debugPrint('Profile update error: $e');
      emit(ProfileError(message: 'Cập nhật thất bại. Vui lòng thử lại.'));
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }

  /// Update avatar
  Future<void> _onAvatarUpdateRequested(
    ProfileAvatarUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    emit(const ProfileUpdating());

    try {
      await _profileRepository.uploadAvatar(event.imagePath);
      
      // Reload profile to get updated avatar URL
      final user = await _profileRepository.getProfile();
      final stats = currentState is ProfileLoaded 
          ? currentState.stats 
          : await _profileRepository.getProfileStats();

      emit(ProfileAvatarUpdateSuccess(avatarUrl: user.profile?.avatarUrl ?? ''));
      emit(ProfileLoaded(user: user, stats: stats));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      emit(ProfileError(message: 'Không thể tải lên ảnh đại diện.'));
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }

  /// Upload photos
  Future<void> _onPhotosUploadRequested(
    ProfilePhotosUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    emit(const ProfileUpdating());

    try {
      await _profileRepository.uploadPhotos(event.imagePaths);
      
      // Reload profile to get updated photos
      final user = await _profileRepository.getProfile();
      final stats = currentState is ProfileLoaded 
          ? currentState.stats 
          : await _profileRepository.getProfileStats();

      emit(ProfilePhotosUpdateSuccess());
      emit(ProfileLoaded(user: user, stats: stats));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    } catch (e) {
      debugPrint('Photos upload error: $e');
      emit(ProfileError(message: 'Không thể tải lên ảnh.'));
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }

  /// Delete photo
  Future<void> _onPhotoDeleteRequested(
    ProfilePhotoDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;

    try {
      await _profileRepository.deletePhoto(event.photoUrl);
      
      // Reload profile to get updated photos
      final user = await _profileRepository.getProfile();
      final stats = currentState is ProfileLoaded 
          ? currentState.stats 
          : await _profileRepository.getProfileStats();

      emit(ProfileLoaded(user: user, stats: stats));
    } on ApiException catch (e) {
      emit(ProfileError(message: e.message));
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    } catch (e) {
      debugPrint('Photo delete error: $e');
      if (currentState is ProfileLoaded) {
        emit(currentState);
      }
    }
  }

  /// Update location
  Future<void> _onLocationUpdateRequested(
    ProfileLocationUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _profileRepository.updateLocation(
        latitude: event.latitude,
        longitude: event.longitude,
        city: event.city,
        district: event.district,
      );
    } catch (e) {
      debugPrint('Location update error: $e');
      // Silent fail - don't show error for location updates
    }
  }

  /// Reset profile state (used when user logs out)
  void _onResetRequested(
    ProfileResetRequested event,
    Emitter<ProfileState> emit,
  ) {
    emit(const ProfileInitial());
  }
}
