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
import 'package:catdex/features/events/application/event_card_ui_generation_controller.dart';
import 'package:catdex/features/events/application/event_generation_coordinator.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/events/data/shared_preferences_event_usage_repository.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:catdex/features/events/domain/entities/event_card_xp_reward.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/events/domain/services/halloween_event_catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final entry in const <EventCardGenerationFailure, EventUiFailureReason>{
    EventCardGenerationFailure.eventVariantInvalid:
        EventUiFailureReason.eventVariantInvalid,
    EventCardGenerationFailure.eventVariantDisabled:
        EventUiFailureReason.eventVariantDisabled,
    EventCardGenerationFailure.selectedVariantInvalid:
        EventUiFailureReason.selectedVariantInvalid,
  }.entries) {
    test('${entry.key.name} maps to a typed non-network UI failure', () {
      final result = mapEventGenerationFailureToUiReason(
        eventFailure: entry.key,
        remoteFailure: RemoteCardGenerationFailureReason.remoteApiFailure,
      );

      expect(result, entry.value);
      expect(result, isNot(EventUiFailureReason.network));
    });
  }

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
    expect(result.eventXpAward?.newlyGranted, isTrue);
    expect(result.eventXpAward?.awardedAmount, eventCardGenerationXp);
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
      expect(
        (await SharedPreferences.getInstance()).getString(
          'catdex_event_card_xp_ledger_v1',
        ),
        isNull,
      );
    },
  );

  test('event usage commit failure awards no XP', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final coordinator = _CommitFailingCoordinator(usage);
    final container = _container(
      repository: _MemoryDiscoveryRepository(_discovery()),
      cards: _MemoryCatCardRepository(),
      remote: _EventRemoteCardGenerationService(),
      usage: usage,
      coordinator: coordinator,
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
    expect(result.eventXpAward, isNull);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'catdex_event_card_xp_ledger_v1',
      ),
      isNull,
    );
  });

  for (final failureReason in [
    RemoteCardGenerationFailureReason.missingPhoto,
    RemoteCardGenerationFailureReason.storagePermissionDenied,
  ]) {
    test(
      '${failureReason.name} releases reservation without event usage',
      () async {
        const usage = SharedPreferencesEventUsageRepository();
        final remote = _EventRemoteCardGenerationService(
          failureReason: failureReason,
        );
        final container = _container(
          repository: _MemoryDiscoveryRepository(_discovery()),
          cards: _MemoryCatCardRepository(),
          remote: remote,
          usage: usage,
        );
        addTearDown(container.dispose);

        for (var attempt = 0; attempt < 2; attempt += 1) {
          final result = await container
              .read(cardGenerationPipelineProvider)
              .generateEventCard(
                event: _activeTestEvent,
                discovery: _discovery(),
                displayData: _displayData,
                collectionNumber: 1,
              );
          expect(result.success, isFalse);
          expect(result.failureReason, failureReason);
        }

        expect(remote.calls, 2);
        expect(
          (await usage.getSnapshot(
            playerId: 'local-explorer',
            eventId: 'halloween_2026',
          )).committedUsage,
          0,
        );
      },
    );
  }

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

  test('Premium generation requires a selected variant', () async {
    final remote = _EventRemoteCardGenerationService();
    final container = _container(
      repository: _MemoryDiscoveryRepository(_discovery()),
      cards: _MemoryCatCardRepository(),
      remote: remote,
      usage: const SharedPreferencesEventUsageRepository(),
      premium: true,
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

    expect(
      result.eventFailure,
      EventCardGenerationFailure.variantSelectionRequired,
    );
    expect(remote.calls, 0);
  });

  test(
    'selected Premium variant reaches renderer and persisted record',
    () async {
      final remote = _EventRemoteCardGenerationService();
      final cards = _MemoryCatCardRepository();
      final container = _container(
        repository: _MemoryDiscoveryRepository(_discovery()),
        cards: cards,
        remote: remote,
        usage: const SharedPreferencesEventUsageRepository(),
        premium: true,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: _discovery(),
            displayData: _displayData,
            collectionNumber: 1,
            selectedVariantId: 'halloween_haunted_frame',
          );

      expect(result.success, isTrue);
      expect(remote.lastEventRequest?.variantId, 'halloween_haunted_frame');
      expect(remote.lastEventRequest?.tier, EventArtworkTier.free);
      expect(
        cards.savedCards.single.eventArtworkVariantId,
        'halloween_haunted_frame',
      );
    },
  );

  for (final variant in const [
    'halloween_pumpkin_king',
    'halloween_night_spirit',
  ]) {
    test('$variant reaches renderer with exact persisted metadata', () async {
      final remote = _EventRemoteCardGenerationService();
      final cards = _MemoryCatCardRepository();
      final container = _container(
        repository: _MemoryDiscoveryRepository(_discovery()),
        cards: cards,
        remote: remote,
        usage: const SharedPreferencesEventUsageRepository(),
        premium: true,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: _discovery(),
            displayData: _displayData,
            collectionNumber: 1,
            selectedVariantId: variant,
          );

      final expectedTemplate = halloween2026Event.templateKeyFor(variant);
      expect(result.success, isTrue);
      expect(remote.lastEventRequest?.variantId, variant);
      expect(remote.lastEventRequest?.tier, EventArtworkTier.premium);
      expect(remote.lastEventRequest?.templateKey, expectedTemplate);
      expect(cards.savedCards.single.eventArtworkVariantId, variant);
      expect(cards.savedCards.single.eventArtworkTier, 'premium');
      expect(cards.savedCards.single.eventTemplateKey, expectedTemplate);
    });
  }

  test('one Premium cat can collect all six distinct variants', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final remote = _EventRemoteCardGenerationService();
    final cards = _MemoryCatCardRepository();
    final container = _container(
      repository: _MemoryDiscoveryRepository(_discovery()),
      cards: cards,
      remote: remote,
      usage: usage,
      premium: true,
    );
    addTearDown(container.dispose);

    for (final variant in _activeTestEvent.allVariantIds) {
      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: _discovery(),
            displayData: _displayData,
            collectionNumber: 1,
            selectedVariantId: variant,
          );
      expect(result.success, isTrue, reason: variant);
    }

    expect(
      cards.savedCards.map((card) => card.logicalIdentity).toSet(),
      hasLength(6),
    );
    expect(
      cards.savedCards.map((card) => card.eventArtworkVariantId).toSet(),
      _activeTestEvent.allVariantIds.toSet(),
    );
    expect(remote.calls, 6);
  });

  test(
    'same cat and variant is blocked without consuming another use',
    () async {
      const usage = SharedPreferencesEventUsageRepository();
      final existing = _eventRecordFor(
        discoveryId: _discovery().id,
        variant: 'halloween_haunted_frame',
      );
      final remote = _EventRemoteCardGenerationService();
      final container = _container(
        repository: _MemoryDiscoveryRepository(_discovery()),
        cards: _MemoryCatCardRepository(initialCards: [existing]),
        remote: remote,
        usage: usage,
        premium: true,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: _discovery(),
            displayData: _displayData,
            collectionNumber: 1,
            selectedVariantId: 'halloween_haunted_frame',
          );

      expect(
        result.eventFailure,
        EventCardGenerationFailure.selectedVariantAlreadyOwned,
      );
      expect(remote.calls, 0);
      expect(
        (await usage.getSnapshot(
          playerId: 'local-explorer',
          eventId: 'halloween_2026',
        )).committedUsage,
        1,
      );
    },
  );

  test('same selected variant remains available for another cat', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final cards = _MemoryCatCardRepository(
      initialCards: [
        _eventRecordFor(
          discoveryId: 'different-cat',
          variant: 'halloween_haunted_frame',
        ),
      ],
    );
    final remote = _EventRemoteCardGenerationService();
    final container = _container(
      repository: _MemoryDiscoveryRepository(_discovery()),
      cards: cards,
      remote: remote,
      usage: usage,
      premium: true,
    );
    addTearDown(container.dispose);

    final result = await container
        .read(cardGenerationPipelineProvider)
        .generateEventCard(
          event: _activeTestEvent,
          discovery: _discovery(),
          displayData: _displayData,
          collectionNumber: 1,
          selectedVariantId: 'halloween_haunted_frame',
        );

    expect(result.success, isTrue);
    expect(remote.calls, 1);
    expect(
      cards.savedCards.where(
        (card) => card.eventArtworkVariantId == 'halloween_haunted_frame',
      ),
      hasLength(2),
    );
  });

  test(
    'renderer variant mismatch releases reservation before persistence',
    () async {
      const usage = SharedPreferencesEventUsageRepository();
      final cards = _MemoryCatCardRepository();
      final remote = _EventRemoteCardGenerationService(
        responseVariantOverride: 'halloween_moonlight',
      );
      final container = _container(
        repository: _MemoryDiscoveryRepository(_discovery()),
        cards: cards,
        remote: remote,
        usage: usage,
        premium: true,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: _activeTestEvent,
            discovery: _discovery(),
            displayData: _displayData,
            collectionNumber: 1,
            selectedVariantId: 'halloween_haunted_frame',
          );

      expect(
        result.eventFailure,
        EventCardGenerationFailure.eventArtworkValidationFailed,
      );
      expect(cards.savedCards, isEmpty);
      expect(
        (await usage.getSnapshot(
          playerId: 'local-explorer',
          eventId: 'halloween_2026',
        )).committedUsage,
        0,
      );
    },
  );
}

