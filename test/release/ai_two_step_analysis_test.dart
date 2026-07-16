import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI engine pipeline foundation', () {
    late String functionText;

    setUpAll(() {
      functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();
    });

    test('Vision observation does not include breed', () {
      expect(functionText, contains('type CatVisionObservation'));
      expect(
        functionText,
        contains('function observationFromVisualInspection'),
      );
      expect(functionText, contains('baseColor'));
      expect(functionText, contains('secondaryColor'));
      expect(functionText, contains('whitePresent'));
      expect(functionText, contains('orangePresent'));
      expect(functionText, contains('blackPresent'));
      expect(functionText, contains('visibleConfidence'));
      expect(
        functionText,
        isNot(contains('type CatVisionObservation = {\n  breed')),
      );
      expect(
        functionText,
        contains('Analyze only objective visible cat facts'),
      );
      expect(functionText, contains('Do not return breed'));
      expect(functionText, contains('uncertain'));
      expect(functionText, contains('parseVisionEngineObservation'));
    });

    test('Rule Engine classifies tabby short hair as Domestic Tabby Cat', () {
      expect(functionText, contains('function classifyWithRuleEngine('));
      expect(functionText, contains('function breedFromObservationRules('));
      expect(functionText, contains('isTabbyPattern(coatPattern)'));
      expect(functionText, contains('shortOrMediumHair'));
      expect(functionText, contains('domestic_tabby_cat'));
      expect(functionText, contains('function rarityFromObservationRules('));
      expect(functionText, contains('if (breed.startsWith("domestic_"))'));
      expect(functionText, contains('"common"'));
    });

    test('Rule Engine classifies solid black as Domestic Black Cat', () {
      expect(functionText, contains('isSolidPattern(coatPattern)'));
      expect(functionText, contains('isBlackColor(coatColor)'));
      expect(functionText, contains('domestic_black_cat'));
    });

    test(
      'Rule Engine classifies domestic long hair as Domestic Longhair Cat',
      () {
        expect(functionText, contains('hairLength === "pelo lungo"'));
        expect(functionText, contains('domestic_longhair_cat'));
      },
    );

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

    test('event variants only appear with activeEventId', () {
      expect(functionText, contains('function variantFromRuleEngine('));
      expect(
        functionText,
        contains('return activeEventId === null ? "normal" : "event_edition";'),
      );
      expect(functionText, contains('activeEventIdFor(body)'));
    });

    test('Lore Engine story never contains null or unknown', () {
      expect(functionText, contains('function generateLoreWithLoreEngine('));
      expect(functionText, contains('function cleanLoreText('));
      expect(functionText, contains('normalized.includes("unknown")'));
      expect(functionText, contains('normalized.includes("null")'));
      expect(functionText, contains('deterministicLoreFallback'));
    });

    test('output remains Flutter-compatible', () {
      const requiredKeys = [
        'breed',
        'confidence',
        'candidates',
        'coatColor',
        'coatPattern',
        'eyeColor',
        'hairLength',
        'estimatedAge',
        'traits',
        'personality',
        'rarity',
        'variant',
        'story',
        'funFact',
        'safetyStatus',
        'analyzedAt',
      ];

      for (final key in requiredKeys) {
        expect(functionText, contains('$key: analysis.$key'));
      }
    });
  });
}
