import 'package:intl/intl.dart';

import 'partner_stats_model.dart';

/// Partner Booking model
class PartnerBooking {
  final String id;
  final String bookingCode;
  final String userId;
  final String partnerId;
  final String status;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int duration;
  final double hourlyRate;
  final double subtotal;
  final double serviceFee;
  final double totalAmount;
  final String? meetingLocation;
  final String? userNote;
  final List<String> activities;
  final BookingUserInfo? user;
  final DateTime createdAt;

  PartnerBooking({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.partnerId,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.hourlyRate,
    required this.subtotal,
    required this.serviceFee,
    required this.totalAmount,
    this.meetingLocation,
    this.userNote,
    required this.activities,
    this.user,
    required this.createdAt,
  });

  /// Parse time string from backend (handles both "HH:mm" and ISO datetime format)
  static String _parseTimeString(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    
    // If it's already in HH:mm format, return as is
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(str)) {
      return str;
    }
    
    // If it's ISO datetime format (e.g., "1970-01-01T06:00:00.000Z")
    if (str.contains('T')) {
      try {
        final dateTime = DateTime.parse(str).toLocal();
        return DateFormat('HH:mm').format(dateTime);
      } catch (_) {
        return str;
      }
    }
    
    return str;
  }

  factory PartnerBooking.fromJson(Map<String, dynamic> json) {
    return PartnerBooking(
      id: json['id']?.toString() ?? '',
      bookingCode: json['bookingCode']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      startTime: _parseTimeString(json['startTime']),
      endTime: _parseTimeString(json['endTime']),
      duration: json['duration'] is int
          ? json['duration']
          : int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      hourlyRate: PartnerStats.parseDouble(json['hourlyRate']),
      subtotal: PartnerStats.parseDouble(json['subtotal']),
      serviceFee: PartnerStats.parseDouble(json['serviceFee']),
      totalAmount: PartnerStats.parseDouble(json['totalAmount']),
      meetingLocation:
          json['meetingLocation'] is String ? json['meetingLocation'] : null,
      userNote: json['userNote'] is String ? json['userNote'] : null,
      activities: (json['activities'] is List)
          ? List<String>.from(
              (json['activities'] as List).map((e) => e.toString()),
            )
          : <String>[],
      user: json['user'] is Map<String, dynamic>
          ? BookingUserInfo.fromJson(json['user'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  /// Get status display text in Vietnamese
  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PAID':
        return 'Đã thanh toán';
      case 'ONGOING':
        return 'Đang diễn ra';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// Check if booking is upcoming
  bool get isUpcoming =>
      status == 'PENDING' || status == 'CONFIRMED' || status == 'PAID';

  /// Check if booking is completed
  bool get isCompleted => status == 'COMPLETED';

  /// Check if booking is cancelled
  bool get isCancelled => status == 'CANCELLED';
}

/// User basic info for booking
class BookingUserInfo {
  final String id;
  final String email;
  final String? role;
  final BookingProfileInfo? profile;

  BookingUserInfo({
    required this.id,
    required this.email,
    this.role,
    this.profile,
  });

  factory BookingUserInfo.fromJson(Map<String, dynamic> json) {
    return BookingUserInfo(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role'] is String ? json['role'] : null,
      profile: json['profile'] is Map<String, dynamic>
          ? BookingProfileInfo.fromJson(json['profile'])
          : null,
    );
  }

  String get displayName =>
      profile?.displayName ?? profile?.fullName ?? email.split('@').first;

  String? get avatarUrl => profile?.avatarUrl;
}

/// Profile info for booking
class BookingProfileInfo {
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;

  BookingProfileInfo({this.fullName, this.displayName, this.avatarUrl});

  factory BookingProfileInfo.fromJson(Map<String, dynamic> json) {
    return BookingProfileInfo(
      fullName: json['fullName'] is String ? json['fullName'] : null,
      displayName: json['displayName'] is String ? json['displayName'] : null,
      avatarUrl: json['avatarUrl'] is String ? json['avatarUrl'] : null,
    );
  }
}

/// Partner Bookings paginated response
class PartnerBookingsResponse {
  final List<PartnerBooking> bookings;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PartnerBookingsResponse({
    required this.bookings,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PartnerBookingsResponse.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    return PartnerBookingsResponse(
      bookings: (json['data'] as List?)
              ?.map((e) => PartnerBooking.fromJson(e))
              .toList() ??
          [],
      total: meta['total'] ?? 0,
      page: meta['page'] ?? 1,
      limit: meta['limit'] ?? 10,
      totalPages: meta['totalPages'] ?? 1,
      hasNextPage: meta['hasNextPage'] ?? false,
      hasPreviousPage: meta['hasPreviousPage'] ?? false,
    );
  }
}
