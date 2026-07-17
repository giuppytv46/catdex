import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains exactly the 27 intended V1 definitions', () {
    expect(AchievementCatalogV1.definitions, hasLength(27));
    expect(
      AchievementCatalogV1.definitions.map((item) => item.achievementId),
      containsAll(<String>[
        'first_discovery',
        'discovery_100',
        'first_normal_card',
        'normal_cards_50',
        'first_legendary',
        'geolocated_discoveries_20',
        'daily_missions_30',
        'first_event_card',
        'halloween_free_collection',
        'halloween_premium_collection',
        'level_50',
      ]),
    );
  });

  test('achievement IDs and sort orders are unique', () {
    const definitions = AchievementCatalogV1.definitions;
    expect(
      definitions.map((item) => item.achievementId).toSet(),
      hasLength(definitions.length),
    );
    expect(
      definitions.map((item) => item.sortOrder).toSet(),
      hasLength(definitions.length),
    );
  });

  test('thresholds and rewards are centralized and exact', () {
    final byId = {
      for (final item in AchievementCatalogV1.definitions)
        item.achievementId: item,
    };
    expect(byId['first_discovery']?.targetValue, 1);
    expect(byId['first_discovery']?.rewardXp, 50);
    expect(byId['discovery_100']?.rewardXp, 1000);
    expect(byId['normal_cards_50']?.targetValue, 50);
    expect(byId['first_legendary']?.rewardXp, 600);
    expect(byId['halloween_free_collection']?.targetValue, 3);
    expect(byId['halloween_premium_collection']?.rewardXp, 500);
    expect(byId['level_50']?.targetValue, 50);
  });

  test('Halloween variant sets contain the supported unique variants', () {
    expect(AchievementCatalogV1.halloweenFreeVariants, {
      'halloween_pumpkins',
      'halloween_moonlight',
      'halloween_haunted_frame',
    });
    expect(AchievementCatalogV1.halloweenPremiumVariants, {
      'halloween_witch_cat',
      'halloween_pumpkin_king',
      'halloween_night_spirit',
    });
  });

  test('Premium collection stays visible and event-specific', () {
    final definition = AchievementCatalogV1.definitions.singleWhere(
      (item) => item.achievementId == 'halloween_premium_collection',
    );
    expect(definition.category, AchievementCategory.events);
    expect(definition.isEventSpecific, isTrue);
    expect(definition.eventKey, AchievementCatalogV1.halloweenEventKey);
    expect(definition.tier, AchievementTier.platinum);
  });
}
