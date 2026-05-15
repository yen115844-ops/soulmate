import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/partner_repository.dart';
import 'partner_detail_event.dart';
import 'partner_detail_state.dart';

/// Partner Detail BLoC - Handles fetching and displaying partner detail
class PartnerDetailBloc extends Bloc<PartnerDetailEvent, PartnerDetailState> {
  final PartnerRepository _partnerRepository;

  PartnerDetailBloc({
    required PartnerRepository partnerRepository,
    PartnerDetailResponse? initialDetail,
  })
      : _partnerRepository = partnerRepository,
        super(
          initialDetail != null
              ? PartnerDetailLoaded(detail: initialDetail)
              : PartnerDetailInitial(),
        ) {
    on<LoadPartnerDetail>(_onLoadPartnerDetail);
    on<RefreshPartnerDetail>(_onRefreshPartnerDetail);
  }

  Future<void> _onLoadPartnerDetail(
    LoadPartnerDetail event,
    Emitter<PartnerDetailState> emit,
  ) async {
    // If we already have a "quick" detail (from Home card),
    // keep showing it while fetching full detail in background.
    if (state is! PartnerDetailLoaded) {
      emit(PartnerDetailLoading());
    }
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
      // If UI is already showing an initial detail, keep it and avoid
      // replacing the screen with a blocking error widget.
      final existing = state;
      if (existing is PartnerDetailLoaded) {
        return;
      }

      emit(
        const PartnerDetailError(
          message: 'Không thể tải thông tin partner. Vui lòng thử lại.',
        ),
      );
    }
  }
}
