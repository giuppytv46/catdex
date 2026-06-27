import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';

class CatSpecies {
  const CatSpecies({
    required this.id,
    required this.displayName,
    required this.scientificName,
    required this.originCountry,
    required this.baseRarity,
    required this.active,
  });

  final String id;
  final String displayName;
  final String scientificName;
  final String originCountry;
  final CatRarity baseRarity;
  final bool active;
}
