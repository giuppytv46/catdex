import 'package:catdex/features/cards/application/cat_card_legacy_migration.dart';
import 'package:catdex/features/cards/data/merged_cat_card_repository.dart';
import 'package:catdex/features/cards/data/shared_preferences_cat_card_repository.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/events/data/shared_preferences_event_usage_repository.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('one discovery owns a normal card and event cards', () async {
    const repository = SharedPreferencesCatCardRepository();
    await repository.saveCard(_normal());
    await repository.saveCard(_event('halloween_pumpkins'));

    final cards = await repository.getCardsForDiscovery('cat-1');
    expect(cards, hasLength(2));
    expect(cards.map((card) => card.cardType).toSet(), {
      CatCardType.normal,
      CatCardType.event,
    });
    expect(
      (await repository.getNormalCardForDiscovery('cat-1'))?.finalCardUrl,
      contains('/normal/'),
    );
  });

  test('three Halloween variants and Premium coexist', () async {
    const repository = SharedPreferencesCatCardRepository();
    for (final variant in [
      'halloween_pumpkins',
      'halloween_moonlight',
      'halloween_haunted_frame',
      'halloween_witch_cat',
    ]) {
      await repository.saveCard(
        _event(variant, premium: variant == 'halloween_witch_cat'),
      );
    }

    final cards = await repository.getEventCards('halloween_2026', '2026');
    expect(cards, hasLength(4));
    expect(
      cards.map((card) => card.eventArtworkVariantId).toSet(),
      hasLength(4),
    );
  });

  test('two event editions coexist', () async {
    const repository = SharedPreferencesCatCardRepository();
    await repository.saveCard(_event('halloween_pumpkins'));
    await repository.saveCard(
      _event('halloween_pumpkins', edition: '2027'),
    );

    expect(await repository.getCardsForDiscovery('cat-1'), hasLength(2));
  });

  test(
    'normal and event logical uniqueness replace exact identity only',
    () async {
      const repository = SharedPreferencesCatCardRepository();
      await repository.saveCard(_normal(urlSuffix: 'first'));
      await repository.saveCard(_normal(urlSuffix: 'second'));
      await repository.saveCard(_event('halloween_pumpkins'));
      await repository.saveCard(
        _event('halloween_pumpkins', urlSuffix: 'replacement'),
      );

      final cards = await repository.getCardsForDiscovery('cat-1');
      expect(cards, hasLength(2));
      expect(
        (await repository.getNormalCardForDiscovery('cat-1'))?.finalCardUrl,
        contains('second'),
      );
      expect(
        (await repository.getCardById(
          eventCardId(
            discoveryId: 'cat-1',
            eventKey: 'halloween_2026',
            eventEdition: '2026',
            eventArtworkVariantId: 'halloween_pumpkins',
          ),
        ))?.finalCardUrl,
        contains('replacement'),
      );
    },
  );

  test('cards for different discoveries remain separate', () async {
    const repository = SharedPreferencesCatCardRepository();
    await repository.saveCard(_normal());
    await repository.saveCard(_normal(discoveryId: 'cat-2'));

    expect(await repository.getAllCards(), hasLength(2));
  });

  test('normal album count excludes event cards', () {
    final cards = [
      _normal(),
      _event('halloween_pumpkins'),
      _event('halloween_moonlight'),
    ];
    expect(normalCardCountForRarity(cards, CatRarity.common), 1);
  });

  test('local persistence survives repository recreation', () async {
    const first = SharedPreferencesCatCardRepository();
    await first.saveCard(_normal());

    const recreated = SharedPreferencesCatCardRepository();
    expect(
      (await recreated.getCardById(normalCardId('cat-1')))?.isCompleted,
      true,
    );
  });

  test('remote empty result does not remove local card', () async {
    final local = _MemoryCardRepository([_normal()]);
    final merged = MergedCatCardRepository(
      localRepository: local,
      remoteRepository: _MemoryCardRepository([]),
    );

    expect(await merged.getAllCards(), hasLength(1));
  });

  test('null or partial remote URL does not erase valid local URL', () async {
    final localCard = _normal();
    final remotePartial = CatCardRecord(
      cardId: localCard.cardId,
      discoveryId: localCard.discoveryId,
      ownerId: localCard.ownerId,
      cardType: localCard.cardType,
      rarity: localCard.rarity,
      finalCardUrl: '',
      templateKey: localCard.templateKey,
      generationStatus: CatCardGenerationStatus.pending,
      generationRequestId: localCard.generationRequestId,
      idempotencyKey: localCard.idempotencyKey,
      createdAt: localCard.createdAt,
      updatedAt: localCard.updatedAt.add(const Duration(days: 1)),
    );
    final merged = MergedCatCardRepository(
      localRepository: _MemoryCardRepository([localCard]),
      remoteRepository: _MemoryCardRepository([remotePartial]),
    );

    expect(
      (await merged.getAllCards()).single.finalCardUrl,
      localCard.finalCardUrl,
    );
  });

  test('legacy normal and event records migrate with stable identities', () {
    final normal = legacyCardRecordFromDiscovery(
      _legacyDiscovery(event: false),
    );
    final event = legacyCardRecordFromDiscovery(_legacyDiscovery(event: true));

    expect(normal?.cardId, normalCardId('cat-1'));
    expect(normal?.cardType, CatCardType.normal);
    expect(
      event?.cardId,
      eventCardId(
        discoveryId: 'cat-1',
        eventKey: 'halloween_2026',
        eventEdition: '2026',
        eventArtworkVariantId: 'halloween_pumpkins',
      ),
    );
    expect(event?.cardType, CatCardType.event);
  });

  test('repeated legacy migration save is idempotent', () async {
    const repository = SharedPreferencesCatCardRepository();
    final record = legacyCardRecordFromDiscovery(
      _legacyDiscovery(event: true),
    )!;
    await repository.saveCard(record);
    await repository.saveCard(record);

    expect(await repository.getAllCards(), hasLength(1));
  });

  test('legacy migration is idempotent and consumes no event usage', () async {
    const repository = SharedPreferencesCatCardRepository();
    const usage = SharedPreferencesEventUsageRepository();
    await usage.saveSnapshot(
      playerId: 'owner-1',
      eventId: 'halloween_2026',
      snapshot: const EventUsageSnapshot(),
    );

    final first = await migrateLegacyCatCardRecords(
      discoveries: [_legacyDiscovery(event: true)],
      repository: repository,
    );
    final second = await migrateLegacyCatCardRecords(
      discoveries: [_legacyDiscovery(event: true)],
      repository: repository,
    );

    expect(first, 1);
    expect(second, 0);
    expect(await repository.getAllCards(), hasLength(1));
    expect(
      (await usage.getSnapshot(
        playerId: 'owner-1',
        eventId: 'halloween_2026',
      )).committedUsage,
      0,
    );
  });

  test('Premium expiration does not affect owned Premium record', () async {
    const repository = SharedPreferencesCatCardRepository();
    await repository.saveCard(_event('halloween_witch_cat', premium: true));

    final restored = await repository.getCardById(
      eventCardId(
        discoveryId: 'cat-1',
        eventKey: 'halloween_2026',
        eventEdition: '2026',
        eventArtworkVariantId: 'halloween_witch_cat',
      ),
    );
    expect(restored?.isPremiumArtwork, true);
    expect(restored?.isCompleted, true);
  });
}

