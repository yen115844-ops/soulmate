import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/partner_repository.dart';
import 'schedule_settings_event.dart';
import 'schedule_settings_state.dart';

class ScheduleSettingsBloc
    extends Bloc<ScheduleSettingsEvent, ScheduleSettingsState> {
  final PartnerRepository _partnerRepository;

  ScheduleSettingsBloc({required PartnerRepository partnerRepository})
      : _partnerRepository = partnerRepository,
        super(const ScheduleSettingsInitial()) {
    on<ScheduleSettingsLoadRequested>(_onLoadRequested);
    on<ScheduleSettingsGetSlotsRequested>(_onGetSlotsRequested);
    on<ScheduleSettingsCreateSlotRequested>(_onCreateSlotRequested);
    on<ScheduleSettingsUpdateSlotRequested>(_onUpdateSlotRequested);
    on<ScheduleSettingsDeleteSlotRequested>(_onDeleteSlotRequested);
  }

  Future<void> _onLoadRequested(
    ScheduleSettingsLoadRequested event,
    Emitter<ScheduleSettingsState> emit,
  ) async {
    emit(const ScheduleSettingsLoading());

    try {
      // Load slots for current month
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final response = await _partnerRepository.getAvailabilitySlots(
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
      );

      emit(ScheduleSettingsLoaded(slots: response.slots));
    } catch (e) {
      debugPrint('Schedule settings load error: $e');
      emit(ScheduleSettingsError(message: 'Không thể tải lịch. $e'));
    }
  }

  Future<void> _onGetSlotsRequested(
    ScheduleSettingsGetSlotsRequested event,
    Emitter<ScheduleSettingsState> emit,
  ) async {
    if (state is! ScheduleSettingsLoaded) {
      emit(const ScheduleSettingsLoading());
    }

    try {
      final response = await _partnerRepository.getAvailabilitySlots(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(ScheduleSettingsLoaded(slots: response.slots));
    } catch (e) {
      debugPrint('Get slots error: $e');
      if (state is ScheduleSettingsLoaded) {
        final currentState = state as ScheduleSettingsLoaded;
        emit(ScheduleSettingsError(
          message: 'Không thể tải lịch. $e',
          previousSlots: currentState.slots,
        ));
      } else {
        emit(ScheduleSettingsError(message: 'Không thể tải lịch. $e'));
      }
    }
  }

  Future<void> _onCreateSlotRequested(
    ScheduleSettingsCreateSlotRequested event,
    Emitter<ScheduleSettingsState> emit,
  ) async {
    if (state is! ScheduleSettingsLoaded) return;

    final currentState = state as ScheduleSettingsLoaded;
    emit(ScheduleSettingsSlotOperationInProgress(
      slots: currentState.slots,
      operationType: 'create',
    ));

    try {
      final newSlot = await _partnerRepository.createAvailabilitySlot(
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        note: event.note,
      );

      final updatedSlots = [...currentState.slots, newSlot];
      emit(ScheduleSettingsSlotOperationSuccess(
        slots: updatedSlots,
        message: 'Thêm lịch thành công',
      ));
    } catch (e) {
      debugPrint('Create slot error: $e');
      emit(ScheduleSettingsError(
        message: 'Không thể thêm lịch. $e',
        previousSlots: currentState.slots,
      ));
    }
  }

  Future<void> _onUpdateSlotRequested(
    ScheduleSettingsUpdateSlotRequested event,
    Emitter<ScheduleSettingsState> emit,
  ) async {
    if (state is! ScheduleSettingsLoaded) return;

    final currentState = state as ScheduleSettingsLoaded;
    emit(ScheduleSettingsSlotOperationInProgress(
      slots: currentState.slots,
      operationType: 'update',
    ));

    try {
      final updatedSlot = await _partnerRepository.updateAvailabilitySlot(
        slotId: event.slotId,
        startTime: event.startTime,
        endTime: event.endTime,
        note: event.note,
      );

      final updatedSlots = currentState.slots.map((slot) {
        if (slot.id == event.slotId) {
          return updatedSlot;
        }
        return slot;
      }).toList();

      emit(ScheduleSettingsSlotOperationSuccess(
        slots: updatedSlots,
        message: 'Cập nhật lịch thành công',
      ));
    } catch (e) {
      debugPrint('Update slot error: $e');
      emit(ScheduleSettingsError(
        message: 'Không thể cập nhật lịch. $e',
        previousSlots: currentState.slots,
      ));
    }
  }

  Future<void> _onDeleteSlotRequested(
    ScheduleSettingsDeleteSlotRequested event,
    Emitter<ScheduleSettingsState> emit,
  ) async {
    if (state is! ScheduleSettingsLoaded) return;

    final currentState = state as ScheduleSettingsLoaded;
    emit(ScheduleSettingsSlotOperationInProgress(
      slots: currentState.slots,
      operationType: 'delete',
    ));

    try {
      await _partnerRepository.deleteAvailabilitySlot(event.slotId);

      final updatedSlots =
          currentState.slots.where((slot) => slot.id != event.slotId).toList();

      emit(ScheduleSettingsSlotOperationSuccess(
        slots: updatedSlots,
        message: 'Xóa lịch thành công',
      ));
    } catch (e) {
      debugPrint('Delete slot error: $e');
      emit(ScheduleSettingsError(
        message: 'Không thể xóa lịch. $e',
        previousSlots: currentState.slots,
      ));
    }
  }
}
