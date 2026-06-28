import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('beta QA foundation', () {
    test('beta QA documents exist', () {
      const requiredDocs = [
        'docs/BETA_QA_CHECKLIST.md',
        'docs/KNOWN_LIMITATIONS.md',
      ];

      for (final path in requiredDocs) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });
  });
}