CatCardRecord _normal({
  String discoveryId = 'cat-1',
  String urlSuffix = 'normal',
}) {
  final now = DateTime.utc(2026, 10, 15);
  return CatCardRecord(
    cardId: normalCardId(discoveryId),
    discoveryId: discoveryId,
    ownerId: 'owner-1',
    cardType: CatCardType.normal,
    rarity: CatRarity.common,
    finalCardUrl: 'https://cards.example/$urlSuffix/final-card.png',
    templateKey: 'default/common',
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'normal-request',
    idempotencyKey: normalCardId(discoveryId),
    createdAt: now,
    updatedAt: now.add(Duration(seconds: urlSuffix.length)),
  );
}

CatCardRecord _event(
  String variant, {
  String edition = '2026',
  bool premium = false,
  String urlSuffix = 'event',
}) {
  final now = DateTime.utc(2026, 10, 15);
  final id = eventCardId(
    discoveryId: 'cat-1',
    eventKey: 'halloween_2026',
    eventEdition: edition,
    eventArtworkVariantId: variant,
  );
  return CatCardRecord(
    cardId: id,
    discoveryId: 'cat-1',
    ownerId: 'owner-1',
    cardType: CatCardType.event,
    rarity: CatRarity.common,
    finalCardUrl: 'https://cards.example/$urlSuffix/$variant/final-card.png',
    templateKey: premium ? 'halloween_witch_cat_premium' : variant,
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'request-$edition-$variant',
    idempotencyKey: id,
    createdAt: now,
    updatedAt: now.add(Duration(seconds: urlSuffix.length)),
    eventKey: 'halloween_2026',
    eventEdition: edition,
    eventArtworkVariantId: variant,
    eventArtworkTier: premium ? 'premium' : 'free',
    eventTemplateKey: premium ? 'halloween_witch_cat_premium' : variant,
    generatedDuringEventAt: now,
    isPremiumArtwork: premium,
  );
}

