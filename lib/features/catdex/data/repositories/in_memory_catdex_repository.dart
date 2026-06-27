import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';
import 'package:catdex/features/catdex/domain/repositories/catdex_repository.dart';

class InMemoryCatDexRepository implements CatDexRepository {
  InMemoryCatDexRepository({
    List<CatSpecies>? species,
    List<CatVariant>? variants,
  }) : _species = List.unmodifiable(species ?? CatDexSeedData.species),
       _variants = List.unmodifiable(variants ?? CatDexSeedData.variants);

  final List<CatSpecies> _species;
  final List<CatVariant> _variants;

  @override
  Future<List<CatSpecies>> getSpecies() async {
    return _species;
  }

  @override
  Future<CatSpecies?> getSpeciesById(String id) async {
    for (final species in _species) {
      if (species.id == id) {
        return species;
      }
    }

    return null;
  }

  @override
  Future<List<CatVariant>> getVariants() async {
    return _variants;
  }

  @override
  Future<CatVariant?> getVariantById(String id) async {
    for (final variant in _variants) {
      if (variant.id == id) {
        return variant;
      }
    }

    return null;
  }
}
