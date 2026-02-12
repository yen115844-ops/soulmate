import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/partner_repository.dart';
import 'partner_registration_event.dart';
import 'partner_registration_state.dart';

// Re-export events and states for backward compatibility
export 'partner_registration_event.dart';
export 'partner_registration_state.dart';

/// BLoC for partner registration
class PartnerRegistrationBloc
    extends Bloc<PartnerRegistrationEvent, PartnerRegistrationState> {
  final PartnerRepository _repository;

  PartnerRegistrationBloc({required PartnerRepository repository})
      : _repository = repository,
        super(const PartnerRegistrationInitial()) {
    on<PartnerRegistrationSubmitted>(_onSubmitted);
    on<PartnerRegistrationReset>(_onReset);
  }

  Future<void> _onSubmitted(
    PartnerRegistrationSubmitted event,
    Emitter<PartnerRegistrationState> emit,
  ) async {
    emit(const PartnerRegistrationLoading(message: 'Đang tải ảnh...'));

    try {
      final result = await _repository.registerAsPartner(
        serviceTypes: event.serviceTypes,
        hourlyRate: event.hourlyRate,
        introduction: event.introduction,
        bio: event.bio,
        bankName: event.bankName,
        bankAccountNo: event.bankAccountNo,
        bankAccountName: event.bankAccountName,
        photos: event.photos,
        minimumHours: event.minimumHours,
        experienceYears: event.experienceYears,
      );

      emit(PartnerRegistrationSuccess(result));
    } on PartnerAlreadyExistsException catch (e) {
      emit(PartnerRegistrationFailure(
        error: e.message,
        isAlreadyPartner: true,
      ));
    } catch (e) {
      debugPrint('Đăng ký thất bại: $e');
      emit(PartnerRegistrationFailure(
        error: getErrorMessage(e),
      ));
    }
  }

  void _onReset(
    PartnerRegistrationReset event,
    Emitter<PartnerRegistrationState> emit,
  ) {
    emit(const PartnerRegistrationInitial());
  }
}
