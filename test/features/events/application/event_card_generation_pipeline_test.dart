import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_generation_pipeline.dart';
import 'package:catdex/features/cards/application/cat_card_legacy_migration.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/data/shared_preferences_cat_card_repository.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/events/application/event_generation_coordinator.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/events/data/shared_preferences_event_usage_repository.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:catdex/features/events/domain/services/halloween_event_catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('event usage commits only after persistence readback', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final repository = _MemoryDiscoveryRepository(_discovery());
    final cards = _MemoryCatCardRepository();
    final remote = _EventRemoteCardGenerationService();
    final container = _container(
      repository: repository,
      cards: cards,
      remote: remote,
      usage: usage,
    );
    addTearDown(container.dispose);

    final result = await container
        .read(cardGenerationPipelineProvider)
        .generateEventCard(
          event: _activeTestEvent,
          discovery: _discovery(),
          displayData: _displayData,
          collectionNumber: 1,
        );

    expect(result.success, isTrue);
    final snapshot = await usage.getSnapshot(
      playerId: 'local-explorer',
      eventId: 'halloween_2026',
    );
    expect(snapshot.committedUsage, 1);
    expect(snapshot.ownedVariantIds, {'halloween_pumpkins'});
    expect(cards.readCount, greaterThanOrEqualTo(1));
    expect(cards.savedCards, hasLength(1));
    expect(cards.savedCards.single.cardType, CatCardType.event);
    expect(cards.savedCards.single.eventArtworkVariantId, 'halloween_pumpkins');
    expect(result.discovery.card, isNull);
  });

  test(
    'persistence failure releases event reservation without usage',
    () async {
      const usage = SharedPreferencesEventUsageRepository();
      final normal = _normalCardRecord();
      final cards = _MemoryCatCardRepository(
        initialCards: [normal],
        failEventPersistence: true,
      );
      final container = _container(
        repository: _MemoryDiscoveryRepository(_discovery()),
        cards: cards,
        remote: _EventRemoteCardGenerationService(),
        usage: usage,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: _discovery(),
            displayData: _displayData,
            collectionNumber: 1,
          );

      expect(result.success, isFalse);
      expect(
        result.eventFailure,
        EventCardGenerationFailure.eventPersistenceFailed,
      );
      expect(
        (await usage.getSnapshot(
          playerId: 'local-explorer',
          eventId: 'halloween_2026',
        )).committedUsage,
        0,
      );
      expect(await cards.getNormalCardForDiscovery(_discovery().id), normal);
      expect(await cards.getEventCards('halloween_2026', '2026'), isEmpty);
    },
  );

  test(
    'existing event card is preserved while another variant is added',
    () async {
      final existing = _discovery(card: _eventCard());
      final legacyRecord = legacyCardRecordFromDiscovery(existing)!;
      final cards = _MemoryCatCardRepository(initialCards: [legacyRecord]);
      final remote = _EventRemoteCardGenerationService();
      final container = _container(
        repository: _MemoryDiscoveryRepository(existing),
        cards: cards,
        remote: remote,
        usage: const SharedPreferencesEventUsageRepository(),
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: existing,
            displayData: _displayData,
            collectionNumber: 1,
          );

      expect(result.success, isTrue);
      expect(remote.calls, 1);
      final eventCards = await cards.getEventCards('halloween_2026', '2026');
      expect(eventCards, hasLength(2));
      expect(
        eventCards
            .singleWhere(
              (card) => card.eventArtworkVariantId == 'halloween_witch_cat',
            )
            .finalCardUrl,
        legacyRecord.finalCardUrl,
      );
      expect(
        eventCards.map((card) => card.eventArtworkVariantId),
        contains('halloween_pumpkins'),
      );
    },
  );

  for (final pendingReason in RemoteCardGenerationPendingReason.values) {
    test('${pendingReason.name} recovery commits one event use', () async {
      const usage = SharedPreferencesEventUsageRepository();
      final remote = _EventRemoteCardGenerationService(
        pendingReason: pendingReason,
      );
      final cards = _MemoryCatCardRepository();
      final container = _container(
        repository: _MemoryDiscoveryRepository(_discovery()),
        cards: cards,
        remote: remote,
        usage: usage,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: _discovery(),
            displayData: _displayData,
            collectionNumber: 1,
          );

      expect(result.success, isTrue);
      expect(remote.calls, 1);
      expect(
        (await usage.getSnapshot(
          playerId: 'local-explorer',
          eventId: 'halloween_2026',
        )).committedUsage,
        1,
      );
      expect(cards.savedCards, hasLength(1));
    });
  }

  test(
    'event metadata survives repository recreation and expiration',
    () async {
      const first = SharedPreferencesCatCardRepository();
      final record = legacyCardRecordFromDiscovery(
        _discovery(card: _eventCard()),
      )!;
      await first.saveCard(record);

      const recreated = SharedPreferencesCatCardRepository();
      final restored = await recreated.getCardById(record.cardId);

      expect(restored?.eventKey, 'halloween_2026');
      expect(restored?.eventEdition, '2026');
      expect(restored?.eventArtworkVariantId, 'halloween_witch_cat');
      expect(restored?.eventArtworkTier, 'premium');
      expect(restored?.cardType, CatCardType.event);
      expect(restored?.finalCardUrl, isNotEmpty);
      expect(halloween2026Event.isActiveAt(DateTime.utc(2027)), isFalse);
    },
  );

  test('production runtime does not trust a client Premium boolean', () {
    const runtime = EventRuntimeConfiguration();
    expect(runtime.premiumTestEntitlementEnabled, isFalse);
  });
}

