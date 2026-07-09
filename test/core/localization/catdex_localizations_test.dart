import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports all CatDex launch locales', () {
    expect(CatDexLocalizations.supportedLocales, hasLength(11));
    expect(
      CatDexLocalizations.supportedLocales,
      containsAll(const [
        Locale('it'),
        Locale('en', 'US'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('ja'),
        Locale('zh', 'CN'),
        Locale('ko'),
        Locale('hi', 'IN'),
        Locale('pt', 'BR'),
        Locale('pt', 'PT'),
      ]),
    );
  });

  test('localizes core display values without changing internal codes', () {
    const italian = CatDexLocalizations(Locale('it'));
    const japanese = CatDexLocalizations(Locale('ja'));
    const chinese = CatDexLocalizations(Locale('zh', 'CN'));

    expect(italian.localizeDisplayValue('common'), 'Comune');
    expect(japanese.localizeDisplayValue('domestic_tabby_cat'), 'トラ柄のイエネコ');
    expect(japanese.localizeDisplayValue('occhi gialli'), '黄色');
    expect(japanese.localizeDisplayValue('pelo medio'), '中毛');
    expect(japanese.localizeDisplayValue('adulto'), '成猫');
    expect(japanese.captureChooseCatPhoto, '猫の写真を選択');
    expect(
      japanese.captureChooseCatPhotoSubtitle,
      '新しい写真を撮るか、ギャラリーからインポートしてください。',
    );
    expect(japanese.captureTakePhoto, '写真を撮る');
    expect(japanese.captureImportFromGallery, 'ギャラリーからインポート');
    expect(japanese.bottomCatdex, 'CatDex');
    expect(japanese.bottomCapture, '撮影');
    expect(japanese.bottomCards, 'カード');
    expect(japanese.bottomProfile, 'プロフィール');
    expect(chinese.localizeDisplayValue('lazy'), '慵懒');
  });

  test('translates manual edit personality labels without changing keys', () {
    const internal = 'elegant';
    const italian = CatDexLocalizations(Locale('it'));
    const english = CatDexLocalizations(Locale('en', 'US'));
    const japanese = CatDexLocalizations(Locale('ja'));

    expect(internal, 'elegant');
    expect(italian.localizeDisplayValue(internal), 'Elegante');
    expect(english.localizeDisplayValue(internal), 'Elegant');
    expect(japanese.localizeDisplayValue(internal), isNot('Elegante'));
  });
}
