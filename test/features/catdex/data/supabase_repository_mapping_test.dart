import 'package:catdex/features/catdex/data/repositories/supabase_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:test/test.dart';

void main() {
  test('maps Supabase cat species rows', () {
    final species = SupabaseCatDexRepository.mapSpecies({
      'id': 'maine_coon',
      'display_name': 'Maine Coon',
      'scientific_name': 'Felis catus',
      'origin_country': 'United States',
      'base_rarity': 'rare',
      'active': true,
    });

    expect(species.id, 'maine_coon');
    expect(species.displayName, 'Maine Coon');
    expect(species.baseRarity, CatRarity.rare);
  });

  test('maps Supabase cat variant rows', () {
    final variant = SupabaseCatDexRepository.mapVariant({
      'id': 'shiny',
      'name': 'Shiny',
      'reward_multiplier': 2.0,
      'xp_bonus': 120,
      'event_required': false,
    });

    expect(variant.id, 'shiny');
    expect(variant.rewardMultiplier, 2);
    expect(variant.xpBonus, 120);
  });

  test('maps Supabase discovery rows with traits', () {
    final discovery = SupabaseDiscoveryRepository.mapDiscovery({
      'id': 'discovery-1',
      'user_id': 'user-1',
      'species_id': 'domestic_tabby_cat',
      'variant_id': 'normal',
      'rarity': 'common',
      'personality': 'curious',
      'friendship_points': 30,
      'nickname': 'Mochi',
      'city': 'Rome',
      'country': 'Italy',
      'favorite': true,
      'discovered_at': '2026-06-28T12:00:00.000Z',
      'discovery_traits': [
        {
          'trait_name': 'Mood',
          'trait_value': 'Curious',
          'rarity_weight': 1.0,
        },
      ],
    });

    expect(discovery.id, 'discovery-1');
    expect(discovery.playerId, 'user-1');
    expect(discovery.personality, CatPersonality.curious);
    expect(discovery.traits.single.name, 'Mood');
    expect(discovery.favorite, isTrue);
  });

  test('serializes CatDiscovery for Supabase', () {
    final row = SupabaseDiscoveryRepository.toDiscoveryRow(
      CatDiscovery(
        id: 'discovery-1',
        playerId: 'local-user',
        speciesId: 'domestic_tabby_cat',
        variantId: 'normal',
        rarity: CatRarity.common,
        personality: CatPersonality.curious,
        traits: const [CatTrait(name: 'Mood', value: 'Curious')],
        discoveredAt: DateTime.utc(2026, 6, 28, 12),
        friendshipPoints: 30,
        nickname: 'Mochi',
      ),
      'cloud-user',
    );

    expect(row['id'], 'discovery-1');
    expect(row['user_id'], 'cloud-user');
    expect(row['rarity'], 'common');
    expect(row['personality'], 'curious');
  });

  test('maps Supabase progress rows', () {
    final progress = SupabasePlayerProgressRepository.mapProgress(
      {
        'id': 'user-1',
        'xp': 1000,
        'level': 4,
        'coins': 80,
        'discovery_count': 5,
        'duplicate_discovery_count': 2,
      },
      achievementRows: [
        {'achievement_id': 'first_cat'},
      ],
      badgeRows: [
        {'badge_id': 'explorer'},
      ],
    );

    expect(progress.playerId, 'user-1');
    expect(progress.totalXp, 1000);
    expect(progress.achievementIds, ['first_cat']);
    expect(progress.badgeIds, ['explorer']);
  });

  test('serializes PlayerProgress for Supabase profiles', () {
    const progress = PlayerProgress(
      playerId: 'user-1',
      totalXp: 1000,
      level: 4,
      coins: 80,
      discoveryCount: 5,
      duplicateDiscoveryCount: 2,
      achievementIds: ['first_cat'],
      badgeIds: ['explorer'],
    );

    final row = SupabasePlayerProgressRepository.toProfileRow(progress);

    expect(row['id'], 'user-1');
    expect(row['xp'], 1000);
    expect(row['duplicate_discovery_count'], 2);
  });
}
