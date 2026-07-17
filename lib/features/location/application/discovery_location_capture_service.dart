import 'dart:async';

import 'package:catdex/features/location/data/geolocator_location_repository.dart';
import 'package:catdex/features/location/data/shared_preferences_location_privacy_preferences_repository.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/location/domain/repositories/location_privacy_preferences_repository.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationPrivacyPreferencesRepositoryProvider =
    Provider<LocationPrivacyPreferencesRepository>((_) {
      return const SharedPreferencesLocationPrivacyPreferencesRepository();
    });

final discoveryLocationRepositoryProvider = Provider<LocationRepository>((_) {
  return const GeolocatorLocationRepository();
});

final discoveryLocationCaptureServiceProvider =
    Provider<DiscoveryLocationCaptureService>((ref) {
      return DiscoveryLocationCaptureService(
        privacyRepository: ref.watch(
          locationPrivacyPreferencesRepositoryProvider,
        ),
        locationRepository: ref.watch(discoveryLocationRepositoryProvider),
      );
    });

class DiscoveryLocationCaptureOutcome {
  const DiscoveryLocationCaptureOutcome({
    this.location,
    this.locationConsentVersion,
    this.failureReason,
  });

  final CatDiscoveryLocation? location;
  final String? locationConsentVersion;
  final LocationFailureReason? failureReason;
}

class DiscoveryLocationCaptureService {
  const DiscoveryLocationCaptureService({
    required LocationPrivacyPreferencesRepository privacyRepository,
    required LocationRepository locationRepository,
    this.timeout = const Duration(seconds: 4),
  }) : _privacyRepository = privacyRepository,
       _locationRepository = locationRepository;

  final LocationPrivacyPreferencesRepository _privacyRepository;
  final LocationRepository _locationRepository;
  final Duration timeout;

  Future<DiscoveryLocationCaptureOutcome> captureForDiscovery() async {
    final preferences = await _privacyRepository.getPreferences();
    debugPrint(
      'CATDEX_LOCATION_COLLECTION_ENABLED '
      '${preferences.locationCollectionEnabled}',
    );
    final explicitlyDisabled =
        preferences.rememberLocationChoice &&
        !preferences.locationCollectionEnabled;
    if (explicitlyDisabled) {
      return const DiscoveryLocationCaptureOutcome();
    }

    debugPrint('CATDEX_LOCATION_REQUEST_STARTED');
    if (!await _locationRepository.checkServiceEnabled()) {
      return _failure(
        LocationFailureReason.serviceDisabled,
        preferences.locationConsentVersion,
      );
    }

    var permission = await _locationRepository.checkPermission();
    debugPrint('CATDEX_LOCATION_PERMISSION_STATUS ${permission.name}');
    if (_canRequest(permission, preferences)) {
      permission = await _locationRepository.requestPermission();
      debugPrint('CATDEX_LOCATION_PERMISSION_STATUS ${permission.name}');
    }
    await _rememberPermission(preferences, permission);

    final permissionFailure = _permissionFailure(permission);
    if (permissionFailure != null) {
      return _failure(
        permissionFailure,
        preferences.locationConsentVersion,
      );
    }

    final result = await _locationRepository.getCurrentLocation().timeout(
      timeout,
      onTimeout: () => const LocationServiceFailure(
        LocationFailureReason.timeout,
      ),
    );
    switch (result) {
      case LocationServiceFailure(:final reason):
        return _failure(reason, preferences.locationConsentVersion);
      case LocationServiceSuccess(:final location):
        if (!location.hasValidCoordinates) {
          return _failure(
            LocationFailureReason.invalidCoordinates,
            preferences.locationConsentVersion,
          );
        }
        final timestampedLocation = _withCaptureTimestamp(location);
        final persistedLocation =
            preferences.locationPrecisionMode ==
                LocationPrecisionMode.approximate
            ? timestampedLocation.toApproximate()
            : timestampedLocation;
        if (persistedLocation.isApproximate) {
          debugPrint('CATDEX_LOCATION_APPROXIMATED');
        }
        debugPrint(
          'CATDEX_LOCATION_REQUEST_SUCCESS '
          'hasLocation=true approximate=${persistedLocation.isApproximate} '
          'accuracy=${_accuracyCategory(persistedLocation)}',
        );
        return DiscoveryLocationCaptureOutcome(
          location: persistedLocation,
          locationConsentVersion:
              preferences.locationConsentVersion ?? 'map-v2-os-permission',
        );
    }
  }

  CatDiscoveryLocation _withCaptureTimestamp(
    CatDiscoveryLocation location,
  ) {
    if (location.capturedAt != null) return location;
    return CatDiscoveryLocation.tryCreate(
          latitude: location.latitude,
          longitude: location.longitude,
          horizontalAccuracyMeters: location.horizontalAccuracyMeters,
          capturedAt: DateTime.now().toUtc(),
          source: location.source,
          locality: location.locality,
          administrativeArea: location.administrativeArea,
          countryCode: location.countryCode,
          isApproximate: location.isApproximate,
          schemaVersion: location.schemaVersion,
        ) ??
        location;
  }

  bool _canRequest(
    LocationPermissionStatus status,
    LocationPrivacyPreferences preferences,
  ) {
    if (status != LocationPermissionStatus.notDetermined &&
        status != LocationPermissionStatus.denied) {
      return false;
    }

    // The plugin reports `denied` both before the first request and after a
    // rejection. Persisting the last result lets saves request at most once.
    return preferences.lastPermissionStatus ==
        LocationPermissionStatus.notDetermined;
  }

  LocationFailureReason? _permissionFailure(
    LocationPermissionStatus permission,
  ) {
    return switch (permission) {
      LocationPermissionStatus.granted => null,
      LocationPermissionStatus.permanentlyDenied =>
        LocationFailureReason.permissionDeniedForever,
      LocationPermissionStatus.unsupported =>
        LocationFailureReason.unsupportedPlatform,
      LocationPermissionStatus.notDetermined ||
      LocationPermissionStatus.denied ||
      LocationPermissionStatus.restricted =>
        LocationFailureReason.permissionDenied,
    };
  }

  Future<void> _rememberPermission(
    LocationPrivacyPreferences preferences,
    LocationPermissionStatus permission,
  ) async {
    if (preferences.lastPermissionStatus == permission) return;
    await _privacyRepository.savePreferences(
      preferences.copyWith(lastPermissionStatus: permission),
    );
  }

  DiscoveryLocationCaptureOutcome _failure(
    LocationFailureReason reason,
    String? consentVersion,
  ) {
    debugPrint('CATDEX_LOCATION_REQUEST_FAILED reason=${reason.name}');
    return DiscoveryLocationCaptureOutcome(
      locationConsentVersion: consentVersion,
      failureReason: reason,
    );
  }

  String _accuracyCategory(CatDiscoveryLocation location) {
    if (location.isApproximate) return 'approximate';
    final accuracy = location.horizontalAccuracyMeters;
    if (accuracy == null) return 'unknown';
    if (accuracy <= 20) return 'high';
    if (accuracy <= 100) return 'medium';
    return 'low';
  }
}
