import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_composer_service.dart';
import 'package:catdex/features/cards/application/card_generation_state_controller.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/presentation/cards_binder_page.dart';
import 'package:catdex/features/cards/presentation/catdex_trading_card_page.dart';
import 'package:catdex/features/cards/presentation/widgets/card_generation_status_panel.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _FakeCardComposer fakeComposer;
  late HttpOverrides? previousHttpOverrides;

  setUp(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestImageHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    fakeComposer = _FakeCardComposer();
  });

  tearDown(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  testWidgets('renders Cards page with deterministic mock cards', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(fakeComposer));
    await pumpCards(tester);
    await openCommonAlbum(tester);

    expect(commonAlbumTitle, findsOneWidget);
    expect(
      cardSemanticLabelContaining(
        'Gatto domestico tigrato, Gatto domestico tigrato',
      ),
      findsOneWidget,
    );
    expect(cardSemanticLabelContaining('Mochi,'), findsNothing);
    await scrollAlbumUntilVisible(
      tester,
      cardSemanticLabelContaining('Sole,'),
    );
    expect(cardSemanticLabelContaining('Sole,'), findsOneWidget);
  });

  testWidgets('rendering four cards does not call generation', (tester) async {
    final remote = _FakeRemoteCardGenerationService();
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        remoteCardGenerationService: remote,
        autoGenerateMissingCards: true,
      ),
    );
    await pumpCards(tester);

    expect(remote.calls, 0);
  });

  testWidgets('opening Cards album does not call generation', (tester) async {
    final remote = _FakeRemoteCardGenerationService();
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        remoteCardGenerationService: remote,
        autoGenerateMissingCards: true,
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    expect(remote.calls, 0);
  });

  testWidgets('one explicit tap creates exactly one request and one usage', (
    tester,
  ) async {
    final remote = _FakeRemoteCardGenerationService();
    final repository = _FakeDiscoveryRepository();
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: repository,
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await pumpCards(tester);

    expect(remote.calls, 1);
    expect(repository.saved, hasLength(1));
    expect(
      repository.saved.single.card?.cardImageUrl,
      'https://renderer.example/generated/missing-card-1/final-card.png',
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('catdex_monetization_daily_card_generation_count'),
      1,
    );
  });

  testWidgets('generated grid card opens persisted artwork detail', (
    tester,
  ) async {
    final remote = _FakeRemoteCardGenerationService();
    final repository = _FakeDiscoveryRepository();
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: repository,
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await pumpCards(tester);
    await tester.tap(cardSemanticLabelContaining('Sole,').first);
    await pumpCards(tester);

    expect(find.text('Carta non generata'), findsNothing);
    expect(find.text('Genera carta'), findsNothing);
    expect(remote.calls, 1);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('catdex_monetization_daily_card_generation_count'),
      1,
    );
  });

  testWidgets('rapid multiple taps create one request', (tester) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(blocker: blocker);
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    final generateButton = find.text('Genera carta');
    await tester.tap(generateButton);
    await tester.tap(generateButton);
    await tester.pump();
    expect(remote.calls, 1);

    blocker.complete();
    await pumpCards(tester);
    expect(remote.calls, 1);
  });

  testWidgets('album generation state is shared with card detail', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(blocker: blocker);
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository([_soleDiscovery]),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();
    await tester.tap(cardSemanticLabelContaining('Sole,').first);
    await pumpCards(tester);

    expect(
      inCardDetail(find.text(cardGenerationStatusTitle)),
      findsOneWidget,
    );
    expect(
      inCardDetail(find.text(cardGenerationStatusDefaultMessage)),
      findsOneWidget,
    );
    expect(inCardDetail(find.text('Genera carta')), findsNothing);
    expect(inCardDetail(find.text('Rigenera carta')), findsNothing);
    expect(inCardDetail(find.text('Carta non generata')), findsNothing);
    expect(remote.calls, 1);

    blocker.complete();
    await pumpCards(tester);

    expect(
      inCardDetail(find.text(cardGenerationStatusTitle)),
      findsNothing,
    );
    expect(inCardDetail(find.text('Genera carta')), findsNothing);
    expect(inCardDetail(find.text('Carta non generata')), findsNothing);
    expect(remote.calls, 1);
  });

  testWidgets('generation failure is shared with card detail retry state', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(
      blocker: blocker,
      succeeds: false,
    );
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository([_soleDiscovery]),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();
    await tester.tap(cardSemanticLabelContaining('Sole,').first);
    await pumpCards(tester);
    blocker.complete();
    await pumpCards(tester);

    expect(
      inCardDetail(find.text('Errore generazione carta')),
      findsWidgets,
    );
    expect(inCardDetail(find.text('Riprova')), findsOneWidget);
    expect(inCardDetail(find.text('Carta non generata')), findsNothing);
    expect(remote.calls, 1);
  });

  testWidgets('pending recovery hides Retry and keeps loading state', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(
      blocker: blocker,
      pendingReason: RemoteCardGenerationPendingReason.generationTimeout,
    );
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();

    expect(find.text(cardGenerationStatusTitle), findsWidgets);
    expect(find.text(cardGenerationStatusDefaultMessage), findsWidgets);
    expect(find.text('Riprova'), findsNothing);

    blocker.complete();
    await pumpCards(tester);
    expect(remote.calls, 1);
    expect(find.text('Errore generazione carta'), findsNothing);
    expect(find.text('Carta non generata'), findsNothing);
  });

  testWidgets('album tile keeps full long-wait text', (tester) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(blocker: blocker);
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));

    _expectReadableWrappedText(
      tester,
      find.text(cardGenerationStatusTitle),
    );
    _expectReadableWrappedText(
      tester,
      find.text(cardGenerationStatusLongWaitMessage),
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Errore generazione carta'), findsNothing);
    expect(find.text('Riprova'), findsNothing);
    expect(remote.calls, 1);

    blocker.complete();
    await pumpCards(tester);
  });

  testWidgets('after 60 seconds UI remains generating', (tester) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(blocker: blocker);
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));

    expect(find.text(cardGenerationStatusLongWaitMessage), findsWidgets);
    expect(find.text('Errore generazione carta'), findsNothing);
    expect(find.text('Riprova'), findsNothing);
    expect(remote.calls, 1);

    blocker.complete();
    await pumpCards(tester);
  });

  testWidgets('200 after 25 seconds shows final card and commits once', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(blocker: blocker);
    final repository = _FakeDiscoveryRepository();
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: repository,
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 25));
    expect(find.text('Errore generazione carta'), findsNothing);

    blocker.complete();
    await pumpCards(tester);

    expect(remote.calls, 1);
    expect(repository.saved, hasLength(1));
    expect(find.text('Carta non generata'), findsNothing);
    expect(find.text('Errore generazione carta'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('catdex_monetization_daily_card_generation_count'),
      1,
    );
  });

  testWidgets('one physical tap emits one user tap and one request', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(blocker: blocker);
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) {
        logs.add(message);
      }
    };
    try {
      await tester.tap(find.text('Genera carta'));
      await tester.pump();
      expect(remote.calls, 1);
      expect(
        logs.where((log) => log == 'CATDEX_CARD_GENERATION_USER_TAP'),
        hasLength(1),
      );
      expect(
        logs.where(
          (log) => log.startsWith(
            'CATDEX_CARD_GENERATION_REQUEST_DISCOVERY_ID',
          ),
        ),
        hasLength(1),
      );
    } finally {
      blocker.complete();
      await pumpCards(tester);
      debugPrint = previousDebugPrint;
    }
  });

  testWidgets('confirmed permanent failure shows error', (tester) async {
    final remote = _FakeRemoteCardGenerationService(succeeds: false);
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await pumpCards(tester);

    expect(find.text('Errore generazione carta'), findsWidgets);
    expect(find.text('Riprova'), findsOneWidget);
    expect(remote.calls, 1);
  });

  testWidgets('recovery exhaustion shows error', (tester) async {
    final remote = _FakeRemoteCardGenerationService(
      pendingReason: RemoteCardGenerationPendingReason.generationTimeout,
      succeeds: false,
    );
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await pumpCards(tester);

    expect(find.text('Errore generazione carta'), findsWidgets);
    expect(find.text('Riprova'), findsOneWidget);
    expect(remote.calls, 1);
  });

  testWidgets('navigating away and back does not create another request', (
    tester,
  ) async {
    final blocker = Completer<void>();
    final remote = _FakeRemoteCardGenerationService(blocker: blocker);
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
        remoteCardGenerationService: remote,
        discoveryRepository: _FakeDiscoveryRepository(),
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await tester.tap(find.text('Genera carta'));
    await tester.pump();
    expect(remote.calls, 1);

    Navigator.of(tester.element(find.byType(RarityCardsAlbumPage))).pop();
    await pumpCards(tester);
    await openCommonAlbum(tester);

    expect(find.text('Genera carta'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RarityCardsAlbumPage)),
    );
    expect(
      container
          .read(cardGenerationStateProvider)['missing-card-1']
          ?.isGenerating,
      isTrue,
    );
    expect(remote.calls, 1);

    blocker.complete();
    await pumpCards(tester);
  });

  testWidgets('bicolor mock card displays normalized species', (tester) async {
    await tester.pumpWidget(_testApp(fakeComposer));
    await pumpCards(tester);
    await openCommonAlbum(tester);
    await scrollAlbumUntilVisible(
      tester,
      cardSemanticLabelContainingAll([
        'Luna Nuova',
        'Gatto domestico bicolore',
      ]),
    );

    expect(
      cardSemanticLabelContainingAll([
        'Luna Nuova',
        'Gatto domestico bicolore',
      ]),
      findsOneWidget,
    );
    expect(find.textContaining('marrone/grigio'), findsNothing);
  });

  testWidgets('tabby mock card displays tabby species', (tester) async {
    await tester.pumpWidget(_testApp(fakeComposer));
    await pumpCards(tester);
    await openCommonAlbum(tester);

    expect(
      cardSemanticLabelContaining(
        'Gatto domestico tigrato, Gatto domestico tigrato',
      ),
      findsOneWidget,
    );
    expect(cardSemanticLabelContaining('Mochi,'), findsNothing);
  });

  testWidgets('missing card path does not block grid', (tester) async {
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    expect(commonAlbumTitle, findsOneWidget);
    expect(cardSemanticLabelContaining('Sole,'), findsOneWidget);
    expect(fakeComposer.calls, 0);
  });

  testWidgets('legacy discoveries without generated artwork are handled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
      ),
    );
    await pumpCards(tester);
    await openCommonAlbum(tester);

    await scrollAlbumUntilVisible(
      tester,
      cardSemanticLabelContaining('Legacy,'),
    );
    expect(cardSemanticLabelContaining('Legacy,'), findsOneWidget);
    expect(find.text('Carta non generata'), findsWidgets);
    await scrollAlbumUntilVisible(tester, cardSemanticLabelContaining('Sole,'));
    expect(cardSemanticLabelContaining('Sole,'), findsOneWidget);
    await scrollAlbumUntilVisible(
      tester,
      cardSemanticLabelContaining(
        'Gatto domestico tigrato, Gatto domestico tigrato',
      ),
    );
    expect(
      cardSemanticLabelContaining(
        'Gatto domestico tigrato, Gatto domestico tigrato',
      ),
      findsOneWidget,
    );
    expect(cardSemanticLabelContaining('Mochi,'), findsNothing);
  });
}

