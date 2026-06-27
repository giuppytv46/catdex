import 'dart:math';

import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward.dart';

class DiscoveryRewardCalculator {
  const DiscoveryRewardCalculator();

  static const duplicateXpRate = 0.35;
  static const duplicateCoinRate = 0.5;

  int xpForDiscovery({
    required CatSpecies species,
    required CatVariant variant,
    required CatRarity rarity,
    required bool duplicate,
  }) {
    final effectiveRarity = rarity.index >= species.baseRarity.index
        ? rarity
        : species.baseRarity;
    final rawXp =
        effectiveRarity.baseXp *
            effectiveRarity.multiplier *
            variant.rewardMultiplier +
        variant.xpBonus;
    final adjustedXp = duplicate ? rawXp * duplicateXpRate : rawXp;

    return max(1, adjustedXp.round());
  }

  DiscoveryReward rewardForDiscovery({
    required CatSpecies species,
    required CatVariant variant,
    required CatRarity rarity,
    required bool duplicate,
  }) {
    final xp = xpForDiscovery(
      species: species,
      variant: variant,
      rarity: rarity,
      duplicate: duplicate,
    );
    final effectiveRarity = rarity.index >= species.baseRarity.index
        ? rarity
        : species.baseRarity;
    final baseCoins =
        (10 * effectiveRarity.multiplier * variant.rewardMultiplier).round();
    final coins = duplicate
        ? max(1, (baseCoins * duplicateCoinRate).round())
        : baseCoins;

    return DiscoveryReward(
      xp: xp,
      coins: coins,
      friendshipPoints: duplicate ? 18 : 30,
      duplicate: duplicate,
    );
  }
}
