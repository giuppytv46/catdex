import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';
import 'package:catdex/features/catdex/domain/repositories/catdex_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCatDexRepository implements CatDexRepository {
  const SupabaseCatDexRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CatSpecies>> getSpecies() async {
    final rows = await _client
        .from('cat_species')
        .select()
        .eq('active', true)
        .order('display_name');

    return rows.map(mapSpecies).toList(growable: false);
  }

  @override
  Future<CatSpecies?> getSpeciesById(String id) async {
    final row = await _client
        .from('cat_species')
        .select()
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : mapSpecies(row);
  }

  @override
  Future<List<CatVariant>> getVariants() async {
    final rows = await _client
        .from('cat_variants')
        .select()
        .eq('active', true)
        .order('name');

    return rows.map(mapVariant).toList(growable: false);
  }

  @override
  Future<CatVariant?> getVariantById(String id) async {
    final row = await _client
        .from('cat_variants')
        .select()
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : mapVariant(row);
  }

  static CatSpecies mapSpecies(Map<String, dynamic> row) {
    return CatSpecies(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      scientificName: row['scientific_name'] as String,
      originCountry: row['origin_country'] as String,
      baseRarity: _rarity(row['base_rarity'] as String),
      active: row['active'] as bool? ?? true,
    );
  }

  static CatVariant mapVariant(Map<String, dynamic> row) {
    return CatVariant(
      id: row['id'] as String,
      name: row['name'] as String,
      rewardMultiplier: (row['reward_multiplier'] as num).toDouble(),
      xpBonus: row['xp_bonus'] as int? ?? 0,
      requiresEvent: row['event_required'] as bool? ?? false,
    );
  }

  static CatRarity _rarity(String name) {
    for (final rarity in CatRarity.values) {
      if (rarity.name == name) {
        return rarity;
      }
    }

    throw FormatException('Unknown rarity: $name');
  }
}
