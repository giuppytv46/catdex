import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/cards/application/card_generation_state_controller.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:catdex/features/cards/presentation/catdex_trading_card_page.dart';
import 'package:catdex/features/cards/presentation/widgets/card_generation_status_panel.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('one detail tap invokes one generation callback', (tester) async {
    final blocker = Completer<String?>();
    var callbackCalls = 0;
    final logs = <String>[];
    final previousDebugPrint = debugPrint;

    await tester.pumpWidget(
      _testApp(
        onGenerate: () {
          callbackCalls += 1;
          return blocker.future;
        },
      ),
    );
    await _pumpDetail(tester);

    debugPrint = (message, {wrapWidth}) {
      if (message != null) {
        logs.add(message);
      }
    };
    try {
      await tester.tap(find.text('Genera carta'));
      await tester.pump();

      expect(callbackCalls, 1);
      expect(
        logs.where((log) => log == 'CATDEX_CARD_GENERATION_USER_TAP'),
        hasLength(1),
      );
      expect(
        logs.where((log) => log == 'CATDEX_CARD_UI_SINGLE_TAP_HANDLED'),
        hasLength(1),
      );
    } finally {
      blocker.complete(null);
      await tester.pump();
      debugPrint = previousDebugPrint;
    }
  });

  testWidgets('detail shows readable long-wait text', (tester) async {
    final blocker = Completer<String?>();
    await tester.pumpWidget(_testApp(onGenerate: () => blocker.future));
    await _pumpDetail(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));

    _expectReadableWrappedText(
      tester,
      find.text(cardGenerationStatusTitle),
    );
    _expectReadableWrappedText(
      tester,
      find.text(cardGenerationStatusLongWaitMessage),
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Genera carta'), findsNothing);
    expect(find.text('Rigenera carta'), findsNothing);
    expect(find.text('Carta non generata'), findsNothing);
    expect(find.text('Errore generazione carta'), findsNothing);

    blocker.complete(null);
    await tester.pump();
  });

  testWidgets('valid finalCardUrl hides generate CTA', (tester) async {
    await tester.pumpWidget(
      _testApp(
        discovery: _generatedDiscovery,
        onGenerate: () async => null,
      ),
    );
    await _pumpDetail(tester);

    expect(find.text('Carta non generata'), findsNothing);
    expect(find.text('Genera carta'), findsNothing);
  });

  testWidgets('temporary image load error keeps generated state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        discovery: _generatedDiscovery,
        onGenerate: () async => null,
      ),
    );
    await _pumpDetail(tester);

    expect(find.text('Impossibile caricare l’immagine'), findsOneWidget);
    expect(find.text('Carta non generata'), findsNothing);
    expect(find.text('Genera carta'), findsNothing);
    expect(find.text('Ricarica'), findsOneWidget);
  });

  testWidgets('ungenerated card shows generate CTA', (tester) async {
    await tester.pumpWidget(_testApp(onGenerate: () async => null));
    await _pumpDetail(tester);

    expect(find.text('Carta non generata'), findsOneWidget);
    expect(find.text('Genera carta'), findsOneWidget);
  });

  testWidgets('repository reload still shows existing artwork', (
    tester,
  ) async {
    final repository = _FakeDiscoveryRepository(_generatedDiscovery);

    await tester.pumpWidget(
      _testApp(
        discovery: _generatedDiscovery,
        repository: repository,
        onGenerate: () async => null,
      ),
    );
    await _pumpDetail(tester);
    expect(find.text('Genera carta'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      _testApp(
        discovery: _generatedDiscovery,
        repository: repository,
        onGenerate: () async => null,
      ),
    );
    await _pumpDetail(tester);

    expect(find.text('Genera carta'), findsNothing);
    expect(repository.lookups, 2);
  });

  testWidgets('opening generated card does not request generation', (
    tester,
  ) async {
    var generationCalls = 0;
    await tester.pumpWidget(
      _testApp(
        discovery: _generatedDiscovery,
        onGenerate: () async {
          generationCalls += 1;
          return null;
        },
      ),
    );
    await _pumpDetail(tester);

    expect(generationCalls, 0);
    expect(find.text('Genera carta'), findsNothing);
  });

  testWidgets('event card detail resolves event artwork by cardId', (
    tester,
  ) async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      await tester.pumpWidget(
        _testApp(
          discovery: _generatedDiscovery,
          cardId: _eventRecord.cardId,
          cardRepository: _FakeCatCardRepository([
            _normalRecord,
            _eventRecord,
          ]),
          onGenerate: () async => null,
        ),
      );
      await _pumpDetail(tester);

      expect(
        logs,
        contains('CATDEX_CARD_DETAIL_FINAL_URL ${_eventRecord.finalCardUrl}'),
      );
      expect(
        logs,
        isNot(
          contains(
            'CATDEX_CARD_DETAIL_FINAL_URL ${_normalRecord.finalCardUrl}',
          ),
        ),
      );
    } finally {
      debugPrint = previousDebugPrint;
    }
  });

  testWidgets('normal card detail does not show event artwork', (tester) async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      await tester.pumpWidget(
        _testApp(
          discovery: _generatedDiscovery,
          cardId: _normalRecord.cardId,
          cardRepository: _FakeCatCardRepository([
            _normalRecord,
            _eventRecord,
          ]),
          onGenerate: () async => null,
        ),
      );
      await _pumpDetail(tester);

      expect(
        logs,
        contains('CATDEX_CARD_DETAIL_FINAL_URL ${_normalRecord.finalCardUrl}'),
      );
      expect(
        logs,
        isNot(
          contains('CATDEX_CARD_DETAIL_FINAL_URL ${_eventRecord.finalCardUrl}'),
        ),
      );
    } finally {
      debugPrint = previousDebugPrint;
    }
  });

  testWidgets('generated card route loads the latest entity by stable ID', (
    tester,
  ) async {
    final repository = _FakeDiscoveryRepository(_generatedDiscovery);

    await tester.pumpWidget(
      _navigationTestApp(repository: repository),
    );
    await _openCardDetail(tester);

    expect(repository.lastLookupId, _generatedDiscovery.id);
    expect(find.byType(CatDexTradingCardPage), findsOneWidget);
    expect(find.text('Genera carta'), findsNothing);
  });

  testWidgets('back returns only to the Cards album', (tester) async {
    await tester.pumpWidget(
      _navigationTestApp(
        repository: _FakeDiscoveryRepository(_generatedDiscovery),
      ),
    );
    await _openCardDetail(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Album carte'), findsOneWidget);
    expect(find.byType(CatDexTradingCardPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening and closing the same card repeatedly does not throw', (
    tester,
  ) async {
    await tester.pumpWidget(
      _navigationTestApp(
        repository: _FakeDiscoveryRepository(_generatedDiscovery),
      ),
    );

    for (var index = 0; index < 3; index += 1) {
      await _openCardDetail(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Album carte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('back while generated artwork is loading does not throw', (
    tester,
  ) async {
    await tester.pumpWidget(
      _navigationTestApp(
        repository: _FakeDiscoveryRepository(_generatedDiscovery),
      ),
    );

    await tester.tap(find.byKey(const Key('open_card_detail')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Album carte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing discovery shows a safe localized message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _navigationTestApp(
        repository: _FakeDiscoveryRepository(null),
        cardRepository: _FakeCatCardRepository(),
      ),
    );
    await _openCardDetail(tester);

    expect(find.text('Questa carta non è più disponibile.'), findsOneWidget);
    expect(find.text('Genera carta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open and back do not call generation or consume a card action', (
    tester,
  ) async {
    var generationCalls = 0;
    await tester.pumpWidget(
      _navigationTestApp(
        repository: _FakeDiscoveryRepository(_generatedDiscovery),
        onGenerate: () async {
          generationCalls += 1;
          return null;
        },
      ),
    );
    await _openCardDetail(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(generationCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed generation state survives back navigation', (
    tester,
  ) async {
    final repository = _FakeDiscoveryRepository(_generatedDiscovery);
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(cardGenerationStateProvider.notifier)
        .complete(_generatedDiscovery.id);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _navigationMaterialApp(),
      ),
    );
    await _openCardDetail(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(
      container
          .read(cardGenerationStateProvider)[_generatedDiscovery.id]
          ?.isCompleted,
      isTrue,
    );
  });

  testWidgets('double back request does not pop two routes', (tester) async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    await tester.pumpWidget(
      _navigationTestApp(
        repository: _FakeDiscoveryRepository(_generatedDiscovery),
      ),
    );
    await _openCardDetail(tester);

    debugPrint = (message, {wrapWidth}) {
      if (message != null) {
        logs.add(message);
      }
    };
    try {
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backButton);
      await tester.tap(backButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Album carte'), findsOneWidget);
      expect(
        logs.where(
          (log) => log.startsWith('CATDEX_CARD_DETAIL_BACK_REQUESTED'),
        ),
        hasLength(1),
      );
      expect(
        logs.where(
          (log) => log.startsWith('CATDEX_CARD_DETAIL_BACK_COMPLETED'),
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugPrint = previousDebugPrint;
    }
  });

  testWidgets('repository completion after page disposal is ignored', (
    tester,
  ) async {
    final repository = _DeferredDiscoveryRepository();
    await tester.pumpWidget(_navigationTestApp(repository: repository));

    await tester.tap(find.byKey(const Key('open_card_detail')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CatDexTradingCardPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    repository.complete(_generatedDiscovery);
    await tester.pump();

    expect(find.text('Album carte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system pop lifecycle returns safely to the Cards album', (
    tester,
  ) async {
    await tester.pumpWidget(
      _navigationTestApp(
        repository: _FakeDiscoveryRepository(_generatedDiscovery),
      ),
    );
    await _openCardDetail(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Album carte'), findsOneWidget);
    expect(find.byType(CatDexTradingCardPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _expectReadableWrappedText(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  expect(text.textAlign, TextAlign.center);
  expect(text.softWrap, isNot(false));
  expect(text.maxLines, isNot(1));
  expect(text.overflow, isNot(TextOverflow.ellipsis));
}

Future<void> _pumpDetail(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

Widget _testApp({
  required CardGenerationCallback onGenerate,
  CatDiscovery? discovery,
  DiscoveryRepository? repository,
  CatCardRepository? cardRepository,
  String? cardId,
}) {
  final selectedDiscovery = discovery ?? _entry.discovery!;
  return ProviderScope(
    overrides: [
      discoveryRepositoryProvider.overrideWithValue(
        repository ?? _FakeDiscoveryRepository(selectedDiscovery),
      ),
      catCardRepositoryProvider.overrideWithValue(
        cardRepository ?? _cardRepositoryForDiscovery(selectedDiscovery),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: CatDexLocalizations.localizationsDelegates,
      supportedLocales: CatDexLocalizations.supportedLocales,
      home: CatDexTradingCardPage(
        discoveryId: selectedDiscovery.id,
        cardId: cardId,
        collectionNumber: 1,
        onGenerate: onGenerate,
      ),
    ),
  );
}

Widget _navigationTestApp({
  required DiscoveryRepository repository,
  CardGenerationCallback? onGenerate,
  CatCardRepository? cardRepository,
}) {
  return ProviderScope(
    overrides: [
      discoveryRepositoryProvider.overrideWithValue(repository),
      catCardRepositoryProvider.overrideWithValue(
        cardRepository ?? _FakeCatCardRepository([_normalRecord]),
      ),
    ],
    child: _navigationMaterialApp(onGenerate: onGenerate),
  );
}

Widget _navigationMaterialApp({CardGenerationCallback? onGenerate}) {
  return MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: CatDexLocalizations.localizationsDelegates,
    supportedLocales: CatDexLocalizations.supportedLocales,
    home: _CardsAlbumHarness(onGenerate: onGenerate),
  );
}

class _CardsAlbumHarness extends StatelessWidget {
  const _CardsAlbumHarness({this.onGenerate});

  final CardGenerationCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Album carte'),
            FilledButton(
              key: const Key('open_card_detail'),
              onPressed: () {
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CatDexTradingCardPage(
                        discoveryId: _generatedDiscovery.id,
                        collectionNumber: 1,
                        onGenerate: onGenerate ?? () async => null,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Apri carta'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openCardDetail(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_card_detail')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
  expect(find.byType(CatDexTradingCardPage), findsOneWidget);
}

CatCardRepository _cardRepositoryForDiscovery(CatDiscovery discovery) {
  final card = discovery.card;
  if (card?.cardImageUrl?.isNotEmpty != true) {
    return _FakeCatCardRepository();
  }
  return _FakeCatCardRepository([
    CatCardRecord(
      cardId: normalCardId(discovery.id),
      discoveryId: discovery.id,
      ownerId: discovery.playerId,
      cardType: CatCardType.normal,
      rarity: discovery.rarity,
      finalCardUrl: card!.cardImageUrl!,
      illustratedCatUrl: card.illustratedCatImageUrl,
      templateKey: card.cardTemplateId,
      generationStatus: CatCardGenerationStatus.completed,
      generationRequestId: normalCardId(discovery.id),
      idempotencyKey: normalCardId(discovery.id),
      createdAt: card.generatedAt,
      updatedAt: card.generatedAt,
    ),
  ]);
}

class _FakeCatCardRepository implements CatCardRepository {
  _FakeCatCardRepository([List<CatCardRecord> cards = const []])
    : _cards = {for (final card in cards) card.cardId: card};

  final Map<String, CatCardRecord> _cards;

  @override
  Future<bool> cardExists(String logicalIdentity) async {
    return _cards.values.any((card) => card.logicalIdentity == logicalIdentity);
  }

  @override
  Future<void> deleteCard(String cardId) async => _cards.remove(cardId);

  @override
  Future<List<CatCardRecord>> getAllCards() async =>
      _cards.values.toList(growable: false);

  @override
  Future<CatCardRecord?> getCardById(String cardId) async => _cards[cardId];

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
  Future<CatCardRecord?> getNormalCardForDiscovery(String discoveryId) async =>
      _cards[normalCardId(discoveryId)];

  @override
  Future<void> saveCard(CatCardRecord card) async {
    _cards[card.cardId] = card;
  }
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository(this.discovery);

  CatDiscovery? discovery;
  int lookups = 0;
  String? lastLookupId;

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    lookups += 1;
    lastLookupId = id;
    return discovery?.id == id ? discovery : null;
  }

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    final current = discovery;
    if (current == null || current.playerId != playerId) {
      return const [];
    }
    return [current];
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    final current = discovery;
    return current != null &&
        current.playerId == playerId &&
        current.speciesId == speciesId;
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    this.discovery = discovery;
  }
}

class _DeferredDiscoveryRepository implements DiscoveryRepository {
  final Completer<CatDiscovery?> _lookup = Completer<CatDiscovery?>();

  void complete(CatDiscovery? discovery) {
    if (!_lookup.isCompleted) {
      _lookup.complete(discovery);
    }
  }

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) => _lookup.future;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async =>
      const [];

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async => false;

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {}
}

final _entry = CatDexCollectionEntry(
  species: const CatSpecies(
    id: 'domestic_orange_cat',
    displayName: 'Gatto domestico arancione tigrato',
    scientificName: 'Felis catus',
    originCountry: 'Italia',
    baseRarity: CatRarity.common,
    active: true,
  ),
  variantName: 'Normale',
  variantId: 'normal',
  discovered: true,
  collectionNumber: 1,
  displayName: 'Sole',
  discovery: CatDiscovery(
    id: 'detail-card-1',
    playerId: 'local-player',
    speciesId: 'domestic_orange_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.playful,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 13),
    friendshipPoints: 0,
    customName: 'Sole',
    suggestedName: 'Sole',
    displayPhotoPath: 'https://example.test/cat.jpg',
    coatColor: 'arancione',
    coatPattern: 'tigrato',
  ),
);

final CatDiscovery _generatedDiscovery = _entry.discovery!.copyWithCard(
  CatDiscoveryCard(
    cardId: 'card-detail-card-1',
    discoveryId: 'detail-card-1',
    cardFrameStyle: 'default',
    cardBackgroundStyle: 'default',
    cardRarityStyle: 'common',
    isEventCard: false,
    originalPhotoPath: 'https://example.test/cat.jpg',
    generatedAt: DateTime.utc(2026, 7, 14),
    cardImageUrl: 'https://example.test/generated/detail-card-1/final-card.png',
    cardTemplateId: 'default/common',
  ),
);

final _normalRecord = CatCardRecord(
  cardId: normalCardId(_generatedDiscovery.id),
  discoveryId: _generatedDiscovery.id,
  ownerId: _generatedDiscovery.playerId,
  cardType: CatCardType.normal,
  rarity: _generatedDiscovery.rarity,
  finalCardUrl:
      'https://example.test/generated/detail-card-1/normal/final-card.png',
  templateKey: 'default/common',
  generationStatus: CatCardGenerationStatus.completed,
  generationRequestId: normalCardId(_generatedDiscovery.id),
  idempotencyKey: normalCardId(_generatedDiscovery.id),
  createdAt: DateTime.utc(2026, 7, 14),
  updatedAt: DateTime.utc(2026, 7, 14),
);

final _eventRecord = CatCardRecord(
  cardId: eventCardId(
    discoveryId: _generatedDiscovery.id,
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    eventArtworkVariantId: 'halloween_pumpkins',
  ),
  discoveryId: _generatedDiscovery.id,
  ownerId: _generatedDiscovery.playerId,
  cardType: CatCardType.event,
  rarity: _generatedDiscovery.rarity,
  finalCardUrl:
      'https://example.test/generated/detail-card-1/event/final-card.png',
  templateKey: 'halloween_pumpkins',
  generationStatus: CatCardGenerationStatus.completed,
  generationRequestId: 'event-request-1',
  idempotencyKey: 'event-idempotency-1',
  createdAt: DateTime.utc(2026, 10, 15),
  updatedAt: DateTime.utc(2026, 10, 15),
  eventKey: 'halloween_2026',
  eventEdition: '2026',
  eventArtworkVariantId: 'halloween_pumpkins',
  eventArtworkTier: 'free',
  eventTemplateKey: 'halloween_pumpkins',
  generatedDuringEventAt: DateTime.utc(2026, 10, 15),
);
