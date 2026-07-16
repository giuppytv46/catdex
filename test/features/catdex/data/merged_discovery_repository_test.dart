import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/merged_discovery_repository.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local and remote discoveries merge by discoveryId', () async {
    final repository = _repository(
      local: [_discovery(id: 'local-1', name: 'Calico')],
      remote: [_discovery(id: 'remote-1', name: 'Jack')],
    );

    final discoveries = await repository.getDiscoveriesForPlayer('player-1');

    expect(discoveries.map((item) => item.id), {
      'local-1',
      'remote-1',
    });
  });

  test('partial remote response does not delete local discoveries', () async {
    final repository = _repository(
      local: [
        _discovery(id: 'calico-id', name: 'Calico'),
        _discovery(id: 'jack-id', name: 'Jack'),
      ],
      remote: [_discovery(id: 'jack-id', name: 'Jack remoto')],
    );

    final discoveries = await repository.getDiscoveriesForPlayer('player-1');

    expect(discoveries.map((item) => item.id), {
      'calico-id',
      'jack-id',
    });
    expect(
      discoveries.singleWhere((item) => item.id == 'jack-id').customName,
      'Jack',
    );
  });

  test('partial local cache does not delete remote discoveries', () async {
    final repository = _repository(
      local: [_discovery(id: 'calico-id', name: 'Calico')],
      remote: [
        _discovery(id: 'calico-id', name: 'Calico remoto'),
        _discovery(id: 'jack-id', name: 'Jack'),
      ],
    );

    final discoveries = await repository.getDiscoveriesForPlayer('player-1');

    expect(discoveries.map((item) => item.id), {
      'calico-id',
      'jack-id',
    });
  });

  test('same name with different discovery ids preserves both', () async {
    final repository = _repository(
      local: [_discovery(id: 'cat-1', name: 'Luna')],
      remote: [_discovery(id: 'cat-2', name: 'Luna')],
    );

    final discoveries = await repository.getDiscoveriesForPlayer('player-1');

    expect(discoveries, hasLength(2));
    expect(discoveries.every((item) => item.customName == 'Luna'), isTrue);
  });

  test(
    'same discovery id is not duplicated and local data is preserved',
    () async {
      final repository = _repository(
        local: [_discovery(id: 'cat-1', name: 'Nome locale')],
        remote: [_discovery(id: 'cat-1', name: 'Nome remoto')],
      );

      final discoveries = await repository.getDiscoveriesForPlayer('player-1');

      expect(discoveries, hasLength(1));
      expect(discoveries.single.customName, 'Nome locale');
    },
  );

  test('local metadata keeps newer generated artwork from remote', () async {
    final repository = _repository(
      local: [_discovery(id: 'cat-1', name: 'Nome locale')],
      remote: [
        _discovery(
          id: 'cat-1',
          name: 'Nome remoto',
          finalCardUrl:
              'https://renderer.example/generated/cat-1/final-card.png',
        ),
      ],
    );

    final discovery = (await repository.getDiscoveriesForPlayer(
      'player-1',
    )).single;

    expect(discovery.customName, 'Nome locale');
    expect(discovery.card?.cardImageUrl, contains('final-card.png'));
  });

  test('partial remote record does not erase complete local fields', () async {
    final repository = _repository(
      local: [
        _discovery(
          id: 'cat-1',
          name: 'Luna locale',
          photoPath: 'catdex/originals/luna.jpg',
          storagePath: 'catdex/originals/player/cat-1.jpg',
          story: 'Storia completa',
          favorite: true,
          finalCardUrl:
              'https://renderer.example/generated/cat-1/final-card.png',
          illustratedCatUrl:
              'https://renderer.example/generated/cat-1/illustrated.png',
          templateKey: 'default/epic',
        ),
      ],
      remote: [_discovery(id: 'cat-1', name: '-')],
    );

    final restored = (await repository.getDiscoveriesForPlayer(
      'player-1',
    )).single;

    expect(restored.customName, 'Luna locale');
    expect(restored.displayPhotoPath, 'catdex/originals/luna.jpg');
    expect(
      restored.originalPhotoStoragePath,
      'catdex/originals/player/cat-1.jpg',
    );
    expect(restored.story, 'Storia completa');
    expect(restored.favorite, isTrue);
    expect(restored.card?.cardImageUrl, contains('final-card.png'));
    expect(restored.card?.illustratedCatImageUrl, contains('illustrated.png'));
    expect(restored.card?.cardTemplateId, 'default/epic');
  });

  test('partial local record does not erase complete remote fields', () async {
    final repository = _repository(
      local: [_discovery(id: 'cat-1', name: '-')],
      remote: [
        _discovery(
          id: 'cat-1',
          name: 'Luna remota',
          photoPath: 'https://images.example/luna.jpg',
          storagePath: 'catdex/originals/player/cat-1.jpg',
          story: 'Storia remota',
          favorite: true,
          finalCardUrl:
              'https://renderer.example/generated/cat-1/final-card.png',
          illustratedCatUrl:
              'https://renderer.example/generated/cat-1/illustrated.png',
          templateKey: 'default/rare',
        ),
      ],
    );

    final restored = (await repository.getDiscoveriesForPlayer(
      'player-1',
    )).single;

    expect(restored.customName, 'Luna remota');
    expect(restored.displayPhotoPath, 'https://images.example/luna.jpg');
    expect(restored.originalPhotoStoragePath, isNotEmpty);
    expect(restored.story, 'Storia remota');
    expect(restored.favorite, isTrue);
    expect(restored.card?.cardImageUrl, contains('final-card.png'));
    expect(restored.card?.illustratedCatImageUrl, contains('illustrated.png'));
    expect(restored.card?.cardTemplateId, 'default/rare');
  });
}

MergedDiscoveryRepository _repository({
  required List<CatDiscovery> local,
  required List<CatDiscovery> remote,
}) {
  return MergedDiscoveryRepository(
    localRepository: InMemoryDiscoveryRepository(discoveries: local),
    remoteRepository: InMemoryDiscoveryRepository(discoveries: remote),
  );
}

CatDiscovery _discovery({
  required String id,
  required String name,
  String? finalCardUrl,
  String? photoPath,
  String? storagePath,
  String? story,
  bool favorite = false,
  String? illustratedCatUrl,
  String templateKey = 'common_clean',
}) {
  return CatDiscovery(
    id: id,
    playerId: 'player-1',
    speciesId: 'domestic_calico_cat',
    variantId: 'normal',
    rarity: CatRarity.uncommon,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 14),
    friendshipPoints: 10,
    customName: name,
    suggestedName: name,
    originalPhotoPath: photoPath,
    displayPhotoPath: photoPath,
    originalPhotoStoragePath: storagePath,
    story: story,
    favorite: favorite,
    card: finalCardUrl == null && illustratedCatUrl == null
        ? null
        : CatDiscoveryCard(
            cardId: 'card-$id',
            discoveryId: id,
            cardFrameStyle: 'default',
            cardBackgroundStyle: 'default',
            cardRarityStyle: 'uncommon',
            isEventCard: false,
            originalPhotoPath: null,
            generatedAt: DateTime.utc(2026, 7, 14, 12),
            cardImageUrl: finalCardUrl,
            illustratedCatImageUrl: illustratedCatUrl,
            cardTemplateId: templateKey,
          ),
  );
}
