/// Availability Slot model
class AvailabilitySlot {
  final String id;
  final String partnerId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? note;
  final DateTime createdAt;

  AvailabilitySlot({
    required this.id,
    required this.partnerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'].toString())
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'].toString())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'AVAILABLE',
      note: json['note'] is String ? json['note'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  /// Get time display (HH:mm - HH:mm)
  String get timeDisplay {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  /// Check if slot is available
  bool get isAvailable => status == 'AVAILABLE';

  /// Check if slot is booked
  bool get isBooked => status == 'BOOKED';
}

/// Availability slots response
class AvailabilitySlotsResponse {
  final List<AvailabilitySlot> slots;

  AvailabilitySlotsResponse({required this.slots});

  factory AvailabilitySlotsResponse.fromJson(dynamic json) {
    if (json is List) {
      return AvailabilitySlotsResponse(
        slots: json
            .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    if (json is Map<String, dynamic> && json.containsKey('data')) {
      final data = json['data'];
      if (data is List) {
        return AvailabilitySlotsResponse(
          slots: data
              .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    }

    return AvailabilitySlotsResponse(slots: []);
  }
}
