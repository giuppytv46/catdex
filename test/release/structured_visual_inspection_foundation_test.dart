import 'dart:io';

import 'package:test/test.dart';

void main() {
  final edgeFunction = File(
    'supabase/functions/analyze_cat_photo/index.ts',
  ).readAsStringSync();

  test('Edge Function uses structured visual inspection schema', () {
    expect(edgeFunction, contains('type CatVisualInspection = {'));
    expect(edgeFunction, contains('coatBaseColor'));
    expect(edgeFunction, contains('hasWhite'));
    expect(edgeFunction, contains('visibleEyes'));
    expect(edgeFunction, contains('CatVisualInspectionConfidence'));
    expect(edgeFunction, contains('reasoningShort'));
  });

  test('Edge Function retries uncertain visual fields', () {
    expect(edgeFunction, contains('CATDEX_VISUAL_INSPECTION_STARTED'));
    expect(edgeFunction, contains('CATDEX_VISUAL_INSPECTION_RAW_JSON'));
    expect(edgeFunction, contains('CATDEX_VISUAL_INSPECTION_RETRY_REASON'));
    expect(edgeFunction, contains('detectEyeColorEnumFromPhoto'));
    expect(edgeFunction, contains('detectCoatBaseColorFromPhoto'));
    expect(edgeFunction, contains('detectCoatPatternFromPhoto'));
  });

  test('Edge Function maps visual inspection to CatDex display values', () {
    expect(edgeFunction, contains('arancione tigrato'));
    expect(edgeFunction, contains('grigio/bianco'));
    expect(edgeFunction, contains('nero/bianco'));
    expect(edgeFunction, contains('Gatto domestico arancione tigrato'));
    expect(edgeFunction, contains('Gatto domestico bicolore'));
  });
}
