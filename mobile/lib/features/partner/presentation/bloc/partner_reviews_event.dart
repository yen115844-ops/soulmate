import 'package:equatable/equatable.dart';

/// Events for PartnerReviewsBloc
abstract class PartnerReviewsEvent extends Equatable {
  const PartnerReviewsEvent();

  @override
  List<Object?> get props => [];
}

/// Load reviews
class PartnerReviewsLoadRequested extends PartnerReviewsEvent {
  final int page;
  final String? minRating;
  final String? sortBy;

  const PartnerReviewsLoadRequested({
    this.page = 1,
    this.minRating,
    this.sortBy,
  });

  @override
  List<Object?> get props => [page, minRating, sortBy];
}

/// Load more reviews (pagination)
class PartnerReviewsLoadMoreRequested extends PartnerReviewsEvent {
  const PartnerReviewsLoadMoreRequested();
}

/// Refresh reviews
class PartnerReviewsRefreshRequested extends PartnerReviewsEvent {
  const PartnerReviewsRefreshRequested();
}

/// Filter reviews by rating
class PartnerReviewsFilterChanged extends PartnerReviewsEvent {
  final String? minRating;
  final String? sortBy;

  const PartnerReviewsFilterChanged({
    this.minRating,
    this.sortBy,
  });

  @override
  List<Object?> get props => [minRating, sortBy];
}
