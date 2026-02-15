import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/base_repository.dart';
import 'models/partner_models.dart';

// Re-export models for backward compatibility
export 'models/partner_models.dart';

/// Partner Repository - Handles all partner-related API calls
class PartnerRepository with BaseRepositoryMixin {
  final ApiClient _apiClient;

  PartnerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Update presence (lastActiveAt) so "online" shows on Home/Favorites.
  /// Safe to call for any user; no-op if user is not a partner.
  Future<void> updatePresence() async {
    await _apiClient.put(PartnerEndpoints.presence);
  }

  // ==================== Partner Dashboard API ====================

  /// Get partner dashboard data (stats + profile + user info)
  Future<PartnerDashboardData> getPartnerDashboard() async {
    try {
      // Fetch profile, stats, and bookings in parallel
      final results = await Future.wait([
        _apiClient.get('/partners/me/profile'),
        _apiClient.get('/bookings/stats/partner'),
        _apiClient.get('/bookings/partner-bookings?limit=5'),
      ]);

      final profileData = extractRawData(results[0].data) as Map<String, dynamic>;
      final statsData = extractRawData(results[1].data);
      final bookingsData = extractRawData(results[2].data);

      debugPrint('Profile data keys: ${profileData.keys}');

      final profile = PartnerProfileResponse.fromJson(profileData);
      debugPrint('Profile parsed successfully');

      // Extract user info from profile response
      PartnerUserInfo? userInfo;
      if (profileData['user'] is Map<String, dynamic>) {
        userInfo = PartnerUserInfo.fromJson(
          profileData['user'] as Map<String, dynamic>,
        );
        debugPrint('User info parsed: ${userInfo.name}');
      }

      final stats = PartnerStats.fromJson(statsData as Map<String, dynamic>);
      debugPrint('Stats parsed successfully');

      final bookingsList = bookingsData is Map
          ? bookingsData['data']
          : bookingsData;
      final allBookings =
          (bookingsList as List?)
              ?.map((e) => PartnerBooking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      // Filter for upcoming bookings only (PENDING, CONFIRMED, PAID)
      final upcomingBookings = allBookings.where((b) => b.isUpcoming).toList();
      debugPrint(
        'Bookings parsed successfully: ${upcomingBookings.length} upcoming',
      );

      return PartnerDashboardData(
        profile: profile,
        stats: stats,
        upcomingBookings: upcomingBookings,
        userInfo: userInfo,
      );
    } catch (e, stackTrace) {
      debugPrint('Partner dashboard error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get partner bookings with filters
  Future<PartnerBookingsResponse> getPartnerBookings({
    int page = 1,
    int limit = 10,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };

    final response = await _apiClient.get(
      '/bookings/partner-bookings',
      queryParameters: queryParams,
    );

    return PartnerBookingsResponse.fromJson(extractRawData(response.data));
  }

  /// Confirm a booking
  Future<PartnerBooking> confirmBooking(
    String bookingId, {
    String? note,
  }) async {
    final response = await _apiClient.put(
      '/bookings/$bookingId/confirm',
      data: {if (note != null) 'note': note},
    );

    return PartnerBooking.fromJson(extractRawData(response.data));
  }

  /// Reject/Cancel a booking
  Future<PartnerBooking> cancelBooking(String bookingId, String reason) async {
    final response = await _apiClient.put(
      '/bookings/$bookingId/cancel',
      data: {'reason': reason, 'cancelledBy': 'PARTNER'},
    );

    return PartnerBooking.fromJson(extractRawData(response.data));
  }

  /// Start a booking (begin meeting)
  Future<PartnerBooking> startBooking(String bookingId) async {
    final response = await _apiClient.put('/bookings/$bookingId/start');
    return PartnerBooking.fromJson(extractRawData(response.data));
  }

  /// Complete a booking
  Future<PartnerBooking> completeBooking(String bookingId, {String? note}) async {
    final response = await _apiClient.put(
      '/bookings/$bookingId/complete',
      data: {if (note != null) 'note': note},
    );
    return PartnerBooking.fromJson(extractRawData(response.data));
  }

  /// Toggle partner availability
  Future<PartnerProfileResponse> toggleAvailability(bool isAvailable) async {
    final response = await _apiClient.put(
      '/partners/me/profile',
      data: {'isAvailable': isAvailable},
    );

    return PartnerProfileResponse.fromJson(extractRawData(response.data));
  }

  /// Get partner earnings/transactions
  Future<PartnerEarningsData> getPartnerEarnings({
    String period = 'month', // week, month, year, all
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Fetch stats and wallet transactions
      final results = await Future.wait([
        _apiClient.get('/bookings/stats/partner'),
        _apiClient.get('/wallet'),
        _apiClient.get(
          '/wallet/transactions',
          queryParameters: {'page': page, 'limit': limit, 'period': period},
        ),
      ]);

      final statsData = extractRawData(results[0].data);
      final walletData = extractRawData(results[1].data);
      final transactionsData = extractRawData(results[2].data);

      return PartnerEarningsData(
        stats: PartnerStats.fromJson(statsData),
        wallet: PartnerWalletInfo.fromJson(walletData),
        transactions: _parseTransactions(transactionsData),
      );
    } catch (e) {
      debugPrint('Partner earnings error: $e');
      rethrow;
    }
  }

  /// Parse transactions from API response
  List<WalletTransaction> _parseTransactions(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      data = data['data'];
    }
    if (data is List) {
      return data
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Request withdrawal
  Future<void> requestWithdrawal({required double amount, String? note}) async {
    await _apiClient.post(
      '/wallet/withdraw',
      data: {'amount': amount, if (note != null) 'note': note},
    );
  }

  // ==================== Partner Registration ====================

  /// Register as a partner
  Future<PartnerProfileResponse> registerAsPartner({
    required List<String> serviceTypes,
    required int hourlyRate,
    required String introduction,
    required String bio,
    required String bankName,
    required String bankAccountNo,
    required String bankAccountName,
    required List<File> photos,
    int? minimumHours,
    int? experienceYears,
  }) async {
    try {
      // 1. Upload photos first
      List<String> photoUrls = [];
      if (photos.isNotEmpty) {
        photoUrls = await _uploadPhotos(photos);
      }

      // 2. Create partner profile
      final response = await _apiClient.post(
        '/partners/register',
        data: {
          'serviceTypes': serviceTypes,
          'hourlyRate': hourlyRate,
          'introduction': introduction,
          'bio': bio,
          'bankName': bankName,
          'bankAccountNo': bankAccountNo,
          'bankAccountName': bankAccountName,
          'photoUrls': photoUrls,
          if (minimumHours != null) 'minimumHours': minimumHours,
          if (experienceYears != null) 'experienceYears': experienceYears,
        },
      );

      return PartnerProfileResponse.fromJson(extractRawData(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw PartnerAlreadyExistsException();
      }
      rethrow;
    }
  }

  /// Upload photos to server
  Future<List<String>> _uploadPhotos(List<File> photos) async {
    final List<MultipartFile> files = [];

    for (final photo in photos) {
      files.add(
        await MultipartFile.fromFile(
          photo.path,
          filename: photo.path.split('/').last,
        ),
      );
    }

    final formData = FormData.fromMap({'files': files});

    final response = await _apiClient.post('/upload/images', data: formData);

    final data = extractRawData(response.data);
    if (data['urls'] != null) {
      return List<String>.from(data['urls']);
    }

    return [];
  }

  // ==================== Partner Profile ====================

  /// Get my partner profile
  Future<PartnerProfileResponse> getMyPartnerProfile() async {
    final response = await _apiClient.get('/partners/me/profile');
    return PartnerProfileResponse.fromJson(extractRawData(response.data));
  }

  /// Get my partner profile with full user info (photos, bio, etc)
  Future<PartnerProfileFullResponse> getMyPartnerProfileFull() async {
    final response = await _apiClient.get('/partners/me/profile');
    final data = extractRawData(response.data) as Map<String, dynamic>;

    final profile = PartnerProfileResponse.fromJson(data);

    // Extract user profile info
    PartnerUserProfileInfo? userProfile;
    if (data['user'] is Map<String, dynamic>) {
      final userData = data['user'] as Map<String, dynamic>;
      if (userData['profile'] is Map<String, dynamic>) {
        userProfile = PartnerUserProfileInfo.fromJson(
          userData['profile'] as Map<String, dynamic>,
        );
      }
    }

    return PartnerProfileFullResponse(
      profile: profile,
      userProfile: userProfile,
    );
  }

  /// Update partner profile
  Future<PartnerProfileResponse> updatePartnerProfile({
    List<String>? serviceTypes,
    int? hourlyRate,
    String? introduction,
    int? minimumHours,
    bool? isAvailable,
  }) async {
    final response = await _apiClient.put(
      '/partners/me/profile',
      data: {
        if (serviceTypes != null) 'serviceTypes': serviceTypes,
        if (hourlyRate != null) 'hourlyRate': hourlyRate,
        if (introduction != null) 'introduction': introduction,
        if (minimumHours != null) 'minimumHours': minimumHours,
        if (isAvailable != null) 'isAvailable': isAvailable,
      },
    );

    return PartnerProfileResponse.fromJson(extractRawData(response.data));
  }

  /// Update bank account information
  Future<void> updateBankInfo({
    required String bankName,
    required String bankAccountNo,
    required String bankAccountName,
  }) async {
    await _apiClient.put(
      '/partners/me/profile',
      data: {
        'bankName': bankName,
        'bankAccountNo': bankAccountNo,
        'bankAccountName': bankAccountName,
      },
    );
  }

  /// Add photos to partner portfolio
  Future<List<String>> addPhotos(List<File> photos) async {
    if (photos.isEmpty) return [];

    // 1. Upload photos first
    final photoUrls = await _uploadPhotos(photos);

    // 2. Update partner profile with new photo URLs
    await _apiClient.put(
      '/partners/me/profile',
      data: {'photoUrls': photoUrls},
    );

    return photoUrls;
  }

  /// Remove photos from partner portfolio
  Future<void> removePhotos(List<String> photoUrls) async {
    if (photoUrls.isEmpty) return;

    await _apiClient.put(
      '/partners/me/profile',
      data: {'removePhotoUrls': photoUrls},
    );
  }

  /// Get bank account information
  Future<BankAccountInfo?> getBankAccountInfo() async {
    try {
      final response = await _apiClient.get('/wallet');
      final data = extractRawData(response.data) as Map<String, dynamic>;

      if (data['bankName'] != null || data['bankAccountNo'] != null) {
        return BankAccountInfo(
          bankName: data['bankName'] as String? ?? '',
          bankAccountNo: data['bankAccountNo'] as String? ?? '',
          bankAccountName: data['bankAccountName'] as String? ?? '',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== Partner Search ====================

  /// Search partners
  Future<PartnerSearchResponse> searchPartners({
    int page = 1,
    int limit = 10,
    String? serviceType,
    String? gender,
    int? minRate,
    int? maxRate,
    String? city,
    bool? verifiedOnly,
    String? sortBy,
  }) async {
    final response = await _apiClient.get(
      '/partners/search',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (serviceType != null) 'serviceType': serviceType,
        if (gender != null) 'gender': gender,
        if (minRate != null) 'minRate': minRate,
        if (maxRate != null) 'maxRate': maxRate,
        if (city != null) 'city': city,
        if (verifiedOnly != null) 'verifiedOnly': verifiedOnly,
        if (sortBy != null) 'sortBy': sortBy,
      },
    );

    return PartnerSearchResponse.fromJson(extractRawData(response.data));
  }

  /// Get partner by ID
  Future<PartnerProfileResponse> getPartnerById(String partnerId) async {
    final response = await _apiClient.get('/partners/$partnerId');
    return PartnerProfileResponse.fromJson(extractRawData(response.data));
  }

  /// Get partner by ID with full user info
  Future<PartnerDetailResponse> getPartnerByIdWithUser(String partnerId) async {
    final response = await _apiClient.get('/partners/$partnerId');
    return PartnerDetailResponse.fromJson(
      extractRawData(response.data) as Map<String, dynamic>,
    );
  }

  // ==================== Availability Slots API ====================

  /// Get availability slots for current partner
  Future<AvailabilitySlotsResponse> getAvailabilitySlots({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };

    final response = await _apiClient.get(
      '/partners/me/slots',
      queryParameters: queryParams,
    );

    return AvailabilitySlotsResponse.fromJson(extractRawData(response.data));
  }

  /// Create availability slot
  Future<AvailabilitySlot> createAvailabilitySlot({
    required String date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    final response = await _apiClient.post(
      '/partners/me/slots',
      data: {
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        if (note != null) 'note': note,
      },
    );

    return AvailabilitySlot.fromJson(extractRawData(response.data));
  }

  /// Update availability slot
  Future<AvailabilitySlot> updateAvailabilitySlot({
    required String slotId,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    final response = await _apiClient.put(
      '/partners/me/slots/$slotId',
      data: {
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (note != null) 'note': note,
      },
    );

    return AvailabilitySlot.fromJson(extractRawData(response.data));
  }

  /// Delete availability slot
  Future<void> deleteAvailabilitySlot(String slotId) async {
    await _apiClient.delete('/partners/me/slots/$slotId');
  }

  // ==================== Reviews API ====================

  /// Get reviews for a specific partner (public endpoint)
  Future<PartnerReviewsResponse> getPartnerReviews({
    required String partnerId,
    int page = 1,
    int limit = 10,
    String? minRating,
    String? sortBy,
  }) async {
    try {
      final response = await _apiClient.get(
        '/reviews/user/$partnerId',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (minRating != null) 'minRating': minRating,
          if (sortBy != null) 'sortBy': sortBy,
        },
      );

      final data = extractRawData(response.data);
      return PartnerReviewsResponse.fromJson(data);
    } catch (e) {
      debugPrint('Reviews API error, falling back to partner profile: $e');

      // Fallback: Get reviews from partner detail
      final response = await _apiClient.get('/partners/$partnerId');

      final data = extractRawData(response.data);
      var reviewsResponse = PartnerReviewsResponse.fromPartnerData(data);

      // Filter reviews by minRating on client side
      if (minRating != null) {
        final minRatingValue = double.tryParse(minRating) ?? 0;
        final filteredReviews = reviewsResponse.reviews
            .where((r) => r.overallRating >= minRatingValue)
            .toList();
        reviewsResponse = PartnerReviewsResponse(
          reviews: filteredReviews,
          total: filteredReviews.length,
          page: page,
          limit: limit,
          totalPages: 1,
        );
      }

      return reviewsResponse;
    }
  }

  /// Get review statistics for a specific partner (public endpoint)
  Future<ReviewStats> getPartnerReviewStats({
    required String partnerId,
  }) async {
    try {
      final response = await _apiClient.get('/reviews/user/$partnerId/stats');
      final data = extractRawData(response.data);

      return ReviewStats(
        averageRating: PartnerStats.parseDouble(data['averageRating']),
        totalReviews: data['totalReviews'] ?? 0,
        rating5Count: data['ratingDistribution']?['5'] ?? 0,
        rating4Count: data['ratingDistribution']?['4'] ?? 0,
        rating3Count: data['ratingDistribution']?['3'] ?? 0,
        rating2Count: data['ratingDistribution']?['2'] ?? 0,
        rating1Count: data['ratingDistribution']?['1'] ?? 0,
      );
    } catch (e) {
      debugPrint('Review stats API error, falling back to partner data: $e');

      // Fallback: Get stats from partner detail
      final partnerResponse = await _apiClient.get('/partners/$partnerId');
      final partnerData = extractRawData(partnerResponse.data) as Map<String, dynamic>;

      return ReviewStats(
        averageRating: PartnerStats.parseDouble(partnerData['averageRating']),
        totalReviews: partnerData['totalReviews'] ?? 0,
        rating5Count: 0,
        rating4Count: 0,
        rating3Count: 0,
        rating2Count: 0,
        rating1Count: 0,
      );
    }
  }

  // ==================== Helper Methods ====================
}
