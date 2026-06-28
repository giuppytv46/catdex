import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class FakeCatAnalysisRepository implements CatAnalysisRepository {
  const FakeCatAnalysisRepository();

  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) async {
    final seed = _seedForPath(photo.path);
    const variants = CatDexSeedData.variants;
    final primarySpecies = _realisticSpecies[seed % _realisticSpecies.length];
    final secondarySpecies =
        _realisticSpecies[(seed + 1) % _realisticSpecies.length];
    final variant = variants.firstWhere((variant) => variant.id == 'normal');
    final confidence = CatAnalysisConfidence(0.62 + (seed % 18) / 100);

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
      ],
      visualTraits: CatVisualTraits(
        coatColor: _coatColors[seed % _coatColors.length],
        coatPattern: _coatPatterns[seed % _coatPatterns.length],
        eyeColor: _eyeColors[seed % _eyeColors.length],
        hairLength: _hairLengths[seed % _hairLengths.length],
        notableTraits: [
          CatTrait(name: 'Baffi', value: _whiskers[seed % _whiskers.length]),
          CatTrait(name: 'Posa', value: _poses[seed % _poses.length]),
          CatTrait(name: 'Umore', value: _moods[seed % _moods.length]),
        ],
      ),
      confidence: confidence,
      rarity: seed.isEven ? CatRarity.common : CatRarity.uncommon,
      variant: variant,
      personality:
          _realisticPersonalities[seed % _realisticPersonalities.length],
      story: _storyFor(primarySpecies.displayName, variant.name),
      analyzedAt: DateTime.utc(2026, 6, 27, 12),
    );
  }

  int _seedForPath(String path) {
    return path.codeUnits.fold<int>(0, (total, codeUnit) => total + codeUnit);
  }

  String _storyFor(String speciesName, String variantName) {
    return 'Questo $variantName $speciesName sembra un tranquillo gatto di '
        'quartiere pronto a entrare nel tuo CatDex.';
  }

  static final List<CatSpecies> _realisticSpecies = [
    CatDexSeedData.species.firstWhere(
      (species) => species.id == 'domestic_shorthair_cat',
    ),
    CatDexSeedData.species.firstWhere(
      (species) => species.id == 'domestic_tabby_cat',
    ),
    CatDexSeedData.species.firstWhere(
      (species) => species.id == 'european_shorthair',
    ),
  ];

  static const List<CatPersonality> _realisticPersonalities = [
    CatPersonality.curious,
    CatPersonality.friendly,
    CatPersonality.relaxed,
    CatPersonality.playful,
    CatPersonality.sleepy,
  ];

  static const _coatColors = [
    'Nero',
    'Marrone',
    'Crema',
    'Arancione',
    'Bianco',
    'Grigio',
  ];

  static const _coatPatterns = [
    'Tigrato',
    'Solido',
    'Bicolore',
    'Colorpoint',
    'Calico',
    'Squama di tartaruga',
  ];

  static const _eyeColors = [
    'Verdi',
    'Dorati',
    'Blu',
    'Ramati',
    'Ambra',
  ];

  static const _hairLengths = [
    'Corto',
    'Medio',
    'Lungo',
    'Soffice',
  ];

  static const _whiskers = [
    'Lunghi',
    'Chiari',
    'Curvi',
    'Evidenti',
  ];

  static const _poses = [
    'Seduto',
    'In osservazione',
    'Disteso',
    'Rilassato',
  ];

  static const _moods = [
    'Curioso',
    'Rilassato',
    'Giocoso',
    'Attento',
  ];
}
