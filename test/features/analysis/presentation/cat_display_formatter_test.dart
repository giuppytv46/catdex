import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:test/test.dart';

void main() {
  const formatter = CatDisplayFormatter();

  test('normalizes gray and white bicolor display values', () {
    final displayData = formatter.fromDiscovery(
      _discovery(
        speciesId: 'domestic_gray_cat',
        coatColor: 'grigio/bianco',
        coatPattern: 'bicolore',
        eyeColor: 'amber',
      ),
    );

    expect(displayData.displaySpecies, 'Gatto domestico bicolore');
    expect(displayData.displayCoatColor, 'Grigio/bianco');
    expect(displayData.displayCoatPattern, 'Bicolore');
    expect(displayData.displayEyeColor, 'occhi ambrati');
    expect(displayData.displayStory, contains('grigio e bianco'));
    expect(displayData.displayStory, isNot(contains('marrone/grigio')));
    expect(displayData.displayStory, isNot(contains('tigrato')));
    expect(displayData.displayFunFact, contains('gatti bicolore'));
  });

  test('keeps real tabby values as tabby display values', () {
    final displayData = formatter.fromDiscovery(
      _discovery(
        speciesId: 'domestic_tabby_cat',
        coatColor: 'marrone/grigio tigrato',
        coatPattern: 'tigrato mackerel',
      ),
    );

    expect(displayData.displaySpecies, 'Gatto domestico tigrato');
    expect(displayData.displayCoatColor, 'Marrone/grigio tigrato');
    expect(displayData.displayCoatPattern, 'Tigrato mackerel');
  });

  test('normalizes orange tabby display values', () {
    final displayData = formatter.fromDiscovery(
      _discovery(
        speciesId: 'domestic_tabby_cat',
        coatColor: 'arancione',
        coatPattern: 'tigrato',
      ),
    );

    expect(displayData.displaySpecies, 'Gatto domestico arancione tigrato');
    expect(displayData.displayCoatColor, 'Arancione tigrato');
    expect(displayData.displayCoatPattern, 'Tigrato');
  });
}

CatDiscovery _discovery({
  required String speciesId,
  required String coatColor,
  required String coatPattern,
  String eyeColor = 'occhi gialli',
}) {
  return CatDiscovery(
    id: 'display-test',
    playerId: 'local-player',
    speciesId: speciesId,
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 6, 30),
    friendshipPoints: 0,
    customName: 'Luna',
    suggestedName: 'Luna',
    coatColor: coatColor,
    coatPattern: coatPattern,
    eyeColor: eyeColor,
    hairLength: 'pelo corto',
    estimatedAge: 'adulto',
    story: 'Un gatto marrone/grigio tigrato entra nel CatDex.',
    funFact: 'I gatti domestici hanno mantelli molto vari.',
  );
}
