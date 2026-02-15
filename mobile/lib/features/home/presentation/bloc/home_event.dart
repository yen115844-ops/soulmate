import 'package:equatable/equatable.dart';

import '../../domain/home_filter.dart';

/// Home BLoC Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load partners with current filter
class HomeLoadPartners extends HomeEvent {
  final bool refresh;

  const HomeLoadPartners({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// Load more partners (pagination)
class HomeLoadMore extends HomeEvent {
  const HomeLoadMore();
}

/// Apply filter
class HomeApplyFilter extends HomeEvent {
  final HomeFilter filter;

  const HomeApplyFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Reset filter to default
class HomeResetFilter extends HomeEvent {
  const HomeResetFilter();
}

/// Search partners by query
class HomeSearch extends HomeEvent {
  final String query;

  const HomeSearch(this.query);

  @override
  List<Object?> get props => [query];
}

/// Toggle favorite partner
class HomeToggleFavorite extends HomeEvent {
  final String partnerId;

  const HomeToggleFavorite(this.partnerId);

  @override
  List<Object?> get props => [partnerId];
}

/// Detect user location via GPS and match against provinces
class HomeDetectLocation extends HomeEvent {
  const HomeDetectLocation();
}

/// User manually selected a city from the picker
class HomeSelectCity extends HomeEvent {
  final String cityId;
  final String cityName;

  const HomeSelectCity({required this.cityId, required this.cityName});

  @override
  List<Object?> get props => [cityId, cityName];
}

/// Retry location detection (clear cache and re-detect)
class HomeRetryLocation extends HomeEvent {
  const HomeRetryLocation();
}
