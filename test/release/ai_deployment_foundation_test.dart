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
  });
}
