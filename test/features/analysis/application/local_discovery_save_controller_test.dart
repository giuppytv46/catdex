import 'dart:io';

import 'package:catdex/features/analysis/application/local_discovery_save_controller.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_pending_sync_queue_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/home/application/home_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Directory documentsDirectory;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = Directory.systemTemp.createTempSync('catdex_save_test_');
    documentsDirectory = Directory('${tempDirectory.path}/documents')
      ..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return documentsDirectory.path;
            }

            return null;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('saves local discovery into repository and session state', () async {
    final discoveryRepository = InMemoryDiscoveryRepository();
    final progressRepository = InMemoryPlayerProgressRepository();
    final sourcePhoto = _writeTestPhoto(tempDirectory, 'cat.jpg');
    final container = _container(
      discoveryRepository: discoveryRepository,
      progressRepository: progressRepository,
    );
    addTearDown(container.dispose);

    await container.read(localDiscoverySaveControllerProvider.future);
    await container
        .read(localDiscoverySaveControllerProvider.notifier)
        .save(
          _analysisResult(),
          photoPath: sourcePhoto.path,
          customName: 'Nebbia',
        );

    final saveState = container.read(localDiscoverySaveControllerProvider);
    final discoveries = await discoveryRepository.getDiscoveriesForPlayer(
      LocalPlayerSession.playerId,
    );
    final sessionDiscoveries = container.read(localDiscoverySessionProvider);
    final catDex = container.read(catDexControllerProvider);

    expect(saveState.value?.status, LocalDiscoverySaveStatus.saved);
    expect(discoveries, hasLength(1));
    expect(sessionDiscoveries, hasLength(1));
    expect(
      discoveries.single.speciesId,
      _analysisResult().primaryBreed.species.id,
    );
    expect(discoveries.single.nickname, 'Nebbia');
    expect(
      discoveries.single.suggestedName,
      _analysisResult().primaryBreed.species.displayName,
    );
    expect(discoveries.single.suggestedName, isNot('Mochi'));
    expect(
      discoveries.single.originalPhotoPath,
      startsWith('catdex/originals/'),
    );
    expect(
      discoveries.single.displayPhotoPath,
      startsWith('catdex/originals/'),
    );
    expect(discoveries.single.photoPath, startsWith('catdex/originals/'));
    expect(
      File(
        '${documentsDirectory.path}/${discoveries.single.displayPhotoPath}',
      ).existsSync(),
      isTrue,
    );
    expect(discoveries.single.story, _analysisResult().story);
    expect(discoveries.single.funFact, _analysisResult().funFact);
    expect(discoveries.single.coatColor, 'Black');
    expect(discoveries.single.coatPattern, 'Solid');
    expect(discoveries.single.eyeColor, 'Green');
    expect(discoveries.single.hairLength, 'Short');
    expect(discoveries.single.estimatedAge, 'adult');
    expect(discoveries.single.xpEarned, saveState.value?.reward?.xp);
    expect(discoveries.single.coinsEarned, saveState.value?.reward?.coins);
    expect(
      discoveries.single.confidenceScore,
      _analysisResult().confidence.score,
    );
    expect(discoveries.single.card?.discoveryId, discoveries.single.id);
    expect(discoveries.single.card?.cardFrameStyle, 'green_simple_frame');
    expect(discoveries.single.card?.isEventCard, isFalse);
    expect(catDex.entries.first.displayName, 'Nebbia');
    expect(
      catDex.entries.first.discoveredPhotoPath,
      discoveries.single.photoPath,
    );
  });

  test('updates local player progress with discovery reward', () async {
    final discoveryRepository = InMemoryDiscoveryRepository();
    final progressRepository = InMemoryPlayerProgressRepository();
    final container = _container(
      discoveryRepository: discoveryRepository,
      progressRepository: progressRepository,
    );
    addTearDown(container.dispose);

    await container.read(localDiscoverySaveControllerProvider.future);
    await container
        .read(localDiscoverySaveControllerProvider.notifier)
        .save(_analysisResult());

    final saveState = container.read(localDiscoverySaveControllerProvider);
    final progress = await progressRepository.getProgress(
      LocalPlayerSession.playerId,
    );

    expect(progress.totalXp, saveState.value?.reward?.xp);
    expect(progress.coins, saveState.value?.reward?.coins);
    expect(progress.discoveryCount, 1);
    expect(progress.level, greaterThanOrEqualTo(1));
  });

  test(
    'keeps persistent local display photo when cloud storage path exists',
    () async {
      final discoveryRepository = InMemoryDiscoveryRepository();
      final progressRepository = InMemoryPlayerProgressRepository();
      final sourcePhoto = _writeTestPhoto(tempDirectory, 'local-cat.jpg');
      final container = _container(
        discoveryRepository: discoveryRepository,
        progressRepository: progressRepository,
      );
      addTearDown(container.dispose);

      await container.read(localDiscoverySaveControllerProvider.future);
      await container
          .read(localDiscoverySaveControllerProvider.notifier)
          .save(
            _analysisResult(),
            photoPath: sourcePhoto.path,
            cloudStoragePath: 'catdex/originals/cloud-user/discovery.jpg',
          );

      final discoveries = await discoveryRepository.getDiscoveriesForPlayer(
        LocalPlayerSession.playerId,
      );
      final catDex = container.read(catDexControllerProvider);

      expect(
        discoveries.single.displayPhotoPath,
        startsWith('catdex/originals/'),
      );
      expect(
        File(
          '${documentsDirectory.path}/${discoveries.single.displayPhotoPath}',
        ).existsSync(),
        isTrue,
      );
      expect(
        discoveries.single.originalPhotoPath,
        discoveries.single.displayPhotoPath,
      );
      expect(
        discoveries.single.originalPhotoStoragePath,
        'catdex/originals/cloud-user/discovery.jpg',
      );
      expect(discoveries.single.photoPath, discoveries.single.displayPhotoPath);
      expect(
        catDex.entries.first.discoveredPhotoPath,
        discoveries.single.displayPhotoPath,
      );
    },
  );

  test('updates live Home and CatDex state after saving', () async {
    final discoveryRepository = InMemoryDiscoveryRepository();
    final progressRepository = InMemoryPlayerProgressRepository();
    final container = _container(
      discoveryRepository: discoveryRepository,
      progressRepository: progressRepository,
    );
    addTearDown(container.dispose);
    final initialHome = container.read(homeControllerProvider);

    await container.read(localDiscoverySaveControllerProvider.future);
    await container
        .read(localDiscoverySaveControllerProvider.notifier)
        .save(_analysisResult());

    final progressSession = container.read(localPlayerProgressSessionProvider);
    final home = container.read(homeControllerProvider);
    final catDex = container.read(catDexControllerProvider);
    final savedSpeciesId = _analysisResult().primaryBreed.species.id;

    expect(progressSession.discoveryCount, 1);
    expect(home.playerProgress.totalXp, progressSession.totalXp);
    expect(home.recentDiscoveries.first.speciesName, isNotEmpty);
    expect(
      home.collectionCompletion,
      greaterThanOrEqualTo(initialHome.collectionCompletion),
    );
    expect(
      catDex.entries
          .singleWhere((entry) => entry.species.id == savedSpeciesId)
          .discovered,
      isTrue,
    );
    expect(catDex.discoveredCount, 1);
    expect(catDex.entries.first.species.id, savedSpeciesId);
    expect(catDex.entries.first.discovered, isTrue);
    expect(catDex.entries.first.discoveredPhotoPath, isNull);
    expect(catDex.entries.skip(1).every((entry) => !entry.discovered), isTrue);
  });

  test(
    'applies duplicate reward logic for repeated local discoveries',
    () async {
      final discoveryRepository = InMemoryDiscoveryRepository();
      final progressRepository = InMemoryPlayerProgressRepository();
      final container = _container(
        discoveryRepository: discoveryRepository,
        progressRepository: progressRepository,
      );
      addTearDown(container.dispose);
      final notifier = container.read(
        localDiscoverySaveControllerProvider.notifier,
      );

      await container.read(localDiscoverySaveControllerProvider.future);
      await notifier.save(_analysisResult());
      await notifier.save(_analysisResult());

      final saveState = container.read(localDiscoverySaveControllerProvider);
      final progress = await progressRepository.getProgress(
        LocalPlayerSession.playerId,
      );

      expect(saveState.value?.reward?.duplicate, isTrue);
      expect(progress.discoveryCount, 2);
      expect(progress.duplicateDiscoveryCount, 1);
    },
  );

  test('queues pending sync when cloud save fails', () async {
    final pendingQueue = InMemoryPendingSyncQueueRepository();
    final progressRepository = InMemoryPlayerProgressRepository();
    final container = ProviderContainer(
      overrides: [
        activeCatDexSessionProvider.overrideWithValue(
          const ActiveCatDexSession.cloud(playerId: 'cloud-user'),
        ),
        discoveryRepositoryProvider.overrideWithValue(
          const _FailingDiscoveryRepository(),
        ),
        playerProgressRepositoryProvider.overrideWithValue(progressRepository),
        pendingSyncQueueRepositoryProvider.overrideWithValue(pendingQueue),
      ],
    );
    addTearDown(container.dispose);

    await container.read(localDiscoverySaveControllerProvider.future);
    await container
        .read(localDiscoverySaveControllerProvider.notifier)
        .save(_analysisResult());

    final saveState = container.read(localDiscoverySaveControllerProvider);
    final pendingItems = await pendingQueue.pendingDiscoveriesForPlayer(
      'cloud-user',
    );
    final sessionDiscoveries = container.read(localDiscoverySessionProvider);

    expect(saveState.value?.status, LocalDiscoverySaveStatus.failure);
    expect(saveState.value?.pendingSync, isNotNull);
    expect(saveState.value?.message, contains('retry'));
    expect(pendingItems, hasLength(1));
    expect(sessionDiscoveries, hasLength(1));
  });

  test('does not report save success when read-after-write fails', () async {
    final progressRepository = InMemoryPlayerProgressRepository();
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(
          const _MissingReadbackDiscoveryRepository(),
        ),
        playerProgressRepositoryProvider.overrideWithValue(progressRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(localDiscoverySaveControllerProvider.future);
    await container
        .read(localDiscoverySaveControllerProvider.notifier)
        .save(_analysisResult());

    final saveState = container.read(localDiscoverySaveControllerProvider);
    expect(saveState.value?.status, LocalDiscoverySaveStatus.failure);
    expect(container.read(localDiscoverySessionProvider), isEmpty);
  });
}

