import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('same species with different discovery ids preserves both', () {
    final container = _container([
      _discovery(id: 'calico-1', name: 'Calico'),
      _discovery(id: 'calico-2', name: 'Jack'),
    ]);
    addTearDown(container.dispose);

    final discovered = container
        .read(catDexControllerProvider)
        .entries
        .where((entry) => entry.discovered)
        .toList(growable: false);

    expect(discovered, hasLength(2));
    expect(discovered.map((entry) => entry.discovery?.id), {
      'calico-1',
      'calico-2',
    });
  });

  test('missing photo does not remove discovery from CatDex', () {
    final container = _container([
      _discovery(id: 'no-photo', name: 'Senza foto'),
    ]);
    addTearDown(container.dispose);

    final entry = container
        .read(catDexControllerProvider)
        .entries
        .singleWhere((item) => item.discovery?.id == 'no-photo');

    expect(entry.discovered, isTrue);
    expect(entry.discoveredPhotoPath, isNull);
  });

  test('failed card generation does not remove discovery from CatDex', () {
    final container = _container([
      _discovery(id: 'failed-card', name: 'Carta fallita', withCard: true),
    ]);
    addTearDown(container.dispose);

    final entry = container
        .read(catDexControllerProvider)
        .entries
        .singleWhere((item) => item.discovery?.id == 'failed-card');

    expect(entry.discovered, isTrue);
    expect(entry.discovery?.card?.cardImageUrl, isNull);
  });

  test('search filter restores every discovery after clearing query', () {
    final container = _container([
      _discovery(id: 'calico-id', name: 'Calico'),
      _discovery(
        id: 'jack-id',
        name: 'Jack',
        speciesId: 'domestic_tabby_cat',
      ),
    ]);
    addTearDown(container.dispose);
    final controller = container.read(catDexControllerProvider.notifier)
      ..updateSearchQuery('Calico');
    expect(
      container
          .read(catDexControllerProvider)
          .visibleEntries
          .where((entry) => entry.discovered)
          .single
          .discovery
          ?.id,
      'calico-id',
    );

    controller.updateSearchQuery('');
    expect(
      container
          .read(catDexControllerProvider)
          .visibleEntries
          .where((entry) => entry.discovered),
      hasLength(2),
    );
  });

  test('normal album entries ignore event card records', () {
    final first = _discovery(id: 'cat-1', name: 'Luna');
    final second = _discovery(id: 'cat-2', name: 'Mochi');
    final normal = _cardRecord(
      discoveryId: first.id,
      type: CatCardType.normal,
    );
    final eventForFirst = _cardRecord(
      discoveryId: first.id,
      type: CatCardType.event,
      variant: 'halloween_pumpkins',
    );
    final eventForSecond = _cardRecord(
      discoveryId: second.id,
      type: CatCardType.event,
      variant: 'halloween_moonlight',
    );
    final container = _container(
      [first, second],
      cards: [normal, eventForFirst, eventForSecond],
    );
    addTearDown(container.dispose);

    final entries = container
        .read(catDexControllerProvider)
        .entries
        .where((entry) => entry.discovery != null)
        .toList(growable: false);

    expect(entries.where((entry) => entry.cardRecord != null), hasLength(1));
    expect(
      entries
          .singleWhere((entry) => entry.discovery?.id == first.id)
          .cardRecord,
      normal,
    );
    expect(
      entries
          .singleWhere((entry) => entry.discovery?.id == second.id)
          .cardRecord,
      isNull,
    );
  });
}

ProviderContainer _container(
  List<CatDiscovery> discoveries, {
  List<CatCardRecord> cards = const [],
}) {
  final cardRepository = _MemoryCardRepository(cards);
  return ProviderContainer(
    overrides: [
      localDiscoverySessionProvider.overrideWith(
        () => _SeededDiscoverySession(discoveries),
      ),
      catCardRepositoryProvider.overrideWithValue(cardRepository),
      catCardCollectionProvider.overrideWith(
        () => _SeededCardCollection(cards),
      ),
    ],
  );
}

