import 'package:equatable/equatable.dart';

import '../../../../shared/data/models/master_data_models.dart';
import '../../../partner/domain/entities/partner_entity.dart';
import '../../domain/home_filter.dart';

/// Location detection status
enum LocationDetectionStatus {
  initial,
  detecting,
  detected,
  permissionDenied,
}

/// Home BLoC State
class HomeState extends Equatable {
  final HomeStatus status;
  final List<PartnerEntity> partners;
  final HomeFilter filter;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final String? errorMessage;
  final Set<String> favoriteIds;

  // Location detection
  final LocationDetectionStatus locationStatus;
  final List<ProvinceModel> provinces;

  const HomeState({
    this.status = HomeStatus.initial,
    this.partners = const [],
    this.filter = const HomeFilter(),
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.errorMessage,
    this.favoriteIds = const {},
    this.locationStatus = LocationDetectionStatus.initial,
    this.provinces = const [],
  });

  /// Initial state
  factory HomeState.initial() => const HomeState();

  /// Loading state
  bool get isLoading => status == HomeStatus.loading;

  /// Loading more state
  bool get isLoadingMore => status == HomeStatus.loadingMore;

  /// Has error
  bool get hasError => status == HomeStatus.error;

  /// Is success
  bool get isSuccess => status == HomeStatus.success;

  /// Is empty
  bool get isEmpty => isSuccess && partners.isEmpty;

  HomeState copyWith({
    HomeStatus? status,
    List<PartnerEntity>? partners,
    HomeFilter? filter,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    String? errorMessage,
    Set<String>? favoriteIds,
    bool clearError = false,
    LocationDetectionStatus? locationStatus,
    List<ProvinceModel>? provinces,
  }) {
    return HomeState(
      status: status ?? this.status,
      partners: partners ?? this.partners,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      favoriteIds: favoriteIds ?? this.favoriteIds,
      locationStatus: locationStatus ?? this.locationStatus,
      provinces: provinces ?? this.provinces,
    );
  }

  @override
  List<Object?> get props => [
        status,
        partners,
        filter,
        currentPage,
        totalPages,
        hasMore,
        errorMessage,
        favoriteIds,
        locationStatus,
        provinces,
      ];
}

/// Home Status
enum HomeStatus {
  initial,
  loading,
  loadingMore,
  success,
  error,
}
