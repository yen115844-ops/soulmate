import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/base_repository.dart';
import '../domain/entities/booking_entity.dart';

class BookingRepository with BaseRepositoryMixin {
  final ApiClient _apiClient;

  BookingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get user bookings as customer
  Future<BookingListResponse> getUserBookings({
    int page = 1,
    int limit = 10,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await _apiClient.get(
        '/bookings/my-bookings',
        queryParameters: queryParams,
      );

      return BookingListResponse.fromJson(extractRawData(response.data));
    } catch (e, stackTrace) {
      debugPrint('Get user bookings error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get booking detail by ID
  Future<BookingEntity> getBookingById(String bookingId) async {
    try {
      final response = await _apiClient.get('/bookings/$bookingId');
      return BookingEntity.fromJson(extractRawData(response.data));
    } catch (e, stackTrace) {
      debugPrint('Get booking detail error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a new booking
  Future<BookingEntity> createBooking({
    required String partnerId,
    required String serviceType,
    required DateTime startTime,
    required DateTime endTime,
    String? note,
    String? location,
  }) async {
    try {
      // Format date as 'yyyy-MM-dd'
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      
      final response = await _apiClient.post(
        '/bookings',
        data: {
          'partnerId': partnerId,
          'serviceType': serviceType,
          'date': dateFormat.format(startTime),
          'startTime': timeFormat.format(startTime),
          'endTime': timeFormat.format(endTime),
          if (note != null) 'userNote': note,
          if (location != null) 'meetingLocation': location,
        },
      );

      return BookingEntity.fromJson(extractRawData(response.data));
    } catch (e, stackTrace) {
      debugPrint('Create booking error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Cancel a booking
  Future<BookingEntity> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.put(
        '/bookings/$bookingId/cancel',
        data: {
          'reason': reason,
        },
      );

      return BookingEntity.fromJson(extractRawData(response.data));
    } catch (e, stackTrace) {
      debugPrint('Cancel booking error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Complete a booking (user marks as done when IN_PROGRESS)
  Future<BookingEntity> completeBooking({
    required String bookingId,
    String? note,
  }) async {
    try {
      final response = await _apiClient.put(
        '/bookings/$bookingId/complete',
        data: note != null && note.isNotEmpty ? {'note': note} : <String, dynamic>{},
      );
      return BookingEntity.fromJson(extractRawData(response.data));
    } catch (e, stackTrace) {
      debugPrint('Complete booking error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get user booking statistics
  Future<BookingStatsResponse> getUserBookingStats() async {
    try {
      final response = await _apiClient.get('/bookings/stats/user');
      return BookingStatsResponse.fromJson(extractRawData(response.data));
    } catch (e, stackTrace) {
      debugPrint('Get booking stats error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

}

// Response models
class BookingListResponse {
  final List<BookingEntity> bookings;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  BookingListResponse({
    required this.bookings,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  /// Check if there are more pages to load
  bool get hasNextPage => page < totalPages;

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns { data: [...], meta: { total, page, limit, totalPages, ... } }
    final items = json['data'];
    final meta = json['meta'] as Map<String, dynamic>?;
    final list = items is List
        ? items.map((e) => BookingEntity.fromJson(e as Map<String, dynamic>)).toList()
        : (json['bookings'] as List?)
                ?.map((e) => BookingEntity.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

    return BookingListResponse(
      bookings: list,
      total: meta?['total'] ?? json['total'] ?? list.length,
      page: meta?['page'] ?? json['page'] ?? 1,
      limit: meta?['limit'] ?? json['limit'] ?? 10,
      totalPages: meta?['totalPages'] ?? json['totalPages'] ?? 1,
    );
  }
}

class BookingStatsResponse {
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int upcomingBookings;
  final double totalSpent;

  BookingStatsResponse({
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.upcomingBookings,
    required this.totalSpent,
  });

  factory BookingStatsResponse.fromJson(Map<String, dynamic> json) {
    return BookingStatsResponse(
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      upcomingBookings: json['upcomingBookings'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
    );
  }
}
