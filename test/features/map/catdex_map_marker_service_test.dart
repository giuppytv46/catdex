import 'dart:io';

import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/map/application/map_discovery_image_provider.dart';
import 'package:catdex/features/map/domain/services/catdex_map_marker_service.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CatDexMapMarkerService();

  test('only discoveries with valid locations create markers', () {
    final result = service.prepare([
      mapTestDiscovery(id: 'located', latitude: 45, longitude: 7),
      mapTestDiscovery(id: 'missing'),
    ]);

    expect(result.markers.map((item) => item.discoveryId), ['located']);
    expect(result.missingLocationCount, 1);
  });

  test('discoveries with invalid locations do not create fake markers', () {
    final invalid = mapTestDiscovery(
      id: 'invalid',
      location: const CatDiscoveryLocation(latitude: 95, longitude: 200),
    );

    final result = service.prepare([invalid]);

    expect(result.markers, isEmpty);
    expect(result.initialViewport, CatDexMapMarkerService.neutralViewport);
  });

  test('two discoveries at the same location remain separate', () {
    final result = service.prepare([
      mapTestDiscovery(id: 'one', latitude: 45, longitude: 7),
      mapTestDiscovery(id: 'two', latitude: 45, longitude: 7),
    ]);

    expect(result.markers, hasLength(2));
    expect(result.markers.map((item) => item.discoveryId).toSet(), {
      'one',
      'two',
    });
  });

  test('nearby cats are represented as a cluster candidate', () {
    final result = service.prepare([
      mapTestDiscovery(id: 'one', latitude: 45, longitude: 7),
      mapTestDiscovery(id: 'two', latitude: 45.005, longitude: 7.005),
    ]);

    expect(result.nearbyClusterCount, 1);
  });

  test('local and remote refresh duplicates do not duplicate markers', () {
    final discovery = mapTestDiscovery(
      id: 'same-id',
      latitude: 45,
      longitude: 7,
    );

    final result = service.prepare([discovery, discovery]);

    expect(result.markers, hasLength(1));
    expect(result.totalDiscoveryCount, 1);
  });

  test('same display name with different ids remains separate', () {
    final result = service.prepare([
      mapTestDiscovery(
        id: 'luna-one',
        latitude: 45,
        longitude: 7,
      ),
      mapTestDiscovery(
        id: 'luna-two',
        latitude: 45,
        longitude: 7,
      ),
    ]);

    expect(result.markers, hasLength(2));
  });

  test('single discovery uses a neighborhood-level initial zoom', () {
    final result = service.prepare([
      mapTestDiscovery(id: 'one', latitude: 45, longitude: 7),
    ]);

    expect(result.initialViewport.zoom, 14.5);
    expect(result.initialViewport.latitude, 45);
  });

  test('multiple discovery bounds produce a useful camera center', () {
    final result = service.prepare([
      mapTestDiscovery(id: 'one', latitude: 40, longitude: 8),
      mapTestDiscovery(id: 'two', latitude: 44, longitude: 12),
    ]);

    expect(result.initialViewport.latitude, 42);
    expect(result.initialViewport.longitude, 10);
    expect(result.initialViewport.zoom, greaterThan(3));
  });

  test('hundreds of mock markers are prepared synchronously', () {
    final discoveries = List.generate(
      750,
      (index) => mapTestDiscovery(
        id: 'cat-$index',
        latitude: 40 + (index % 50) * 0.001,
        longitude: 8 + (index % 40) * 0.001,
      ),
    );
    final stopwatch = Stopwatch()..start();

    final result = service.prepare(discoveries);

    stopwatch.stop();
    expect(result.markers, hasLength(750));
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });

  test('newest discoveries are prepared first', () {
    final result = service.prepare([
      mapTestDiscovery(
        id: 'old',
        latitude: 45,
        longitude: 7,
        discoveredAt: DateTime.utc(2026),
      ),
      mapTestDiscovery(
        id: 'new',
        latitude: 45,
        longitude: 7,
        discoveredAt: DateTime.utc(2026, 2),
      ),
    ]);

    expect(result.markers.first.discoveryId, 'new');
  });

  test(
    'map image provider uses the canonical resolver for a local file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'catdex-map-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/cat.jpg');
      await file.writeAsBytes([1]);
      final discovery = mapTestDiscovery(id: 'photo', photoPath: file.path);
      final container = ProviderContainer(
        overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      final resolved = await container.read(
        mapDiscoveryImageProvider(discovery).future,
      );

      expect(resolved.type, CatDexResolvedImageType.local);
      expect(resolved.path, file.path);
    },
  );
}

CatDiscovery mapTestDiscovery({
  required String id,
  String name = 'Luna',
  double? latitude,
  double? longitude,
  CatDiscoveryLocation? location,
  bool approximate = false,
  String? photoPath,
  DateTime? discoveredAt,
  CatRarity rarity = CatRarity.uncommon,
}) {
  final resolvedLocation =
      location ??
      (latitude == null || longitude == null
          ? null
          : CatDiscoveryLocation(
              latitude: latitude,
              longitude: longitude,
              capturedAt: DateTime.utc(2026, 7),
              locality: 'Torino',
              administrativeArea: 'Piemonte',
              countryCode: 'IT',
              isApproximate: approximate,
            ));
  return CatDiscovery(
    id: id,
    playerId: 'local-explorer',
    speciesId: 'domestic_tabby_cat',
    variantId: 'normal',
    rarity: rarity,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: discoveredAt ?? DateTime.utc(2026, 7, 15),
    friendshipPoints: 10,
    customName: name,
    suggestedName: name,
    displayPhotoPath: photoPath,
    originalPhotoPath: photoPath,
    coatColor: 'arancione tigrato',
    coatPattern: 'tigrato',
    eyeColor: 'occhi ambrati',
    hairLength: 'pelo corto',
    captureLocation: resolvedLocation,
    locationCapturedAt: resolvedLocation?.capturedAt,
  );
}
