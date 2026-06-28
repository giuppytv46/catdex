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
    final map = _optionalMap(json);
    if (map == null) {
      return _safeFallback();
    }

    try {
      final primaryBreed = _primaryBreed(map);
      final candidates = _candidates(map, primaryBreed);
      final confidence = _confidence(map['confidence']);
      final realisticPrimaryBreed = _realisticPrimaryBreed(
        primaryBreed,
        confidence,
      );
      final realisticCandidates = _realisticCandidates(
        candidates,
        realisticPrimaryBreed,
      );

      return CatAnalysisResult(
        primaryBreed: realisticPrimaryBreed,
        breedCandidates: realisticCandidates,
        visualTraits: _visualTraits(map),
        confidence: confidence,
        rarity: _realisticRarity(
          _rarity(_optionalString(map['rarity']) ?? 'common'),
          confidence,
        ),
        variant: _realisticVariant(
          _variant(
            _optionalString(map['variantId']) ??
                _optionalString(map['variant']) ??
                'normal',
          ),
        ),
        personality: _personality(
          _optionalString(map['personality']) ?? 'curious',
        ),
        story: _optionalString(map['story']) ?? _fallbackStory,
        analyzedAt: DateTime.parse(
          _optionalString(map['analyzedAt']) ??
              DateTime.utc(2026, 6, 28).toIso8601String(),
        ),
      );
    } on FormatException {
      return _safeFallback();
    }
  }

  CatBreedCandidate _breedCandidate(Object? json) {
    final map = _map(json);

    return CatBreedCandidate(
      species: _species(
        _optionalString(map['speciesId']) ??
            _optionalString(map['breed']) ??
            'domestic_shorthair_cat',
      ),
      confidence: _confidence(map['confidence']),
    );
  }

  CatBreedCandidate _primaryBreed(Map<String, Object?> map) {
    if (map.containsKey('primaryBreed')) {
      return _breedCandidate(map['primaryBreed']);
    }

    return CatBreedCandidate(
      species: _species(
        _optionalString(map['breed']) ?? 'domestic_shorthair_cat',
      ),
      confidence: _confidence(map['confidence']),
    );
  }

  CatBreedCandidate _realisticPrimaryBreed(
    CatBreedCandidate primaryBreed,
    CatAnalysisConfidence confidence,
  ) {
    if (confidence.score < 0.8 ||
        (_rareBreedIds.contains(primaryBreed.species.id) &&
            confidence.score < 0.9)) {
      return CatBreedCandidate(
        species: _species('domestic_shorthair_cat'),
        confidence: confidence,
      );
    }

    return primaryBreed;
  }

  List<CatBreedCandidate> _realisticCandidates(
    List<CatBreedCandidate> candidates,
    CatBreedCandidate primaryBreed,
  ) {
    final filtered = candidates
        .where((candidate) => !_rareBreedIds.contains(candidate.species.id))
        .toList(growable: false);

    if (filtered.isEmpty ||
        filtered.first.species.id != primaryBreed.species.id) {
      return [primaryBreed, ...filtered].take(3).toList(growable: false);
    }

    return filtered.take(3).toList(growable: false);
  }

  List<CatBreedCandidate> _candidates(
    Map<String, Object?> map,
    CatBreedCandidate primaryBreed,
  ) {
    final source = map['breedCandidates'] ?? map['candidates'];
    final candidates = _optionalList(
      source,
    )?.map(_breedCandidate).toList(growable: false);

    return candidates == null || candidates.isEmpty
        ? [primaryBreed]
        : candidates;
  }

  CatVisualTraits _visualTraits(Map<String, Object?> resultMap) {
    final map = _optionalMap(resultMap['visualTraits']) ?? resultMap;
    final traits =
        (_optionalList(map['notableTraits']) ??
                _optionalList(map['traits']) ??
                const [])
            .map((item) {
              final trait = _map(item);

              return CatTrait(
                name: _optionalString(trait['name']) ?? 'Trait',
                value: _optionalString(trait['value']) ?? 'Unknown',
                rarityWeight: _optionalDouble(trait['rarityWeight']) ?? 1,
              );
            })
            .toList(growable: false);

    return CatVisualTraits(
      coatColor: _optionalString(map['coatColor']) ?? 'Unknown',
      coatPattern: _optionalString(map['coatPattern']) ?? 'Unknown',
      eyeColor: _optionalString(map['eyeColor']) ?? 'Unknown',
      hairLength: _optionalString(map['hairLength']) ?? 'Unknown',
      notableTraits: traits.isEmpty
          ? const [CatTrait(name: 'Mood', value: 'Curious')]
          : traits,
    );
  }

  CatAnalysisConfidence _confidence(Object? value) {
    final score = _double(value);
    if (score < 0 || score > 1) {
      throw const FormatException('confidence must be between 0 and 1');
    }

    return CatAnalysisConfidence(score);
  }

  CatSpecies _species(String rawValue) {
    final normalizedValue = _normalize(rawValue);
    for (final species in CatDexSeedData.species) {
      if (species.id == rawValue ||
          _normalize(species.displayName) == normalizedValue) {
        return species;
      }
    }

    throw FormatException('Unknown species id: $rawValue');
  }

  CatVariant _variant(String rawValue) {
    final normalizedValue = _normalize(rawValue);
    for (final variant in CatDexSeedData.variants) {
      if (variant.id == rawValue ||
          _normalize(variant.name) == normalizedValue) {
        return variant;
      }
    }

    throw FormatException('Unknown variant id: $rawValue');
  }

  CatVariant _realisticVariant(CatVariant variant) {
    if (variant.id == 'event_edition') {
      return _variant('normal');
    }

    return variant;
  }

  CatRarity _realisticRarity(
    CatRarity rarity,
    CatAnalysisConfidence confidence,
  ) {
    if (rarity == CatRarity.legendary && confidence.score < 0.98) {
      return CatRarity.rare;
    }

    if (rarity == CatRarity.mythic && confidence.score < 0.99) {
      return CatRarity.rare;
    }

    return rarity;
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
    final map = _optionalMap(value);
    if (map != null) {
      return map;
    }

    throw const FormatException('Expected JSON object');
  }

  Map<String, Object?>? _optionalMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return value.cast<String, Object?>();
    }

    return null;
  }

  List<Object?>? _optionalList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return value.cast<Object?>();
    }

    return null;
  }

  String? _optionalString(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    return null;
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

  CatAnalysisResult _safeFallback() {
    final species = _species('domestic_shorthair_cat');
    const confidence = CatAnalysisConfidence(0.35);

    return CatAnalysisResult(
      primaryBreed: CatBreedCandidate(
        species: species,
        confidence: confidence,
      ),
      breedCandidates: [
        CatBreedCandidate(species: species, confidence: confidence),
      ],
      visualTraits: const CatVisualTraits(
        coatColor: 'Unknown',
        coatPattern: 'Unknown',
        eyeColor: 'Unknown',
        hairLength: 'Unknown',
        notableTraits: [CatTrait(name: 'Mood', value: 'Curious')],
      ),
      confidence: confidence,
      rarity: CatRarity.common,
      variant: _variant('normal'),
      personality: CatPersonality.curious,
      story: _fallbackStory,
      analyzedAt: DateTime.utc(2026, 6, 28),
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
  }

  static const _fallbackStory =
      'This mysterious local cat keeps a few secrets, but still earns a cozy '
      'CatDex card.';
}

const _rareBreedIds = {
  'cymric',
  'lykoi',
  'khao_manee',
  'peterbald',
  'sokoke',
  'toyger',
  'chausie',
  'savannah',
  'serengeti',
  'burmilla',
};
