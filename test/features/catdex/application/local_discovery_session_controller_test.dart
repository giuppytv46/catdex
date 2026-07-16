import 'dart:async';

import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('addDiscovery upserts instead of duplicating', () {
    final repository = _FakeDiscoveryRepository();
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(localDiscoverySessionProvider.notifier)
      ..addDiscovery(_discovery(id: 'cat-1', name: 'Mochi'))
      ..addDiscovery(_discovery(id: 'cat-1', name: 'Mochi Due'));

    final discoveries = container.read(localDiscoverySessionProvider);
    expect(discoveries, hasLength(1));
    expect(discoveries.single.customName, 'Mochi Due');
  });

  test('refreshFromRepository replaces session without duplicates', () async {
    final repository = _FakeDiscoveryRepository(
      discoveries: [_discovery(id: 'cat-1', name: 'Mochi')],
    );
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await (container.read(localDiscoverySessionProvider.notifier)
          ..addDiscovery(_discovery(id: 'cat-1', name: 'Old Mochi')))
        .refreshFromRepository();

    final discoveries = container.read(localDiscoverySessionProvider);
    expect(discoveries, hasLength(1));
    expect(discoveries.single.customName, 'Mochi');
  });

  test('refreshFromRepository dedupes repeated discovery ids', () async {
    final repository = _FakeDiscoveryRepository(
      discoveries: [
        _discovery(id: 'cat-1', name: 'Lunetta'),
        _discovery(id: 'cat-1', name: 'Lunetta duplicate'),
        _discovery(id: 'cat-2', name: 'Lunetta'),
      ],
    );
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(localDiscoverySessionProvider.notifier)
        .refreshFromRepository();

    final discoveries = container.read(localDiscoverySessionProvider);
    expect(discoveries, hasLength(2));
    expect(
      discoveries.map((discovery) => discovery.id),
      unorderedEquals(['cat-1', 'cat-2']),
    );
    expect(
      discoveries.where((discovery) => discovery.customName == 'Lunetta'),
      hasLength(2),
    );
  });

  test('refreshDiscoveryById updates completed card artwork', () async {
    final repository = _FakeDiscoveryRepository(
      discoveries: [
        _discovery(
          id: 'cat-1',
          name: 'Mochi',
          finalCardUrl:
              'https://catdex-card-renderer-alpha.onrender.com/generated/cards/cat-1/final-card.png',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await (container.read(localDiscoverySessionProvider.notifier)
          ..addDiscovery(_discovery(id: 'cat-1', name: 'Mochi')))
        .refreshDiscoveryById('cat-1');

    final discovery = container.read(localDiscoverySessionProvider).single;
    expect(discovery.card?.cardImageUrl, contains('final-card.png'));
  });

  test('refresh does not reset an already generated card', () async {
    final repository = _FakeDiscoveryRepository(
      discoveries: [
        _discovery(id: 'cat-1', name: 'Mochi', includePhoto: false),
      ],
    );
    final generated = _discovery(
      id: 'cat-1',
      name: 'Mochi',
      finalCardUrl:
          'https://catdex-card-renderer-alpha.onrender.com/generated/cards/cat-1/final-card.png',
    );
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await (container.read(
      localDiscoverySessionProvider.notifier,
    )..addDiscovery(generated)).refreshFromRepository();

    final refreshed = container.read(localDiscoverySessionProvider).single;
    expect(refreshed.card?.cardImageUrl, contains('final-card.png'));
    expect(refreshed.displayPhotoPath, '/tmp/cat.jpg');
    expect(
      refreshed.originalPhotoStoragePath,
      'catdex/originals/player/cat-1.jpg',
    );
  });

  test('startup restoration does not block the initial state', () async {
    final completer = Completer<List<CatDiscovery>>();
    final repository = _DeferredDiscoveryRepository(completer.future);
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(container.read(localDiscoverySessionProvider), isEmpty);

    completer.complete([_discovery(id: 'cat-1', name: 'Mochi')]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(localDiscoverySessionProvider), hasLength(1));
  });

  test('saved discovery survives a partial repository refresh', () async {
    final repository = _FakeDiscoveryRepository(
      discoveries: [_discovery(id: 'persisted-1', name: 'Persistita')],
    );
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(localDiscoverySessionProvider.notifier)
      ..addDiscovery(_discovery(id: 'new-local', name: 'Nuova'));

    await controller.refreshFromRepository();

    expect(
      container.read(localDiscoverySessionProvider).map((item) => item.id),
      {'persisted-1', 'new-local'},
    );
  });

  test('Calico and Jack style ids remain after refresh', () async {
    const calicoId = '3a44c321-886a-4b3e-a825-f63c33131738';
    const jackId = '9251941b-e22a-4cb0-b650-c09471acea9d';
    final repository = _FakeDiscoveryRepository(
      discoveries: [_discovery(id: calicoId, name: 'Calico')],
    );
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(localDiscoverySessionProvider.notifier)
      ..addDiscovery(_discovery(id: calicoId, name: 'Calico'))
      ..addDiscovery(_discovery(id: jackId, name: 'Jack'));

    await controller.refreshFromRepository();

    expect(
      container.read(localDiscoverySessionProvider).map((item) => item.id),
      {calicoId, jackId},
    );
  });

  test(
    'repeated Cards-style refresh does not alter CatDex discoveries',
    () async {
      final repository = _FakeDiscoveryRepository(
        discoveries: [_discovery(id: 'cat-1', name: 'Calico')],
      );
      final container = ProviderContainer(
        overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(localDiscoverySessionProvider.notifier)
        ..addDiscovery(_discovery(id: 'cat-1', name: 'Calico'))
        ..addDiscovery(_discovery(id: 'cat-2', name: 'Jack'));

      await controller.refreshFromRepository();
      await controller.refreshFromRepository();

      final discoveries = container.read(localDiscoverySessionProvider);
      expect(discoveries.map((item) => item.id), {'cat-1', 'cat-2'});
      expect(discoveries, hasLength(2));
    },
  );
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository({List<CatDiscovery> discoveries = const []})
    : _discoveries = [...discoveries];

  final List<CatDiscovery> _discoveries;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    return _discoveries
        .where((discovery) => discovery.playerId == playerId)
        .toList(growable: false);
  }

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    for (final discovery in _discoveries) {
      if (discovery.id == id) {
        return discovery;
      }
    }

    return null;
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    return _discoveries.any(
      (discovery) =>
          discovery.playerId == playerId && discovery.speciesId == speciesId,
    );
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    _discoveries
      ..removeWhere((item) => item.id == discovery.id)
      ..insert(0, discovery);
  }
}

class _DeferredDiscoveryRepository implements DiscoveryRepository {
  _DeferredDiscoveryRepository(this.discoveries);

  final Future<List<CatDiscovery>> discoveries;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) {
    return discoveries;
  }

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async => null;

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async => false;

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {}
}