Future<void> pumpCards(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openCommonAlbum(WidgetTester tester) async {
  await tester.tap(find.text('Comune').first);
  await pumpCards(tester);
}

Future<void> scrollAlbumUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -300),
    );
  }
  await tester.pump(const Duration(milliseconds: 100));
}

Finder cardSemanticLabelContaining(String fragment) {
  return find.byWidgetPredicate((widget) {
    return widget is Semantics &&
        (widget.properties.label?.contains(fragment) ?? false);
  });
}

Finder cardSemanticLabelContainingAll(List<String> fragments) {
  return find.byWidgetPredicate((widget) {
    final label = widget is Semantics ? widget.properties.label : null;
    return label != null && fragments.every(label.contains);
  });
}

Finder inCardDetail(Finder matching) {
  return find.descendant(
    of: find.byType(CatDexTradingCardPage),
    matching: matching,
  );
}

void _expectReadableWrappedText(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  expect(text.textAlign, TextAlign.center);
  expect(text.softWrap, isNot(false));
  expect(text.maxLines, isNot(1));
  expect(text.overflow, isNot(TextOverflow.ellipsis));
}

Finder get commonAlbumTitle {
  return find.descendant(
    of: find.byType(AppBar),
    matching: find.text('Album Comune'),
  );
}

