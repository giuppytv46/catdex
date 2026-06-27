import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';

abstract interface class CatDexRepository {
  Future<List<CatSpecies>> getSpecies();

  Future<CatSpecies?> getSpeciesById(String id);

  Future<List<CatVariant>> getVariants();

  Future<CatVariant?> getVariantById(String id);
}
