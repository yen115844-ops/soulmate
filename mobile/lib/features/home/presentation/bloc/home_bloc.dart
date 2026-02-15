import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/base_repository.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/data/models/master_data_models.dart';
import '../../../favorites/data/favorites_repository.dart';
import '../../data/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Home BLoC - Manages home page state and location detection
class HomeBloc extends Bloc<HomeEvent, HomeState> with BaseRepositoryMixin {
  final HomeRepository _repository;
  final FavoritesRepository? _favoritesRepository;
  static const int _pageSize = 20;

  HomeBloc({
    required HomeRepository repository,
    FavoritesRepository? favoritesRepository,
  }) : _repository = repository,
       _favoritesRepository = favoritesRepository,
       super(HomeState.initial()) {
    on<HomeLoadPartners>(_onLoadPartners);
    on<HomeLoadMore>(_onLoadMore);
    on<HomeApplyFilter>(_onApplyFilter);
    on<HomeResetFilter>(_onResetFilter);
    on<HomeSearch>(_onSearch);
    on<HomeToggleFavorite>(_onToggleFavorite);
    on<HomeDetectLocation>(_onDetectLocation);
    on<HomeSelectCity>(_onSelectCity);
    on<HomeRetryLocation>(_onRetryLocation);
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
        provinceId: state.filter.provinceId,
        districtId: state.filter.districtId,
        verifiedOnly: state.filter.verifiedOnly ? true : null,
        availableNow: state.filter.availableNow ? true : null,
        sortBy: state.filter.sortBy,
      );

