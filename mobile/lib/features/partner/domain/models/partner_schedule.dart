import 'package:flutter/material.dart';

/// Days of the week
enum DayOfWeek {
  monday(1, 'Thứ 2', 'T2'),
  tuesday(2, 'Thứ 3', 'T3'),
  wednesday(3, 'Thứ 4', 'T4'),
  thursday(4, 'Thứ 5', 'T5'),
  friday(5, 'Thứ 6', 'T6'),
  saturday(6, 'Thứ 7', 'T7'),
  sunday(7, 'Chủ nhật', 'CN');

  const DayOfWeek(this.value, this.displayName, this.shortName);
  
  final int value;
  final String displayName;
  final String shortName;

  /// Get DayOfWeek from DateTime weekday
  static DayOfWeek fromDateTime(DateTime date) {
    return DayOfWeek.values.firstWhere((d) => d.value == date.weekday);
  }
}

/// Time slot for a specific time range
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  /// Check if time slot is valid (end > start)
  bool get isValid {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes > startMinutes;
  }

  /// Get duration in minutes
  int get durationInMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  /// Format time slot as string
  String get displayString {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  /// Check if a time is within this slot
  bool containsTime(TimeOfDay time) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return timeMinutes >= startMinutes && timeMinutes < endMinutes;
  }

  /// Check if this slot overlaps with another
  bool overlaps(TimeSlot other) {
    final thisStart = startTime.hour * 60 + startTime.minute;
    final thisEnd = endTime.hour * 60 + endTime.minute;
    final otherStart = other.startTime.hour * 60 + other.startTime.minute;
    final otherEnd = other.endTime.hour * 60 + other.endTime.minute;
    
    return thisStart < otherEnd && thisEnd > otherStart;
  }

  Map<String, dynamic> toJson() => {
    'startHour': startTime.hour,
    'startMinute': startTime.minute,
    'endHour': endTime.hour,
    'endMinute': endTime.minute,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    startTime: TimeOfDay(
      hour: json['startHour'] as int,
      minute: json['startMinute'] as int,
    ),
    endTime: TimeOfDay(
      hour: json['endHour'] as int,
      minute: json['endMinute'] as int,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

/// Daily schedule with available time slots
class DailySchedule {
  final DayOfWeek dayOfWeek;
  final bool isEnabled;
  final List<TimeSlot> timeSlots;

  const DailySchedule({
    required this.dayOfWeek,
    this.isEnabled = true,
    this.timeSlots = const [],
  });

  DailySchedule copyWith({
    DayOfWeek? dayOfWeek,
    bool? isEnabled,
    List<TimeSlot>? timeSlots,
  }) {
    return DailySchedule(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      timeSlots: timeSlots ?? this.timeSlots,
    );
  }

  /// Check if a time is available on this day
  bool isTimeAvailable(TimeOfDay time) {
    if (!isEnabled) return false;
    return timeSlots.any((slot) => slot.containsTime(time));
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek.value,
    'isEnabled': isEnabled,
    'timeSlots': timeSlots.map((s) => s.toJson()).toList(),
  };

  factory DailySchedule.fromJson(Map<String, dynamic> json) => DailySchedule(
    dayOfWeek: DayOfWeek.values.firstWhere((d) => d.value == json['dayOfWeek']),
    isEnabled: json['isEnabled'] as bool? ?? true,
    timeSlots: (json['timeSlots'] as List<dynamic>?)
        ?.map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
        .toList() ?? [],
  );
}

/// Weekly schedule containing all days
class WeeklySchedule {
  final Map<DayOfWeek, DailySchedule> schedule;

  const WeeklySchedule({required this.schedule});

  /// Create default weekly schedule (Mon-Fri, 8:00-18:00)
  factory WeeklySchedule.defaultSchedule() {
    final defaultSlot = TimeSlot(
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 0),
    );

    return WeeklySchedule(
      schedule: {
        for (final day in DayOfWeek.values)
          day: DailySchedule(
            dayOfWeek: day,
            isEnabled: day != DayOfWeek.sunday,
            timeSlots: day != DayOfWeek.sunday ? [defaultSlot] : [],
          ),
      },
    );
  }

  /// Create empty schedule (all days disabled)
  factory WeeklySchedule.empty() {
    return WeeklySchedule(
      schedule: {
        for (final day in DayOfWeek.values)
          day: DailySchedule(
            dayOfWeek: day,
            isEnabled: false,
            timeSlots: [],
          ),
      },
    );
  }

  /// Get schedule for a specific day
  DailySchedule? getScheduleForDay(DayOfWeek day) => schedule[day];

  /// Check if a specific date and time is available
  bool isDateTimeAvailable(DateTime dateTime) {
    final day = DayOfWeek.fromDateTime(dateTime);
    final daySchedule = schedule[day];
    if (daySchedule == null || !daySchedule.isEnabled) return false;
    
    final time = TimeOfDay.fromDateTime(dateTime);
    return daySchedule.isTimeAvailable(time);
  }

  /// Get available time slots for a specific date
  List<TimeSlot> getAvailableSlotsForDate(DateTime date) {
    final day = DayOfWeek.fromDateTime(date);
    final daySchedule = schedule[day];
    if (daySchedule == null || !daySchedule.isEnabled) return [];
    return daySchedule.timeSlots;
  }

  /// Get list of enabled days
  List<DayOfWeek> get enabledDays {
    return schedule.entries
        .where((e) => e.value.isEnabled)
        .map((e) => e.key)
        .toList();
  }

  WeeklySchedule copyWith({
    Map<DayOfWeek, DailySchedule>? schedule,
  }) {
    return WeeklySchedule(
      schedule: schedule ?? Map.from(this.schedule),
    );
  }

  /// Update schedule for a specific day
  WeeklySchedule updateDay(DayOfWeek day, DailySchedule dailySchedule) {
    final newSchedule = Map<DayOfWeek, DailySchedule>.from(schedule);
    newSchedule[day] = dailySchedule;
    return WeeklySchedule(schedule: newSchedule);
  }

  Map<String, dynamic> toJson() => {
    'schedule': schedule.map(
      (key, value) => MapEntry(key.value.toString(), value.toJson()),
    ),
  };

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final scheduleMap = json['schedule'] as Map<String, dynamic>;
    return WeeklySchedule(
      schedule: {
        for (final day in DayOfWeek.values)
          day: scheduleMap.containsKey(day.value.toString())
              ? DailySchedule.fromJson(
                  scheduleMap[day.value.toString()] as Map<String, dynamic>,
                )
              : DailySchedule(dayOfWeek: day, isEnabled: false),
      },
    );
  }
}

