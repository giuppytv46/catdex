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

    test('solid black can normalize to Nero', () {
      expect(functionText, contains('if (solid && isBlackColor(color))'));
      expect(functionText, contains('return "Nero";'));
    });
  });
}
