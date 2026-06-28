import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';

class CatAnalysisResultJsonParser {
  const CatAnalysisResultJsonParser();

  CatAnalysisResult parse(Object? json) {
    final map = _map(json);
    final primaryBreed = _breedCandidate(map['primaryBreed']);
    final candidates = _list(
      map['breedCandidates'],
    ).map(_breedCandidate).toList(growable: false);
    final confidence = _confidence(map['confidence']);

    return CatAnalysisResult(
      primaryBreed: primaryBreed,
      breedCandidates: candidates.isEmpty ? [primaryBreed] : candidates,
      visualTraits: _visualTraits(map['visualTraits']),
      confidence: confidence,
      rarity: _rarity(_string(map['rarity'])),
      variant: _variant(_string(map['variantId'])),
      personality: _personality(_string(map['personality'])),
      story: _string(map['story']),
      analyzedAt: DateTime.parse(_string(map['analyzedAt'])),
    );
  }

  CatBreedCandidate _breedCandidate(Object? json) {
    final map = _map(json);

    return CatBreedCandidate(
      species: _species(_string(map['speciesId'])),
      confidence: _confidence(map['confidence']),
    );
  }

  CatVisualTraits _visualTraits(Object? json) {
    final map = _map(json);
    final traits = _list(map['notableTraits'])
        .map((item) {
          final trait = _map(item);

          return CatTrait(
            name: _string(trait['name']),
            value: _string(trait['value']),
            rarityWeight: _optionalDouble(trait['rarityWeight']) ?? 1,
          );
        })
        .toList(growable: false);

    return CatVisualTraits(
      coatColor: _string(map['coatColor']),
      coatPattern: _string(map['coatPattern']),
      eyeColor: _string(map['eyeColor']),
      hairLength: _string(map['hairLength']),
      notableTraits: traits,
    );
  }

  CatAnalysisConfidence _confidence(Object? value) {
    final score = _double(value);
    if (score < 0 || score > 1) {
      throw const FormatException('confidence must be between 0 and 1');
    }

    return CatAnalysisConfidence(score);
  }

  CatSpecies _species(String id) {
    for (final species in CatDexSeedData.species) {
      if (species.id == id) {
        return species;
      }
    }

    throw FormatException('Unknown species id: $id');
  }

  CatVariant _variant(String id) {
    for (final variant in CatDexSeedData.variants) {
      if (variant.id == id) {
        return variant;
      }
    }

    throw FormatException('Unknown variant id: $id');
  }

  CatRarity _rarity(String name) {
    for (final rarity in CatRarity.values) {
      if (rarity.name == name) {
        return rarity;
      }
    }

    throw FormatException('Unknown rarity: $name');
  }

  CatPersonality _personality(String name) {
    for (final personality in CatPersonality.values) {
      if (personality.name == name) {
        return personality;
      }
    }

    throw FormatException('Unknown personality: $name');
  }

  Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return value.cast<String, Object?>();
    }

    throw const FormatException('Expected JSON object');
  }

  List<Object?> _list(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return value.cast<Object?>();
    }

    throw const FormatException('Expected JSON list');
  }

  String _string(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw const FormatException('Expected non-empty string');
  }

  double _double(Object? value) {
    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    throw const FormatException('Expected number');
  }

  double? _optionalDouble(Object? value) {
    if (value == null) {
      return null;
    }

    return _double(value);
  }
}
