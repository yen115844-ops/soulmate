import 'package:equatable/equatable.dart';

abstract class MyReviewsEvent extends Equatable {
  const MyReviewsEvent();

  @override
  List<Object?> get props => [];
}

class MyReviewsLoadRequested extends MyReviewsEvent {
  const MyReviewsLoadRequested();
}

class MyReviewsRefreshRequested extends MyReviewsEvent {
  const MyReviewsRefreshRequested();
}

class MyReviewDeleteRequested extends MyReviewsEvent {
  final String reviewId;

  const MyReviewDeleteRequested(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

class ReviewResponseSubmitted extends MyReviewsEvent {
  final String reviewId;
  final String response;

  const ReviewResponseSubmitted({
    required this.reviewId,
    required this.response,
  });

  @override
  List<Object?> get props => [reviewId, response];
}
