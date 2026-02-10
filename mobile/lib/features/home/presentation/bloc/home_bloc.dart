import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/home_repository.dart';
import '../../domain/home_filter.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Home BLoC - Manages home page state
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository;
  static const int _pageSize = 20;

  HomeBloc({required HomeRepository repository})
      : _repository = repository,
        super(HomeState.initial()) {
    on<HomeLoadPartners>(_onLoadPartners);
    on<HomeLoadMore>(_onLoadMore);
    on<HomeApplyFilter>(_onApplyFilter);
    on<HomeResetFilter>(_onResetFilter);
  }

  /// Load partners with current filter
  Future<void> _onLoadPartners(
    HomeLoadPartners event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // If refreshing, show loading state
      if (event.refresh || state.status == HomeStatus.initial) {
        emit(state.copyWith(status: HomeStatus.loading));
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
        errorMessage: null,
      ));
    } catch (e) {
      debugPrint('HomeBloc: Load partners error: $e');
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: _getErrorMessage(e),
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
        status: HomeStatus.success, // Keep success to show existing data
        errorMessage: _getErrorMessage(e),
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

    // Reload with new filter
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

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
    }
    if (error.toString().contains('TimeoutException')) {
      return 'Kết nối quá chậm. Vui lòng thử lại.';
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