Widget _testApp(
  _FakeCardComposer composer, {
  bool autoGenerateMissingCards = false,
  List<CatDiscovery>? discoveries,
  RemoteCardGenerationService? remoteCardGenerationService,
  DiscoveryRepository? discoveryRepository,
}) {
  return ProviderScope(
    overrides: [
      cardComposerProvider.overrideWithValue(composer),
      if (remoteCardGenerationService != null)
        remoteCardGenerationServiceProvider.overrideWithValue(
          remoteCardGenerationService,
        ),
      if (discoveryRepository != null)
        discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
      localDiscoverySessionProvider.overrideWith(
        () => _MockDiscoverySessionController(
          discoveries ?? _defaultDiscoveries,
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: CatDexLocalizations.localizationsDelegates,
      supportedLocales: CatDexLocalizations.supportedLocales,
      home: CardsBinderPage(
        autoGenerateMissingCards: autoGenerateMissingCards,
      ),
    ),
  );
}

class _MockDiscoverySessionController extends LocalDiscoverySessionController {
  _MockDiscoverySessionController(this.discoveries);

  final List<CatDiscovery> discoveries;

  @override
  List<CatDiscovery> build() {
    return discoveries;
  }
}

class _FakeCardComposer implements CardComposer {
  int calls = 0;

  @override
  Future<String> generateCardImage({
    required CatDiscovery discovery,
    required CatDisplayData display,
    int collectionNumber = 1,
  }) async {
    calls++;
    return '/fake/generated_${discovery.id}.png';
  }
}

class _FakeRemoteCardGenerationService extends RemoteCardGenerationService {
  _FakeRemoteCardGenerationService({
    this.blocker,
    this.pendingReason,
    this.succeeds = true,
  }) : super(endpoint: 'https://renderer.example/api/generate-card');

  final Completer<void>? blocker;
  final RemoteCardGenerationPendingReason? pendingReason;
  final bool succeeds;
  int calls = 0;

  @override
  Future<RemoteGeneratedCard?> generateCard({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    String? debugRarityOverride,
    ValueChanged<RemoteCardGenerationPendingReason>? onPending,
    EventCardGenerationRequest? eventRequest,
  }) async {
    calls += 1;
    final reason = pendingReason;
    if (reason != null) {
      onPending?.call(reason);
    }
    await blocker?.future;
    if (!succeeds) {
      return null;
    }
    return RemoteGeneratedCard(
      finalCardUrl:
          'https://renderer.example/generated/${discovery.id}/final-card.png',
      selectedTemplateKey: 'default/common',
    );
  }
}

class _FakeDiscoveryRepository implements DiscoveryRepository {
  _FakeDiscoveryRepository([Iterable<CatDiscovery> initial = const []]) {
    saved.addAll(initial);
  }

  final List<CatDiscovery> saved = [];

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    for (final discovery in saved) {
      if (discovery.id == id) {
        return discovery;
      }
    }
    return null;
  }

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    return saved
        .where((discovery) => discovery.playerId == playerId)
        .toList(growable: false);
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    return saved.any(
      (discovery) =>
          discovery.playerId == playerId && discovery.speciesId == speciesId,
    );
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    saved
      ..removeWhere((candidate) => candidate.id == discovery.id)
      ..add(discovery);
  }
}