File _writeTestPhoto(Directory directory, String name) {
  return File('${directory.path}/$name')..writeAsBytesSync(_onePixelPng);
}

ProviderContainer _container({
  required InMemoryDiscoveryRepository discoveryRepository,
  required InMemoryPlayerProgressRepository progressRepository,
}) {
  return ProviderContainer(
    overrides: [
      discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
      playerProgressRepositoryProvider.overrideWithValue(progressRepository),
    ],
  );
}

class _FailingDiscoveryRepository implements DiscoveryRepository {
  const _FailingDiscoveryRepository();

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    return null;
  }

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    return const [];
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    return false;
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    throw StateError('cloud unavailable');
  }
}

class _MissingReadbackDiscoveryRepository implements DiscoveryRepository {
  const _MissingReadbackDiscoveryRepository();

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async => null;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    return const [];
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    return false;
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {}
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
      coatColor: 'Black',
      coatPattern: 'Solid',
      eyeColor: 'Green',
      hairLength: 'Short',
      notableTraits: [],
    ),
    confidence: confidence,
    rarity: CatRarity.common,
    variant: variant,
    personality: CatPersonality.curious,
    story: 'A calm local discovery.',
    analyzedAt: DateTime.utc(2026),
    estimatedAge: 'adult',
    funFact: 'Domestic cats can recognize familiar voices.',
  );
}

const _onePixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  15,
  4,
  0,
  9,
  251,
  3,
  253,
  160,
  130,
  243,
  191,
  0,
  0,
  0,
  0,
  73,
  69,
  68,
  174,
  66,
  96,
  130,
];