ProviderContainer _container({
  required DiscoveryRepository repository,
  required RemoteCardGenerationService remote,
  required SharedPreferencesEventUsageRepository usage,
  CatCardRepository? cards,
  bool premium = false,
  EventGenerationCoordinator? coordinator,
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
        coordinator ?? EventGenerationCoordinator(usageRepository: usage),
      ),
      eventRuntimeConfigurationProvider.overrideWithValue(
        _AlwaysActiveEventRuntime(premium: premium),
      ),
    ],
  );
}

class _CommitFailingCoordinator extends EventGenerationCoordinator {
  _CommitFailingCoordinator(EventUsageRepository usageRepository)
    : super(usageRepository: usageRepository);

  @override
  Future<bool> commit(EventGenerationReservation reservation) async => false;
}

class _AlwaysActiveEventRuntime extends EventRuntimeConfiguration {
  const _AlwaysActiveEventRuntime({this.premium = false});

  final bool premium;

  @override
  CatDexEvent? activeEvent(DateTime now) => _activeTestEvent;

  @override
  bool get premiumTestEntitlementEnabled => premium;
}

class _EventRemoteCardGenerationService extends RemoteCardGenerationService {
  _EventRemoteCardGenerationService({
    this.pendingReason,
    this.failureReason,
    this.responseVariantOverride,
  }) : super(endpoint: 'https://renderer.example/api/generate-card');

