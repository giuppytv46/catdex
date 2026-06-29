import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI coat accuracy foundation', () {
    late String functionText;

    setUpAll(() {
      functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();
    });

    test('prompt distinguishes common tabby coat colors', () {
      expect(functionText, contains('marrone tigrato'));
      expect(functionText, contains('grigio tigrato'));
      expect(functionText, contains('arancione tigrato'));
      expect(functionText, contains('nero solido'));
      expect(functionText, contains('mostly solid black'));
      expect(functionText, contains('mostly white'));
    });

    test('tabby normalization cannot become Nero, Calico, or Colorpoint', () {
      expect(functionText, contains('function realisticCoatColor('));
      expect(functionText, contains('if (tabby)'));
      expect(functionText, contains('isBlackColor(color) && !solid'));
      expect(functionText, contains('isCalicoColor(color)'));
      expect(functionText, contains('isColorpointColor(color)'));
      expect(functionText, contains('marrone/grigio tigrato'));
    });

    test('solid black can normalize to nero solido', () {
      expect(functionText, contains('if (solid && isBlackColor(color))'));
      expect(functionText, contains('return "nero solido";'));
    });

    test('black and white bicolor safeguards run before tabby fallback', () {
      expect(
        functionText,
        contains('function isBlackWhiteBicolorObservation('),
      );
      expect(functionText, contains('function isBlackWhiteBicolorCoat('));
      expect(functionText, contains('function isBlackWhiteBicolorVisual('));
      expect(functionText, contains('return "nero/bianco";'));
      expect(functionText, contains('"domestic_black_white_cat"'));
      expect(functionText, contains('"domestic_tuxedo_cat"'));
      expect(
        functionText,
        contains('Do not classify black-and-white bicolor cats as brown'),
      );
      expect(functionText, contains('Use tabby or mackerel_tabby only'));
    });

    test('Cat03-like brown gray mackerel tabby does not become orange', () {
      expect(
        functionText,
        contains('function normalizeCoatColorFromObservation('),
      );
      expect(
        functionText,
        contains('const rawCoatColor = coatColorFromObservation('),
      );
      expect(functionText, contains('function isCat03LikeTabby('));
      expect(functionText, contains('function isClearlyOrangeTabby('));
      expect(functionText, contains('current.includes("arancione")'));
      expect(functionText, contains('return "marrone/grigio tigrato";'));
      expect(functionText, contains('return "marrone/grigio tigrato";'));
      expect(functionText, contains('return "marrone tigrato";'));
      expect(functionText, contains('return "tigrato mackerel";'));
      expect(functionText, contains('secondaryColor === "unknown"'));
      expect(functionText, contains('secondaryUnknown'));
      expect(functionText, contains('Orange tabby is allowed only when'));
      expect(functionText, contains('must not become orange'));
    });

    test('true orange tabby remains allowed by post-processing guard', () {
      expect(functionText, contains('observation.orangePresent'));
      expect(functionText, contains('baseColor === "orange"'));
      expect(functionText, contains('observation.visibleConfidence >= 0.9'));
      expect(functionText, contains('!secondaryUnknown'));
      expect(functionText, contains('return currentColor;'));
      expect(functionText, contains('return "arancione tigrato";'));
    });
  });
}
