import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/base_repository.dart';
import '../../../favorites/data/favorites_repository.dart';
import '../../data/home_repository.dart';
import '../../domain/home_filter.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Home BLoC - Manages home page state
class HomeBloc extends Bloc<HomeEvent, HomeState> with BaseRepositoryMixin {
  final HomeRepository _repository;
  final FavoritesRepository? _favoritesRepository;
  static const int _pageSize = 20;

  HomeBloc({
    required HomeRepository repository,
    FavoritesRepository? favoritesRepository,
  })  : _repository = repository,
        _favoritesRepository = favoritesRepository,
        super(HomeState.initial()) {
    on<HomeLoadPartners>(_onLoadPartners);
    on<HomeLoadMore>(_onLoadMore);
    on<HomeApplyFilter>(_onApplyFilter);
    on<HomeResetFilter>(_onResetFilter);
    on<HomeSearch>(_onSearch);
    on<HomeToggleFavorite>(_onToggleFavorite);
  }

  /// Load partners with current filter
  Future<void> _onLoadPartners(
    HomeLoadPartners event,
    Emitter<HomeState> emit,
  ) async {
    try {
      if (event.refresh || state.status == HomeStatus.initial) {
        emit(state.copyWith(status: HomeStatus.loading, clearError: true));
      }

      final response = await _repository.searchPartners(
        page: 1,
        limit: _pageSize,
        serviceType: state.filter.serviceType,
        gender: state.filter.gender,
        minAge: state.filter.minAge,
        maxAge: state.filter.maxAge,
        minRate: state.filter.minRate,
        maxRate: state.filter.maxRate,
        radius: state.filter.radius,
        city: state.filter.city,
        district: state.filter.district,
        verifiedOnly: state.filter.verifiedOnly ? true : null,
        availableNow: state.filter.availableNow ? true : null,
        sortBy: state.filter.sortBy,
      );

      emit(state.copyWith(
        status: HomeStatus.success,
        partners: response.partners,
        currentPage: response.page,
        totalPages: response.totalPages,
        hasMore: response.hasNextPage,
        clearError: true,
      ));
    } catch (e) {
      debugPrint('HomeBloc: Load partners error: $e');
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  /// Load more partners (pagination)
  Future<void> _onLoadMore(
    HomeLoadMore event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    try {
      emit(state.copyWith(status: HomeStatus.loadingMore));

      final nextPage = state.currentPage + 1;
      final response = await _repository.searchPartners(
        page: nextPage,
        limit: _pageSize,
        serviceType: state.filter.serviceType,
        gender: state.filter.gender,
        minAge: state.filter.minAge,
        maxAge: state.filter.maxAge,
        minRate: state.filter.minRate,
        maxRate: state.filter.maxRate,
        radius: state.filter.radius,
        city: state.filter.city,
        district: state.filter.district,
        verifiedOnly: state.filter.verifiedOnly ? true : null,
        availableNow: state.filter.availableNow ? true : null,
        sortBy: state.filter.sortBy,
      );

      emit(state.copyWith(
        status: HomeStatus.success,
        partners: [...state.partners, ...response.partners],
        currentPage: response.page,
        totalPages: response.totalPages,
        hasMore: response.hasNextPage,
      ));
    } catch (e) {
      debugPrint('HomeBloc: Load more error: $e');
      emit(state.copyWith(
        status: HomeStatus.success,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  /// Apply filter and reload partners
  Future<void> _onApplyFilter(
    HomeApplyFilter event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(
      filter: event.filter,
      status: HomeStatus.loading,
    ));

    add(const HomeLoadPartners(refresh: true));
  }

  /// Reset filter and reload
  Future<void> _onResetFilter(
    HomeResetFilter event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(
      filter: HomeFilter.empty,
      status: HomeStatus.loading,
    ));

    add(const HomeLoadPartners(refresh: true));
  }

  /// Search partners by query
  Future<void> _onSearch(
    HomeSearch event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading, clearError: true));

      final response = await _repository.searchPartners(
        page: 1,
        limit: _pageSize,
        query: event.query,
        serviceType: state.filter.serviceType,
        gender: state.filter.gender,
        sortBy: state.filter.sortBy,
      );

      emit(state.copyWith(
        status: HomeStatus.success,
        partners: response.partners,
        currentPage: response.page,
        totalPages: response.totalPages,
        hasMore: response.hasNextPage,
        clearError: true,
      ));
    } catch (e) {
      debugPrint('HomeBloc: Search error: $e');
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: getErrorMessage(e),
      ));
    }
  }

  /// Toggle favorite partner
  Future<void> _onToggleFavorite(
    HomeToggleFavorite event,
    Emitter<HomeState> emit,
  ) async {
    if (_favoritesRepository == null) return;

    final isFavorite = state.favoriteIds.contains(event.partnerId);
    // Optimistic update
    final updatedFavorites = Set<String>.from(state.favoriteIds);
    if (isFavorite) {
      updatedFavorites.remove(event.partnerId);
    } else {
      updatedFavorites.add(event.partnerId);
    }
    emit(state.copyWith(favoriteIds: updatedFavorites));

    try {
      if (isFavorite) {
        await _favoritesRepository.removeFavorite(event.partnerId);
      } else {
        await _favoritesRepository.addFavorite(event.partnerId);
      }
    } catch (e) {
      // Revert on error
      debugPrint('HomeBloc: Toggle favorite error: $e');
      emit(state.copyWith(favoriteIds: state.favoriteIds));
    }
  }
}
