import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../data/reviews_repository.dart';
import 'my_reviews_event.dart';
import 'my_reviews_state.dart';

class MyReviewsBloc extends Bloc<MyReviewsEvent, MyReviewsState> {
  final ReviewsRepository _repository;

  MyReviewsBloc(this._repository) : super(const MyReviewsState()) {
    on<MyReviewsLoadRequested>(_onLoadRequested);
    on<MyReviewsRefreshRequested>(_onRefreshRequested);
    on<MyReviewDeleteRequested>(_onDeleteRequested);
    on<ReviewResponseSubmitted>(_onResponseSubmitted);
  }

  Future<void> _onLoadRequested(
    MyReviewsLoadRequested event,
    Emitter<MyReviewsState> emit,
  ) async {
    emit(state.copyWith(status: MyReviewsStatus.loading));

    try {
      final givenResult = await _repository.getGivenReviews(limit: 50);
      final receivedResult = await _repository.getReceivedReviews(limit: 50);
      final statsResult = await _repository.getMyStats();

      emit(state.copyWith(
        status: MyReviewsStatus.loaded,
        givenReviews: givenResult.data,
        receivedReviews: receivedResult.data,
        stats: statsResult,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MyReviewsStatus.error,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    MyReviewsRefreshRequested event,
    Emitter<MyReviewsState> emit,
  ) async {
    add(const MyReviewsLoadRequested());
  }

  Future<void> _onDeleteRequested(
    MyReviewDeleteRequested event,
    Emitter<MyReviewsState> emit,
  ) async {
    try {
      // Optimistically remove
      final updatedGiven = state.givenReviews
          .where((r) => r.id != event.reviewId)
          .toList();

      emit(state.copyWith(givenReviews: updatedGiven));

      await _repository.deleteReview(event.reviewId);
    } catch (e) {
      // Refresh on error
      add(const MyReviewsRefreshRequested());
      emit(state.copyWith(
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  Future<void> _onResponseSubmitted(
    ReviewResponseSubmitted event,
    Emitter<MyReviewsState> emit,
  ) async {
    try {
      await _repository.respondToReview(event.reviewId, event.response);
      add(const MyReviewsRefreshRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: getErrorMessage(e),
      ));
    }
  }
}
