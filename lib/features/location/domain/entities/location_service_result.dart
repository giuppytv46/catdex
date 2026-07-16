import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';

enum LocationFailureReason {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unavailable,
  unsupportedPlatform,
  invalidCoordinates,
}

sealed class LocationServiceResult {
  const LocationServiceResult();
}

class LocationServiceSuccess extends LocationServiceResult {
  const LocationServiceSuccess(this.location);

  final CatDiscoveryLocation location;
}

class LocationServiceFailure extends LocationServiceResult {
  const LocationServiceFailure(this.reason);

  final LocationFailureReason reason;
}
