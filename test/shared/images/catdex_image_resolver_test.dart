import 'dart:io';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('catdex_images_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDirectory.path;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('valid local file returns localFile', () async {
    final photo = writeImage(tempDirectory, 'original.jpg');
    final discovery = _discovery(originalPhotoPath: photo.path);

    final resolved = await CatDexImageResolver.resolveBestImagePath(
      discovery: discovery,
    );

    expect(resolved.type, CatDexResolvedImageType.local);
    expect(resolved.path, photo.path);
    expect(resolved.provider, isA<FileImage>());
  });

  test('returns displayPhotoPath before originalPhotoPath', () async {
    final original = writeImage(tempDirectory, 'original.jpg');
    final display = writeImage(tempDirectory, 'display.jpg');
    final discovery = _discovery(
      originalPhotoPath: original.path,
      displayPhotoPath: display.path,
    );

    final resolved = CatDexImageResolver.resolveBestPhotoPath(discovery);

    expect(resolved, display.path);
  });

  test('hasUsablePhoto is false when no image path exists', () async {
    final discovery = _discovery();

    expect(CatDexImageResolver.hasUsablePhoto(discovery), isFalse);
  });

  test('missing local file is rejected', () async {
    final discovery = _discovery(
      displayPhotoPath: '${tempDirectory.path}/missing.jpg',
    );

    final resolved = await CatDexImageResolver.resolveBestImagePath(
      discovery: discovery,
    );

    expect(resolved.type, CatDexResolvedImageType.none);
    expect(resolved.usesPlaceholder, isTrue);
  });

  test('old iOS container path is rejected', () async {
    final discovery = _discovery(
      displayPhotoPath:
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
          'catdex/originals/original_discovery.jpg',
    );

    final resolved = await CatDexImageResolver.resolveBestImagePath(
      discovery: discovery,
    );

    expect(resolved.type, CatDexResolvedImageType.none);
  });

  test('missing local file falls back to Supabase signed URL', () async {
    final discovery = _discovery(
      displayPhotoPath: '${tempDirectory.path}/missing.jpg',
      originalPhotoStoragePath: 'catdex/originals/player/discovery.jpg',
    );

    final resolved = await CatDexImageResolver.resolveBestImagePath(
      discovery: discovery,
      signedUrlForStoragePath: (path) async =>
          'https://catdex.supabase.co/signed/$path?token=abc',
    );

    expect(resolved.type, CatDexResolvedImageType.network);
    expect(resolved.usesPlaceholder, isFalse);
    expect(resolved.provider, isA<NetworkImage>());
    expect(resolved.networkUrl, contains('token=abc'));
  });

  test('storage object path is not treated as local file', () async {
    final discovery = _discovery(
      originalPhotoPath: 'catdex/originals/player/discovery.jpg',
    );

    final resolved = await CatDexImageResolver.resolveBestImagePath(
      discovery: discovery,
      signedUrlForStoragePath: (path) async =>
          'https://catdex.supabase.co/signed/$path',
    );

    expect(resolved.type, CatDexResolvedImageType.network);
    expect(resolved.source, 'displayPhotoPath');
    expect(
      resolved.networkUrl,
      contains(
        'https://catdex.supabase.co/signed/catdex/originals/player/discovery.jpg',
      ),
    );
    expect(resolved.provider, isA<NetworkImage>());
  });

  test(
    'falls back from missing local display path to remote original URL',
    () async {
      final discovery = _discovery(
        displayPhotoPath: '${tempDirectory.path}/missing.jpg',
        originalPhotoPath: 'https://photos.example.com/cat.jpg',
      );

      final resolved = await CatDexImageResolver.resolveBestImagePath(
        discovery: discovery,
      );

      expect(resolved.type, CatDexResolvedImageType.network);
      expect(resolved.usesPlaceholder, isFalse);
      expect(resolved.source, 'originalPhotoPath');
      expect(resolved.provider, isA<NetworkImage>());
    },
  );

  test(
    'reinstall-style container UUID change still loads remote image',
    () async {
      final discovery = _discovery(
        displayPhotoPath:
            '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
            'catdex/originals/original_discovery.jpg',
        originalPhotoStoragePath: 'catdex/originals/player/discovery.jpg',
      );

      final resolved = await CatDexImageResolver.resolveBestImagePath(
        discovery: discovery,
        signedUrlForStoragePath: (path) async =>
            'https://catdex.supabase.co/signed/$path',
      );

      expect(resolved.type, CatDexResolvedImageType.network);
      expect(resolved.networkUrl, contains('catdex/originals/player'));
    },
  );

  test('signed URL failure produces placeholder without crashing', () async {
    final discovery = _discovery(
      originalPhotoStoragePath: 'catdex/originals/player/failure.jpg',
    );

    final resolved = await CatDexImageResolver.resolveBestImagePath(
      discovery: discovery,
      signedUrlForStoragePath: (_) async => throw StateError('offline'),
    );

    expect(resolved.type, CatDexResolvedImageType.none);
    expect(resolved.usesPlaceholder, isTrue);
  });

  test('path source helpers classify local and storage paths explicitly', () {
    expect(
      CatDexImageResolver.isAbsoluteLocalPath(
        '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
        'catdex/originals/original_discovery.jpg',
      ),
      isTrue,
    );
    expect(
      CatDexImageResolver.isSupabaseStorageObjectPath(
        '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
        'catdex/originals/original_discovery.jpg',
      ),
      isFalse,
    );
    expect(
      CatDexImageResolver.isSupabaseStorageObjectPath(
        'catdex/originals/player/discovery.jpg',
      ),
      isTrue,
    );
    expect(
      CatDexImageResolver.isSupabaseStorageObjectPath(
        'https://photos.example.com/cat.jpg',
      ),
      isFalse,
    );
  });
}

File writeImage(Directory directory, String name) {
  final file = File('${directory.path}/$name')..writeAsBytesSync(_onePixelPng);
  return file;
}

CatDiscovery _discovery({
  String? originalPhotoPath,
  String? displayPhotoPath,
  String? originalPhotoStoragePath,
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
    originalPhotoStoragePath: originalPhotoStoragePath,
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
