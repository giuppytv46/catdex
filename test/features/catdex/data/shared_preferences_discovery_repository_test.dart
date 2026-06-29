import 'package:catdex/features/catdex/data/repositories/shared_preferences_discovery_repository.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists local discoveries across repository instances', () async {
    const repository = SharedPreferencesDiscoveryRepository();
    final discovery = CatDiscovery(
      id: 'discovery-1',
      playerId: 'player-1',
      speciesId: 'domestic_tabby_cat',
      variantId: 'normal',
      rarity: CatRarity.common,
      personality: CatPersonality.curious,
      traits: const [
        CatTrait(name: 'Mantello', value: 'marrone/grigio tigrato'),
      ],
      discoveredAt: DateTime.utc(2026, 6, 29),
      friendshipPoints: 20,
      customName: 'Nebbia',
      suggestedName: 'Mochi',
      originalPhotoPath: '/tmp/original-cat.jpg',
      displayPhotoPath: '/tmp/display-cat.jpg',
      story: 'Un gatto tigrato osserva il mondo.',
      funFact: 'I gatti tigrati hanno spesso una M sulla fronte.',
      coatColor: 'marrone/grigio tigrato',
      coatPattern: 'tigrato mackerel',
      eyeColor: 'occhi gialli',
      hairLength: 'pelo corto',
      estimatedAge: 'adulto',
      xpEarned: 80,
      coinsEarned: 15,
      confidenceScore: 0.91,
      card: CatDiscoveryCard(
        cardId: 'card-discovery-1',
        discoveryId: 'discovery-1',
        cardFrameStyle: 'green_simple_frame',
        cardBackgroundStyle: 'default',
        cardRarityStyle: 'common',
        isEventCard: false,
        originalPhotoPath: '/tmp/original-cat.jpg',
        generatedAt: DateTime.utc(2026, 6, 29),
      ),
    );

    await repository.saveDiscovery(discovery);

    const restoredRepository = SharedPreferencesDiscoveryRepository();
    final discoveries = await restoredRepository.getDiscoveriesForPlayer(
      'player-1',
    );

    expect(discoveries, hasLength(1));
    expect(discoveries.single.id, 'discovery-1');
    expect(discoveries.single.customName, 'Nebbia');
    expect(discoveries.single.suggestedName, 'Mochi');
    expect(discoveries.single.speciesId, 'domestic_tabby_cat');
    expect(discoveries.single.originalPhotoPath, '/tmp/original-cat.jpg');
    expect(discoveries.single.displayPhotoPath, '/tmp/display-cat.jpg');
    expect(discoveries.single.photoPath, '/tmp/display-cat.jpg');
    expect(discoveries.single.story, 'Un gatto tigrato osserva il mondo.');
    expect(
      discoveries.single.funFact,
      'I gatti tigrati hanno spesso una M sulla fronte.',
    );
    expect(discoveries.single.coatColor, 'marrone/grigio tigrato');
    expect(discoveries.single.coatPattern, 'tigrato mackerel');
    expect(discoveries.single.eyeColor, 'occhi gialli');
    expect(discoveries.single.hairLength, 'pelo corto');
    expect(discoveries.single.estimatedAge, 'adulto');
    expect(discoveries.single.rarity, CatRarity.common);
    expect(discoveries.single.variantId, 'normal');
    expect(discoveries.single.xpEarned, 80);
    expect(discoveries.single.coinsEarned, 15);
    expect(discoveries.single.confidenceScore, 0.91);
    expect(discoveries.single.discoveredAt, DateTime.utc(2026, 6, 29));
    expect(discoveries.single.card?.cardId, 'card-discovery-1');
    expect(discoveries.single.card?.cardFrameStyle, 'green_simple_frame');
    expect(discoveries.single.card?.cardBackgroundStyle, 'default');
    expect(discoveries.single.card?.isEventCard, isFalse);
  });
}
