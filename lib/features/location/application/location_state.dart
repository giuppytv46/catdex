import 'package:catdex/features/location/domain/entities/catdex_location.dart';

enum LocationStatus {
  idle,
  requestingPermission,
  locating,
  located,
  denied,
  disabled,
  failure,
}

class LocationState {
  const LocationState({
    required this.status,
    this.location,
    this.message,
  });

  const LocationState.idle()
    : status = LocationStatus.idle,
      location = null,
      message = null;

  final LocationStatus status;
  final CatDexLocation? location;
  final String? message;
}
