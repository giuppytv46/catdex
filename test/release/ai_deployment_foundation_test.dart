import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI deployment foundation', () {
    test('deployment docs and scripts exist', () {
      const paths = [
        'docs/AI_DEPLOYMENT.md',
        'scripts/deploy_ai_function.sh',
        'scripts/test_ai_function.sh',
      ];

      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });

    test('scripts do not contain committed secrets', () {
      final scriptText = [
        File('scripts/deploy_ai_function.sh').readAsStringSync(),
        File('scripts/test_ai_function.sh').readAsStringSync(),
      ].join('\n');

      expect(scriptText, isNot(contains('sk-')));
      expect(scriptText, isNot(contains('service_role=')));
      expect(scriptText, isNot(contains('OPENAI_API_KEY=')));
    });

    test('Edge Function keeps OpenAI failures safe and debuggable', () {
      final functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();

      expect(functionText, contains('/v1/chat/completions'));
      expect(functionText, contains('response_format'));
      expect(functionText, contains('catdex_cat_observation'));
      expect(functionText, contains('type: "image_url"'));
      expect(functionText, contains(r'Authorization: `Bearer ${openAiKey}`'));
      expect(functionText, contains('openAiFallbackReason'));
      expect(functionText, contains('mockReason: safeForLog'));
      expect(functionText, isNot(contains('ai_failed')));
      expect(functionText, isNot(contains('502')));
    });

    test('Edge Function uses observation first and local CatDex rules', () {
      final functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();

      final observationIndex = functionText.indexOf(
        'const observation = parseVisionEngineObservation(value);',
      );
      final classificationIndex = functionText.indexOf(
        'const classification = classifyWithRuleEngine(observation, context);',
      );
      final loreIndex = functionText.indexOf(
        'const lore = generateLoreWithLoreEngine(observation, classification);',
      );
      final successResponseIndex = functionText.indexOf(
        'return jsonResponse(toResultEnvelope(analysis), 200);',
      );
      final mockFallbackIndex = functionText.indexOf(
        'mockAnalysisResult(openAiFallbackReason(error))',
      );

      expect(observationIndex, isNonNegative);
      expect(classificationIndex, isNonNegative);
      expect(loreIndex, isNonNegative);
      expect(observationIndex, lessThan(classificationIndex));
      expect(classificationIndex, lessThan(loreIndex));
      expect(functionText, contains('Do not return breed'));
      expect(functionText, contains('If a visual fact is uncertain'));
      expect(functionText, contains('function parseVisionEngineObservation('));
      expect(functionText, contains('function classifyWithRuleEngine('));
      expect(functionText, contains('breedFromObservationRules('));
      expect(functionText, contains('rarityFromObservationRules('));
      expect(functionText, contains('function generateLoreWithLoreEngine('));
      expect(functionText, contains('storyFromObservation('));
      expect(successResponseIndex, isNonNegative);
      expect(mockFallbackIndex, isNonNegative);
      expect(successResponseIndex, lessThan(mockFallbackIndex));
      expect(functionText, contains('backend: {'));
      expect(functionText, contains('mock: true'));
    });
  });
}
