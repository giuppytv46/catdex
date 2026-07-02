import 'dart:io';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('catdex_images_');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('returns originalPhotoPath when present', () {
    final photo = writeImage(tempDirectory, 'original.jpg');
    final discovery = _discovery(originalPhotoPath: photo.path);

    final resolved = CatDexImageResolver.resolveBestPhotoPath(discovery);

    expect(resolved, photo.path);
  });

  test('returns displayPhotoPath before originalPhotoPath', () {
    final original = writeImage(tempDirectory, 'original.jpg');
    final display = writeImage(tempDirectory, 'display.jpg');
    final discovery = _discovery(
      originalPhotoPath: original.path,
      displayPhotoPath: display.path,
    );

    final resolved = CatDexImageResolver.resolveBestPhotoPath(discovery);

    expect(resolved, display.path);
  });

  test('hasUsablePhoto is false when no image path exists', () {
    final discovery = _discovery();

    expect(CatDexImageResolver.hasUsablePhoto(discovery), isFalse);
  });
}

File writeImage(Directory directory, String name) {
  final file = File('${directory.path}/$name')..writeAsBytesSync(_onePixelPng);
  return file;
}

CatDiscovery _discovery({
  String? originalPhotoPath,
  String? displayPhotoPath,
}) {
  return CatDiscovery(
    id: 'discovery-1',
    playerId: 'local-player',
    speciesId: 'domestic_tabby_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 6, 30),
    friendshipPoints: 1,
    originalPhotoPath: originalPhotoPath,
    displayPhotoPath: displayPhotoPath,
  );
}

const _onePixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  15,
  4,
  0,
  9,
  251,
  3,
  253,
  160,
  130,
  243,
  191,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
