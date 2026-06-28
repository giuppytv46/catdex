import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('release foundation', () {
    test('release documents exist', () {
      const requiredDocs = [
        'docs/RELEASE_PREPARATION.md',
        'docs/PERMISSIONS.md',
        'docs/PRIVACY_POLICY_DRAFT.md',
        'docs/STORE_LISTING_DRAFT.md',
        'docs/RELEASE_CHECKLIST.md',
        'docs/APP_ICON_PLACEHOLDER.md',
        'docs/SPLASH_SCREEN_PLACEHOLDER.md',
      ];

      for (final path in requiredDocs) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });

    test('release build scripts exist', () {
      const requiredScripts = [
        'scripts/build_android.sh',
        'scripts/build_ios.sh',
      ];

      for (final path in requiredScripts) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });

    test('native release config placeholders exist', () {
      const requiredPlaceholders = [
        'android/release/key.properties.example',
        'ios/Runner/Config/ReleaseConfig.example.xcconfig',
      ];

      for (final path in requiredPlaceholders) {
        expect(File(path).existsSync(), isTrue, reason: '$path should exist');
      }
    });
  });
}
