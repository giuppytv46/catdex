import 'package:catdex/features/cards/presentation/cards_binder_page.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/features/catdex/presentation/catdex_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CardsBinderPage shows saved cards without fake cards', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const CardsBinderPage()));
    await tester.pumpAndSettle();

    expect(find.text('Carte'), findsWidgets);
    expect(find.text('Il tuo mazzo di gatti scoperti'), findsOneWidget);
    expect(find.text('Luna Nuova'), findsOneWidget);
    expect(find.text('Nessuna carta ancora'), findsNothing);
    expect(find.text('Mochi'), findsNothing);
  });

  testWidgets('tapping a saved card opens CatDexTradingCardPage', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const CardsBinderPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luna Nuova'));
    await tester.pumpAndSettle();

    expect(find.byType(CatDexTradingCardPage), findsOneWidget);
    expect(find.text('Luna Nuova'), findsWidgets);
    expect(find.textContaining('Gatto domestico bicolore'), findsWidgets);
  });

  testWidgets('CatDexTradingCardPage localizes bicolor safeguard', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(CatDexTradingCardPage(entry: _blackWhiteEntry())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luna Nuova'), findsWidgets);
    expect(find.textContaining('Gatto domestico bicolore'), findsWidgets);
    expect(find.text('Nero/bianco'), findsOneWidget);
    expect(find.text('Bicolore'), findsOneWidget);
    expect(find.text('domestic_gray_cat'), findsNothing);
    expect(find.text('marrone/grigio'), findsNothing);
  });
}

Widget _testApp(Widget child) {
  return ProviderScope(
    overrides: [
      localDiscoverySessionProvider.overrideWith(
        _SeededLocalDiscoverySessionController.new,
      ),
    ],
    child: MaterialApp(home: child),
  );
}

class _SeededLocalDiscoverySessionController
    extends LocalDiscoverySessionController {
  @override
  List<CatDiscovery> build() {
    return [_blackWhiteDiscovery()];
  }
}

CatDexCollectionEntry _blackWhiteEntry() {
  final species = CatDexSeedData.species.firstWhere(
    (item) => item.id == 'domestic_gray_cat',
  );

  return CatDexCollectionEntry(
    species: species,
    variantName: 'Normal',
    variantId: 'normal',
    discovered: true,
    collectionNumber: 1,
    discovery: _blackWhiteDiscovery(),
    displayName: 'Luna Nuova',
  );
}

CatDiscovery _blackWhiteDiscovery() {
  return CatDiscovery(
    id: 'discovery-black-white',
    playerId: 'local-player',
    speciesId: 'domestic_gray_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [
      CatTrait(name: 'Mantello', value: 'marrone/grigio'),
    ],
    discoveredAt: DateTime.utc(2026, 6, 29),
    friendshipPoints: 10,
    customName: 'Luna Nuova',
    suggestedName: 'Luna Nuova',
    story: 'Un gatto bicolore dallo sguardo attento.',
    coatColor: 'marrone/grigio',
    coatPattern: 'bicolore',
    eyeColor: 'occhi gialli',
    hairLength: 'pelo medio',
    estimatedAge: 'adulto',
    xpEarned: 80,
    coinsEarned: 15,
    confidenceScore: 0.88,
    card: CatDiscoveryCard(
      cardId: 'card-black-white',
      discoveryId: 'discovery-black-white',
      cardFrameStyle: 'green_simple_frame',
      cardBackgroundStyle: 'default',
      cardRarityStyle: 'common',
      isEventCard: false,
      originalPhotoPath: null,
      generatedAt: DateTime.utc(2026, 6, 29),
    ),
  );
}