ProviderContainer _container({
  required DiscoveryRepository repository,
  required RemoteCardGenerationService remote,
  required SharedPreferencesEventUsageRepository usage,
  CatCardRepository? cards,
}) {
  return ProviderContainer(
    overrides: [
      discoveryRepositoryProvider.overrideWithValue(repository),
      catCardRepositoryProvider.overrideWithValue(
        cards ?? _MemoryCatCardRepository(),
      ),
      remoteCardGenerationServiceProvider.overrideWithValue(remote),
      eventUsageRepositoryProvider.overrideWithValue(usage),
      eventGenerationCoordinatorProvider.overrideWithValue(
        EventGenerationCoordinator(usageRepository: usage),
      ),
      eventRuntimeConfigurationProvider.overrideWithValue(
        const _AlwaysActiveEventRuntime(),
      ),
    ],
  );
}

class _AlwaysActiveEventRuntime extends EventRuntimeConfiguration {
  const _AlwaysActiveEventRuntime();

  @override
  CatDexEvent? activeEvent(DateTime now) => _activeTestEvent;

  @override
  bool get premiumTestEntitlementEnabled => false;
}

class _EventRemoteCardGenerationService extends RemoteCardGenerationService {
  _EventRemoteCardGenerationService({this.pendingReason})
    : super(endpoint: 'https://renderer.example/api/generate-card');

  final RemoteCardGenerationPendingReason? pendingReason;
  int calls = 0;

  @override
  Future<RemoteGeneratedCard?> generateCard({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    String? debugRarityOverride,
    EventCardGenerationRequest? eventRequest,
    void Function(RemoteCardGenerationPendingReason)? onPending,
  }) async {
    calls += 1;
    final pending = pendingReason;
    if (pending != null) onPending?.call(pending);
    final request = eventRequest!;
    return RemoteGeneratedCard(
      finalCardUrl:
          'https://renderer.example/generated/${discovery.id}/final-card.png',
      illustratedCatUrl:
          'https://renderer.example/generated/${discovery.id}/cat.png',
      selectedTemplateKey: 'events/${request.eventKey}/${request.templateKey}',
      eventKey: request.eventKey,
      eventEdition: request.eventEdition,
      eventArtworkVariantId: request.variantId,
      eventArtworkTier: request.tier.wireValue,
      eventTemplateKey: request.templateKey,
      generationStatus: 'completed',
      isEventCard: true,
    );
  }
}

class _MemoryDiscoveryRepository implements DiscoveryRepository {
  _MemoryDiscoveryRepository(this.discovery);

  CatDiscovery? discovery;
  int readCount = 0;

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    readCount += 1;
    return discovery;
  }

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    return discovery == null ? const [] : [discovery!];
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async => false;

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    this.discovery = discovery;
  }
}

class _MemoryCatCardRepository implements CatCardRepository {
  _MemoryCatCardRepository({
    List<CatCardRecord> initialCards = const [],
    this.failEventPersistence = false,
  }) : _cards = {for (final card in initialCards) card.cardId: card};

  final Map<String, CatCardRecord> _cards;
  final bool failEventPersistence;
  int readCount = 0;

  List<CatCardRecord> get savedCards => _cards.values.toList(growable: false);

