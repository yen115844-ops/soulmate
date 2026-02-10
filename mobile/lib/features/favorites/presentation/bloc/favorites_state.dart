import 'package:equatable/equatable.dart';

import '../../data/models/favorite_model.dart';

enum FavoritesStatus { initial, loading, loaded, error }

class FavoritesState extends Equatable {
  final FavoritesStatus status;
  final List<FavoritePartnerModel> favorites;
  final int total;
  final int page;
  final int limit;
  final bool hasReachedMax;
  final String? errorMessage;

  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.favorites = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoritePartnerModel>? favorites,
    int? total,
    int? page,
    int? limit,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      favorites: favorites ?? this.favorites,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, favorites, total, page, limit, hasReachedMax, errorMessage];
}