final List<CatDiscovery> _defaultDiscoveries = [
  _blackWhiteDiscovery,
  _tabbyDiscovery,
  _soleDiscovery,
  _legacyDiscovery,
];

final _blackWhiteDiscovery = CatDiscovery(
  id: 'black-white-1',
  playerId: 'local-player',
  speciesId: 'domestic_black_white_cat',
  variantId: 'normal',
  rarity: CatRarity.common,
  personality: CatPersonality.relaxed,
  traits: [
    const CatTrait(name: 'Mantello', value: 'nero/bianco'),
    const CatTrait(name: 'Pattern', value: 'bicolore'),
  ],
  discoveredAt: _blackWhiteDate,
  friendshipPoints: 10,
  customName: 'Luna Nuova',
  suggestedName: 'Luna Nuova',
  originalPhotoPath: '/fake/photo_luna.png',
  displayPhotoPath: '/fake/photo_luna.png',
  story: 'Un gatto domestico bicolore dal mantello nero e bianco.',
  funFact: 'I gatti bicolore hanno macchie uniche.',
  coatColor: 'nero/bianco',
  coatPattern: 'bicolore',
  eyeColor: 'occhi gialli',
  hairLength: 'pelo medio',
  estimatedAge: 'adulto',
  xpEarned: 80,
  coinsEarned: 15,
  confidenceScore: 0.88,
  card: CatDiscoveryCard(
    cardId: 'card-black-white',
    discoveryId: 'black-white-1',
    cardFrameStyle: 'green_simple_frame',
    cardBackgroundStyle: 'default',
    cardRarityStyle: 'common',
    isEventCard: false,
    cardImageUrl:
        'https://example.test/generated/cards/black-white-1/final-card.png',
    originalPhotoPath: '/fake/photo_luna.png',
    generatedAt: _blackWhiteDate,
  ),
);

