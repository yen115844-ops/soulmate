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
  final String? city;
  final String? district;
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
    this.city,
    this.district,
    this.verifiedOnly = false,
    this.availableNow = false,
    this.sortBy = 'rating',
  });

  /// Empty filter
  static const HomeFilter empty = HomeFilter();

  /// Check if filter is empty
  bool get isEmpty =>
      serviceType == null &&
      gender == null &&
      minAge == null &&
      maxAge == null &&
      minRate == null &&
      maxRate == null &&
      radius == null &&
      city == null &&
      district == null &&
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
      city: (clearCity || clearLocation) ? null : city,
      district: (clearDistrict || clearLocation) ? null : district,
      verifiedOnly: verifiedOnly,
      availableNow: availableNow,
      sortBy: sortBy,
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
        city,
        district,
        verifiedOnly,
        availableNow,
        sortBy,
      ];
}
