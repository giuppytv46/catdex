import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('CatDex dynamic card template assets are registered', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      File('assets/cards/templates/common_card_template.png').existsSync(),
      isTrue,
    );
    expect(File('assets/cards/test_illustrated_cat.png').existsSync(), isTrue);
    expect(
      pubspec,
      contains('assets/cards/templates/common_card_template.png'),
    );
    expect(pubspec, contains('assets/cards/test_illustrated_cat.png'));
    expect(pubspec, isNot(contains('assets/cards/card_artwork_test.png')));
    expect(
      pubspec,
      isNot(contains('assets/cards/card_common_background.png')),
    );
    expect(pubspec, isNot(contains('assets/cards/card_common_front.png')));
    expect(pubspec, isNot(contains('assets/cards/card_common_base.png')));
    expect(pubspec, isNot(contains('assets/cards/card_common_foreground.png')));
    expect(pubspec, isNot(contains('assets/cards/card_common_overlay.png')));
    expect(pubspec, isNot(contains('assets/cards/card_common_template.png')));
    expect(pubspec, isNot(contains('assets/cards/card_common_clean.png')));
    expect(pubspec, isNot(contains('assets/cards/test_cat_illustration.png')));
    expect(pubspec, isNot(contains('assets/cards/test_cat_cutout.png')));
  });
}
