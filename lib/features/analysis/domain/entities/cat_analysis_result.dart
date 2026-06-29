import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';

class CatAnalysisResult {
  const CatAnalysisResult({
    required this.primaryBreed,
    required this.breedCandidates,
    required this.visualTraits,
    required this.confidence,
    required this.rarity,
    required this.variant,
    required this.personality,
    required this.story,
    required this.analyzedAt,
    this.backendBreed,
    this.backendRarity,
    this.backendVariant,
    this.backendPersonality,
    this.estimatedAge,
    this.funFact,
  });

  final CatBreedCandidate primaryBreed;
  final List<CatBreedCandidate> breedCandidates;
  final CatVisualTraits visualTraits;
  final CatAnalysisConfidence confidence;
  final CatRarity rarity;
  final CatVariant variant;
  final CatPersonality personality;
  final String story;
  final DateTime analyzedAt;
  final String? backendBreed;
  final String? backendRarity;
  final String? backendVariant;
  final String? backendPersonality;
  final String? estimatedAge;
  final String? funFact;

  String get displayBreed => backendBreed ?? 'Unknown';
  String get displayRarity => backendRarity ?? 'Unknown';
  String get displayVariant => backendVariant ?? 'Unknown';
  String get displayPersonality => backendPersonality ?? 'Unknown';
}
