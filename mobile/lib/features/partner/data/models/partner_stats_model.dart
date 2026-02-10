import 'partner_booking_model.dart';
import 'partner_profile_model.dart';

/// Partner Stats from /bookings/stats/partner
class PartnerStats {
  final int total;
  final int completed;
  final int cancelled;
  final int pending;
  final double totalEarned;

  PartnerStats({
    this.total = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.pending = 0,
    this.totalEarned = 0,
  });

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    return PartnerStats(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      pending: json['pending'] ?? 0,
      totalEarned: parseDouble(json['totalEarned']),
    );
  }

  /// Helper to parse double from various types (String, int, double)
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Partner Dashboard aggregated data
class PartnerDashboardData {
  final PartnerProfileResponse profile;
  final PartnerStats stats;
  final List<PartnerBooking> upcomingBookings;
  final PartnerUserInfo? userInfo;

  PartnerDashboardData({
    required this.profile,
    required this.stats,
    required this.upcomingBookings,
    this.userInfo,
  });
}
