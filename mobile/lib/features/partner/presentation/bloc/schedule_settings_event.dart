import 'package:equatable/equatable.dart';

/// Events for ScheduleSettingsBloc
abstract class ScheduleSettingsEvent extends Equatable {
  const ScheduleSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load schedule preference
class ScheduleSettingsLoadRequested extends ScheduleSettingsEvent {
  const ScheduleSettingsLoadRequested();
}

/// Save schedule preference
class ScheduleSettingsSaveRequested extends ScheduleSettingsEvent {
  final String jsonData;

  const ScheduleSettingsSaveRequested({required this.jsonData});

  @override
  List<Object?> get props => [jsonData];
}

/// Create new availability slot
class ScheduleSettingsCreateSlotRequested extends ScheduleSettingsEvent {
  final String date;
  final String startTime;
  final String endTime;
  final String? note;

  const ScheduleSettingsCreateSlotRequested({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.note,
  });

  @override
  List<Object?> get props => [date, startTime, endTime, note];
}

/// Update availability slot
class ScheduleSettingsUpdateSlotRequested extends ScheduleSettingsEvent {
  final String slotId;
  final String? startTime;
  final String? endTime;
  final String? note;

  const ScheduleSettingsUpdateSlotRequested({
    required this.slotId,
    this.startTime,
    this.endTime,
    this.note,
  });

  @override
  List<Object?> get props => [slotId, startTime, endTime, note];
}

/// Delete availability slot
class ScheduleSettingsDeleteSlotRequested extends ScheduleSettingsEvent {
  final String slotId;

  const ScheduleSettingsDeleteSlotRequested({required this.slotId});

  @override
  List<Object?> get props => [slotId];
}

/// Get availability slots for date range
class ScheduleSettingsGetSlotsRequested extends ScheduleSettingsEvent {
  final String? startDate;
  final String? endDate;

  const ScheduleSettingsGetSlotsRequested({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}