class _SeededDiscoverySession extends LocalDiscoverySessionController {
  _SeededDiscoverySession(this.discoveries);

  final List<CatDiscovery> discoveries;

  @override
  List<CatDiscovery> build() => discoveries;
}

class _SeededCardCollection extends CatCardCollectionController {
  _SeededCardCollection(this.cards);

  final List<CatCardRecord> cards;

  @override
  List<CatCardRecord> build() => cards;
}

class _MemoryCardRepository implements CatCardRepository {
  _MemoryCardRepository(List<CatCardRecord> cards)
    : _cards = {for (final card in cards) card.cardId: card};

  final Map<String, CatCardRecord> _cards;

  @override
  Future<bool> cardExists(String logicalIdentity) async =>
      _cards.values.any((card) => card.logicalIdentity == logicalIdentity);

  @override
  Future<void> deleteCard(String cardId) async => _cards.remove(cardId);

  @override
  Future<List<CatCardRecord>> getAllCards() async => _cards.values.toList();

  @override
  Future<CatCardRecord?> getCardById(String cardId) async => _cards[cardId];

  @override
  Future<List<CatCardRecord>> getCardsForDiscovery(String discoveryId) async =>
      _cards.values.where((card) => card.discoveryId == discoveryId).toList();

  @override
  Future<List<CatCardRecord>> getEventCards(
    String eventKey,
    String eventEdition,
  ) async => _cards.values
      .where(
        (card) =>
            card.cardType == CatCardType.event &&
            card.eventKey == eventKey &&
            card.eventEdition == eventEdition,
      )
      .toList();

  @override
  Future<CatCardRecord?> getNormalCardForDiscovery(String discoveryId) async =>
      _cards[normalCardId(discoveryId)];

  @override
  Future<void> saveCard(CatCardRecord card) async {
    _cards[card.cardId] = card;
  }
}

CatDiscovery _discovery({
  required String id,
  required String name,
  String speciesId = 'domestic_calico_cat',
  bool withCard = false,
}) {
  final discoveredAt = DateTime.utc(2026, 7, 14);
  return CatDiscovery(
    id: id,
    playerId: 'local-explorer',
    speciesId: speciesId,
    variantId: 'normal',
    rarity: CatRarity.uncommon,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: discoveredAt,
    friendshipPoints: 10,
    customName: name,
    card: withCard
        ? CatDiscoveryCard(
            cardId: 'card-$id',
            discoveryId: id,
            cardFrameStyle: 'default',
            cardBackgroundStyle: 'default',
            cardRarityStyle: 'uncommon',
            isEventCard: false,
            originalPhotoPath: null,
            generatedAt: discoveredAt,
          )
        : null,
  );
}

CatCardRecord _cardRecord({
  required String discoveryId,
  required CatCardType type,
  String? variant,
}) {
  final id = type == CatCardType.normal
      ? normalCardId(discoveryId)
      : eventCardId(
          discoveryId: discoveryId,
          eventKey: 'halloween_2026',
          eventEdition: '2026',
          eventArtworkVariantId: variant!,
        );
  return CatCardRecord(
    cardId: id,
    discoveryId: discoveryId,
    ownerId: 'local-explorer',
    cardType: type,
    rarity: CatRarity.uncommon,
    finalCardUrl: 'https://cards.example/$id/final-card.png',
    templateKey: type == CatCardType.normal ? 'default/uncommon' : variant!,
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: id,
    idempotencyKey: id,
    createdAt: DateTime.utc(2026, 10, 15),
    updatedAt: DateTime.utc(2026, 10, 15),
    eventKey: type == CatCardType.event ? 'halloween_2026' : null,
    eventEdition: type == CatCardType.event ? '2026' : null,
    eventArtworkVariantId: variant,
    eventArtworkTier: type == CatCardType.event ? 'free' : null,
    eventTemplateKey: variant,
  );
}
