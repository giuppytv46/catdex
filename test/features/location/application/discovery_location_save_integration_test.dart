import 'dart:async';

import 'package:catdex/features/analysis/application/local_discovery_save_controller.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/location/application/discovery_location_capture_service.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';
import 'package:catdex/features/location/domain/repositories/location_privacy_preferences_repository.dart';
import 'package:catdex/features/location/domain/repositories/location_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('location acquisition failure still saves discovery', () async {
    final repository = InMemoryDiscoveryRepository();
    final container = _container(
      repository,
      locationRepository: _FakeLocationRepository(),
    );
    addTearDown(container.dispose);

    await _save(container);

    expect(
      container.read(localDiscoverySaveControllerProvider).value?.status,
      LocalDiscoverySaveStatus.saved,
    );
    final discoveries = await repository.getDiscoveriesForPlayer(
      LocalPlayerSession.playerId,
    );
    expect(discoveries.single.captureLocation, isNull);
  });

  test('location timeout still saves discovery', () async {
    final repository = InMemoryDiscoveryRepository();
    final container = _container(
      repository,
      locationRepository: _FakeLocationRepository(neverCompletes: true),
      timeout: const Duration(milliseconds: 5),
    );
    addTearDown(container.dispose);

    await _save(container);

    expect(
      container.read(localDiscoverySaveControllerProvider).value?.status,
      LocalDiscoverySaveStatus.saved,
    );
    expect(
      (await repository.getDiscoveriesForPlayer(
        LocalPlayerSession.playerId,
      )).single.captureLocation,
      isNull,
    );
  });

  test('permission denied does not block saving', () async {
    final repository = InMemoryDiscoveryRepository();
    final locationRepository = _FakeLocationRepository(
      permission: LocationPermissionStatus.denied,
    );
    final container = _container(
      repository,
      locationRepository: locationRepository,
    );
    addTearDown(container.dispose);

    await _save(container);

    expect(
      container.read(localDiscoverySaveControllerProvider).value?.status,
      LocalDiscoverySaveStatus.saved,
    );
    expect(locationRepository.currentLocationCalls, 0);
  });

  test('successful optional location is persisted with discovery', () async {
    final repository = InMemoryDiscoveryRepository();
    final container = _container(
      repository,
      locationRepository: _FakeLocationRepository(
        result: LocationServiceSuccess(
          CatDiscoveryLocation.tryCreate(
            latitude: 45.4642,
            longitude: 9.19,
            capturedAt: DateTime.utc(2026, 7, 16),
            source: CatDiscoveryLocationSource.gps,
          )!,
        ),
      ),
    );
    addTearDown(container.dispose);

    await _save(container);

    final discovery = (await repository.getDiscoveriesForPlayer(
      LocalPlayerSession.playerId,
    )).single;
    expect(discovery.captureLocation, isNotNull);
    expect(discovery.captureLocation?.isApproximate, isTrue);
    expect(discovery.locationConsentVersion, 'location-v1');
  });
}

ProviderContainer _container(
  InMemoryDiscoveryRepository repository, {
  required _FakeLocationRepository locationRepository,
  Duration timeout = const Duration(seconds: 1),
}) {
  final captureService = DiscoveryLocationCaptureService(
    privacyRepository: _FakePrivacyRepository(),
    locationRepository: locationRepository,
    timeout: timeout,
  );
  return ProviderContainer(
    overrides: [
      activeCatDexSessionProvider.overrideWithValue(
        const ActiveCatDexSession.guest(
          playerId: LocalPlayerSession.playerId,
        ),
      ),
      discoveryRepositoryProvider.overrideWithValue(repository),
      playerProgressRepositoryProvider.overrideWithValue(
        InMemoryPlayerProgressRepository(),
      ),
      discoveryLocationCaptureServiceProvider.overrideWithValue(
        captureService,
      ),
      supabaseConfiguredProvider.overrideWithValue(false),
    ],
  );
}

Future<void> _save(ProviderContainer container) async {
  await container.read(localDiscoverySaveControllerProvider.future);
  await container
      .read(localDiscoverySaveControllerProvider.notifier)
      .save(_analysisResult());
}

class _FakePrivacyRepository implements LocationPrivacyPreferencesRepository {
  LocationPrivacyPreferences preferences = const LocationPrivacyPreferences(
    locationCollectionEnabled: true,
    locationPrecisionMode: LocationPrecisionMode.approximate,
    rememberLocationChoice: true,
    locationConsentVersion: 'location-v1',
    lastPermissionStatus: LocationPermissionStatus.notDetermined,
  );

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
    this.permission = LocationPermissionStatus.granted,
    this.result = const LocationServiceFailure(
      LocationFailureReason.unavailable,
    ),
    this.neverCompletes = false,
  });

  final LocationPermissionStatus permission;
  final LocationServiceResult result;
  final bool neverCompletes;
  int currentLocationCalls = 0;

  @override
  Future<bool> checkServiceEnabled() async => true;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permission;

  @override
  Future<LocationPermissionStatus> requestPermission() async => permission;

  @override
  Future<LocationServiceResult> getCurrentLocation() {
    currentLocationCalls += 1;
    return neverCompletes
        ? Completer<LocationServiceResult>().future
        : Future.value(result);
  }

  @override
  Future<LocationServiceResult> getLastKnownLocation() async => result;
}

CatAnalysisResult _analysisResult() {
  final species = CatDexSeedData.species.first;
  final variant = CatDexSeedData.variants.first;
  const confidence = CatAnalysisConfidence(0.91);
  return CatAnalysisResult(
    primaryBreed: CatBreedCandidate(
      species: species,
      confidence: confidence,
    ),
    breedCandidates: [
      CatBreedCandidate(species: species, confidence: confidence),
    ],
    visualTraits: const CatVisualTraits(
      coatColor: 'Nero',
      coatPattern: 'Solido',
      eyeColor: 'Occhi verdi',
      hairLength: 'Corto',
      notableTraits: [],
    ),
    confidence: confidence,
    rarity: CatRarity.common,
    variant: variant,
    personality: CatPersonality.curious,
    story: 'Una scoperta locale.',
    analyzedAt: DateTime.utc(2026, 7, 16),
  );
}
