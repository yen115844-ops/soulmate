import 'package:equatable/equatable.dart';

import '../../data/partner_repository.dart';

/// States for PartnerReviewsBloc
abstract class PartnerReviewsState extends Equatable {
  const PartnerReviewsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PartnerReviewsInitial extends PartnerReviewsState {
  const PartnerReviewsInitial();
}

/// Loading state
class PartnerReviewsLoading extends PartnerReviewsState {
  const PartnerReviewsLoading();
}

/// Loaded state with reviews data
class PartnerReviewsLoaded extends PartnerReviewsState {
  final List<PartnerReview> reviews;
  final ReviewStats stats;
  final int total;
  final int page;
  final int totalPages;
  final bool hasNextPage;
  final String? currentFilter;
  final String? currentSort;
  final bool isLoadingMore;
  /// True when only the filter changed and reviews are being refetched (stats stay visible).
  final bool isFiltering;

  const PartnerReviewsLoaded({
    required this.reviews,
    required this.stats,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasNextPage,
    this.currentFilter,
    this.currentSort,
    this.isLoadingMore = false,
    this.isFiltering = false,
  });

  /// Copy with new values
  PartnerReviewsLoaded copyWith({
    List<PartnerReview>? reviews,
    ReviewStats? stats,
    int? total,
    int? page,
    int? totalPages,
    bool? hasNextPage,
    String? currentFilter,
    String? currentSort,
    bool? isLoadingMore,
    bool? isFiltering,
  }) {
    return PartnerReviewsLoaded(
      reviews: reviews ?? this.reviews,
      stats: stats ?? this.stats,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSort: currentSort ?? this.currentSort,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        reviews,
        stats,
        total,
        page,
        totalPages,
        hasNextPage,
        currentFilter,
        currentSort,
        isLoadingMore,
        isFiltering,
      ];
}

/// Error state
class PartnerReviewsError extends PartnerReviewsState {
  final String message;

  const PartnerReviewsError({required this.message});

  @override
  List<Object?> get props => [message];
}
