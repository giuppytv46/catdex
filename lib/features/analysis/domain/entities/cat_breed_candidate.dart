import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';

class CatBreedCandidate {
  const CatBreedCandidate({
    required this.species,
    required this.confidence,
  });

  final CatSpecies species;
  final CatAnalysisConfidence confidence;
}
