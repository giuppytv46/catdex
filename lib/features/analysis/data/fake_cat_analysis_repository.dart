import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';

class FakeCatAnalysisRepository implements CatAnalysisRepository {
  const FakeCatAnalysisRepository();

  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) async {
    final seed = _seedForPath(photo.path);
    const species = CatDexSeedData.species;
    const variants = CatDexSeedData.variants;
    final primarySpecies = species[seed % species.length];
    final secondarySpecies = species[(seed + 7) % species.length];
    final fallbackSpecies = species[(seed + 19) % species.length];
    final variant = variants[seed % variants.length];
    final rarity = _effectiveRarity(primarySpecies.baseRarity, variant);
    final confidence = CatAnalysisConfidence(0.72 + (seed % 21) / 100);

    return CatAnalysisResult(
      primaryBreed: CatBreedCandidate(
        species: primarySpecies,
        confidence: confidence,
      ),
      breedCandidates: [
        CatBreedCandidate(species: primarySpecies, confidence: confidence),
        CatBreedCandidate(
          species: secondarySpecies,
          confidence: const CatAnalysisConfidence(0.64),
        ),
        CatBreedCandidate(
          species: fallbackSpecies,
          confidence: const CatAnalysisConfidence(0.48),
        ),
      ],
      visualTraits: CatVisualTraits(
        coatColor: _coatColors[seed % _coatColors.length],
        coatPattern: _coatPatterns[seed % _coatPatterns.length],
        eyeColor: _eyeColors[seed % _eyeColors.length],
        hairLength: _hairLengths[seed % _hairLengths.length],
        notableTraits: [
          CatTrait(name: 'Whiskers', value: _whiskers[seed % _whiskers.length]),
          CatTrait(name: 'Pose', value: _poses[seed % _poses.length]),
          CatTrait(name: 'Mood', value: _moods[seed % _moods.length]),
        ],
      ),
      confidence: confidence,
      rarity: rarity,
      variant: variant,
      personality: CatPersonality.values[seed % CatPersonality.values.length],
      story: _storyFor(primarySpecies.displayName, variant.name),
      analyzedAt: DateTime.utc(2026, 6, 27, 12),
    );
  }

  int _seedForPath(String path) {
    return path.codeUnits.fold<int>(0, (total, codeUnit) => total + codeUnit);
  }

  CatRarity _effectiveRarity(CatRarity baseRarity, CatVariant variant) {
    if (variant.requiresEvent) {
      return CatRarity.epic;
    }

    if (variant.rewardMultiplier >= 2.2) {
      return CatRarity.legendary;
    }

    if (variant.rewardMultiplier >= 1.8 &&
        baseRarity.index < CatRarity.rare.index) {
      return CatRarity.rare;
    }

    return baseRarity;
  }

  String _storyFor(String speciesName, String variantName) {
    return 'This $variantName $speciesName looks like a tiny neighborhood '
        'legend, calmly studying the world before choosing its next cozy nap.';
  }

  static const _coatColors = [
    'Black',
    'Silver',
    'Cream',
    'Orange',
    'White',
    'Blue Gray',
  ];

  static const _coatPatterns = [
    'Tabby',
    'Solid',
    'Tuxedo',
    'Colorpoint',
    'Calico',
    'Tortoiseshell',
  ];

  static const _eyeColors = [
    'Green',
    'Gold',
    'Blue',
    'Copper',
    'Amber',
  ];

  static const _hairLengths = [
    'Short',
    'Medium',
    'Long',
    'Fluffy',
  ];

  static const _whiskers = [
    'Long',
    'Bright',
    'Curved',
    'Bold',
  ];

  static const _poses = [
    'Sitting',
    'Watching',
    'Stretching',
    'Lounging',
  ];

  static const _moods = [
    'Curious',
    'Relaxed',
    'Playful',
    'Alert',
  ];
}
