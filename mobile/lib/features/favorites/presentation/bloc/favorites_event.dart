import 'package:equatable/equatable.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class FavoritesLoadRequested extends FavoritesEvent {
  final int page;
  final int limit;

  const FavoritesLoadRequested({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class FavoritesRefreshRequested extends FavoritesEvent {
  const FavoritesRefreshRequested();
}

class FavoriteRemoveRequested extends FavoritesEvent {
  final String partnerId;

  const FavoriteRemoveRequested(this.partnerId);

  @override
  List<Object?> get props => [partnerId];
}

class FavoriteAddRequested extends FavoritesEvent {
  final String partnerId;

  const FavoriteAddRequested(this.partnerId);

  @override
  List<Object?> get props => [partnerId];
}
