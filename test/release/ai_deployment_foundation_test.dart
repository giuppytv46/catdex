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
      expect(functionText, contains('type: "image_url"'));
      expect(functionText, contains(r'Authorization: `Bearer ${openAiKey}`'));
      expect(functionText, contains('openAiFallbackReason'));
      expect(functionText, contains('mockReason: safeForLog'));
      expect(functionText, isNot(contains('ai_failed')));
      expect(functionText, isNot(contains('502')));
    });

    test('Edge Function prompt favors realistic domestic cat analysis', () {
      final functionText = File(
        'supabase/functions/analyze_cat_photo/index.ts',
      ).readAsStringSync();

      expect(functionText, contains('Use domestic_tabby_cat for common tabby'));
      expect(functionText, contains('Use european_shorthair only when'));
      expect(functionText, contains('Do not output tortoiseshell unless'));
      expect(functionText, contains('Rarity must be common'));
      expect(functionText, contains('Return story, funFact'));
      expect(functionText, contains('in Italian'));
      expect(functionText, contains('realisticBreedId('));
      expect(functionText, contains('realisticRarity('));
    });
  });
}
