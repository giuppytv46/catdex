import 'dart:async';

import 'package:catdex/features/analysis/data/cat_analysis_result_json_parser.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/presentation/cat_analysis_display_formatter.dart';
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

  test('specific Sphynx breed wins over bicolor species override', () {
    final logs = <String>[];
    late final displayData = runZoned(
      () => formatter.fromAnalysis(
        _analysisResult(
          breedKey: 'breed',
          breed: 'sphynx_cat',
          personality: 'alert',
        ),
      ),
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, message) => logs.add(message),
      ),
    );

    expect(displayData.displayName, 'Sphynx');
    expect(displayData.displaySpecies, 'Sphynx');
    expect(displayData.displayCoatColor, 'Grigio/bianco');
    expect(displayData.displayCoatPattern, 'Bicolore');
    expect(displayData.displayPersonality, 'Vigile');
    expect(
      logs,
      contains('CATDEX_SPECIES_OVERRIDE_SKIPPED reason=specific_breed'),
    );
  });

  test('generic domestic bicolor still uses phenotype species label', () {
    final displayData = formatter.fromDiscovery(
      _discovery(
        speciesId: 'domestic_gray_cat',
        coatColor: 'grigio/bianco',
        coatPattern: 'bicolore',
      ),
    );

    expect(displayData.displaySpecies, 'Gatto domestico bicolore');
  });

  test('every supported personality token has a localized display value', () {
    const displayFormatter = CatAnalysisDisplayFormatter();

    for (final entry in CatAnalysisDisplayFormatter.personalityLabels.entries) {
      expect(displayFormatter.personalityLabel(entry.key), entry.value);
      expect(displayFormatter.personalityLabel(entry.key), isNot(entry.key));
    }
  });

  test('unknown personality token never appears raw in display data', () {
    final displayData = formatter.fromAnalysis(
      _analysisResult(
        breedKey: 'breed',
        breed: 'sphynx_cat',
        personality: 'backend_unknown_personality',
      ),
    );

    expect(displayData.displayPersonality, 'Curioso');
    expect(
      displayData.displayPersonality,
      isNot('backend_unknown_personality'),
    );
  });

  test('saved Sphynx is reformatted without mutating persisted identity', () {
    final card = CatDiscoveryCard(
      cardId: 'card-sphynx-existing',
      discoveryId: 'sphynx-existing',
      cardFrameStyle: 'rare',
      cardBackgroundStyle: 'default',
      cardRarityStyle: 'epic',
      isEventCard: false,
      originalPhotoPath: 'catdex/originals/sphynx-existing.jpg',
      generatedAt: DateTime.utc(2026, 7),
      cardImageUrl: 'https://example.test/final-card.png',
    );
    final discovery = _discovery(
      id: 'sphynx-existing',
      speciesId: 'sphynx_cat',
      coatColor: 'grigio/bianco',
      coatPattern: 'bicolore',
      story: 'Uno Sphynx curioso osserva il mondo.',
      funFact: 'Questo Sphynx ama i luoghi caldi.',
      originalPhotoPath: 'catdex/originals/sphynx-existing.jpg',
      displayPhotoPath: 'catdex/originals/sphynx-existing.jpg',
      card: card,
    );

    final displayData = formatter.fromDiscovery(discovery);

    expect(displayData.displaySpecies, 'Sphynx');
    expect(displayData.displayCoatColor, 'Grigio/bianco');
    expect(displayData.displayCoatPattern, 'Bicolore');
    expect(displayData.displayStory, discovery.story);
    expect(displayData.displayFunFact, discovery.funFact);
    expect(discovery.id, 'sphynx-existing');
    expect(
      discovery.originalPhotoPath,
      'catdex/originals/sphynx-existing.jpg',
    );
    expect(discovery.displayPhotoPath, discovery.originalPhotoPath);
    expect(discovery.card, same(card));
    expect(discovery.card!.cardImageUrl, 'https://example.test/final-card.png');
  });
}

CatDiscovery _discovery({
  required String speciesId,
  required String coatColor,
  required String coatPattern,
  String id = 'display-test',
  String eyeColor = 'occhi gialli',
  String story = 'Un gatto marrone/grigio tigrato entra nel CatDex.',
  String funFact = 'I gatti domestici hanno mantelli molto vari.',
  String? originalPhotoPath,
  String? displayPhotoPath,
  CatDiscoveryCard? card,
}) {
  return CatDiscovery(
    id: id,
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
    originalPhotoPath: originalPhotoPath,
    displayPhotoPath: displayPhotoPath,
    coatColor: coatColor,
    coatPattern: coatPattern,
    eyeColor: eyeColor,
    hairLength: 'pelo corto',
    estimatedAge: 'adulto',
    story: story,
    funFact: funFact,
    card: card,
  );
}

CatAnalysisResult _analysisResult({
  required String breedKey,
  required String breed,
  required String personality,
}) {
  return const CatAnalysisResultJsonParser().parse({
    breedKey: breed,
    'confidence': 0.91,
    'coatColor': 'grigio/bianco',
    'coatPattern': 'bicolore',
    'eyeColor': 'amber',
    'hairLength': 'short',
    'personality': personality,
    'rarity': 'epic',
    'variant': 'normal',
    'story': 'Uno Sphynx curioso osserva il mondo.',
    'funFact': 'Questo Sphynx ama i luoghi caldi.',
    'analyzedAt': '2026-07-01T12:00:00.000Z',
  });
}
