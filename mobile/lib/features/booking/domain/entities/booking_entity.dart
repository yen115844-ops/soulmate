import 'package:equatable/equatable.dart';

/// Helper function to parse int from dynamic value (handles both int and String)
int _parseIntFromDynamic(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

/// Booking Entity - Represents a booking in the app
class BookingEntity extends Equatable {
  final String id;
  final String? bookingCode;
  final String userId;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final String serviceType;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // PENDING, CONFIRMED, PAID, IN_PROGRESS, COMPLETED, CANCELLED, REJECTED
  final int totalAmount;
  final String? note;
  final String? location;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingEntity({
    required this.id,
    this.bookingCode,
    required this.userId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    required this.serviceType,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalAmount,
    this.note,
    this.location,
    this.cancellationReason,
    this.cancelledBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingEntity.fromJson(Map<String, dynamic> json) {
    // Extract partner info - API returns partner with profile (fullName, displayName, avatarUrl)
    final partner = json['partner'] as Map<String, dynamic>?;
    final profile = partner?['profile'] as Map<String, dynamic>?;

    // Parse date (yyyy-MM-dd or ISO) for calendar day (use UTC parts to avoid timezone shifting the day)
    final dateStr = json['date'];
    final dateParsed = dateStr != null
        ? DateTime.parse(dateStr.toString())
        : DateTime.now();
    final year = dateParsed.year;
    final month = dateParsed.month;
    final day = dateParsed.day;

    // Parse startTime/endTime - API may return full ISO (2026-01-31T06:00:00Z) or time-only (1970-01-01T06:00:00Z)
    // Combine booking date with time-of-day so formattedDate and formattedTimeRange use correct day
    DateTime combineDateWithTime(String field) {
      final value = json[field];
      if (value == null) return DateTime(year, month, day);
      final parsed = DateTime.parse(value.toString());
      return DateTime(
        year,
        month,
        day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      );
    }

    return BookingEntity(
      id: json['id'] as String,
      bookingCode: json['bookingCode'] as String?,
      userId: json['userId'] as String,
      partnerId: json['partnerId'] as String,
      partnerName: profile?['fullName'] as String? ?? profile?['displayName'] as String? ?? 'Unknown',
      partnerAvatar: profile?['avatarUrl'] as String?,
      serviceType: json['serviceType'] as String,
      startTime: combineDateWithTime('startTime'),
      endTime: combineDateWithTime('endTime'),
      status: json['status'] as String,
      totalAmount: _parseIntFromDynamic(json['totalAmount']),
      note: json['note'] as String? ?? json['userNote'] as String?,
      location: json['location'] as String? ?? json['meetingLocation'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancelledBy: json['cancelledBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'partnerId': partnerId,
      'serviceType': serviceType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'totalAmount': totalAmount,
      'note': note,
      'location': location,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Check if booking is upcoming (including in progress)
  bool get isUpcoming {
    return status == 'PENDING' ||
        status == 'CONFIRMED' ||
        status == 'PAID' ||
        status == 'IN_PROGRESS';
  }

  /// Check if booking is past (completed or cancelled)
  bool get isPast {
    return status == 'COMPLETED' ||
        status == 'CANCELLED' ||
        status == 'REJECTED';
  }

  /// Format date for display
  String get formattedDate {
    final day = startTime.day.toString().padLeft(2, '0');
    final month = startTime.month.toString().padLeft(2, '0');
    final year = startTime.year;
    return '$day/$month/$year';
  }

  /// Format time range for display
  String get formattedTimeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  /// Format amount as Vietnamese currency
  String get formattedAmount {
    if (totalAmount >= 1000000) {
      return '${(totalAmount / 1000000).toStringAsFixed(1)}M';
    } else if (totalAmount >= 1000) {
      return '${(totalAmount / 1000).toStringAsFixed(0)}K';
    }
    return totalAmount.toString();
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'CONFIRMED':
      case 'PAID':
        return 'success';
      case 'PENDING':
        return 'warning';
      case 'COMPLETED':
        return 'info';
      case 'CANCELLED':
      case 'REJECTED':
        return 'error';
      default:
        return 'default';
    }
  }

  /// Get status text in Vietnamese
  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PAID':
        return 'Đã thanh toán';
      case 'IN_PROGRESS':
        return 'Đang diễn ra';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'REJECTED':
        return 'Bị từ chối';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [
        id,
        bookingCode,
        userId,
        partnerId,
        partnerName,
        partnerAvatar,
        serviceType,
        startTime,
        endTime,
        status,
        totalAmount,
        note,
        location,
        cancellationReason,
        cancelledBy,
        createdAt,
        updatedAt,
      ];
}
