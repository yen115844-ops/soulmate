import 'package:equatable/equatable.dart';

import '../../data/partner_repository.dart';

/// States for ScheduleSettingsBloc
abstract class ScheduleSettingsState extends Equatable {
  const ScheduleSettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ScheduleSettingsInitial extends ScheduleSettingsState {
  const ScheduleSettingsInitial();
}

/// Loading state
class ScheduleSettingsLoading extends ScheduleSettingsState {
  const ScheduleSettingsLoading();
}

/// Loaded state with slots
class ScheduleSettingsLoaded extends ScheduleSettingsState {
  final List<AvailabilitySlot> slots;
  final bool hasChanges;

  const ScheduleSettingsLoaded({
    required this.slots,
    this.hasChanges = false,
  });

  /// Get slots for specific date
  List<AvailabilitySlot> getSlotsForDate(DateTime date) {
    return slots
        .where((slot) =>
            slot.date.year == date.year &&
            slot.date.month == date.month &&
            slot.date.day == date.day)
        .toList();
  }

  /// Copy with new values
  ScheduleSettingsLoaded copyWith({
    List<AvailabilitySlot>? slots,
    bool? hasChanges,
  }) {
    return ScheduleSettingsLoaded(
      slots: slots ?? this.slots,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }

  @override
  List<Object?> get props => [slots, hasChanges];
}

/// Saving state
class ScheduleSettingsSaving extends ScheduleSettingsState {
  final List<AvailabilitySlot> slots;

  const ScheduleSettingsSaving({required this.slots});

  @override
  List<Object?> get props => [slots];
}

/// Slot operation in progress
class ScheduleSettingsSlotOperationInProgress extends ScheduleSettingsState {
  final List<AvailabilitySlot> slots;
  final String operationType; // create, update, delete

  const ScheduleSettingsSlotOperationInProgress({
    required this.slots,
    required this.operationType,
  });

  @override
  List<Object?> get props => [slots, operationType];
}

/// Slot operation success
class ScheduleSettingsSlotOperationSuccess extends ScheduleSettingsState {
  final List<AvailabilitySlot> slots;
  final String message;

  const ScheduleSettingsSlotOperationSuccess({
    required this.slots,
    required this.message,
  });

  @override
  List<Object?> get props => [slots, message];
}

/// Error state
class ScheduleSettingsError extends ScheduleSettingsState {
  final String message;
  final List<AvailabilitySlot>? previousSlots;

  const ScheduleSettingsError({
    required this.message,
    this.previousSlots,
  });

  @override
  List<Object?> get props => [message, previousSlots];
}