CatDiscovery _discovery({
  required String id,
  required String name,
  String? finalCardUrl,
  bool includePhoto = true,
}) {
  final discoveredAt = DateTime.utc(2026, 7, 11);
  return CatDiscovery(
    id: id,
    playerId: LocalPlayerSession.playerId,
    speciesId: 'domestic_tabby_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: discoveredAt,
    friendshipPoints: 10,
    customName: name,
    suggestedName: name,
    originalPhotoPath: includePhoto ? '/tmp/cat.jpg' : null,
    displayPhotoPath: includePhoto ? '/tmp/cat.jpg' : null,
    originalPhotoStoragePath: includePhoto
        ? 'catdex/originals/player/$id.jpg'
        : null,
    story: 'Un gatto entra nel CatDex.',
    funFact: 'Ogni gatto e unico.',
    coatColor: 'marrone',
    coatPattern: 'tigrato',
    eyeColor: 'occhi gialli',
    hairLength: 'pelo corto',
    estimatedAge: 'adulto',
    xpEarned: 80,
    coinsEarned: 15,
    confidenceScore: 0.9,
    card: CatDiscoveryCard(
      cardId: 'card_$id',
      discoveryId: id,
      cardFrameStyle: 'green_simple_frame',
      cardBackgroundStyle: 'default',
      cardRarityStyle: 'common',
      isEventCard: false,
      cardImageUrl: finalCardUrl,
      originalPhotoPath: '/tmp/cat.jpg',
      generatedAt: discoveredAt,
    ),
  );
}
