import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'models/review_model.dart';

class ReviewsRepository {
  final ApiClient _apiClient;

  ReviewsRepository(this._apiClient);

  /// Create a new review for a booking
  Future<ReviewModel> createReview({
    required String bookingId,
    required int overallRating,
    String? comment,
    int? punctualityRating,
    int? communicationRating,
    int? attitudeRating,
    int? serviceQualityRating,
    List<String>? tags,
    bool isAnonymous = false,
  }) async {
    final response = await _apiClient.post(
      ReviewEndpoints.base,
      data: {
        'bookingId': bookingId,
        'overallRating': overallRating,
        if (comment != null) 'comment': comment,
        if (punctualityRating != null) 'punctualityRating': punctualityRating,
        if (communicationRating != null)
          'communicationRating': communicationRating,
        if (attitudeRating != null) 'attitudeRating': attitudeRating,
        if (serviceQualityRating != null)
          'serviceQualityRating': serviceQualityRating,
        if (tags != null) 'tags': tags,
        'isAnonymous': isAnonymous,
      },
    );
    final responseData = response.data as Map<String, dynamic>;
    return ReviewModel.fromJson(responseData['data'] ?? responseData);
  }

  /// Get reviews I gave to partners
  Future<ReviewsListResponse> getGivenReviews({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ReviewEndpoints.given,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    return ReviewsListResponse.fromJson(data);
  }

  /// Get reviews I received from others
  Future<ReviewsListResponse> getReceivedReviews({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ReviewEndpoints.received,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    return ReviewsListResponse.fromJson(data);
  }

  /// Get my review statistics
  Future<ReviewStatsModel> getMyStats() async {
    final response = await _apiClient.get(ReviewEndpoints.stats);
    final data = response.data as Map<String, dynamic>;
    return ReviewStatsModel.fromJson(data['data'] ?? data);
  }

  /// Delete my review
  Future<void> deleteReview(String reviewId) async {
    await _apiClient.delete(ReviewEndpoints.detail(reviewId));
  }

  /// Update my review
  Future<ReviewModel> updateReview(
    String reviewId, {
    int? overallRating,
    String? comment,
    List<String>? tags,
  }) async {
    final response = await _apiClient.patch(
      ReviewEndpoints.detail(reviewId),
      data: {
        if (overallRating != null) 'overallRating': overallRating,
        if (comment != null) 'comment': comment,
        if (tags != null) 'tags': tags,
      },
    );
    final responseData = response.data as Map<String, dynamic>;
    return ReviewModel.fromJson(responseData['data'] ?? responseData);
  }

  /// Respond to a review I received
  Future<void> respondToReview(String reviewId, String response) async {
    await _apiClient.post(
      ReviewEndpoints.respond(reviewId),
      data: {'response': response},
    );
  }
}
