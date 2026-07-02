import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';

class CardTextData {
  const CardTextData({
    required this.cardNumber,
    required this.catName,
    required this.species,
    required this.rarity,
    required this.starCount,
  });

  final String cardNumber;
  final String catName;
  final String species;
  final String rarity;
  final int starCount;
}

class CardTextFormatter {
  const CardTextFormatter();

  CardTextData fromDiscovery({
    required CatDiscovery discovery,
    required CatDisplayData display,
    required int collectionNumber,
  }) {
    return fromDisplay(
      display: display,
      collectionNumber: collectionNumber,
      starCount: _starCountFor(discovery.rarity),
    );
  }

  CardTextData fromDisplay({
    required CatDisplayData display,
    required int collectionNumber,
    required int starCount,
  }) {
    return CardTextData(
      cardNumber: '#${collectionNumber.toString().padLeft(4, '0')}',
      catName: display.displayName.toUpperCase(),
      species: display.displaySpecies,
      rarity: display.displayRarity,
      starCount: starCount,
    );
  }

  int _starCountFor(CatRarity rarity) {
    return switch (rarity) {
      CatRarity.common => 1,
      CatRarity.uncommon => 2,
      CatRarity.rare => 3,
      CatRarity.epic => 4,
      CatRarity.legendary || CatRarity.mythic => 5,
    };
  }
}
