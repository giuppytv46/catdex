import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  @override
  Future<bool> checkServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } on Object {
      return false;
    }
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    try {
      return _permissionStatus(await Geolocator.checkPermission());
    } on Object {
      return LocationPermissionStatus.unsupported;
    }
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      return _permissionStatus(await Geolocator.requestPermission());
    } on Object {
      return LocationPermissionStatus.unsupported;
    }
  }

  @override
  Future<LocationServiceResult> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return _resultFor(position);
    } on LocationServiceDisabledException {
      return const LocationServiceFailure(
        LocationFailureReason.serviceDisabled,
      );
    } on PermissionDeniedException {
      return const LocationServiceFailure(
        LocationFailureReason.permissionDenied,
      );
    } on Object {
      return const LocationServiceFailure(LocationFailureReason.unavailable);
    }
  }

  @override
  Future<LocationServiceResult> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        return const LocationServiceFailure(LocationFailureReason.unavailable);
      }
      return _resultFor(position);
    } on Object {
      return const LocationServiceFailure(LocationFailureReason.unavailable);
    }
  }

  LocationServiceResult _resultFor(Position position) {
    final location = CatDiscoveryLocation.tryCreate(
      latitude: position.latitude,
      longitude: position.longitude,
      horizontalAccuracyMeters: position.accuracy,
      capturedAt: position.timestamp,
      source: CatDiscoveryLocationSource.gps,
    );
    if (location == null) {
      return const LocationServiceFailure(
        LocationFailureReason.invalidCoordinates,
      );
    }
    return LocationServiceSuccess(location);
  }

  LocationPermissionStatus _permissionStatus(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationPermissionStatus.granted,
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.permanentlyDenied,
      LocationPermission.unableToDetermine =>
        LocationPermissionStatus.notDetermined,
    };
  }
}
