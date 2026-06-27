import 'package:catdex/features/catdex/data/repositories/in_memory_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryCatDexRepository', () {
    test('returns seeded species and variants', () async {
      final repository = InMemoryCatDexRepository();

      expect(
        await repository.getSpecies(),
        hasLength(greaterThanOrEqualTo(100)),
      );
      expect(await repository.getVariants(), hasLength(9));
    });

    test('looks up entries by id', () async {
      final repository = InMemoryCatDexRepository();

      final species = await repository.getSpeciesById('maine_coon');
      final variant = await repository.getVariantById('shiny');

      expect(species?.displayName, 'Maine Coon');
      expect(variant?.name, 'Shiny');
    });
  });

  group('InMemoryDiscoveryRepository', () {
    test('saves and reads discoveries by player', () async {
      final repository = InMemoryDiscoveryRepository();
      final discovery = _discovery(
        id: 'discovery-1',
        playerId: 'player-1',
        speciesId: 'maine_coon',
      );

      await repository.saveDiscovery(discovery);

      expect(await repository.getDiscoveryById('discovery-1'), discovery);
      expect(await repository.getDiscoveriesForPlayer('player-1'), [discovery]);
      expect(
        await repository.hasDiscoveredSpecies(
          playerId: 'player-1',
          speciesId: 'maine_coon',
        ),
        isTrue,
      );
    });
  });

  group('InMemoryPlayerProgressRepository', () {
    test('returns empty progress for new players', () async {
      final repository = InMemoryPlayerProgressRepository();

      final progress = await repository.getProgress('player-1');

      expect(progress.playerId, 'player-1');
      expect(progress.level, 1);
      expect(progress.totalXp, 0);
    });

    test('saves and reads progress', () async {
      final repository = InMemoryPlayerProgressRepository();
      const progress = PlayerProgress(
        playerId: 'player-1',
        totalXp: 1000,
        level: 4,
        coins: 80,
        discoveryCount: 5,
        duplicateDiscoveryCount: 2,
        achievementIds: ['first_cat'],
        badgeIds: ['explorer'],
      );

      await repository.saveProgress(progress);

      expect(await repository.getProgress('player-1'), progress);
    });
  });
}

CatDiscovery _discovery({
  required String id,
  required String playerId,
  required String speciesId,
}) {
  return CatDiscovery(
    id: id,
    playerId: playerId,
    speciesId: speciesId,
    variantId: CatDexSeedData.variants.first.id,
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026),
    friendshipPoints: 0,
  );
}
