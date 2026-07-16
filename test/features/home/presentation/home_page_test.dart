import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/features/home/domain/entities/home_dashboard.dart';
import 'package:catdex/features/home/presentation/home_page.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestImageHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  testWidgets('valid local photo is displayed with FileImage', (tester) async {
    final directory = Directory.systemTemp.createTempSync('catdex_home_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final photo = File('${directory.path}/cat.png')
      ..writeAsBytesSync(_onePixelPng, flush: true);
    final discovery = _recentDiscovery(photoPath: photo.path);
    final resolved = await tester.runAsync(
      () => CatDexImageResolver.resolveBestImagePath(
        discovery: discovery.collectionEntry?.discovery,
      ),
    );

    await _pumpCard(
      tester,
      discovery: discovery,
      resolveImage: () async => resolved!,
    );

    final image = tester.widget<Image>(
      find.byKey(const Key('home_discovery_photo')),
    );
    expect(image.image, isA<FileImage>());
    expect(
      find.byKey(const Key('home_discovery_image_placeholder')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('valid network photo is displayed with NetworkImage', (
    tester,
  ) async {
    final discovery = _recentDiscovery(
      photoPath: 'https://example.test/cats/lunetta.png',
    );
    final resolved = await tester.runAsync(
      () => CatDexImageResolver.resolveBestImagePath(
        discovery: discovery.collectionEntry?.discovery,
      ),
    );

    await _pumpCard(
      tester,
      discovery: discovery,
      resolveImage: () async => resolved!,
    );

    final image = tester.widget<Image>(
      find.byKey(const Key('home_discovery_photo')),
    );
    expect(image.image, isA<NetworkImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing photo uses the paw placeholder', (tester) async {
    await _pumpCard(tester, discovery: _recentDiscovery());

    expect(
      find.byKey(const Key('home_discovery_image_placeholder')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale local path does not break the card', (tester) async {
    final discovery = _recentDiscovery(
      photoPath:
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
          'catdex/originals/original_home-test.jpg',
    );

    await _pumpCard(
      tester,
      discovery: discovery,
      resolveImage: () async => const CatDexResolvedImage.none(
        source: 'placeholder',
        candidates: [],
        placeholderReason: 'file_not_found',
        discoveryDebugJson: {},
      ),
    );

    expect(
      find.byKey(const Key('home_discovery_image_placeholder')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home_discovery_photo')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long cat name does not overflow', (tester) async {
    final discovery = _recentDiscovery(
      catName: 'Principessa Lunetta delle Stelle del Nord',
    );

    await _pumpCard(
      tester,
      discovery: discovery,
      size: const Size(320, 568),
    );

    final name = tester.widget<Text>(
      find.byKey(const Key('home_discovery_name')),
    );
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long breed name does not overflow', (tester) async {
    final discovery = _recentDiscovery(
      speciesName: 'Gatto Norvegese delle Foreste a pelo molto lungo',
    );

    await _pumpCard(
      tester,
      discovery: discovery,
      size: const Size(320, 568),
    );

    final species = tester.widget<Text>(
      find.byKey(const Key('home_discovery_species')),
    );
    expect(species.maxLines, 1);
    expect(species.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rarity and variant chips remain inside the card', (
    tester,
  ) async {
    final discovery = _recentDiscovery(
      rarityName: 'Legendary',
      variantName: 'Heterochromia speciale',
    );
    await _pumpCard(
      tester,
      discovery: discovery,
      size: const Size(320, 568),
    );

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('home_discovery_card_home-test')),
    );
    final badgesRect = tester.getRect(
      find.byKey(const Key('home_discovery_badges')),
    );
    expect(cardRect.contains(badgesRect.topLeft), isTrue);
    expect(cardRect.contains(badgesRect.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('XP remains visible inside the card', (tester) async {
    await _pumpCard(
      tester,
      discovery: _recentDiscovery(xpReward: 9999),
      size: const Size(320, 568),
    );

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('home_discovery_card_home-test')),
    );
    final xpRect = tester.getRect(find.byKey(const Key('home_discovery_xp')));
    expect(cardRect.contains(xpRect.topLeft), isTrue);
    expect(cardRect.contains(xpRect.bottomRight), isTrue);
    expect(find.text('9999 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty or placeholder location is hidden', (tester) async {
    await _pumpCard(
      tester,
      discovery: _recentDiscovery(location: 'Location placeholder'),
    );

    expect(find.byKey(const Key('home_discovery_location')), findsNothing);
    expect(find.text('Location placeholder'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small viewport produces no overflow', (tester) async {
    await _pumpCard(
      tester,
      discovery: _recentDiscovery(),
      size: const Size(320, 568),
    );

    expect(find.text('Lunetta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 1.3 produces no overflow', (tester) async {
    await _pumpCard(
      tester,
      discovery: _recentDiscovery(
        catName: 'Lunetta delle Stelle',
      ),
      size: const Size(320, 568),
      textScale: 1.3,
    );

    expect(find.byKey(const Key('home_discovery_xp')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme keeps primary text readable', (tester) async {
    await _pumpCard(
      tester,
      discovery: _recentDiscovery(),
      theme: AppTheme.dark(),
    );

    final name = tester.widget<Text>(
      find.byKey(const Key('home_discovery_name')),
    );
    final foreground = name.style!.color!;
    final background = AppTheme.dark().colorScheme.surface;
    expect(_contrastRatio(foreground, background), greaterThanOrEqualTo(4.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping dispatches the existing discovery detail action', (
    tester,
  ) async {
    var taps = 0;
    await _pumpCard(
      tester,
      discovery: _recentDiscovery(),
      onTap: () => taps += 1,
    );

    await tester.tap(
      find.byKey(const ValueKey('home_discovery_card_home-test')),
    );
    await tester.pump();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}

RecentDiscovery _recentDiscovery({
  String catName = 'Lunetta',
  String speciesName = 'Gatto domestico arancione tigrato',
  String rarityName = 'Uncommon',
  String variantName = 'Normal',
  String? location = 'Torino, Italia',
  int xpReward = 180,
  String? photoPath,
}) {
  final discovery = CatDiscovery(
    id: 'home-test',
    playerId: 'player',
    speciesId: 'domestic_tabby_cat',
    variantId: 'normal',
    rarity: CatRarity.uncommon,
    personality: CatPersonality.relaxed,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 15),
    friendshipPoints: 4,
    customName: catName,
    suggestedName: catName,
    displayPhotoPath: photoPath,
    originalPhotoPath: photoPath,
    city: 'Torino',
    country: 'Italia',
  );
  const species = CatSpecies(
    id: 'domestic_tabby_cat',
    displayName: 'Domestic tabby cat',
    scientificName: 'Felis catus',
    originCountry: 'Worldwide',
    baseRarity: CatRarity.common,
    active: true,
  );

  return RecentDiscovery(
    catName: catName,
    speciesName: speciesName,
    rarityName: rarityName,
    variantName: variantName,
    location: location,
    xpReward: xpReward,
    collectionEntry: CatDexCollectionEntry(
      species: species,
      variantName: variantName,
      variantId: 'normal',
      discovered: true,
      collectionNumber: 1,
      discovery: discovery,
      displayName: catName,
      discoveredPhotoPath: photoPath,
    ),
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required RecentDiscovery discovery,
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeData? theme,
  VoidCallback? onTap,
  Future<CatDexResolvedImage> Function()? resolveImage,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final cardHeight = textScale > 1.15 ? 336.0 : 316.0;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      locale: const Locale('it'),
      localizationsDelegates: CatDexLocalizations.localizationsDelegates,
      supportedLocales: CatDexLocalizations.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: Scaffold(
        body: Center(
          child: SizedBox(
            height: cardHeight,
            child: homeDiscoveryCardForTesting(
              discovery,
              onTap: onTap,
              resolveImage: resolveImage,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

class _TestImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestImageHttpClient();
  }
}

class _TestImageHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestImageHttpClientRequest();
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestImageHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _TestImageHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestImageHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _onePixelPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_onePixelPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  68,
  174,
  66,
  96,
  130,
];
