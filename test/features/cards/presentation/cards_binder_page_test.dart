import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_composer_service.dart';
import 'package:catdex/features/cards/presentation/cards_binder_page.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeCardComposer fakeComposer;

  setUp(() {
    fakeComposer = _FakeCardComposer();
  });

  testWidgets('renders Cards page with deterministic mock cards', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(fakeComposer));
    await pumpCards(tester);

    expect(find.text('Carte'), findsWidgets);
    expect(find.text('Sole'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);
  });

  testWidgets('bicolor mock card displays normalized species', (tester) async {
    await tester.pumpWidget(_testApp(fakeComposer));
    await pumpCards(tester);

    expect(find.text('Mochi'), findsOneWidget);
    expect(find.textContaining('marrone/grigio'), findsNothing);
  });

  testWidgets('tabby mock card displays tabby species', (tester) async {
    await tester.pumpWidget(_testApp(fakeComposer));
    await pumpCards(tester);

    expect(find.text('Mochi'), findsOneWidget);
  });

  testWidgets('missing card path does not block grid', (tester) async {
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
        discoveries: [_soleDiscovery],
      ),
    );
    await pumpCards(tester);

    expect(find.text('Carte'), findsWidgets);
    expect(find.text('Sole'), findsOneWidget);
    expect(fakeComposer.calls, 0);
  });

  testWidgets('legacy discoveries without images are hidden', (tester) async {
    await tester.pumpWidget(
      _testApp(
        fakeComposer,
      ),
    );
    await pumpCards(tester);

    expect(find.text('Legacy'), findsNothing);
    expect(find.text('Sole'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);
  });
}

Future<void> pumpCards(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget _testApp(
  _FakeCardComposer composer, {
  bool autoGenerateMissingCards = false,
  List<CatDiscovery>? discoveries,
}) {
  return ProviderScope(
    overrides: [
      cardComposerProvider.overrideWithValue(composer),
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
    cardImagePath: '/fake/card_luna.png',
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
    cardImagePath: '/fake/card_mochi.png',
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
