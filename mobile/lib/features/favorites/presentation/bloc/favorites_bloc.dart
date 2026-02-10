import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/favorites_repository.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesBloc(this._repository) : super(const FavoritesState()) {
    on<FavoritesLoadRequested>(_onLoadRequested);
    on<FavoritesRefreshRequested>(_onRefreshRequested);
    on<FavoriteRemoveRequested>(_onRemoveRequested);
    on<FavoriteAddRequested>(_onAddRequested);
  }

  Future<void> _onLoadRequested(
    FavoritesLoadRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state.hasReachedMax && event.page > 1) return;

    try {
      if (event.page == 1) {
        emit(state.copyWith(status: FavoritesStatus.loading));
      }

      final response = await _repository.getFavorites(
        page: event.page,
        limit: event.limit,
      );

      final hasReachedMax = response.data.length < event.limit;
      final favorites = event.page == 1
          ? response.data
          : [...state.favorites, ...response.data];

      emit(state.copyWith(
        status: FavoritesStatus.loaded,
        favorites: favorites,
        total: response.total,
        page: event.page,
        limit: event.limit,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FavoritesStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshRequested(
    FavoritesRefreshRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    add(const FavoritesLoadRequested(page: 1));
  }

  Future<void> _onRemoveRequested(
    FavoriteRemoveRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Optimistically remove from list
      final updatedFavorites = state.favorites
          .where((f) => f.partnerId != event.partnerId)
          .toList();

      emit(state.copyWith(
        favorites: updatedFavorites,
        total: state.total - 1,
      ));

      // Call API
      await _repository.removeFavorite(event.partnerId);
    } catch (e) {
      // Refresh on error to restore state
      add(const FavoritesRefreshRequested());
      emit(state.copyWith(
        errorMessage: 'Không thể xóa khỏi yêu thích: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddRequested(
    FavoriteAddRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _repository.addFavorite(event.partnerId);
      // Refresh list to get updated data
      add(const FavoritesRefreshRequested());
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể thêm vào yêu thích: ${e.toString()}',
      ));
    }
  }
}
