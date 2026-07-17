import 'dart:ui' as ui;

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_session.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_session_presenter.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session applies one cache revision and bounded decode target', () {
    final updatedAt = DateTime.utc(2026, 7, 17, 12, 30);
    final session = CardRevealSession.fromRecord(
      card: _eventRecord(updatedAt: updatedAt),
      localizedRarityLabel: 'Evento',
      mediaQuery: const MediaQueryData(
        size: Size(390, 844),
        devicePixelRatio: 3,
      ),
    );

    expect(
      session.finalImageUrl,
      contains('v=${updatedAt.millisecondsSinceEpoch}'),
    );
    expect(session.finalImageUrl.split('v='), hasLength(2));
    expect(session.finalImageProvider, isA<ResizeImage>());
    expect(session.decodeWidth, lessThanOrEqualTo(1500));
    expect(session.decodeHeight, lessThanOrEqualTo(2100));
  });

  testWidgets('root reveal survives source tile disposal and album reorder', (
    tester,
  ) async {
    final sourceVisible = ValueNotifier<bool>(true);
    final reversed = ValueNotifier<bool>(false);
    addTearDown(sourceVisible.dispose);
    addTearDown(reversed.dispose);
    late OverlayState rootOverlay;
    final presenter = CardRevealSessionPresenter(
      coordinator: CatDexCelebrationCoordinator(
        haptics: const NoOpCatDexCelebrationHaptics(),
      ),
    );
    final provider = _TestImageProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      _testApp(
        onOverlayReady: (overlay) => rootOverlay = overlay,
        child: ValueListenableBuilder<bool>(
          valueListenable: sourceVisible,
          builder: (context, visible, _) => ValueListenableBuilder<bool>(
            valueListenable: reversed,
            builder: (context, isReversed, _) => Column(
              children: [
                if (isReversed) const Text('first-after-reorder'),
                if (visible)
                  const SizedBox(
                    key: Key('source_album_tile'),
                    width: 80,
                    height: 120,
                  ),
                if (!isReversed) const Text('last-before-reorder'),
              ],
            ),
          ),
        ),
      ),
    );

    final reveal = presenter.show(
      rootOverlay: rootOverlay,
      session: _session(provider: provider, sessionId: 'survives-reorder'),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('card_reveal_session_overlay')),
      findsOneWidget,
    );
    expect(presenter.activeOverlayCount, 1);

    sourceVisible.value = false;
    reversed.value = true;
    await tester.pump();
    expect(find.byKey(const Key('source_album_tile')), findsNothing);
    expect(find.text('first-after-reorder'), findsOneWidget);
    expect(
      find.byKey(const Key('card_reveal_session_overlay')),
      findsOneWidget,
    );
    final artwork = tester.widget<Image>(
      find.byKey(const Key('card_reveal_session_artwork')),
    );
    expect(identical(artwork.image, provider), isTrue);

    await _pumpUntilVisible(
      tester,
      find.byKey(const Key('card_reveal_continue')),
    );
    await tester.tap(find.byKey(const Key('card_reveal_continue')));
    await tester.pump();
    expect(await reveal, CardRevealSessionAction.continueToAlbum);
    expect(presenter.activeOverlayCount, 0);
    expect(find.byKey(const Key('card_reveal_session_overlay')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ten sequential event reveals leave no overlay or ticker', (
    tester,
  ) async {
    late OverlayState rootOverlay;
    final presenter = CardRevealSessionPresenter(
      coordinator: CatDexCelebrationCoordinator(
        haptics: const NoOpCatDexCelebrationHaptics(),
      ),
    );
    final provider = _TestImageProvider();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      _testApp(
        onOverlayReady: (overlay) => rootOverlay = overlay,
        child: const SizedBox.expand(),
      ),
    );

    for (var index = 0; index < 10; index += 1) {
      final reveal = presenter.show(
        rootOverlay: rootOverlay,
        session: _session(
          provider: provider,
          sessionId: 'event-stress-$index',
        ),
      );
      await tester.pump();
      expect(presenter.activeOverlayCount, 1);
      expect(
        find.byKey(const Key('card_reveal_session_overlay')),
        findsOneWidget,
      );
      await _pumpUntilVisible(
        tester,
        find.byKey(const Key('card_reveal_continue')),
      );
      await tester.tap(find.byKey(const Key('card_reveal_continue')));
      await tester.pump();
      expect(await reveal, CardRevealSessionAction.continueToAlbum);
      expect(presenter.activeOverlayCount, 0);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));
    await tester.pump();
    expect(find.byKey(const Key('card_reveal_session_overlay')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required ValueChanged<OverlayState> onOverlayReady,
  required Widget child,
}) {
  return MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: CatDexLocalizations.localizationsDelegates,
    supportedLocales: CatDexLocalizations.supportedLocales,
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: appChild!,
    ),
    home: Builder(
      builder: (context) {
        onOverlayReady(Overlay.of(context, rootOverlay: true));
        return Scaffold(body: child);
      },
    ),
  );
}

CardRevealSession _session({
  required ImageProvider<Object> provider,
  required String sessionId,
}) {
  return CardRevealSession(
    sessionId: sessionId,
    cardId: 'event-card',
    discoveryId: 'discovery-1',
    cardType: CardRevealSessionType.event,
    eventKey: 'halloween_2026',
    eventVariant: 'halloween_pumpkins',
    rarity: CatRarity.rare,
    localizedRarityLabel: 'Evento',
    finalImageProvider: provider,
    finalImageUrl: 'memory://event-card',
    decodeWidth: 780,
    decodeHeight: 1092,
  );
}

CatCardRecord _eventRecord({required DateTime updatedAt}) {
  return CatCardRecord(
    cardId: 'event-card',
    discoveryId: 'discovery-1',
    ownerId: 'local-explorer',
    cardType: CatCardType.event,
    rarity: CatRarity.rare,
    finalCardUrl: 'https://renderer.example/generated/final-card.png',
    templateKey: 'halloween_pumpkins',
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'request-1',
    idempotencyKey: 'event:discovery-1',
    createdAt: updatedAt,
    updatedAt: updatedAt,
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    eventArtworkVariantId: 'halloween_pumpkins',
  );
}

class _TestImageProvider extends ImageProvider<_TestImageProvider> {
  _TestImageProvider() : _image = _createImage();

  final ui.Image _image;

  @override
  Future<_TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _TestImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(ImageInfo(image: _image)),
    );
  }

  void dispose() => _image.dispose();

  static ui.Image _createImage() {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    return recorder.endRecording().toImageSync(1, 1);
  }
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var index = 0; index < 20; index += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
