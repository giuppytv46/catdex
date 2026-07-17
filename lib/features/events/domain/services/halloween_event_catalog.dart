import 'package:catdex/features/events/domain/entities/catdex_event.dart';

final halloween2026Event = CatDexEvent(
  id: 'halloween_2026',
  edition: '2026',
  startsAt: DateTime.utc(2026, 10),
  endsAt: DateTime.utc(2026, 11, 4),
  standardVariantId: 'halloween_pumpkins',
  standardVariantIds: const <String>[
    'halloween_pumpkins',
    'halloween_moonlight',
    'halloween_haunted_frame',
  ],
  premiumVariantId: 'halloween_witch_cat',
  premiumVariantIds: const <String>[
    'halloween_witch_cat',
    'halloween_pumpkin_king',
    'halloween_night_spirit',
  ],
  premiumGenerationLimit: 15,
  variantTemplateKeys: const <String, String>{
    'halloween_pumpkins': 'halloween_pumpkins',
    'halloween_moonlight': 'halloween_moonlight',
    'halloween_haunted_frame': 'halloween_haunted_frame',
    'halloween_witch_cat': 'halloween_witch_cat_premium',
    'halloween_pumpkin_king': 'halloween_pumpkin_king_premium',
    'halloween_night_spirit': 'halloween_night_spirit_premium',
  },
  variantInstructionKeys: const <String, String>{
    'halloween_pumpkins': 'halloween_pumpkins',
    'halloween_moonlight': 'halloween_moonlight',
    'halloween_haunted_frame': 'halloween_haunted_frame',
    'halloween_witch_cat': 'halloween_witch_hat',
    'halloween_pumpkin_king': 'halloween_pumpkin_king',
    'halloween_night_spirit': 'halloween_night_spirit',
  },
  variantWeights: const <String, int>{
    'halloween_pumpkins': 3,
    'halloween_moonlight': 3,
    'halloween_haunted_frame': 3,
    'halloween_witch_cat': 1,
    'halloween_pumpkin_king': 1,
    'halloween_night_spirit': 1,
  },
  variantSortOrders: const <String, int>{
    'halloween_pumpkins': 0,
    'halloween_moonlight': 1,
    'halloween_haunted_frame': 2,
    'halloween_witch_cat': 3,
    'halloween_pumpkin_king': 4,
    'halloween_night_spirit': 5,
  },
  variantTransformsCatAppearance: const <String, bool>{
    'halloween_pumpkins': false,
    'halloween_moonlight': false,
    'halloween_haunted_frame': false,
    'halloween_witch_cat': true,
    'halloween_pumpkin_king': true,
    'halloween_night_spirit': true,
  },
);

CatDexEvent? catDexEventByKey(String eventKey) {
  return switch (eventKey.trim()) {
    'halloween_2026' => halloween2026Event,
    _ => null,
  };
}

class EventRuntimeConfiguration {
  const EventRuntimeConfiguration();

  static const debugEventKey = String.fromEnvironment(
    'CATDEX_DEBUG_EVENT_KEY',
  );
  static const debugEventActive = bool.fromEnvironment(
    'CATDEX_DEBUG_EVENT_ACTIVE',
  );
  static const debugPremium = bool.fromEnvironment(
    'CATDEX_DEBUG_PREMIUM',
  );

  CatDexEvent? activeEvent(DateTime now) {
    if (debugEventActive && debugEventKey == halloween2026Event.id) {
      return halloween2026Event;
    }
    return halloween2026Event.isActiveAt(now) ? halloween2026Event : null;
  }

  bool get premiumTestEntitlementEnabled =>
      debugEventActive &&
      debugEventKey == halloween2026Event.id &&
      debugPremium;

  bool get debugModeEnabled =>
      debugEventActive && debugEventKey == halloween2026Event.id;
}
