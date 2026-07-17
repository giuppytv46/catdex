import 'dart:async';

import 'package:catdex/features/location/application/discovery_location_capture_service.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/location/domain/repositories/location_privacy_preferences_repository.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicitly disabled collection never requests permission', () async {
    final location = _FakeLocationRepository();
    final service = DiscoveryLocationCaptureService(
      privacyRepository: _FakePrivacyRepository(
        const LocationPrivacyPreferences(
          locationCollectionEnabled: false,
          locationPrecisionMode: LocationPrecisionMode.approximate,
          rememberLocationChoice: true,
          locationConsentVersion: null,
          lastPermissionStatus: LocationPermissionStatus.denied,
        ),
      ),
      locationRepository: location,
    );

    final outcome = await service.captureForDiscovery();

    expect(outcome.location, isNull);
    expect(location.checkPermissionCalls, 0);
    expect(location.requestPermissionCalls, 0);
    expect(location.currentLocationCalls, 0);
  });

  test(
    'granted OS permission automatically captures complete GPS metadata',
    () async {
      final location = _FakeLocationRepository();
      final service = DiscoveryLocationCaptureService(
        privacyRepository: _FakePrivacyRepository(
          const LocationPrivacyPreferences.defaults(),
        ),
        locationRepository: location,
      );

      final outcome = await service.captureForDiscovery();

      expect(outcome.location?.latitude, 45.46);
      expect(outcome.location?.longitude, 9.19);
      expect(outcome.location?.horizontalAccuracyMeters, 1500);
      expect(outcome.location?.capturedAt, DateTime.utc(2026, 7, 16));
      expect(outcome.locationConsentVersion, 'map-v2-os-permission');
      expect(location.requestPermissionCalls, 0);
      expect(location.currentLocationCalls, 1);
    },
  );

  test('permission denied returns typed failure without locating', () async {
    final location = _FakeLocationRepository(
      checkPermissionResult: LocationPermissionStatus.denied,
      requestPermissionResult: LocationPermissionStatus.denied,
    );
    final service = DiscoveryLocationCaptureService(
      privacyRepository: _FakePrivacyRepository(_enabledPreferences()),
      locationRepository: location,
    );

    final outcome = await service.captureForDiscovery();

    expect(outcome.location, isNull);
    expect(outcome.failureReason, LocationFailureReason.permissionDenied);
    expect(location.requestPermissionCalls, 1);
    expect(location.currentLocationCalls, 0);
  });

  test('remembered denial is not requested repeatedly', () async {
    final location = _FakeLocationRepository(
      checkPermissionResult: LocationPermissionStatus.denied,
    );
    final service = DiscoveryLocationCaptureService(
      privacyRepository: _FakePrivacyRepository(
        _enabledPreferences(
          lastPermissionStatus: LocationPermissionStatus.denied,
        ),
      ),
      locationRepository: location,
    );

    await service.captureForDiscovery();
    await service.captureForDiscovery();

    expect(location.requestPermissionCalls, 0);
  });

  test('timeout returns failure and does not throw', () async {
    final location = _FakeLocationRepository(neverCompletes: true);
    final service = DiscoveryLocationCaptureService(
      privacyRepository: _FakePrivacyRepository(_enabledPreferences()),
      locationRepository: location,
      timeout: const Duration(milliseconds: 5),
    );

    final outcome = await service.captureForDiscovery();

    expect(outcome.location, isNull);
    expect(outcome.failureReason, LocationFailureReason.timeout);
  });

  test('approximate capture never persists full precision', () async {
    final location = _FakeLocationRepository();
    final service = DiscoveryLocationCaptureService(
      privacyRepository: _FakePrivacyRepository(_enabledPreferences()),
      locationRepository: location,
    );

    final outcome = await service.captureForDiscovery();

    expect(outcome.location?.latitude, 45.46);
    expect(outcome.location?.longitude, 9.19);
    expect(outcome.location?.isApproximate, isTrue);
  });

  test('precise coordinates are not printed in logs', () async {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = previousDebugPrint);
    final service = DiscoveryLocationCaptureService(
      privacyRepository: _FakePrivacyRepository(
        _enabledPreferences(precision: LocationPrecisionMode.precise),
      ),
      locationRepository: _FakeLocationRepository(),
    );

    await service.captureForDiscovery();

    final logs = messages.join('\n');
    expect(logs, isNot(contains('45.464237')));
    expect(logs, isNot(contains('9.189982')));
  });
}

LocationPrivacyPreferences _enabledPreferences({
  LocationPrecisionMode precision = LocationPrecisionMode.approximate,
  LocationPermissionStatus lastPermissionStatus =
      LocationPermissionStatus.notDetermined,
}) {
  return LocationPrivacyPreferences(
    locationCollectionEnabled: true,
    locationPrecisionMode: precision,
    rememberLocationChoice: true,
    locationConsentVersion: 'location-v1',
    lastPermissionStatus: lastPermissionStatus,
  );
}

class _FakePrivacyRepository implements LocationPrivacyPreferencesRepository {
  _FakePrivacyRepository(this.preferences);

  LocationPrivacyPreferences preferences;

  @override
  Future<LocationPrivacyPreferences> getPreferences() async => preferences;

  @override
  Future<void> savePreferences(
    LocationPrivacyPreferences locationPreferences,
  ) async {
    preferences = locationPreferences;
  }
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository({
    this.checkPermissionResult = LocationPermissionStatus.granted,
    this.requestPermissionResult = LocationPermissionStatus.granted,
    this.neverCompletes = false,
  });

  final LocationPermissionStatus checkPermissionResult;
  final LocationPermissionStatus requestPermissionResult;
  final bool neverCompletes;
  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  int currentLocationCalls = 0;

  @override
  Future<bool> checkServiceEnabled() async => true;

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    checkPermissionCalls += 1;
    return checkPermissionResult;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    requestPermissionCalls += 1;
    return requestPermissionResult;
  }

  @override
  Future<LocationServiceResult> getCurrentLocation() {
    currentLocationCalls += 1;
    if (neverCompletes) return Completer<LocationServiceResult>().future;
    return Future.value(
      LocationServiceSuccess(
        CatDiscoveryLocation.tryCreate(
          latitude: 45.464237,
          longitude: 9.189982,
          horizontalAccuracyMeters: 8,
          capturedAt: DateTime.utc(2026, 7, 16),
          source: CatDiscoveryLocationSource.gps,
        )!,
      ),
    );
  }

  @override
  Future<LocationServiceResult> getLastKnownLocation() {
    return getCurrentLocation();
  }
}
