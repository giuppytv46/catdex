import 'dart:async';

import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/location/application/discovery_location_capture_service.dart';
import 'package:catdex/features/location/application/discovery_location_service.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/map/domain/entities/catdex_map_marker_data.dart';
import 'package:catdex/features/map/domain/services/catdex_map_marker_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catDexMapMarkerServiceProvider = Provider<CatDexMapMarkerService>((_) {
  return const CatDexMapMarkerService();
});

final catDexMapPreparationProvider = Provider<CatDexMapMarkerPreparation>((
  ref,
) {
  final discoveries = ref.watch(localDiscoverySessionProvider);
  final preparation = ref
      .watch(catDexMapMarkerServiceProvider)
      .prepare(discoveries);
  debugPrint('CATDEX_MAP_DISCOVERY_TOTAL ${preparation.totalDiscoveryCount}');
  debugPrint(
    'CATDEX_MAP_LOCATED_DISCOVERY_COUNT ${preparation.markers.length}',
  );
  debugPrint(
    'CATDEX_MAP_MISSING_LOCATION_COUNT ${preparation.missingLocationCount}',
  );
  debugPrint('CATDEX_MAP_MARKERS_BUILT ${preparation.markers.length}');
  debugPrint('CATDEX_MAP_CLUSTER_COUNT ${preparation.nearbyClusterCount}');
  return preparation;
});

final catDexMapLoadProvider = FutureProvider<void>((ref) async {
  await ref
      .read(localDiscoverySessionProvider.notifier)
      .refreshFromRepository();
});

final catDexMapLastKnownLocationProvider =
    FutureProvider<CatDiscoveryLocation?>((ref) async {
      final repository = ref.read(discoveryLocationRepositoryProvider);
      final permission = await repository.checkPermission();
      if (permission != LocationPermissionStatus.granted) return null;
      final result = await repository.getLastKnownLocation();
      return switch (result) {
        LocationServiceSuccess(:final location)
            when location.hasValidCoordinates =>
          location,
        _ => null,
      };
    });

final selectedMapDiscoveryIdProvider =
    NotifierProvider<SelectedMapDiscoveryController, String?>(
      SelectedMapDiscoveryController.new,
    );

class SelectedMapDiscoveryController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String discoveryId) {
    state = discoveryId;
    debugPrint('CATDEX_MAP_MARKER_SELECTED id=$discoveryId');
  }

  void clear() => state = null;
}

enum MapCurrentPositionPhase { idle, requesting, success, failure }

class MapCurrentPositionState {
  const MapCurrentPositionState({
    this.phase = MapCurrentPositionPhase.idle,
    this.location,
    this.failureReason,
  });

  final MapCurrentPositionPhase phase;
  final CatDiscoveryLocation? location;
  final LocationFailureReason? failureReason;
}

final mapCurrentPositionControllerProvider =
    NotifierProvider<MapCurrentPositionController, MapCurrentPositionState>(
      MapCurrentPositionController.new,
    );

class MapCurrentPositionController extends Notifier<MapCurrentPositionState> {
  @override
  MapCurrentPositionState build() => const MapCurrentPositionState();

  Future<LocationPermissionStatus> permissionStatus() {
    return ref.read(discoveryLocationRepositoryProvider).checkPermission();
  }

  Future<void> requestCurrentPosition({
    required bool allowPermissionRequest,
  }) async {
    if (state.phase == MapCurrentPositionPhase.requesting) return;
    state = const MapCurrentPositionState(
      phase: MapCurrentPositionPhase.requesting,
    );
    debugPrint('CATDEX_MAP_CURRENT_LOCATION_REQUESTED');

    final repository = ref.read(discoveryLocationRepositoryProvider);
    if (!await repository.checkServiceEnabled()) {
      _fail(LocationFailureReason.serviceDisabled);
      return;
    }

    final preferencesRepository = ref.read(
      locationPrivacyPreferencesRepositoryProvider,
    );
    final preferences = await preferencesRepository.getPreferences();
    var permission = await repository.checkPermission();
    if (_canRequestPermission(
      permission: permission,
      preferences: preferences,
      allowPermissionRequest: allowPermissionRequest,
    )) {
      permission = await repository.requestPermission();
      await preferencesRepository.savePreferences(
        preferences.copyWith(lastPermissionStatus: permission),
      );
    }

    final permissionFailure = _permissionFailure(permission);
    if (permissionFailure != null) {
      _fail(permissionFailure);
      return;
    }

    final result = await repository.getCurrentLocation().timeout(
      const Duration(seconds: 8),
      onTimeout: () => const LocationServiceFailure(
        LocationFailureReason.timeout,
      ),
    );
    switch (result) {
      case LocationServiceSuccess(:final location)
          when location.hasValidCoordinates:
        if (!ref.mounted) return;
        state = MapCurrentPositionState(
          phase: MapCurrentPositionPhase.success,
          location: location,
        );
        debugPrint('CATDEX_MAP_CURRENT_LOCATION_SUCCESS');
      case LocationServiceSuccess():
        _fail(LocationFailureReason.invalidCoordinates);
      case LocationServiceFailure(:final reason):
        _fail(reason);
    }
  }

  bool _canRequestPermission({
    required LocationPermissionStatus permission,
    required LocationPrivacyPreferences preferences,
    required bool allowPermissionRequest,
  }) {
    if (!allowPermissionRequest) return false;
    if (permission == LocationPermissionStatus.notDetermined) return true;
    return permission == LocationPermissionStatus.denied &&
        preferences.lastPermissionStatus ==
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

  void _fail(LocationFailureReason reason) {
    if (!ref.mounted) return;
    state = MapCurrentPositionState(
      phase: MapCurrentPositionPhase.failure,
      failureReason: reason,
    );
    debugPrint('CATDEX_MAP_CURRENT_LOCATION_FAILED reason=${reason.name}');
  }
}

final catDexMapActionsProvider = Provider<CatDexMapActions>(
  CatDexMapActions.new,
);

class CatDexMapActions {
  const CatDexMapActions(this._ref);

  final Ref _ref;

  Future<bool> removeLocation(String discoveryId) async {
    final removed = await _ref
        .read(discoveryLocationServiceProvider)
        .removeLocationFromDiscovery(discoveryId);
    if (removed) {
      debugPrint('CATDEX_MAP_LOCATION_REMOVED id=$discoveryId');
    }
    return removed;
  }
}