CatDiscovery _legacyDiscovery({required bool event}) {
  final generatedAt = DateTime.utc(2026, 10, 15);
  return CatDiscovery(
    id: 'cat-1',
    playerId: 'owner-1',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: generatedAt,
    friendshipPoints: 0,
    card: CatDiscoveryCard(
      cardId: 'legacy-card',
      discoveryId: 'cat-1',
      cardFrameStyle: 'default',
      cardBackgroundStyle: 'default',
      cardRarityStyle: 'common',
      isEventCard: event,
      originalPhotoPath: null,
      generatedAt: generatedAt,
      cardImageUrl: 'https://cards.example/legacy/final-card.png',
      cardTemplateId: event ? 'halloween_pumpkins' : 'default/common',
      generationStatus: 'completed',
      eventKey: event ? 'halloween_2026' : null,
      eventEdition: event ? '2026' : null,
      eventArtworkVariantId: event ? 'halloween_pumpkins' : null,
      eventArtworkTier: event ? 'free' : null,
      eventTemplateKey: event ? 'halloween_pumpkins' : null,
    ),
  );
}

class _MemoryCardRepository implements CatCardRepository {
  _MemoryCardRepository(List<CatCardRecord> cards)
    : cards = {for (final card in cards) card.cardId: card};

  final Map<String, CatCardRecord> cards;

  @override
  Future<bool> cardExists(String logicalIdentity) async =>
      cards.values.any((card) => card.logicalIdentity == logicalIdentity);

  @override
  Future<void> deleteCard(String cardId) async => cards.remove(cardId);

  @override
  Future<List<CatCardRecord>> getAllCards() async => cards.values.toList();

  @override
  Future<CatCardRecord?> getCardById(String cardId) async => cards[cardId];

  @override
  Future<List<CatCardRecord>> getCardsForDiscovery(String discoveryId) async =>
      cards.values.where((card) => card.discoveryId == discoveryId).toList();

  @override
  Future<List<CatCardRecord>> getEventCards(
    String eventKey,
    String eventEdition,
  ) async => cards.values
      .where(
        (card) =>
            card.eventKey == eventKey && card.eventEdition == eventEdition,
      )
      .toList();

  @override
  Future<CatCardRecord?> getNormalCardForDiscovery(String discoveryId) async =>
      cards[normalCardId(discoveryId)];

  @override
  Future<void> saveCard(CatCardRecord card) async => cards[card.cardId] = card;
}
