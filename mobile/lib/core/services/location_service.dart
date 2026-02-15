import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Result of a location detection
class LocationInfo {
  final String? city;
  final String? district;
  final double latitude;
  final double longitude;

  const LocationInfo({
    this.city,
    this.district,
    required this.latitude,
    required this.longitude,
  });

  /// Display string like "Quận 1, TP Hồ Chí Minh"
  String get displayName {
    if (district != null && city != null) return '$district, $city';
    return city ?? district ?? 'Không xác định';
  }
}

/// Service to detect user's current location and reverse-geocode it
class LocationService {
  LocationService._();
  static final LocationService _instance = LocationService._();
  static LocationService get instance => _instance;

  LocationInfo? _cached;
  DateTime? _cachedAt;
  static const _cacheDuration = Duration(minutes: 10);

  /// Whether the cached location is still valid
  bool get _isCacheValid =>
      _cached != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _cacheDuration;

  /// Detect current location and reverse-geocode to city/district.
  /// Returns null if permission denied or location unavailable.
  Future<LocationInfo?> detectCurrentLocation() async {
    // Return cache if still valid
    if (_isCacheValid) return _cached;

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services disabled');
        return null;
      }

      // Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission denied forever');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint(
        'LocationService: Position detected: ${position.latitude}, ${position.longitude}',
      );

      // Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? city;
      String? district;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // administrativeArea = province/city (e.g. "Thành phố Hồ Chí Minh")
        // subAdministrativeArea = district (e.g. "Quận 1")
        city = place.administrativeArea;
        district = place.subAdministrativeArea ?? place.locality;

        debugPrint(
          'LocationService: Detected → $district, $city '
          '(${position.latitude}, ${position.longitude})',
        );
      }

      _cached = LocationInfo(
        city: city,
        district: district,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _cachedAt = DateTime.now();

      return _cached;
    } catch (e) {
      debugPrint('LocationService: Error detecting location: $e');
      return null;
    }
  }

  /// Clear cached location
  void clearCache() {
    _cached = null;
    _cachedAt = null;
  }
}
