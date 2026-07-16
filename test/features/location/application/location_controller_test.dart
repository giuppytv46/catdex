import 'package:catdex/features/location/application/location_controller.dart';
import 'package:catdex/features/location/application/location_state.dart';
import 'package:catdex/features/location/domain/entities/catdex_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationController', () {
    test('starts idle', () {
      final container = _container();
      addTearDown(container.dispose);

      expect(
        container.read(locationControllerProvider).status,
        LocationStatus.idle,
      );
    });

    test('moves to located with coordinates and place details', () async {
      final container = _container();
      addTearDown(container.dispose);

      await container
          .read(locationControllerProvider.notifier)
          .requestCurrentLocation();

      final state = container.read(locationControllerProvider);

      expect(state.status, LocationStatus.located);
      expect(state.location?.city, 'Milan');
      expect(state.message, isNull);
    });

    test('moves to denied when permission is not granted', () async {
      final container = _container(
        repository: const _FakeLocationRepository(
          permissionStatus: LocationPermissionStatus.denied,
        ),
      );
      addTearDown(container.dispose);

      await container
          .read(locationControllerProvider.notifier)
          .requestCurrentLocation();

      final state = container.read(locationControllerProvider);

      expect(state.status, LocationStatus.denied);
      expect(state.message, 'Location unavailable');
    });

    test('moves to disabled when location services are off', () async {
      final container = _container(
        repository: const _FakeLocationRepository(serviceEnabled: false),
      );
      addTearDown(container.dispose);

      await container
          .read(locationControllerProvider.notifier)
          .requestCurrentLocation();

      final state = container.read(locationControllerProvider);

      expect(state.status, LocationStatus.disabled);
      expect(state.message, 'Location services are turned off.');
    });

    test(
      'keeps coordinates when reverse geocoding has no place details',
      () async {
        final container = _container(
          repository: const _FakeLocationRepository(
            location: CatDexLocation(latitude: 45.4642, longitude: 9.19),
          ),
        );
        addTearDown(container.dispose);

        await container
            .read(locationControllerProvider.notifier)
            .requestCurrentLocation();

        final state = container.read(locationControllerProvider);

        expect(state.status, LocationStatus.located);
        expect(state.location?.hasPlaceDetails, isFalse);
        expect(state.location?.displayLabel, isEmpty);
      },
    );

    test('moves to failure when locating throws', () async {
      final container = _container(
        repository: const _FakeLocationRepository(throwOnLocate: true),
      );
      addTearDown(container.dispose);

      await container
          .read(locationControllerProvider.notifier)
          .requestCurrentLocation();

      final state = container.read(locationControllerProvider);

      expect(state.status, LocationStatus.failure);
      expect(state.message, 'Location unavailable');
    });
  });
}

ProviderContainer _container({_FakeLocationRepository? repository}) {
  return ProviderContainer(
    overrides: [
      locationRepositoryProvider.overrideWithValue(
        repository ?? const _FakeLocationRepository(),
      ),
    ],
  );
}

class _FakeLocationRepository implements LocationRepository {
  const _FakeLocationRepository({
    this.serviceEnabled = true,
    this.permissionStatus = LocationPermissionStatus.granted,
    this.location = const CatDexLocation(
      latitude: 45.4642,
      longitude: 9.19,
      city: 'Milan',
      region: 'Lombardy',
      country: 'Italy',
    ),
    this.throwOnLocate = false,
  });

  final bool serviceEnabled;
  final LocationPermissionStatus permissionStatus;
  final CatDexLocation location;
  final bool throwOnLocate;

  @override
  Future<bool> checkServiceEnabled() async {
    return serviceEnabled;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    return permissionStatus;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    return permissionStatus;
  }

  @override
  Future<LocationServiceResult> getCurrentLocation() async {
    if (throwOnLocate) {
      throw StateError('location unavailable');
    }

    return LocationServiceSuccess(location);
  }

  @override
  Future<LocationServiceResult> getLastKnownLocation() async {
    return LocationServiceSuccess(location);
  }
}