      emit(
        state.copyWith(
          status: HomeStatus.success,
          partners: response.partners,
          currentPage: response.page,
          totalPages: response.totalPages,
          hasMore: response.hasNextPage,
          clearError: true,
        ),
      );
    } catch (e) {
      debugPrint('HomeBloc: Load partners error: $e');
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: getErrorMessage(e),
        ),
      );
    }
  }

  /// Load more partners (pagination)
  Future<void> _onLoadMore(HomeLoadMore event, Emitter<HomeState> emit) async {
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
        provinceId: state.filter.provinceId,
        districtId: state.filter.districtId,
        verifiedOnly: state.filter.verifiedOnly ? true : null,
        availableNow: state.filter.availableNow ? true : null,
        sortBy: state.filter.sortBy,
      );

      emit(
        state.copyWith(
          status: HomeStatus.success,
          partners: [...state.partners, ...response.partners],
          currentPage: response.page,
          totalPages: response.totalPages,
          hasMore: response.hasNextPage,
        ),
      );
    } catch (e) {
      debugPrint('HomeBloc: Load more error: $e');
      emit(
        state.copyWith(
          status: HomeStatus.success,
          errorMessage: getErrorMessage(e),
        ),
      );
    }
  }

  /// Apply filter and reload partners
  Future<void> _onApplyFilter(
    HomeApplyFilter event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(filter: event.filter, status: HomeStatus.loading));

    add(const HomeLoadPartners(refresh: true));
  }

  /// Reset filter and reload
  Future<void> _onResetFilter(
    HomeResetFilter event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(
        filter: state.filter.clearAllExceptLocation(),
        status: HomeStatus.loading,
      ),
    );

    add(const HomeLoadPartners(refresh: true));
  }

  /// Search partners by query
  Future<void> _onSearch(HomeSearch event, Emitter<HomeState> emit) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading, clearError: true));

      final response = await _repository.searchPartners(
        page: 1,
        limit: _pageSize,
        query: event.query,
        serviceType: state.filter.serviceType,
        gender: state.filter.gender,
        minAge: state.filter.minAge,
        maxAge: state.filter.maxAge,
        minRate: state.filter.minRate,
        maxRate: state.filter.maxRate,
        radius: state.filter.radius,
        provinceId: state.filter.provinceId,
        districtId: state.filter.districtId,
        verifiedOnly: state.filter.verifiedOnly ? true : null,
        availableNow: state.filter.availableNow ? true : null,
        sortBy: state.filter.sortBy,
      );

      emit(
        state.copyWith(
          status: HomeStatus.success,
          partners: response.partners,
          currentPage: response.page,
          totalPages: response.totalPages,
          hasMore: response.hasNextPage,
          clearError: true,
        ),
      );
    } catch (e) {
      debugPrint('HomeBloc: Search error: $e');
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: getErrorMessage(e),
        ),
      );
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

  // ───────────────────────── Location Detection ─────────────────────────

  /// Detect user location via GPS, match against provinces, and apply filter
  Future<void> _onDetectLocation(
    HomeDetectLocation event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(locationStatus: LocationDetectionStatus.detecting));

    // Step 1: Load provinces from API
    final provinces = await _repository.getProvinces();
    emit(state.copyWith(provinces: provinces));

    // Step 2: Detect GPS location
    final info = await LocationService.instance.detectCurrentLocation();

    if (info == null) {
      // Permission denied or location unavailable → default to first province
      final firstProvince = provinces.isNotEmpty ? provinces.first : null;
      if (firstProvince != null) {
        final newFilter = state.filter.copyWith(
          provinceId: firstProvince.id,
          city: firstProvince.name,
        );
        emit(
          state.copyWith(
            locationStatus: LocationDetectionStatus.permissionDenied,
            filter: newFilter,
          ),
        );
        add(const HomeLoadPartners(refresh: true));
      } else {
        emit(
          state.copyWith(
            locationStatus: LocationDetectionStatus.permissionDenied,
          ),
        );
      }
      return;
    }

    // Step 3: Match geocoded names against province data
    await _matchAndApplyLocation(info, provinces, emit);
  }

  /// Retry location detection (clears cache first)
  Future<void> _onRetryLocation(
    HomeRetryLocation event,
    Emitter<HomeState> emit,
  ) async {
    LocationService.instance.clearCache();
    add(const HomeDetectLocation());
  }

  /// User manually selected a city from the picker
  Future<void> _onSelectCity(
    HomeSelectCity event,
    Emitter<HomeState> emit,
  ) async {
    final newFilter = state.filter
        .clear(clearCity: true, clearDistrict: true)
        .copyWith(provinceId: event.cityId, city: event.cityName);
    emit(
      state.copyWith(
        filter: newFilter,
        locationStatus: LocationDetectionStatus.detected,
      ),
    );
    add(const HomeLoadPartners(refresh: true));
  }

  /// Match geocoded city/district against API data and apply to filter
  Future<void> _matchAndApplyLocation(
    LocationInfo info,
    List<ProvinceModel> provinces,
    Emitter<HomeState> emit,
  ) async {
    final rawCity = info.city;
    final rawDistrict = info.district;

    // Match city against provinces list
    ProvinceModel? matchedProvince;
    if (rawCity != null && provinces.isNotEmpty) {
      for (final p in provinces) {
        if (_fuzzyMatch(rawCity, p.name)) {
          matchedProvince = p;
          break;
        }
      }
    }

    // Match district if we found the province
    DistrictModel? matchedDistrict;
    if (matchedProvince != null && rawDistrict != null) {
      final districts = await _repository.getDistrictsByProvinceId(
        matchedProvince.id,
      );
      for (final d in districts) {
        if (_fuzzyMatch(rawDistrict, d.name)) {
          matchedDistrict = d;
          break;
        }
      }
    }

    debugPrint(
      'HomeBloc: Location matched → '
      'city: "$rawCity" → "${matchedProvince?.name ?? "(không khớp)"}", '
      'district: "$rawDistrict" → "${matchedDistrict?.name ?? "(không khớp)"}"',
    );

    if (matchedProvince != null) {
      final newFilter = state.filter.copyWith(
        provinceId: matchedProvince.id,
        city: matchedProvince.name,
        districtId: matchedDistrict?.id,
        district: matchedDistrict?.name,
      );
      emit(
        state.copyWith(
          filter: newFilter,
          locationStatus: LocationDetectionStatus.detected,
        ),
      );
    } else {
      // GPS worked but no matching city → default to first province
      final firstProvince = provinces.isNotEmpty ? provinces.first : null;
      if (firstProvince != null) {
        final newFilter = state.filter.copyWith(
          provinceId: firstProvince.id,
          city: firstProvince.name,
        );
        emit(
          state.copyWith(
            filter: newFilter,
            locationStatus: LocationDetectionStatus.permissionDenied,
          ),
        );
      } else {
        emit(
          state.copyWith(
            locationStatus: LocationDetectionStatus.permissionDenied,
          ),
        );
      }
      debugPrint(
        'HomeBloc: No matching city for "$rawCity". '
        'Defaulted to "${firstProvince?.name ?? "null"}".',
      );
    }

    add(const HomeLoadPartners(refresh: true));
  }

  // ───────────────────────── Fuzzy Matching Utils ─────────────────────────

  /// Fuzzy match: normalize both strings and check if they match
  bool _fuzzyMatch(String geocoded, String apiName) {
    final a = _normalize(geocoded);
    final b = _normalize(apiName);
    if (a == b) return true;
    if (b.contains(a) || a.contains(b)) return true;
    return false;
  }

  /// Normalize a Vietnamese location name for comparison
  String _normalize(String input) {
    var s = input.toLowerCase().trim();
    for (final prefix in [
      'thành phố ',
      'thanh pho ',
      'tỉnh ',
      'tinh ',
      'quận ',
      'quan ',
      'huyện ',
      'huyen ',
      'thị xã ',
      'thi xa ',
      'phường ',
      'phuong ',
      'xã ',
      'xa ',
      'tp. ',
      'tp ',
    ]) {
      if (s.startsWith(prefix)) {
        s = s.substring(prefix.length);
        break;
      }
    }
    s = _removeDiacritics(s);
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Remove Vietnamese diacritics
  String _removeDiacritics(String str) {
    const map = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };
    final buf = StringBuffer();
    for (final c in str.split('')) {
      buf.write(map[c] ?? c);
    }
    return buf.toString();
  }
}
