import 'dart:convert';

import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/merged_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_discovery_repository.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/location/application/discovery_location_service.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('location survives repository recreation', () async {
    const repository = SharedPreferencesDiscoveryRepository();
    await repository.saveDiscovery(_discovery());

    const recreated = SharedPreferencesDiscoveryRepository();
    final restored = await recreated.getDiscoveryById('discovery-1');

    expect(restored?.captureLocation, _location);
    expect(restored?.locationConsentVersion, 'location-v1');
    expect(restored?.locationCapturedAt, _location.capturedAt);
  });

  test('old discovery without location still loads', () async {
    const repository = SharedPreferencesDiscoveryRepository();
    await repository.saveDiscovery(_discovery());
    final preferences = await SharedPreferences.getInstance();
    final records = preferences.getStringList(_storageKey)!;
    final json = jsonDecode(records.single) as Map<String, dynamic>
      ..remove('captureLocation')
      ..remove('locationConsentVersion')
      ..remove('locationCapturedAt');
    await preferences.setStringList(_storageKey, [jsonEncode(json)]);

    final restored = await repository.getDiscoveryById('discovery-1');

    expect(restored, isNotNull);
    expect(restored?.captureLocation, isNull);
  });

  test('corrupt location record does not crash restoration', () async {
    const repository = SharedPreferencesDiscoveryRepository();
    await repository.saveDiscovery(_discovery());
    final preferences = await SharedPreferences.getInstance();
    final records = preferences.getStringList(_storageKey)!;
    final json = jsonDecode(records.single) as Map<String, dynamic>;
    json['captureLocation'] = {
      'latitude': 999,
      'longitude': 'not-a-number',
    };
    await preferences.setStringList(_storageKey, [jsonEncode(json)]);

    final restored = await repository.getDiscoveryById('discovery-1');

    expect(restored, isNotNull);
    expect(restored?.captureLocation, isNull);
  });

  test('invalid location does not prevent saving the discovery', () async {
    const repository = SharedPreferencesDiscoveryRepository();
    final invalid = _discovery().copyWithLocation(
      captureLocation: const CatDiscoveryLocation(
        latitude: 200,
        longitude: 9,
      ),
    );

    await repository.saveDiscovery(invalid);
    final restored = await repository.getDiscoveryById('discovery-1');

    expect(restored, isNotNull);
    expect(restored?.captureLocation, isNull);
  });

  test('null merge does not erase valid location', () {
    final merged = mergeDiscoveryRecords(
      preferred: _discovery(withoutLocation: true),
      fallback: _discovery(),
    );

    expect(merged.captureLocation, _location);
  });

  test('generated-card update preserves location', () {
    final original = _discovery();
    final updated = original.copyWithCard(
      CatDiscoveryCard(
        cardId: 'card-1',
        discoveryId: original.id,
        cardFrameStyle: 'common',
        cardBackgroundStyle: 'default',
        cardRarityStyle: 'common',
        isEventCard: false,
        originalPhotoPath: original.originalPhotoPath,
        generatedAt: DateTime.utc(2026, 7, 16),
        cardImageUrl: 'https://example.test/final-card.png',
      ),
    );

    expect(updated.captureLocation, _location);
  });

  test('user-name edit preserves location', () {
    final updated = _discovery().copyWith(customName: 'Luna');

    expect(updated.customName, 'Luna');
    expect(updated.captureLocation, _location);
  });

  test('removeLocation preserves all non-location fields', () async {
    final repository = InMemoryDiscoveryRepository(
      discoveries: [_discovery()],
    );
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final removed = await container
        .read(discoveryLocationServiceProvider)
        .removeLocationFromDiscovery('discovery-1');
    final restored = await repository.getDiscoveryById('discovery-1');

    expect(removed, isTrue);
    expect(restored?.captureLocation, isNull);
    expect(restored?.locationConsentVersion, isNull);
    expect(restored?.locationCapturedAt, isNull);
    expect(restored?.id, 'discovery-1');
    expect(restored?.customName, 'Mochi');
    expect(restored?.photoPath, 'catdex/originals/original-1.jpg');
    expect(restored?.card?.cardId, 'card-discovery-1');
  });
}

const _storageKey = 'catdex_local_discoveries';
final CatDiscoveryLocation _location = CatDiscoveryLocation.tryCreate(
  latitude: 45.46,
  longitude: 9.19,
  horizontalAccuracyMeters: 1500,
  capturedAt: DateTime.utc(2026, 7, 16, 10),
  source: CatDiscoveryLocationSource.gps,
  locality: 'Milano',
  countryCode: 'IT',
  isApproximate: true,
)!;

CatDiscovery _discovery({
  CatDiscoveryLocation? captureLocation,
  bool withoutLocation = false,
}) {
  final resolvedLocation = withoutLocation
      ? null
      : captureLocation ?? _location;
  return CatDiscovery(
    id: 'discovery-1',
    playerId: 'local-explorer',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 16),
    friendshipPoints: 10,
    customName: 'Mochi',
    originalPhotoPath: 'catdex/originals/original-1.jpg',
    displayPhotoPath: 'catdex/originals/original-1.jpg',
    captureLocation: resolvedLocation,
    locationConsentVersion: resolvedLocation == null ? null : 'location-v1',
    locationCapturedAt: resolvedLocation?.capturedAt,
    card: CatDiscoveryCard(
      cardId: 'card-discovery-1',
      discoveryId: 'discovery-1',
      cardFrameStyle: 'common',
      cardBackgroundStyle: 'default',
      cardRarityStyle: 'common',
      isEventCard: false,
      originalPhotoPath: 'catdex/originals/original-1.jpg',
      generatedAt: DateTime.utc(2026, 7, 16),
    ),
  );
}