/// Special date override (for holidays, special events, etc.)
class ScheduleOverride {
  final DateTime date;
  final bool isAvailable;
  final List<TimeSlot>? customSlots;
  final String? reason;

  const ScheduleOverride({
    required this.date,
    required this.isAvailable,
    this.customSlots,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'isAvailable': isAvailable,
    'customSlots': customSlots?.map((s) => s.toJson()).toList(),
    'reason': reason,
  };

  factory ScheduleOverride.fromJson(Map<String, dynamic> json) => ScheduleOverride(
    date: DateTime.parse(json['date'] as String),
    isAvailable: json['isAvailable'] as bool,
    customSlots: (json['customSlots'] as List<dynamic>?)
        ?.map((s) => TimeSlot.fromJson(s as Map<String, dynamic>))
        .toList(),
    reason: json['reason'] as String?,
  );
}

/// Complete partner schedule including weekly schedule and overrides
class PartnerSchedule {
  final String partnerId;
  final WeeklySchedule weeklySchedule;
  final List<ScheduleOverride> overrides;
  final int minBookingHours; // Minimum hours before booking
  final int maxBookingDays; // Maximum days in advance for booking

  const PartnerSchedule({
    required this.partnerId,
    required this.weeklySchedule,
    this.overrides = const [],
    this.minBookingHours = 2,
    this.maxBookingDays = 30,
  });

