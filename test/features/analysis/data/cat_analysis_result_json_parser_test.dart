import 'dart:convert';

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

  test('keeps backend response when seed ids are unknown', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _json();
    final primaryBreed = Map<String, Object?>.from(
      json['primaryBreed']! as Map<String, Object?>,
    );
    primaryBreed['speciesId'] = 'not_a_cat';
    json['primaryBreed'] = primaryBreed;

    final result = parser.parse(json);

    expect(result.primaryBreed.species.id, 'domestic_shorthair_cat');
    expect(result.confidence.score, 0.82);
    expect(result.visualTraits.coatColor, 'Brown');
  });

  test('parses real Edge Function response shape', () {
    const parser = CatAnalysisResultJsonParser();

    final result = parser.parse(_realJson());

    expect(result.primaryBreed.species.id, 'domestic_tabby_cat');
    expect(result.displayBreed, 'domestic_tabby_cat');
    expect(result.breedCandidates, hasLength(2));
    expect(result.visualTraits.coatPattern, 'tigrato');
    expect(result.variant.id, 'normal');
    expect(result.displayRarity, 'common');
    expect(result.displayVariant, 'normal');
    expect(result.displayPersonality, 'curious');
  });

  test('preserves current backend values from decoded or encoded JSON', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _currentBackendJson();

    final decodedResult = parser.parse(json);
    final encodedResult = parser.parse(jsonEncode(json));

    for (final result in [decodedResult, encodedResult]) {
      expect(result.displayBreed, 'domestic_tabby_cat');
      expect(result.primaryBreed.species.id, 'domestic_tabby_cat');
      expect(result.visualTraits.coatPattern, 'tigrato mackerel');
      expect(result.visualTraits.coatColor, 'marrone/grigio tigrato');
      expect(result.displayRarity, 'common');
      expect(result.rarity, CatRarity.common);
      expect(result.displayVariant, 'normal');
      expect(result.variant.id, 'normal');
      expect(result.displayPersonality, 'curious');
      expect(result.personality, CatPersonality.curious);
    }
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

  test('treats literal null strings as absent values', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _realJson()
      ..['estimatedAge'] = 'null'
      ..['story'] = 'null'
      ..['funFact'] = 'null'
      ..['traits'] = [
        {'name': 'null', 'value': 'ignored', 'rarityWeight': 1},
        {'name': 'Posa', 'value': 'null', 'rarityWeight': 1},
      ];

    final result = parser.parse(json);

    expect(result.estimatedAge, isNull);
    expect(result.story, isNot('null'));
    expect(result.funFact, isNull);
    expect(result.visualTraits.notableTraits, isEmpty);
  });

  test('does not replace backend visual fields with fake defaults', () {
    const parser = CatAnalysisResultJsonParser();
    final result = parser.parse(_realJson());

    expect(result.visualTraits.coatColor, 'arancione tigrato');
    expect(result.visualTraits.coatColor, isNot('Bianco'));
    expect(result.visualTraits.coatPattern, 'tigrato');
    expect(result.visualTraits.coatPattern, isNot('Calico'));
    expect(result.visualTraits.hairLength, 'pelo corto');
    expect(result.visualTraits.hairLength, isNot('Lungo'));
  });

  test('falls back safely for malformed response', () {
    const parser = CatAnalysisResultJsonParser();

    final result = parser.parse({'unexpected': 'shape'});

    expect(result.primaryBreed.species.id, 'domestic_shorthair_cat');
    expect(result.visualTraits.coatColor, 'Unknown');
  });

  test('recognizes breed field alias when speciesId is missing', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _realJson()
      ..['breed'] = 'sphynx_cat'
      ..remove('speciesId')
      ..remove('primaryBreed');

    final result = parser.parse(json);

    expect(result.primaryBreed.species.id, 'sphynx');
    expect(result.displayBreed, 'sphynx_cat');
  });

  test('recognizes speciesId field when breed is missing', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _realJson()
      ..remove('breed')
      ..['speciesId'] = 'sphynx_cat'
      ..remove('primaryBreed');

    final result = parser.parse(json);

    expect(result.primaryBreed.species.id, 'sphynx');
    expect(result.displayBreed, 'sphynx_cat');
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
    'coatColor': 'arancione tigrato',
    'coatPattern': 'tigrato',
    'eyeColor': 'occhi gialli',
    'hairLength': 'pelo corto',
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

Map<String, Object?> _currentBackendJson() {
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
    'coatColor': 'marrone/grigio tigrato',
    'coatPattern': 'tigrato mackerel',
    'eyeColor': 'occhi gialli',
    'hairLength': 'pelo corto',
    'estimatedAge': 'adulto',
    'traits': [
      {
        'name': 'Mantello',
        'value': 'marrone/grigio tigrato, tigrato mackerel',
        'rarityWeight': 1,
      },
    ],
    'personality': 'curious',
    'rarity': 'common',
    'variant': 'normal',
    'story': 'Un gatto domestico tigrato entra nel CatDex.',
    'funFact': 'I gatti tigrati domestici sono molto comuni.',
    'safetyStatus': 'safe',
    'analyzedAt': '2026-06-28T12:00:00.000Z',
  };
}
