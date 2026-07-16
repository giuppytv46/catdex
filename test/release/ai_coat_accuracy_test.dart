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
      expect(functionText, contains('Allowed coatBaseColor values only'));
      expect(functionText, contains('Allowed coatPattern values only'));
      expect(functionText, contains('coatBaseColor orange'));
      expect(functionText, contains('true black fur => coatBaseColor black'));
      expect(functionText, contains('pure white or mostly white fur'));
      expect(functionText, contains('brown or taupe non-orange fur'));
      expect(
        functionText,
        contains('Do not return brown or gray for orange/ginger cats'),
      );
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
      final normalizeBody = _functionBody(
        functionText,
        'normalizeCoatColorFromObservation',
      );
      final realisticBody = _functionBody(functionText, 'realisticCoatColor');

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
        normalizeBody.indexOf('isBlackWhiteBicolorObservation'),
        lessThan(normalizeBody.indexOf('if (isBicolorPattern(pattern))')),
      );
      expect(
        realisticBody.indexOf('isBlackWhiteBicolorVisual'),
        lessThan(realisticBody.indexOf('if (tabby)')),
      );
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
      expect(functionText, contains('return "marrone tigrato";'));
      expect(functionText, contains('return "tigrato mackerel";'));
      expect(functionText, contains('secondaryColor === "unknown"'));
      expect(functionText, contains('secondaryUnknown'));

      final realisticBody = _functionBody(functionText, 'realisticCoatColor');
      expect(
        realisticBody.indexOf('isCat03LikeTabby'),
        lessThan(realisticBody.indexOf('isClearlyOrangeTabby')),
      );
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

String _functionBody(String source, String functionName) {
  final start = source.indexOf('function $functionName');
  expect(start, isNonNegative, reason: '$functionName should exist');

  final parameterStart = source.indexOf('(', start);
  expect(
    parameterStart,
    isNonNegative,
    reason: '$functionName should have parameters',
  );

  var parameterDepth = 0;
  var signatureEnd = -1;
  for (var index = parameterStart; index < source.length; index++) {
    final char = source[index];
    if (char == '(') {
      parameterDepth++;
    } else if (char == ')') {
      parameterDepth--;
      if (parameterDepth == 0) {
        signatureEnd = index;
        break;
      }
    }
  }
  expect(
    signatureEnd,
    isNonNegative,
    reason: '$functionName signature should end',
  );

  final openBrace = source.indexOf('{', signatureEnd);
  expect(openBrace, isNonNegative, reason: '$functionName should have a body');

  var depth = 0;
  for (var index = openBrace; index < source.length; index++) {
    final char = source[index];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(openBrace, index + 1);
      }
    }
  }

  fail('Could not read $functionName body');
}