final _tabbyDiscovery = CatDiscovery(
  id: 'tabby-1',
  playerId: 'local-player',
  speciesId: 'domestic_tabby_cat',
  variantId: 'normal',
  rarity: CatRarity.common,
  personality: CatPersonality.curious,
  traits: [
    const CatTrait(name: 'Mantello', value: 'marrone/grigio tigrato'),
    const CatTrait(name: 'Pattern', value: 'tigrato mackerel'),
  ],
  discoveredAt: _tabbyDate,
  friendshipPoints: 8,
  customName: 'Mochi',
  suggestedName: 'Mochi',
  originalPhotoPath: '/fake/photo_mochi.png',
  displayPhotoPath: '/fake/photo_mochi.png',
  story: 'Un gatto tigrato osserva il mondo con calma.',
  funFact: 'I mantelli tigrati sono comuni nei gatti domestici.',
  coatColor: 'marrone/grigio tigrato',
  coatPattern: 'tigrato mackerel',
  eyeColor: 'occhi gialli',
  hairLength: 'pelo corto',
  estimatedAge: 'adulto',
  xpEarned: 60,
  coinsEarned: 10,
  confidenceScore: 0.9,
  card: CatDiscoveryCard(
    cardId: 'card-tabby',
    discoveryId: 'tabby-1',
    cardFrameStyle: 'green_simple_frame',
    cardBackgroundStyle: 'default',
    cardRarityStyle: 'common',
    isEventCard: false,
    cardImageUrl: 'https://example.test/generated/cards/tabby-1/final-card.png',
    originalPhotoPath: '/fake/photo_mochi.png',
    generatedAt: _tabbyDate,
  ),
);

final _soleDiscovery = CatDiscovery(
  id: 'missing-card-1',
  playerId: 'local-player',
  speciesId: 'domestic_orange_cat',
  variantId: 'normal',
  rarity: CatRarity.common,
  personality: CatPersonality.playful,
  traits: [
    const CatTrait(name: 'Mantello', value: 'arancione'),
  ],
  discoveredAt: _orangeDate,
  friendshipPoints: 4,
  customName: 'Sole',
  suggestedName: 'Sole',
  originalPhotoPath: '/fake/photo_sole.png',
  displayPhotoPath: '/fake/photo_sole.png',
  story: 'Un gatto rosso domestico entra nel CatDex.',
  funFact: 'I gatti rossi spesso hanno un mantello tigrato.',
  coatColor: 'arancione',
  coatPattern: 'tigrato',
  eyeColor: 'occhi gialli',
  hairLength: 'pelo corto',
  estimatedAge: 'adulto',
  xpEarned: 50,
  coinsEarned: 8,
  confidenceScore: 0.86,
  card: CatDiscoveryCard(
    cardId: 'card-missing',
    discoveryId: 'missing-card-1',
    cardFrameStyle: 'green_simple_frame',
    cardBackgroundStyle: 'default',
    cardRarityStyle: 'common',
    isEventCard: false,
    originalPhotoPath: '/fake/photo_sole.png',
    generatedAt: _orangeDate,
  ),
);

final _legacyDiscovery = CatDiscovery(
  id: 'legacy-no-image-1',
  playerId: 'local-player',
  speciesId: 'domestic_gray_cat',
  variantId: 'normal',
  rarity: CatRarity.common,
  personality: CatPersonality.relaxed,
  traits: [],
  discoveredAt: _legacyDate,
  friendshipPoints: 2,
  customName: 'Legacy',
  suggestedName: 'Legacy',
);

final _blackWhiteDate = DateTime.utc(2026, 6, 29);
final _tabbyDate = DateTime.utc(2026, 6, 30);
final _orangeDate = DateTime.utc(2026, 6, 30, 12);
final _legacyDate = DateTime.utc(2026, 6, 28);

class _TestImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestImageHttpClient();
  }
}

class _TestImageHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestImageHttpClientRequest();
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestImageHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _TestImageHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestImageHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _onePixelPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_onePixelPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _onePixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  15,
  4,
  0,
  9,
  251,
  3,
  253,
  160,
  130,
  243,
  191,
  0,
  0,
  0,
  0,
  73,
  69,
  68,
  174,
  66,
  96,
  130,
];
