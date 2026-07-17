import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/analysis/domain/services/cat_discovery_factory.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:test/test.dart';

void main() {
  test('creates a CatDiscovery from a local analysis result', () {
    const factory = CatDiscoveryFactory();
    final result = _analysisResult();

    final discovery = factory.create(
      result: result,
      discoveryId: 'discovery-1',
      playerId: 'player-1',
      discoveredAt: DateTime.utc(2026, 6, 28),
      friendshipPoints: 30,
      xpEarned: 100,
      coinsEarned: 15,
      customName: 'Nebbia',
      originalPhotoPath: '/tmp/original-cat.jpg',
      displayPhotoPath: '/tmp/display-cat.jpg',
    );

    expect(discovery.id, 'discovery-1');
    expect(discovery.playerId, 'player-1');
    expect(discovery.speciesId, result.primaryBreed.species.id);
    expect(discovery.variantId, result.variant.id);
    expect(discovery.rarity, result.rarity);
    expect(discovery.personality, result.personality);
    expect(discovery.traits, result.visualTraits.notableTraits);
    expect(discovery.friendshipPoints, 30);
    expect(discovery.xpEarned, 100);
    expect(discovery.coinsEarned, 15);
    expect(discovery.confidenceScore, result.confidence.score);
    expect(discovery.story, result.story);
    expect(discovery.funFact, result.funFact);
    expect(discovery.coatColor, result.visualTraits.coatColor);
    expect(discovery.coatPattern, result.visualTraits.coatPattern);
    expect(discovery.eyeColor, result.visualTraits.eyeColor);
    expect(discovery.hairLength, result.visualTraits.hairLength);
    expect(discovery.estimatedAge, result.estimatedAge);
    expect(discovery.suggestedName, result.primaryBreed.species.displayName);
    expect(discovery.suggestedName, isNot('Mochi'));
    expect(discovery.nickname, 'Nebbia');
    expect(discovery.originalPhotoPath, '/tmp/original-cat.jpg');
    expect(discovery.displayPhotoPath, '/tmp/display-cat.jpg');
    expect(discovery.card?.discoveryId, 'discovery-1');
    expect(discovery.card?.cardFrameStyle, 'green_simple_frame');
    expect(discovery.card?.cardBackgroundStyle, 'default');
    expect(discovery.card?.cardRarityStyle, 'common');
    expect(discovery.card?.isEventCard, isFalse);
    expect(discovery.card?.cutoutImagePath, isNull);
  });
}

CatAnalysisResult _analysisResult() {
  final species = CatDexSeedData.species.first;
  final variant = CatDexSeedData.variants.first;
  const confidence = CatAnalysisConfidence(0.91);

  return CatAnalysisResult(
    primaryBreed: CatBreedCandidate(
      species: species,
      confidence: confidence,
    ),
    breedCandidates: [
      CatBreedCandidate(species: species, confidence: confidence),
    ],
    visualTraits: const CatVisualTraits(
      coatColor: 'Black',
      coatPattern: 'Solid',
      eyeColor: 'Green',
      hairLength: 'Short',
      notableTraits: [
        CatTrait(name: 'Whiskers', value: 'Bright'),
      ],
    ),
    confidence: confidence,
    rarity: CatRarity.common,
    variant: variant,
    personality: CatPersonality.curious,
    story: 'A calm local discovery.',
    analyzedAt: DateTime.utc(2026),
    estimatedAge: 'adult',
    funFact: 'Tabby cats often have an M-shaped forehead marking.',
  );
}
