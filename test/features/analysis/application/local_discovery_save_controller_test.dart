import 'package:catdex/features/analysis/application/local_discovery_save_controller.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves local discovery into repository and session state', () async {
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
    final discoveries = await discoveryRepository.getDiscoveriesForPlayer(
      LocalPlayerSession.playerId,
    );
    final sessionDiscoveries = container.read(localDiscoverySessionProvider);

    expect(saveState.value?.status, LocalDiscoverySaveStatus.saved);
    expect(discoveries, hasLength(1));
    expect(sessionDiscoveries, hasLength(1));
    expect(
      discoveries.single.speciesId,
      _analysisResult().primaryBreed.species.id,
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
  );
}
