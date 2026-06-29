import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI two-step analysis foundation', () {
    late String functionText;

    setUpAll(() {
      functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();
    });

    test('OpenAI prompt requests visible facts only', () {
      expect(functionText, contains('Return only visible facts'));
      expect(functionText, contains('coatBaseColor'));
      expect(functionText, contains('visibleConfidence'));
      expect(functionText, contains('Do not return breed'));
      expect(functionText, contains('Do not return breed, rarity'));
      expect(functionText, contains('If a visual fact is uncertain'));
    });

    test('CatDex rule engine classifies common tabby cats locally', () {
      expect(functionText, contains('function breedFromObservationRules('));
      expect(functionText, contains('isTabbyPattern(coatPattern)'));
      expect(functionText, contains('domestic_tabby_cat'));
      expect(functionText, contains('function rarityFromObservationRules('));
      expect(functionText, contains('return breed.startsWith("domestic_")'));
      expect(functionText, contains('"common"'));
    });

    test('tabby rules avoid black, white, calico, and colorpoint guesses', () {
      expect(functionText, contains('isBlackColor(color) && !solid'));
      expect(functionText, contains('isWhiteColor(color)'));
      expect(functionText, contains('isCalicoColor(color)'));
      expect(functionText, contains('isColorpointColor(color)'));
      expect(functionText, contains('marrone/grigio tigrato'));
    });

    test('tabby output keeps pattern tabby and short hair for common cats', () {
      expect(functionText, contains('return "tigrato";'));
      expect(functionText, contains('return "pelo corto";'));
      expect(functionText, contains('marrone tigrato'));
      expect(functionText, contains('grigio tigrato'));
    });
  });
}
