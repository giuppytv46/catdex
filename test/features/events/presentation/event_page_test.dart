import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/events/application/event_card_ui_generation_controller.dart';
import 'package:catdex/features/events/application/event_ui_state.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/events/domain/services/halloween_event_catalog.dart';
import 'package:catdex/features/events/presentation/event_page.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousOverrides;

  setUpAll(() {
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestImageHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = previousOverrides;
  });

  testWidgets('Free UI shows the configured 3-generation limit', (
    tester,
  ) async {
    await _pump(
      tester,
      EventProgressPanel(state: _state(), generationPending: false),
    );

    expect(find.text('0 di 3 utilizzate'), findsOneWidget);
    expect(find.text('3 rimaste'), findsOneWidget);
  });

  testWidgets('Premium UI shows the configured 15-generation limit', (
    tester,
  ) async {
    await _pump(
      tester,
      EventProgressPanel(
        state: _state(premium: true, committed: 4),
        generationPending: false,
      ),
    );

    expect(find.text('4 di 15 utilizzate'), findsOneWidget);
    expect(find.text('11 rimaste'), findsOneWidget);
  });

  testWidgets('committed usage updates event progress', (tester) async {
    await _pump(
      tester,
      EventProgressPanel(
        state: _state(committed: 1),
        generationPending: false,
      ),
    );

    expect(find.text('1 di 3 utilizzate'), findsOneWidget);
    expect(find.text('2 rimaste'), findsOneWidget);
  });

  testWidgets('pending generation is separate from committed usage', (
    tester,
  ) async {
    await _pump(
      tester,
      EventProgressPanel(
        state: _state(committed: 1),
        generationPending: true,
      ),
    );

    expect(find.text('1 di 3 utilizzate'), findsOneWidget);
    expect(find.byKey(const Key('event_pending_separate')), findsOneWidget);
  });

  testWidgets('three Free artwork slots are shown', (tester) async {
    await _pump(tester, _previewGrid(_state()));

    expect(find.text('Zucche incantate'), findsOneWidget);
    expect(find.text('Notte di luna'), findsOneWidget);
    expect(find.text('Casa infestata'), findsOneWidget);
  });

  testWidgets('Premium witch slot is visible and locked for Free', (
    tester,
  ) async {
    await _pump(tester, _previewGrid(_state()));

    expect(find.text('Gatto stregone'), findsOneWidget);
    expect(find.text('Scopri Premium'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets('Premium witch slot is unlocked for Premium', (tester) async {
    await _pump(tester, _previewGrid(_state(premium: true)));

    expect(find.text('Gatto stregone'), findsOneWidget);
    expect(find.text('Scopri Premium'), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
  });

  testWidgets('selected cat is visually identifiable', (tester) async {
    final discovery = _discovery();
    await _pump(
      tester,
      SizedBox(
        width: 190,
        height: 250,
        child: EventCatSelectionTile(
          discovery: discovery,
          selected: true,
          ownedEventCards: 1,
          resolveImage: () async => const CatDexResolvedImage.none(
            source: 'test',
            candidates: [],
            placeholderReason: 'test',
            discoveryDebugJson: {},
          ),
          onSelected: () {},
        ),
      ),
    );

    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.selected == true,
      ),
    );
    expect(semantics.properties.label, contains('Lunetta'));
  });

  testWidgets('no discoveries shows the Capture CTA', (tester) async {
    await _pumpEventPage(tester, _state());
    await _scrollUntilVisible(
      tester,
      find.byKey(const Key('event_capture_cta')),
    );

    expect(find.text('Prima scopri un gatto'), findsOneWidget);
    expect(find.byKey(const Key('event_capture_cta')), findsOneWidget);
  });

  testWidgets('pending shared state hides duplicate generation action', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      _generationPanel(
        state: _state(discoveries: [_discovery()]),
        generation: const EventUiGenerationState(
          phase: EventUiGenerationPhase.generating,
        ),
        onGenerate: () async => calls++,
      ),
    );

    expect(find.byKey(const Key('event_generation_progress')), findsOneWidget);
    expect(find.byKey(const Key('event_generate_button')), findsNothing);
    expect(calls, 0);
  });

  testWidgets('fourth Free generation is blocked', (tester) async {
    await _pump(
      tester,
      _generationPanel(
        state: _state(committed: 3, discoveries: [_discovery()]),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('event_generate_button')),
    );
    expect(button.onPressed, isNull);
    expect(
      find.text("Hai utilizzato tutte le 3 generazioni gratuite dell'evento."),
      findsOneWidget,
    );
  });

  testWidgets('generation failure does not reduce displayed usage', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        children: [
          EventProgressPanel(
            state: _state(committed: 1),
            generationPending: false,
          ),
          _generationPanel(
            state: _state(committed: 1, discoveries: [_discovery()]),
            generation: const EventUiGenerationState(
              phase: EventUiGenerationPhase.failed,
              failureReason: EventUiFailureReason.eventArtworkValidationFailed,
            ),
          ),
        ],
      ),
    );

    expect(find.text('1 di 3 utilizzate'), findsOneWidget);
    expect(find.textContaining('non è stato consumato'), findsOneWidget);
  });

  testWidgets('completed event result opens by cardId', (tester) async {
    final card = _eventCard();
    String? openedCardId;
    await _pump(
      tester,
      SizedBox(
        width: 180,
        height: 280,
        child: EventAlbumCard(
          card: card,
          onOpen: () => openedCardId = card.cardId,
        ),
      ),
    );

    await tester.tap(find.byKey(ValueKey('event_album_card_${card.cardId}')));
    expect(openedCardId, card.cardId);
  });

  testWidgets('event result does not select a normal card record', (
    tester,
  ) async {
    final eventCard = _eventCard();
    final normalCard = _normalCard();
    final state = _state(cards: [normalCard, eventCard]);

    expect(
      state.cardsForVariant('halloween_pumpkins').single.cardId,
      eventCard.cardId,
    );
    expect(
      state.cardsForVariant('halloween_pumpkins'),
      isNot(contains(normalCard)),
    );
  });

  testWidgets('collected artwork uses real CatCardRecord image', (
    tester,
  ) async {
    await _pump(tester, _previewGrid(_state(cards: [_eventCard()])));

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<NetworkImage>());
    expect(find.text('Raccolto'), findsOneWidget);
  });

  testWidgets('uncollected artwork uses safe decorative placeholder', (
    tester,
  ) async {
    await _pump(tester, _previewGrid(_state()));

    expect(
      find.byKey(const Key('event_artwork_placeholder')),
      findsNWidgets(4),
    );
    expect(find.text('Non ancora raccolto'), findsNWidgets(4));
  });

  test('event cards do not alter normal rarity counts', () {
    final cards = [_normalCard(), _eventCard()];

    expect(normalCardCountForRarity(cards, CatRarity.common), 1);
  });

  testWidgets('expired event disables generation', (tester) async {
    await _pump(
      tester,
      _generationPanel(
        state: _state(active: false, discoveries: [_discovery()]),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('event_generate_button')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Evento terminato'), findsOneWidget);
  });

  testWidgets('expired event preserves owned cards', (tester) async {
    await _pump(
      tester,
      _previewGrid(_state(active: false, cards: [_eventCard()])),
    );

    expect(find.text('Raccolto'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Premium expiration preserves owned witch artwork', (
    tester,
  ) async {
    await _pump(
      tester,
      _previewGrid(
        _state(
          active: false,
          cards: [_eventCard(variant: 'halloween_witch_cat', premium: true)],
        ),
      ),
    );

    expect(find.text('Gatto stregone'), findsOneWidget);
    expect(find.text('Raccolto'), findsOneWidget);
    expect(find.text('Scopri Premium'), findsNothing);
  });

  testWidgets('debug badge appears only in explicit event debug mode', (
    tester,
  ) async {
    await _pump(tester, EventHeaderPanel(state: _state()));
    expect(find.byKey(const Key('event_debug_badge')), findsNothing);

    await _pump(tester, EventHeaderPanel(state: _state(debug: true)));
    expect(find.byKey(const Key('event_debug_badge')), findsOneWidget);
  });

  testWidgets('small event viewport has no overflow', (tester) async {
    await _pumpEventPage(
      tester,
      _state(discoveries: [_discovery()]),
      size: const Size(320, 568),
    );

    expect(find.byKey(const Key('event_header')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event page supports text scale 1.3', (tester) async {
    await _pumpEventPage(
      tester,
      _state(discoveries: [_discovery()]),
      size: const Size(320, 568),
      textScaler: const TextScaler.linear(1.3),
    );

    expect(find.text('Halloween CatDex'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event page remains readable in dark theme', (tester) async {
    await _pumpEventPage(
      tester,
      _state(discoveries: [_discovery()]),
      dark: true,
    );

    final title = tester.widget<Text>(find.text('Halloween CatDex').last);
    expect(title.style?.color, isNot(Colors.black));
    expect(tester.takeException(), isNull);
  });

  testWidgets('artwork image error does not remove owned card state', (
    tester,
  ) async {
    final failedCard = _eventCard(
      url: 'https://example.test/failed/final-card.png',
    );
    final state = _state(cards: [failedCard]);
    await _pump(tester, _previewGrid(state));
    await tester.pump(const Duration(milliseconds: 200));

    expect(state.ownedCards, contains(failedCard));
    expect(find.text('Raccolto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning during generation displays shared progress state', (
    tester,
  ) async {
    const shared = EventUiGenerationState(
      phase: EventUiGenerationPhase.recovering,
      longWait: true,
    );
    await _pump(
      tester,
      _generationPanel(
        state: _state(discoveries: [_discovery()]),
        generation: shared,
      ),
    );
    expect(find.byKey(const Key('event_generation_progress')), findsOneWidget);
    expect(find.byKey(const Key('event_generation_long_wait')), findsOneWidget);

    await _pump(
      tester,
      _generationPanel(
        state: _state(discoveries: [_discovery()]),
        generation: shared,
      ),
    );
    expect(find.byKey(const Key('event_generation_progress')), findsOneWidget);
  });

  testWidgets('idle UI does not automatically start generation', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      _generationPanel(
        state: _state(discoveries: [_discovery()]),
        onGenerate: () async => calls++,
      ),
    );

    expect(calls, 0);
    await tester.tap(find.byKey(const Key('event_generate_button')));
    expect(calls, 1);
  });
}

Widget _previewGrid(EventUiState state) {
  return EventArtworkPreviewGrid(
    state: state,
    onOpenCard: (_) {},
    onOpenPremium: () {},
  );
}

Widget _generationPanel({
  required EventUiState state,
  EventUiGenerationState generation = EventUiGenerationState.idle,
  Future<void> Function()? onGenerate,
}) {
  final discovery = state.discoveries.firstOrNull;
  return EventGenerationPanel(
    state: state,
    selectedDiscovery: discovery,
    generation: generation,
    completedCard: null,
    onGenerate: onGenerate ?? () async {},
    onRetry: () async {},
    onOpenCard: null,
    onBackToEvent: null,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(430, 900),
  bool dark = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: CatDexLocalizations.localizationsDelegates,
      supportedLocales: CatDexLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: widget!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpEventPage(
  WidgetTester tester,
  EventUiState state, {
  Size size = const Size(430, 900),
  bool dark = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eventUiStateProvider.overrideWith((ref, key) async => state),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: CatDexLocalizations.localizationsDelegates,
        supportedLocales: CatDexLocalizations.supportedLocales,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: widget!,
        ),
        home: const EventPage(eventKey: 'halloween_2026'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder finder) async {
  for (var index = 0; index < 8 && finder.evaluate().isEmpty; index += 1) {
    await tester.drag(
      find.byKey(const Key('event_page_scroll')),
      const Offset(0, -320),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

EventUiState _state({
  bool active = true,
  bool debug = false,
  bool premium = false,
  int committed = 0,
  List<CatDiscovery> discoveries = const [],
  List<CatCardRecord> cards = const [],
}) {
  return EventUiState(
    event: halloween2026Event,
    active: active,
    debugMode: debug,
    isPremium: premium,
    usage: EventUsageSnapshot(committedUsage: committed),
    discoveries: discoveries,
    ownedCards: cards,
    rendererConfigured: true,
  );
}

CatDiscovery _discovery() {
  return CatDiscovery(
    id: 'cat-1',
    playerId: 'local-explorer',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7),
    friendshipPoints: 0,
    customName: 'Lunetta',
    coatColor: 'Nero/bianco',
    coatPattern: 'Bicolore',
  );
}

CatCardRecord _eventCard({
  String variant = 'halloween_pumpkins',
  bool premium = false,
  String url = 'https://example.test/event/final-card.png',
}) {
  return CatCardRecord(
    cardId: 'event:cat-1:halloween_2026:2026:$variant',
    discoveryId: 'cat-1',
    ownerId: 'local-explorer',
    cardType: CatCardType.event,
    rarity: CatRarity.common,
    finalCardUrl: url,
    templateKey: variant,
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'request-$variant',
    idempotencyKey: 'idempotency-$variant',
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10),
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    eventArtworkVariantId: variant,
    eventArtworkTier: premium ? 'premium' : 'free',
    eventTemplateKey: variant,
    isPremiumArtwork: premium,
    displayName: 'Lunetta',
    displaySpecies: 'Gatto domestico bicolore',
  );
}

CatCardRecord _normalCard() {
  return CatCardRecord(
    cardId: normalCardId('cat-1'),
    discoveryId: 'cat-1',
    ownerId: 'local-explorer',
    cardType: CatCardType.normal,
    rarity: CatRarity.common,
    finalCardUrl: 'https://example.test/normal/final-card.png',
    templateKey: 'default/common',
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'normal-cat-1',
    idempotencyKey: 'normal-cat-1',
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}

class _TestImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _TestImageHttpClient();
}

class _TestImageHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _TestImageHttpClientRequest(url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestImageHttpClientRequest implements HttpClientRequest {
  _TestImageHttpClientRequest(this.url);

  final Uri url;

  @override
  Future<HttpClientResponse> close() async => _TestImageHttpClientResponse(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestImageHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestImageHttpClientResponse(this.url);

  final Uri url;
  bool get _fails => url.path.contains('failed');

  @override
  int get statusCode => _fails ? HttpStatus.notFound : HttpStatus.ok;

  @override
  int get contentLength => _fails ? 0 : _onePixelPng.length;

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
    return Stream<List<int>>.value(_fails ? const [] : _onePixelPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
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
  78,
  68,
  174,
  66,
  96,
  130,
];