  final RemoteCardGenerationPendingReason? pendingReason;
  final RemoteCardGenerationFailureReason? failureReason;
  final String? responseVariantOverride;
  int calls = 0;
  EventCardGenerationRequest? lastEventRequest;

  @override
  RemoteCardGenerationFailureReason? get lastFailureReason => failureReason;

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
    if (failureReason != null) return null;
    final pending = pendingReason;
    if (pending != null) onPending?.call(pending);
    final request = eventRequest!;
    lastEventRequest = request;
    final responseVariant = responseVariantOverride ?? request.variantId;
    return RemoteGeneratedCard(
      finalCardUrl:
          'https://renderer.example/generated/${discovery.id}/final-card.png',
      illustratedCatUrl:
          'https://renderer.example/generated/${discovery.id}/cat.png',
      selectedTemplateKey: 'events/${request.eventKey}/${request.templateKey}',
      eventKey: request.eventKey,
      eventEdition: request.eventEdition,
      eventArtworkVariantId: responseVariant,
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

CatCardRecord _eventRecordFor({
  required String discoveryId,
  required String variant,
}) {
  final premium = halloween2026Event.isPremiumVariant(variant);
  final template = halloween2026Event.templateKeyFor(variant);
  return CatCardRecord(
    cardId: eventCardId(
      discoveryId: discoveryId,
      eventKey: 'halloween_2026',
      eventEdition: '2026',
      eventArtworkVariantId: variant,
    ),
    discoveryId: discoveryId,
    ownerId: 'local-explorer',
    cardType: CatCardType.event,
    rarity: CatRarity.common,
    finalCardUrl:
        'https://renderer.example/generated/$discoveryId/$variant/final-card.png',
    templateKey: template,
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'request-$discoveryId-$variant',
    idempotencyKey: 'idempotency-$discoveryId-$variant',
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10),
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    eventArtworkVariantId: variant,
    eventArtworkTier: premium ? 'premium' : 'free',
    eventTemplateKey: template,
    generatedDuringEventAt: DateTime.utc(2026, 10),
    isPremiumArtwork: premium,
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
  premiumVariantIds: halloween2026Event.premiumVariantIds,
  premiumGenerationLimit: halloween2026Event.premiumGenerationLimit,
  variantTemplateKeys: halloween2026Event.variantTemplateKeys,
  variantInstructionKeys: halloween2026Event.variantInstructionKeys,
  variantWeights: halloween2026Event.variantWeights,
  variantSortOrders: halloween2026Event.variantSortOrders,
  variantTransformsCatAppearance:
      halloween2026Event.variantTransformsCatAppearance,
);