  /// Check if a specific date and time is available (considering overrides)
  bool isDateTimeAvailable(DateTime dateTime) {
    // Check if within booking window
    final now = DateTime.now();
    final minTime = now.add(Duration(hours: minBookingHours));
    final maxTime = now.add(Duration(days: maxBookingDays));
    
    if (dateTime.isBefore(minTime) || dateTime.isAfter(maxTime)) {
      return false;
    }

    // Check overrides first
    final override = _getOverrideForDate(dateTime);
    if (override != null) {
      if (!override.isAvailable) return false;
      if (override.customSlots != null) {
        final time = TimeOfDay.fromDateTime(dateTime);
        return override.customSlots!.any((slot) => slot.containsTime(time));
      }
    }

    // Fall back to weekly schedule
    return weeklySchedule.isDateTimeAvailable(dateTime);
  }

  /// Get available time slots for a specific date
  List<TimeSlot> getAvailableSlotsForDate(DateTime date) {
    // Check overrides first
    final override = _getOverrideForDate(date);
    if (override != null) {
      if (!override.isAvailable) return [];
      if (override.customSlots != null) return override.customSlots!;
    }

    // Fall back to weekly schedule
    return weeklySchedule.getAvailableSlotsForDate(date);
  }

  /// Get override for a specific date
  ScheduleOverride? _getOverrideForDate(DateTime date) {
    try {
      return overrides.firstWhere(
        (o) =>
            o.date.year == date.year &&
            o.date.month == date.month &&
            o.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get available dates for the next N days
  List<DateTime> getAvailableDates({int days = 30}) {
    final availableDates = <DateTime>[];
    final now = DateTime.now();
    final startDate = now.add(Duration(hours: minBookingHours));
    
    for (int i = 0; i < days; i++) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day + i,
      );
      
      final slots = getAvailableSlotsForDate(date);
      if (slots.isNotEmpty) {
        availableDates.add(date);
      }
    }
    
    return availableDates;
  }

  PartnerSchedule copyWith({
    String? partnerId,
    WeeklySchedule? weeklySchedule,
    List<ScheduleOverride>? overrides,
    int? minBookingHours,
    int? maxBookingDays,
  }) {
    return PartnerSchedule(
      partnerId: partnerId ?? this.partnerId,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      overrides: overrides ?? this.overrides,
      minBookingHours: minBookingHours ?? this.minBookingHours,
      maxBookingDays: maxBookingDays ?? this.maxBookingDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'partnerId': partnerId,
    'weeklySchedule': weeklySchedule.toJson(),
    'overrides': overrides.map((o) => o.toJson()).toList(),
    'minBookingHours': minBookingHours,
    'maxBookingDays': maxBookingDays,
  };

  factory PartnerSchedule.fromJson(Map<String, dynamic> json) => PartnerSchedule(
    partnerId: json['partnerId'] as String,
    weeklySchedule: WeeklySchedule.fromJson(
      json['weeklySchedule'] as Map<String, dynamic>,
    ),
    overrides: (json['overrides'] as List<dynamic>?)
        ?.map((o) => ScheduleOverride.fromJson(o as Map<String, dynamic>))
        .toList() ?? [],
    minBookingHours: json['minBookingHours'] as int? ?? 2,
    maxBookingDays: json['maxBookingDays'] as int? ?? 30,
  );
}

/// Generate hourly time slots from a time range
List<TimeSlot> generateHourlySlots(TimeOfDay start, TimeOfDay end) {
  final slots = <TimeSlot>[];
  var currentHour = start.hour;
  
  while (currentHour < end.hour) {
    slots.add(TimeSlot(
      startTime: TimeOfDay(hour: currentHour, minute: 0),
      endTime: TimeOfDay(hour: currentHour + 1, minute: 0),
    ));
    currentHour++;
  }
  
  return slots;
}
