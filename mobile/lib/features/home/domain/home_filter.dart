import 'package:equatable/equatable.dart';

/// Home filter parameters
class HomeFilter extends Equatable {
  final String? serviceType;
  final String? gender;
  final int? minAge;
  final int? maxAge;
  final int? minRate;
  final int? maxRate;
  final int? radius;
  final String? cityId; // Province UUID for API
  final String? districtId; // District UUID for API
  final String? city; // Display name
  final String? district; // Display name
  final bool verifiedOnly;
  final bool availableNow;
  final String sortBy;

  const HomeFilter({
    this.serviceType,
    this.gender,
    this.minAge,
    this.maxAge,
    this.minRate,
    this.maxRate,
    this.radius,
    this.cityId,
    this.districtId,
    this.city,
    this.district,
    this.verifiedOnly = false,
    this.availableNow = false,
    this.sortBy = 'rating',
  });

  /// Empty filter
  static const HomeFilter empty = HomeFilter();

  /// Check if filter is empty (excluding mandatory location)
  bool get isEmpty =>
      serviceType == null &&
      gender == null &&
      minAge == null &&
      maxAge == null &&
      minRate == null &&
      maxRate == null &&
      radius == null &&
      !verifiedOnly &&
      !availableNow &&
      sortBy == 'rating';

  HomeFilter copyWith({
    String? serviceType,
    String? gender,
    int? minAge,
    int? maxAge,
    int? minRate,
    int? maxRate,
    int? radius,
    String? cityId,
    String? districtId,
    String? city,
    String? district,
    bool? verifiedOnly,
    bool? availableNow,
    String? sortBy,
  }) {
    return HomeFilter(
      serviceType: serviceType ?? this.serviceType,
      gender: gender ?? this.gender,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minRate: minRate ?? this.minRate,
      maxRate: maxRate ?? this.maxRate,
      radius: radius ?? this.radius,
      cityId: cityId ?? this.cityId,
      districtId: districtId ?? this.districtId,
      city: city ?? this.city,
      district: district ?? this.district,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      availableNow: availableNow ?? this.availableNow,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Create filter with cleared optional fields
  HomeFilter clear({
    bool clearServiceType = false,
    bool clearGender = false,
    bool clearAgeRange = false,
    bool clearPriceRange = false,
    bool clearRadius = false,
    bool clearCity = false,
    bool clearDistrict = false,
    bool clearLocation = false,
  }) {
    return HomeFilter(
      serviceType: clearServiceType ? null : serviceType,
      gender: clearGender ? null : gender,
      minAge: clearAgeRange ? null : minAge,
      maxAge: clearAgeRange ? null : maxAge,
      minRate: clearPriceRange ? null : minRate,
      maxRate: clearPriceRange ? null : maxRate,
      radius: clearRadius ? null : radius,
      cityId: (clearCity || clearLocation) ? null : cityId,
      districtId: (clearDistrict || clearLocation) ? null : districtId,
      city: (clearCity || clearLocation) ? null : city,
      district: (clearDistrict || clearLocation) ? null : district,
      verifiedOnly: verifiedOnly,
      availableNow: availableNow,
      sortBy: sortBy,
    );
  }

  /// Clear all filters except location
  HomeFilter clearAllExceptLocation() {
    return HomeFilter(
      cityId: cityId,
      districtId: districtId,
      city: city,
      district: district,
    );
  }

  /// Location display string
  String? get locationDisplay {
    if (city == null && district == null) return null;
    if (district != null && city != null) return '$district, $city';
    return city ?? district;
  }

  @override
  List<Object?> get props => [
    serviceType,
    gender,
    minAge,
    maxAge,
    minRate,
    maxRate,
    radius,
    cityId,
    districtId,
    city,
    district,
    verifiedOnly,
    availableNow,
    sortBy,
  ];
}
