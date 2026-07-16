import 'dart:convert';

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
    final discovery = _discovery(
      id: 'discovery-1',
      customName: 'Nebbia',
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
    expect(
      discoveries.single.originalPhotoPath,
      'catdex/originals/original-cat.jpg',
    );
    expect(
      discoveries.single.displayPhotoPath,
      'catdex/originals/display-cat.jpg',
    );
    expect(
      discoveries.single.originalPhotoStoragePath,
      'catdex/originals/player/discovery-1.jpg',
    );
    expect(discoveries.single.photoPath, 'catdex/originals/display-cat.jpg');
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
    expect(discoveries.single.favorite, isTrue);
  });

  test('same discovery id replaces previous saved item', () async {
    const repository = SharedPreferencesDiscoveryRepository();

    await repository.saveDiscovery(
      _discovery(id: 'discovery-1', customName: 'Lunetta'),
    );
    await repository.saveDiscovery(
      _discovery(id: 'discovery-1', customName: 'Lunetta aggiornata'),
    );

    final discoveries = await repository.getDiscoveriesForPlayer('player-1');

    expect(discoveries, hasLength(1));
    expect(discoveries.single.customName, 'Lunetta aggiornata');
  });

  test('completed card survives repository restart', () async {
    const repository = SharedPreferencesDiscoveryRepository();
    await repository.saveDiscovery(
      _discovery(
        id: 'generated-1',
        customName: 'Luna',
        finalCardUrl:
            'https://renderer.example/generated/generated-1/final-card.png',
      ),
    );

    const restartedRepository = SharedPreferencesDiscoveryRepository();
    final restored = await restartedRepository.getDiscoveryById('generated-1');

    expect(restored?.card?.cardImageUrl, contains('final-card.png'));
    expect(
      restored?.card?.illustratedCatImageUrl,
      'https://renderer.example/generated/generated-1/illustrated-cat.png',
    );
    expect(restored?.card?.cardTemplateId, 'default/common');
  });

  test('corrupted record does not prevent valid discoveries loading', () async {
    const repository = SharedPreferencesDiscoveryRepository();
    await repository.saveDiscovery(
      _discovery(id: 'valid-1', customName: 'Mochi'),
    );
    final preferences = await SharedPreferences.getInstance();
    final records = preferences.getStringList('catdex_local_discoveries')!;
    await preferences.setStringList('catdex_local_discoveries', [
      ...records,
      jsonEncode({'id': 'broken-with-missing-fields'}),
      '{invalid-json',
    ]);

    const restartedRepository = SharedPreferencesDiscoveryRepository();
    final restored = await restartedRepository.getDiscoveriesForPlayer(
      'player-1',
    );

    expect(restored, hasLength(1));
    expect(restored.single.id, 'valid-1');
    expect(
      preferences.getStringList('catdex_local_discoveries'),
      hasLength(1),
    );
  });

  test('same display name with different discovery ids is preserved', () async {
    const repository = SharedPreferencesDiscoveryRepository();

    await repository.saveDiscovery(
      _discovery(id: 'discovery-1', customName: 'Lunetta'),
    );
    await repository.saveDiscovery(
      _discovery(id: 'discovery-2', customName: 'Lunetta'),
    );

    final discoveries = await repository.getDiscoveriesForPlayer('player-1');

    expect(discoveries, hasLength(2));
    expect(
      discoveries.map((discovery) => discovery.id),
      unorderedEquals(['discovery-1', 'discovery-2']),
    );
  });

  test(
    'same species with different discovery ids survives app restart',
    () async {
      const repository = SharedPreferencesDiscoveryRepository();
      await repository.saveDiscovery(
        _discovery(id: 'calico-id', customName: 'Calico'),
      );
      await repository.saveDiscovery(
        _discovery(id: 'jack-id', customName: 'Jack'),
      );

      const restartedRepository = SharedPreferencesDiscoveryRepository();
      final discoveries = await restartedRepository.getDiscoveriesForPlayer(
        'player-1',
      );

      expect(discoveries.map((item) => item.id), {'calico-id', 'jack-id'});
    },
  );
}

CatDiscovery _discovery({
  required String id,
  required String customName,
  String? finalCardUrl,
}) {
  return CatDiscovery(
    id: id,
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
    customName: customName,
    suggestedName: 'Mochi',
    originalPhotoPath: 'catdex/originals/original-cat.jpg',
    displayPhotoPath: 'catdex/originals/display-cat.jpg',
    originalPhotoStoragePath: 'catdex/originals/player/$id.jpg',
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
    favorite: true,
    card: CatDiscoveryCard(
      cardId: 'card-$id',
      discoveryId: id,
      cardFrameStyle: 'green_simple_frame',
      cardBackgroundStyle: 'default',
      cardRarityStyle: 'common',
      isEventCard: false,
      cardImageUrl: finalCardUrl,
      illustratedCatImageUrl:
          'https://renderer.example/generated/$id/illustrated-cat.png',
      cardTemplateId: finalCardUrl == null ? 'common_clean' : 'default/common',
      originalPhotoPath: 'catdex/originals/original-cat.jpg',
      generatedAt: DateTime.utc(2026, 6, 29),
    ),
  );
}
