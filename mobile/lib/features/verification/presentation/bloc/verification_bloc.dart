import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/verification_repository.dart';
import 'verification_event.dart';
import 'verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _repository;

  VerificationBloc({required VerificationRepository repository})
      : _repository = repository,
        super(const VerificationState()) {
    on<VerificationStatusRequested>(_onStatusRequested);
    on<VerificationSelfieSubmitted>(_onSelfieSubmitted);
    on<VerificationReset>(_onReset);
  }

  Future<void> _onStatusRequested(
    VerificationStatusRequested event,
    Emitter<VerificationState> emit,
  ) async {
    emit(state.copyWith(status: VerificationStateStatus.loading));

    try {
      final verification = await _repository.getStatus();
      emit(state.copyWith(
        status: VerificationStateStatus.success,
        verification: verification,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VerificationStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSelfieSubmitted(
    VerificationSelfieSubmitted event,
    Emitter<VerificationState> emit,
  ) async {
    emit(state.copyWith(status: VerificationStateStatus.submitting));

    try {
      final verification = await _repository.submitSelfie(
        event.selfieFile,
        deviceInfo: event.deviceInfo,
      );
      emit(state.copyWith(
        status: VerificationStateStatus.submitted,
        verification: verification,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VerificationStateStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onReset(
    VerificationReset event,
    Emitter<VerificationState> emit,
  ) {
    emit(const VerificationState());
  }
}
