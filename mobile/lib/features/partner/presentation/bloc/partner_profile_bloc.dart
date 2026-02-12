import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/partner_repository.dart';
import 'partner_profile_event.dart';
import 'partner_profile_state.dart';

class PartnerProfileBloc extends Bloc<PartnerProfileEvent, PartnerProfileState> {
  final PartnerRepository _partnerRepository;

  PartnerProfileBloc({required PartnerRepository partnerRepository})
      : _partnerRepository = partnerRepository,
        super(const PartnerProfileInitial()) {
    on<PartnerProfileLoadRequested>(_onLoadRequested);
    on<PartnerProfileRefreshRequested>(_onRefreshRequested);
    on<PartnerProfileUpdateRequested>(_onUpdateRequested);
    on<PartnerAvailabilityToggleRequested>(_onAvailabilityToggleRequested);
  }

  Future<void> _onLoadRequested(
    PartnerProfileLoadRequested event,
    Emitter<PartnerProfileState> emit,
  ) async {
    emit(const PartnerProfileLoading());

    try {
      final result = await _partnerRepository.getMyPartnerProfileFull();
      emit(PartnerProfileLoaded(
        profile: result.profile,
        userProfile: result.userProfile,
      ));
    } catch (e) {
      debugPrint('Partner profile load error: $e');
      emit(PartnerProfileError(message: getErrorMessage(e)));
    }
  }

  Future<void> _onRefreshRequested(
    PartnerProfileRefreshRequested event,
    Emitter<PartnerProfileState> emit,
  ) async {
    try {
      final result = await _partnerRepository.getMyPartnerProfileFull();
      emit(PartnerProfileLoaded(
        profile: result.profile,
        userProfile: result.userProfile,
      ));
    } catch (e) {
      debugPrint('Partner profile refresh error: $e');
      if (state is PartnerProfileLoaded) {
        return; // Keep current state on refresh error
      }
      emit(PartnerProfileError(message: getErrorMessage(e)));
    }
  }

  Future<void> _onUpdateRequested(
    PartnerProfileUpdateRequested event,
    Emitter<PartnerProfileState> emit,
  ) async {
    if (state is! PartnerProfileLoaded) return;

    final currentState = state as PartnerProfileLoaded;
    emit(PartnerProfileUpdating(
      profile: currentState.profile,
      userProfile: currentState.userProfile,
    ));

    try {
      final updatedProfile = await _partnerRepository.updatePartnerProfile(
        serviceTypes: event.serviceTypes,
        hourlyRate: event.hourlyRate,
        introduction: event.introduction,
        minimumHours: event.minimumHours,
        isAvailable: event.isAvailable,
      );

      emit(PartnerProfileLoaded(
        profile: updatedProfile,
        userProfile: currentState.userProfile,
      ));
    } catch (e) {
      debugPrint('Partner profile update error: $e');
      emit(PartnerProfileLoaded(
        profile: currentState.profile,
        userProfile: currentState.userProfile,
      ));
    }
  }

  Future<void> _onAvailabilityToggleRequested(
    PartnerAvailabilityToggleRequested event,
    Emitter<PartnerProfileState> emit,
  ) async {
    if (state is! PartnerProfileLoaded) return;

    final currentState = state as PartnerProfileLoaded;
    emit(PartnerProfileUpdating(
      profile: currentState.profile,
      userProfile: currentState.userProfile,
    ));

    try {
      final updatedProfile = await _partnerRepository.toggleAvailability(
        event.isAvailable,
      );

      emit(PartnerProfileLoaded(
        profile: updatedProfile,
        userProfile: currentState.userProfile,
      ));
    } catch (e) {
      debugPrint('Toggle availability error: $e');
      emit(PartnerProfileLoaded(
        profile: currentState.profile,
        userProfile: currentState.userProfile,
      ));
    }
  }
}
