import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/kyc_repository.dart';
import '../../data/models/kyc_model.dart';
import 'kyc_event.dart';
import 'kyc_state.dart';

class KycBloc extends Bloc<KycEvent, KycState> {
  final KycRepository _repository;

  KycBloc(this._repository) : super(const KycState()) {
    on<KycStatusLoadRequested>(_onStatusLoadRequested);
    on<KycFrontImageSelected>(_onFrontImageSelected);
    on<KycBackImageSelected>(_onBackImageSelected);
    on<KycSelfieSelected>(_onSelfieSelected);
    on<KycSubmitRequested>(_onSubmitRequested);
    on<KycStepChanged>(_onStepChanged);
  }

  Future<void> _onStatusLoadRequested(
    KycStatusLoadRequested event,
    Emitter<KycState> emit,
  ) async {
    emit(state.copyWith(status: KycPageStatus.loading));

    try {
      final kycStatus = await _repository.getKycStatus();
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        kycStatus: kycStatus,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        kycStatus: const KycStatusModel(status: KycStatus.none),
      ));
    }
  }

  Future<void> _onFrontImageSelected(
    KycFrontImageSelected event,
    Emitter<KycState> emit,
  ) async {
    emit(state.copyWith(
      frontImage: event.image,
      status: KycPageStatus.uploading,
    ));

    try {
      final url = await _repository.uploadKycImage(event.image, 'front');
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        frontImageUrl: url,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onBackImageSelected(
    KycBackImageSelected event,
    Emitter<KycState> emit,
  ) async {
    emit(state.copyWith(
      backImage: event.image,
      status: KycPageStatus.uploading,
    ));

    try {
      final url = await _repository.uploadKycImage(event.image, 'back');
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        backImageUrl: url,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onSelfieSelected(
    KycSelfieSelected event,
    Emitter<KycState> emit,
  ) async {
    emit(state.copyWith(
      selfieImage: event.image,
      status: KycPageStatus.uploading,
    ));

    try {
      final url = await _repository.uploadKycImage(event.image, 'selfie');
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        selfieImageUrl: url,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: KycPageStatus.loaded,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onSubmitRequested(
    KycSubmitRequested event,
    Emitter<KycState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        errorMessage: 'Vui lòng tải lên đầy đủ các ảnh',
      ));
      return;
    }

    emit(state.copyWith(status: KycPageStatus.submitting));

    try {
      await _repository.submitKyc(KycSubmitRequest(
        idCardFrontUrl: state.frontImageUrl!,
        idCardBackUrl: state.backImageUrl!,
        selfieUrl: state.selfieImageUrl!,
      ));

      emit(state.copyWith(
        status: KycPageStatus.success,
        successMessage: 'Đã gửi yêu cầu xác minh thành công. Vui lòng chờ phê duyệt.',
        kycStatus: const KycStatusModel(status: KycStatus.pending),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: KycPageStatus.error,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  void _onStepChanged(
    KycStepChanged event,
    Emitter<KycState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step));
  }
}
