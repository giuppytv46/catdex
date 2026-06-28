import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/analysis/presentation/cat_analysis_display_text.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes backend visual values to Italian user-facing traits', () {
    const displayText = CatAnalysisDisplayText();

    final summary = displayText.traitSummary(_result());

    expect(
      summary,
      'Marrone, Tigrato, Occhi ambrati, Pelo corto, Posa: in osservazione',
    );
    expect(summary, isNot(contains('Blue eyes')));
    expect(summary, isNot(contains('Long hair')));
    expect(summary, isNot(contains('curved whiskers')));
    expect(displayText.personality(CatPersonality.relaxed), 'Rilassato');
    expect(displayText.personality(CatPersonality.curious), 'Curioso');
  });
}

CatAnalysisResult _result() {
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
      coatColor: 'Brown',
      coatPattern: 'Tabby',
      eyeColor: 'Amber eyes',
      hairLength: 'Short hair',
      notableTraits: [
        CatTrait(name: 'Posa', value: 'watching'),
        CatTrait(name: 'Whiskers', value: 'curved whiskers'),
      ],
    ),
    confidence: confidence,
    rarity: CatRarity.common,
    variant: variant,
    personality: CatPersonality.relaxed,
    story: 'Un gatto osserva tranquillo.',
    analyzedAt: DateTime.utc(2026),
  );
}
