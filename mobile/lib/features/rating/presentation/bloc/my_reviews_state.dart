import 'package:equatable/equatable.dart';

import '../../data/models/review_model.dart';

enum MyReviewsStatus { initial, loading, loaded, error }

class MyReviewsState extends Equatable {
  final MyReviewsStatus status;
  final List<ReviewModel> givenReviews;
  final List<ReviewModel> receivedReviews;
  final ReviewStatsModel? stats;
  final String? errorMessage;

  const MyReviewsState({
    this.status = MyReviewsStatus.initial,
    this.givenReviews = const [],
    this.receivedReviews = const [],
    this.stats,
    this.errorMessage,
  });

  MyReviewsState copyWith({
    MyReviewsStatus? status,
    List<ReviewModel>? givenReviews,
    List<ReviewModel>? receivedReviews,
    ReviewStatsModel? stats,
    String? errorMessage,
  }) {
    return MyReviewsState(
      status: status ?? this.status,
      givenReviews: givenReviews ?? this.givenReviews,
      receivedReviews: receivedReviews ?? this.receivedReviews,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, givenReviews, receivedReviews, stats, errorMessage];
}
