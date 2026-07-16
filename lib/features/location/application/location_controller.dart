import 'package:catdex/features/location/application/location_state.dart';
import 'package:catdex/features/location/data/geolocator_location_repository.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/location/domain/entities/location_validation_result.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:catdex/features/location/domain/services/location_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationRepositoryProvider = Provider<LocationRepository>((_) {
  return const GeolocatorLocationRepository();
});

final locationValidatorProvider = Provider<LocationValidator>((_) {
  return const LocationValidator();
});

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(
      LocationController.new,
    );

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState.idle();
  }

  Future<void> requestCurrentLocation() async {
    state = const LocationState(status: LocationStatus.requestingPermission);

    try {
      final repository = ref.read(locationRepositoryProvider);
      final serviceEnabled = await repository.checkServiceEnabled();

      if (!serviceEnabled) {
        state = const LocationState(
          status: LocationStatus.disabled,
          message: 'Location services are turned off.',
        );
        return;
      }

      var permissionStatus = await repository.checkPermission();
      if (permissionStatus == LocationPermissionStatus.notDetermined ||
          permissionStatus == LocationPermissionStatus.denied) {
        permissionStatus = await repository.requestPermission();
      }

      if (permissionStatus != LocationPermissionStatus.granted) {
        state = const LocationState(
          status: LocationStatus.denied,
          message: 'Location unavailable',
        );
        return;
      }

      state = const LocationState(status: LocationStatus.locating);

      final result = await repository.getCurrentLocation();
      switch (result) {
        case LocationServiceSuccess(:final location):
          final validationResult = ref
              .read(locationValidatorProvider)
              .validate(location);
          switch (validationResult) {
            case ValidLocationValidationResult():
              state = LocationState(
                status: LocationStatus.located,
                location: location,
              );
            case InvalidLocationValidationResult(:final message):
              state = LocationState(
                status: LocationStatus.failure,
                message: message,
              );
          }
        case LocationServiceFailure():
          state = const LocationState(
            status: LocationStatus.failure,
            message: 'Location unavailable',
          );
      }
    } on Object {
      state = const LocationState(
        status: LocationStatus.failure,
        message: 'Location unavailable',
      );
    }
  }

  void reset() {
    state = const LocationState.idle();
  }
}
