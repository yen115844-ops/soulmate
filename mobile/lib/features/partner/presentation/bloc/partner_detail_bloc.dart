import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/partner_repository.dart';
import 'partner_detail_event.dart';
import 'partner_detail_state.dart';

/// Partner Detail BLoC - Handles fetching and displaying partner detail
class PartnerDetailBloc extends Bloc<PartnerDetailEvent, PartnerDetailState> {
  final PartnerRepository _partnerRepository;

  PartnerDetailBloc({required PartnerRepository partnerRepository})
      : _partnerRepository = partnerRepository,
        super(PartnerDetailInitial()) {
    on<LoadPartnerDetail>(_onLoadPartnerDetail);
    on<RefreshPartnerDetail>(_onRefreshPartnerDetail);
  }

  Future<void> _onLoadPartnerDetail(
    LoadPartnerDetail event,
    Emitter<PartnerDetailState> emit,
  ) async {
    emit(PartnerDetailLoading());
    await _fetchPartnerDetail(event.partnerId, emit);
  }

  Future<void> _onRefreshPartnerDetail(
    RefreshPartnerDetail event,
    Emitter<PartnerDetailState> emit,
  ) async {
    await _fetchPartnerDetail(event.partnerId, emit);
  }

  Future<void> _fetchPartnerDetail(
    String partnerId,
    Emitter<PartnerDetailState> emit,
  ) async {
    try {
      final detail = await _partnerRepository.getPartnerByIdWithUser(partnerId);
      emit(PartnerDetailLoaded(detail: detail));
    } catch (e, stackTrace) {
      debugPrint('PartnerDetailBloc error: $e');
      debugPrint('Stack trace: $stackTrace');
      emit(PartnerDetailError(
        message: 'Không thể tải thông tin partner. Vui lòng thử lại.',
      ));
    }
  }
}
