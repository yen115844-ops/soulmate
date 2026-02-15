import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/partner_repository.dart';
import 'partner_reviews_event.dart';
import 'partner_reviews_state.dart';

class PartnerReviewsBloc
    extends Bloc<PartnerReviewsEvent, PartnerReviewsState> {
  final PartnerRepository _partnerRepository;
  final String partnerId;

  PartnerReviewsBloc({
    required PartnerRepository partnerRepository,
    required this.partnerId,
  })  : _partnerRepository = partnerRepository,
        super(const PartnerReviewsInitial()) {
    on<PartnerReviewsLoadRequested>(_onLoadRequested);
    on<PartnerReviewsLoadMoreRequested>(_onLoadMoreRequested);
    on<PartnerReviewsRefreshRequested>(_onRefreshRequested);
    on<PartnerReviewsFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoadRequested(
    PartnerReviewsLoadRequested event,
    Emitter<PartnerReviewsState> emit,
  ) async {
    emit(const PartnerReviewsLoading());

    try {
      final results = await Future.wait([
        _partnerRepository.getPartnerReviews(
          partnerId: partnerId,
          page: event.page,
          minRating: event.minRating,
          sortBy: event.sortBy,
        ),
        _partnerRepository.getPartnerReviewStats(partnerId: partnerId),
      ]);

      final reviewsResponse = results[0] as PartnerReviewsResponse;
      final stats = results[1] as ReviewStats;

      emit(PartnerReviewsLoaded(
        reviews: reviewsResponse.reviews,
        stats: stats,
        total: reviewsResponse.total,
        page: reviewsResponse.page,
        totalPages: reviewsResponse.totalPages,
        hasNextPage: reviewsResponse.page < reviewsResponse.totalPages,
        currentFilter: event.minRating,
        currentSort: event.sortBy,
        isFiltering: false,
      ));
    } catch (e) {
      debugPrint('Partner reviews load error: $e');
      emit(PartnerReviewsError(message: getErrorMessage(e)));
    }
  }

  Future<void> _onLoadMoreRequested(
    PartnerReviewsLoadMoreRequested event,
    Emitter<PartnerReviewsState> emit,
  ) async {
    if (state is! PartnerReviewsLoaded) return;

    final currentState = state as PartnerReviewsLoaded;
    if (!currentState.hasNextPage || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _partnerRepository.getPartnerReviews(
        partnerId: partnerId,
        page: currentState.page + 1,
        minRating: currentState.currentFilter,
        sortBy: currentState.currentSort,
      );

      emit(PartnerReviewsLoaded(
        reviews: [...currentState.reviews, ...response.reviews],
        stats: currentState.stats,
        total: response.total,
        page: response.page,
        totalPages: response.totalPages,
        hasNextPage: response.page < response.totalPages,
        currentFilter: currentState.currentFilter,
        currentSort: currentState.currentSort,
      ));
    } catch (e) {
      debugPrint('Partner reviews load more error: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onRefreshRequested(
    PartnerReviewsRefreshRequested event,
    Emitter<PartnerReviewsState> emit,
  ) async {
    final currentFilter =
        state is PartnerReviewsLoaded ? (state as PartnerReviewsLoaded).currentFilter : null;
    final currentSort =
        state is PartnerReviewsLoaded ? (state as PartnerReviewsLoaded).currentSort : null;

    try {
      final results = await Future.wait([
        _partnerRepository.getPartnerReviews(
          partnerId: partnerId,
          page: 1,
          minRating: currentFilter,
          sortBy: currentSort,
        ),
        _partnerRepository.getPartnerReviewStats(partnerId: partnerId),
      ]);

      final reviewsResponse = results[0] as PartnerReviewsResponse;
      final stats = results[1] as ReviewStats;

      emit(PartnerReviewsLoaded(
        reviews: reviewsResponse.reviews,
        stats: stats,
        total: reviewsResponse.total,
        page: reviewsResponse.page,
        totalPages: reviewsResponse.totalPages,
        hasNextPage: reviewsResponse.page < reviewsResponse.totalPages,
        currentFilter: currentFilter,
        currentSort: currentSort,
      ));
    } catch (e) {
      debugPrint('Partner reviews refresh error: $e');
      // Keep current state on refresh error
    }
  }

  Future<void> _onFilterChanged(
    PartnerReviewsFilterChanged event,
    Emitter<PartnerReviewsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PartnerReviewsLoaded) {
      add(PartnerReviewsLoadRequested(
        minRating: event.minRating,
        sortBy: event.sortBy,
      ));
      return;
    }

    // Keep summary visible: only refetch reviews, reuse existing stats.
    emit(currentState.copyWith(isFiltering: true));

    try {
      final response = await _partnerRepository.getPartnerReviews(
        partnerId: partnerId,
        page: 1,
        minRating: event.minRating,
        sortBy: event.sortBy ?? currentState.currentSort,
      );

      emit(PartnerReviewsLoaded(
        reviews: response.reviews,
        stats: currentState.stats,
        total: response.total,
        page: response.page,
        totalPages: response.totalPages,
        hasNextPage: response.page < response.totalPages,
        currentFilter: event.minRating,
        currentSort: event.sortBy ?? currentState.currentSort,
        isFiltering: false,
      ));
    } catch (e) {
      debugPrint('Partner reviews filter error: $e');
      emit(currentState.copyWith(isFiltering: false));
    }
  }
}
