import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_composer_service.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets(
    'RealCardComposerService generates an injected-size PNG',
    (
      tester,
    ) async {
      final outputDirectory = Directory(
        '/private/tmp/catdex_card_composer_test',
      );
      if (outputDirectory.existsSync()) {
        outputDirectory.deleteSync(recursive: true);
      }

      const canvasWidth = 150;
      const canvasHeight = 210;
      final service = RealCardComposerService(
        outputDirectory: outputDirectory,
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
      );
      final path = await service.generateCardImage(
        discovery: _discovery(),
        display: _displayData(),
        collectionNumber: 7,
      );

      final file = File(path);
      expect(file.existsSync(), isTrue);

      final generated = img.decodePng(file.readAsBytesSync());
      expect(generated, isNotNull);
      expect(generated!.width, canvasWidth);
      expect(generated.height, canvasHeight);
    },
    // Slow image composition test. Run manually/in integration tests.
    skip: true,
  );
}

CatDiscovery _discovery() {
  return CatDiscovery(
    id: 'composer-test',
    playerId: 'local-player',
    speciesId: 'domestic_tabby_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 6, 30),
    friendshipPoints: 10,
    customName: 'Moka',
    suggestedName: 'Moka',
    originalPhotoPath: 'assets/cards/card_common_base.png',
    displayPhotoPath: 'assets/cards/card_common_base.png',
  );
}

CatDisplayData _displayData() {
  return const CatDisplayData(
    displayName: 'Moka',
    displaySpecies: 'Gatto domestico tigrato',
    displayCoatColor: 'Marrone/grigio tigrato',
    displayCoatPattern: 'Tigrato mackerel',
    displayEyeColor: 'Occhi gialli',
    displayHairLength: 'Pelo corto',
    displayAge: 'Adulto',
    displayPersonality: 'Curioso',
    displayRarity: 'Comune',
    displayVariant: 'Normale',
    displayStory: 'Un gatto domestico tigrato entra nel CatDex.',
    displayFunFact: 'I gatti tigrati sono molto comuni.',
  );
}