  @override
  Future<bool> cardExists(String logicalIdentity) async {
    return _cards.values.any((card) => card.logicalIdentity == logicalIdentity);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    _cards.remove(cardId);
  }

  @override
  Future<List<CatCardRecord>> getAllCards() async => savedCards;

  @override
  Future<CatCardRecord?> getCardById(String cardId) async {
    readCount += 1;
    return _cards[cardId];
  }

  @override
  Future<List<CatCardRecord>> getCardsForDiscovery(String discoveryId) async {
    return _cards.values
        .where((card) => card.discoveryId == discoveryId)
        .toList(growable: false);
  }

  @override
  Future<List<CatCardRecord>> getEventCards(
    String eventKey,
    String eventEdition,
  ) async {
    return _cards.values
        .where(
          (card) =>
              card.cardType == CatCardType.event &&
              card.eventKey == eventKey &&
              card.eventEdition == eventEdition,
        )
        .toList(growable: false);
  }

  @override
  Future<CatCardRecord?> getNormalCardForDiscovery(String discoveryId) async {
    return _cards[normalCardId(discoveryId)];
  }

  @override
  Future<void> saveCard(CatCardRecord card) async {
    if (failEventPersistence && card.cardType == CatCardType.event) {
      throw StateError('event persistence failed');
    }
    _cards[card.cardId] = card;
  }
}

CatDiscovery _discovery({CatDiscoveryCard? card}) {
  return CatDiscovery(
    id: 'event-discovery-1',
    playerId: 'local-explorer',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 10, 15),
    friendshipPoints: 0,
    customName: 'Luna',
    suggestedName: 'Luna',
    originalPhotoPath: 'https://example.test/luna.jpg',
    displayPhotoPath: 'https://example.test/luna.jpg',
    card: card,
  );
}

CatDiscoveryCard _eventCard() {
  return CatDiscoveryCard(
    cardId: 'event-card-1',
    discoveryId: 'event-discovery-1',
    cardFrameStyle: 'halloween',
    cardBackgroundStyle: 'halloween',
    cardRarityStyle: 'common',
    isEventCard: true,
    originalPhotoPath: 'https://example.test/luna.jpg',
    generatedAt: DateTime.utc(2026, 10, 15),
    cardImageUrl:
        'https://renderer.example/generated/event-discovery-1/final-card.png',
    cardTemplateId: 'halloween_witch_cat_premium',
    generationStatus: 'completed',
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    eventArtworkVariantId: 'halloween_witch_cat',
    eventArtworkTier: 'premium',
    eventTemplateKey: 'halloween_witch_cat_premium',
    generatedDuringEventAt: DateTime.utc(2026, 10, 15),
  );
}

CatCardRecord _normalCardRecord() {
  return CatCardRecord(
    cardId: normalCardId(_discovery().id),
    discoveryId: _discovery().id,
    ownerId: 'local-explorer',
    cardType: CatCardType.normal,
    rarity: CatRarity.common,
    finalCardUrl:
        'https://renderer.example/generated/event-discovery-1/normal/final-card.png',
    templateKey: 'default/common',
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: normalCardId(_discovery().id),
    idempotencyKey: normalCardId(_discovery().id),
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10),
  );
}

const _displayData = CatDisplayData(
  displayName: 'Luna',
  displaySpecies: 'Gatto domestico',
  displayCoatColor: 'Nero/bianco',
  displayCoatPattern: 'Bicolore',
  displayEyeColor: 'occhi ambrati',
  displayHairLength: 'Corto',
  displayAge: '-',
  displayPersonality: 'Curiosa',
  displayRarity: 'Comune',
  displayVariant: 'Normale',
  displayStory: '',
  displayFunFact: '',
);

final _activeTestEvent = CatDexEvent(
  id: halloween2026Event.id,
  edition: halloween2026Event.edition,
  startsAt: DateTime.utc(2026, 7),
  endsAt: DateTime.utc(2026, 12),
  standardVariantId: halloween2026Event.standardVariantId,
  standardVariantIds: halloween2026Event.standardVariantIds,
  premiumVariantId: halloween2026Event.premiumVariantId,
  premiumGenerationLimit: halloween2026Event.premiumGenerationLimit,
  variantTemplateKeys: halloween2026Event.variantTemplateKeys,
  variantInstructionKeys: halloween2026Event.variantInstructionKeys,
  variantWeights: halloween2026Event.variantWeights,
);
