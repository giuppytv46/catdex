import 'package:catdex/features/analysis/data/cat_analysis_result_json_parser.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:test/test.dart';

void main() {
  test('parses CatAnalysisResult-compatible backend JSON', () {
    const parser = CatAnalysisResultJsonParser();

    final result = parser.parse(_json());

    expect(result.primaryBreed.species.id, 'domestic_tabby_cat');
    expect(result.breedCandidates, hasLength(2));
    expect(result.visualTraits.coatColor, 'Brown');
    expect(result.visualTraits.notableTraits, hasLength(1));
    expect(result.confidence.score, 0.82);
    expect(result.rarity, CatRarity.common);
    expect(result.variant.id, 'normal');
    expect(result.personality, CatPersonality.curious);
    expect(result.story, isNotEmpty);
  });

  test('falls back safely for unknown seed ids', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _json();
    final primaryBreed = Map<String, Object?>.from(
      json['primaryBreed']! as Map<String, Object?>,
    );
    primaryBreed['speciesId'] = 'not_a_cat';
    json['primaryBreed'] = primaryBreed;

    final result = parser.parse(json);

    expect(result.primaryBreed.species.id, 'domestic_shorthair_cat');
    expect(result.confidence.score, 0.35);
  });

  test('parses real Edge Function response shape', () {
    const parser = CatAnalysisResultJsonParser();

    final result = parser.parse(_realJson());

    expect(result.primaryBreed.species.id, 'domestic_tabby_cat');
    expect(result.displayBreed, 'domestic_tabby_cat');
    expect(result.breedCandidates, hasLength(2));
    expect(result.visualTraits.coatPattern, 'Tabby');
    expect(result.variant.id, 'normal');
    expect(result.displayRarity, 'common');
    expect(result.displayVariant, 'normal');
    expect(result.displayPersonality, 'curious');
  });

  test('preserves backend breed instead of applying local conversion', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _realJson()
      ..['breed'] = 'cymric'
      ..['confidence'] = 0.61
      ..['candidates'] = [
        {'breed': 'cymric', 'confidence': 0.61},
      ];

    final result = parser.parse(json);

    expect(result.primaryBreed.species.id, 'cymric');
    expect(result.displayBreed, 'cymric');
    expect(result.confidence.score, 0.61);
  });

  test('preserves backend variant instead of applying local conversion', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _realJson()..['variant'] = 'event_edition';

    final result = parser.parse(json);

    expect(result.variant.id, 'event_edition');
  });

  test('preserves backend rarity instead of applying local conversion', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _realJson()
      ..['rarity'] = 'legendary'
      ..['confidence'] = 0.85;

    final result = parser.parse(json);

    expect(result.rarity, CatRarity.legendary);
  });

  test('preserves backend visual values unchanged', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _realJson()
      ..['breed'] = 'domestic_orange_cat'
      ..['coatColor'] = 'arancione'
      ..['coatPattern'] = 'tabby'
      ..['eyeColor'] = 'ambra'
      ..['hairLength'] = 'corto'
      ..['estimatedAge'] = 'adulto'
      ..['personality'] = 'osservatore_calmo'
      ..['rarity'] = 'ordinario'
      ..['variant'] = 'standard'
      ..['funFact'] = 'Curiosita ricevuta dal backend.'
      ..['traits'] = <Map<String, Object?>>[];

    final result = parser.parse(json);

    expect(result.displayBreed, 'domestic_orange_cat');
    expect(result.primaryBreed.species.id, 'domestic_orange_cat');
    expect(result.visualTraits.coatColor, 'arancione');
    expect(result.visualTraits.coatPattern, 'tabby');
    expect(result.visualTraits.eyeColor, 'ambra');
    expect(result.visualTraits.hairLength, 'corto');
    expect(result.visualTraits.notableTraits, isEmpty);
    expect(result.estimatedAge, 'adulto');
    expect(result.displayPersonality, 'osservatore_calmo');
    expect(result.displayRarity, 'ordinario');
    expect(result.displayVariant, 'standard');
    expect(result.funFact, 'Curiosita ricevuta dal backend.');
    expect(result.rarity, CatRarity.common);
    expect(result.variant.id, 'normal');
    expect(result.personality, CatPersonality.curious);
  });

  test('falls back safely for malformed response', () {
    const parser = CatAnalysisResultJsonParser();

    final result = parser.parse({'unexpected': 'shape'});

    expect(result.primaryBreed.species.id, 'domestic_shorthair_cat');
    expect(result.visualTraits.coatColor, 'Unknown');
  });
}

Map<String, Object?> _json() {
  return {
    'primaryBreed': {
      'speciesId': 'domestic_tabby_cat',
      'confidence': 0.82,
    },
    'breedCandidates': [
      {
        'speciesId': 'domestic_tabby_cat',
        'confidence': 0.82,
      },
      {
        'speciesId': 'domestic_shorthair_cat',
        'confidence': 0.64,
      },
    ],
    'visualTraits': {
      'coatColor': 'Brown',
      'coatPattern': 'Tabby',
      'eyeColor': 'Green',
      'hairLength': 'Short',
      'notableTraits': [
        {
          'name': 'Mood',
          'value': 'Curious',
          'rarityWeight': 1,
        },
      ],
    },
    'confidence': 0.82,
    'rarity': 'common',
    'variantId': 'normal',
    'personality': 'curious',
    'story': 'A curious local cat joins CatDex.',
    'analyzedAt': '2026-06-28T12:00:00.000Z',
  };
}

Map<String, Object?> _realJson() {
  return {
    'breed': 'domestic_tabby_cat',
    'confidence': 0.82,
    'candidates': [
      {
        'breed': 'domestic_tabby_cat',
        'confidence': 0.82,
      },
      {
        'breed': 'domestic_shorthair_cat',
        'confidence': 0.64,
      },
    ],
    'coatColor': 'Brown',
    'coatPattern': 'Tabby',
    'eyeColor': 'Green',
    'hairLength': 'Short',
    'traits': [
      {
        'name': 'Mood',
        'value': 'Curious',
        'rarityWeight': 1,
      },
    ],
    'personality': 'curious',
    'rarity': 'common',
    'variant': 'normal',
    'story': 'A curious local cat joins CatDex.',
    'safetyStatus': 'safe',
    'analyzedAt': '2026-06-28T12:00:00.000Z',
  };
}
