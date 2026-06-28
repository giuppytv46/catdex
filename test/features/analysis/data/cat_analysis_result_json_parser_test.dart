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

  test('throws FormatException for unknown seed ids', () {
    const parser = CatAnalysisResultJsonParser();
    final json = _json();
    final primaryBreed = Map<String, Object?>.from(
      json['primaryBreed']! as Map<String, Object?>,
    );
    primaryBreed['speciesId'] = 'not_a_cat';
    json['primaryBreed'] = primaryBreed;

    expect(() => parser.parse(json), throwsA(isA<FormatException>()));
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
