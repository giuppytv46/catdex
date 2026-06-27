import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward_calculator.dart';
import 'package:catdex/features/catdex/domain/services/friendship_calculator.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('LevelCalculator', () {
    const calculator = LevelCalculator();

    test('maps zero XP to level 1', () {
      expect(calculator.levelForXp(0), 1);
    });

    test('uses quadratic XP thresholds', () {
      expect(calculator.xpRequiredForLevel(2), 100);
      expect(calculator.xpRequiredForLevel(10), 8100);
      expect(calculator.levelForXp(8099), 9);
      expect(calculator.levelForXp(8100), 10);
    });

    test('caps level at 100', () {
      expect(calculator.levelForXp(2000000), 100);
    });
  });

  group('FriendshipCalculator', () {
    const calculator = FriendshipCalculator();

    test('maps friendship points to levels 1 through 5', () {
      expect(calculator.levelForPoints(0), 1);
      expect(calculator.levelForPoints(40), 2);
      expect(calculator.levelForPoints(120), 3);
      expect(calculator.levelForPoints(260), 4);
      expect(calculator.levelForPoints(500), 5);
    });
  });

  group('DiscoveryRewardCalculator', () {
    const calculator = DiscoveryRewardCalculator();
    final commonSpecies = CatDexSeedData.species.first;
    final normalVariant = CatDexSeedData.variants.first;
    final shinyVariant = CatDexSeedData.variants.firstWhere(
      (variant) => variant.id == 'shiny',
    );

    test('calculates base XP from rarity and variant multipliers', () {
      final normalXp = calculator.xpForDiscovery(
        species: commonSpecies,
        variant: normalVariant,
        rarity: CatRarity.common,
        duplicate: false,
      );
      final rareXp = calculator.xpForDiscovery(
        species: commonSpecies,
        variant: normalVariant,
        rarity: CatRarity.rare,
        duplicate: false,
      );

      expect(normalXp, 100);
      expect(rareXp, greaterThan(normalXp));
    });

    test('variant rewards increase XP', () {
      final normalXp = calculator.xpForDiscovery(
        species: commonSpecies,
        variant: normalVariant,
        rarity: CatRarity.common,
        duplicate: false,
      );
      final shinyXp = calculator.xpForDiscovery(
        species: commonSpecies,
        variant: shinyVariant,
        rarity: CatRarity.common,
        duplicate: false,
      );

      expect(shinyXp, greaterThan(normalXp));
    });

    test('duplicates still reward XP, coins, and friendship', () {
      final firstReward = calculator.rewardForDiscovery(
        species: commonSpecies,
        variant: normalVariant,
        rarity: CatRarity.common,
        duplicate: false,
      );
      final duplicateReward = calculator.rewardForDiscovery(
        species: commonSpecies,
        variant: normalVariant,
        rarity: CatRarity.common,
        duplicate: true,
      );

      expect(duplicateReward.duplicate, isTrue);
      expect(duplicateReward.xp, greaterThan(0));
      expect(duplicateReward.coins, greaterThan(0));
      expect(duplicateReward.friendshipPoints, greaterThan(0));
      expect(duplicateReward.xp, lessThan(firstReward.xp));
      expect(duplicateReward.coins, lessThan(firstReward.coins));
    });
  });
}
