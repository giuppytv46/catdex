import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:test/test.dart';

void main() {
  group('CatDexSeedData', () {
    test('contains at least 100 collectible entries', () {
      expect(CatDexSeedData.species.length, greaterThanOrEqualTo(100));
    });

    test('contains every Sprint 3 variant', () {
      final variantNames = CatDexSeedData.variants
          .map((variant) => variant.name)
          .toSet();

      expect(
        variantNames,
        containsAll({
          'Normal',
          'Shiny',
          'Golden',
          'Albino',
          'Melanistic',
          'Heterochromia',
          'Midnight',
          'Lucky',
          'Event Edition',
        }),
      );
    });

    test('contains all rarity tiers', () {
      final rarities = CatDexSeedData.species
          .map((species) => species.baseRarity)
          .toSet();

      expect(rarities, containsAll(CatRarity.values));
    });
  });
}
