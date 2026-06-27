import 'package:catdex/features/location/domain/entities/catdex_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final currentPermission = await Geolocator.checkPermission();
    final permission = switch (currentPermission) {
      LocationPermission.denied => await Geolocator.requestPermission(),
      _ => currentPermission,
    };

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.permanentlyDenied,
      LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
    };
  }

  @override
  Future<CatDexLocation> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final placeDetails = await _reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return CatDexLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      city: placeDetails.city,
      region: placeDetails.region,
      country: placeDetails.country,
    );
  }

  Future<_PlaceDetails> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return const _PlaceDetails();
      }

      final placemark = placemarks.first;

      return _PlaceDetails(
        city: _firstNotBlank([
          placemark.locality,
          placemark.subAdministrativeArea,
        ]),
        region: _firstNotBlank([
          placemark.administrativeArea,
          placemark.subAdministrativeArea,
        ]),
        country: _firstNotBlank([placemark.country]),
      );
    } on Object {
      return const _PlaceDetails();
    }
  }

  String? _firstNotBlank(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}

class _PlaceDetails {
  const _PlaceDetails({
    this.city,
    this.region,
    this.country,
  });

  final String? city;
  final String? region;
  final String? country;
}
