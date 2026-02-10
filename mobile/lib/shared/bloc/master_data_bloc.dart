import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/master_data_repository.dart';
import 'master_data_event.dart';
import 'master_data_state.dart';

// Re-export events and states for backward compatibility
export 'master_data_event.dart';
export 'master_data_state.dart';

/// Master Data BLoC - Manages master data loading
class MasterDataBloc extends Bloc<MasterDataEvent, MasterDataState> {
  final MasterDataRepository _repository;

  MasterDataBloc({required MasterDataRepository repository})
      : _repository = repository,
        super(const MasterDataInitial()) {
    on<MasterDataLoadRequested>(_onLoadRequested);
    on<PartnerMasterDataLoadRequested>(_onPartnerLoadRequested);
    on<DistrictsLoadRequested>(_onDistrictsLoadRequested);
  }

  Future<void> _onLoadRequested(
    MasterDataLoadRequested event,
    Emitter<MasterDataState> emit,
  ) async {
    emit(const MasterDataLoading());

    try {
      final masterData = await _repository.getProfileMasterData();

      emit(MasterDataLoaded(
        provinces: masterData.provinces,
        interests: masterData.interests,
        talents: masterData.talents,
        languages: masterData.languages,
      ));
    } catch (e) {
      emit(MasterDataError('Không thể tải dữ liệu: ${e.toString()}'));
    }
  }

  Future<void> _onPartnerLoadRequested(
    PartnerMasterDataLoadRequested event,
    Emitter<MasterDataState> emit,
  ) async {
    emit(const MasterDataLoading());

    try {
      final masterData = await _repository.getPartnerMasterData();

      emit(PartnerMasterDataLoaded(
        provinces: masterData.provinces,
        serviceTypes: masterData.serviceTypes,
      ));
    } catch (e) {
      emit(MasterDataError('Không thể tải dữ liệu: ${e.toString()}'));
    }
  }

  Future<void> _onDistrictsLoadRequested(
    DistrictsLoadRequested event,
    Emitter<MasterDataState> emit,
  ) async {
    final currentState = state;

    if (currentState is MasterDataLoaded) {
      try {
        final districts =
            await _repository.getDistrictsByProvince(event.provinceId);

        emit(currentState.copyWith(
          districts: districts,
          selectedProvinceId: event.provinceId,
        ));
      } catch (e) {
        debugPrint('Error loading districts: $e');
      }
    } else if (currentState is PartnerMasterDataLoaded) {
      try {
        final districts =
            await _repository.getDistrictsByProvince(event.provinceId);

        emit(currentState.copyWith(
          districts: districts,
          selectedProvinceId: event.provinceId,
        ));
      } catch (e) {
        debugPrint('Error loading districts: $e');
      }
    }
  }
}
