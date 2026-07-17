import 'dart:async';

import 'package:catdex/features/cards/presentation/reveal/card_reveal_controller.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_surface.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('controller exposes the complete reveal state model', () {
    final controller = CardRevealController(kind: CardRevealKind.premiumEvent);

    expect(controller.state, CardRevealState.idle);
    expect(controller.kind, CardRevealKind.premiumEvent);
    controller.showLoading();
    expect(controller.state, CardRevealState.loading);
    controller.startReveal();
    expect(controller.state, CardRevealState.revealing);
    controller.markRevealed();
    expect(controller.state, CardRevealState.revealed);
    controller.complete();
    expect(controller.state, CardRevealState.completed);
    controller.showError();
    expect(controller.state, CardRevealState.error);

    controller.dispose();
  });

  testWidgets('generated artwork uses a timed 3D reveal', (tester) async {
    final controller = CardRevealController();
    final key = GlobalKey<_RevealHarnessState>();
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          key: key,
          controller: controller,
          generating: true,
        ),
      ),
    );
    await tester.pump();
    expect(controller.state, CardRevealState.loading);

    key.currentState!.showArtwork();
    await tester.pump();
    expect(controller.state, CardRevealState.revealing);
    expect(find.byKey(const Key('card_reveal_3d_flip')), findsOneWidget);
    expect(find.byKey(const Key('card_reveal_particles')), findsNothing);

    await _pumpFor(tester, const Duration(milliseconds: 2500));
    expect(controller.state, CardRevealState.revealing);
    await _pumpFor(tester, const Duration(milliseconds: 220));
    expect(controller.state, CardRevealState.revealed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.state, CardRevealState.completed);

    controller.dispose();
  });

  testWidgets('existing card opens with subtle zoom and no full reveal', (
    tester,
  ) async {
    final controller = CardRevealController();
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          controller: controller,
          generating: false,
          artworkVisible: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('card_existing_open_fade')), findsOneWidget);
    expect(find.byKey(const Key('card_reveal_3d_flip')), findsNothing);
    expect(find.byKey(const Key('card_reveal_particles')), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.state, CardRevealState.completed);

    controller.dispose();
  });

  testWidgets('generated image is ready before the 3D flip starts', (
    tester,
  ) async {
    final controller = CardRevealController();
    final preload = Completer<void>();
    final key = GlobalKey<_RevealHarnessState>();
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          key: key,
          controller: controller,
          generating: true,
          prepareArtwork: (_) => preload.future,
        ),
      ),
    );
    await tester.pump();

    key.currentState!.showArtwork();
    await tester.pump();
    expect(
      find.byKey(const Key('card_reveal_preloading_artwork')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('card_reveal_3d_flip')), findsNothing);
    expect(controller.state, CardRevealState.loading);

    preload.complete();
    await tester.pump();
    expect(controller.state, CardRevealState.revealing);
    expect(find.byKey(const Key('card_reveal_3d_flip')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('regenerating an existing card keeps artwork under the glow', (
    tester,
  ) async {
    final controller = CardRevealController();
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          controller: controller,
          generating: true,
          artworkVisible: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('test_card_artwork')), findsOneWidget);
    expect(find.byKey(const Key('card_reveal_loading_glow')), findsOneWidget);
    expect(
      find.byKey(const Key('card_generation_energy_buildup')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('card_existing_open_fade')), findsNothing);
    expect(controller.state, CardRevealState.loading);

    controller.dispose();
  });

  testWidgets('Reduce Motion replaces flip and particles with a fade', (
    tester,
  ) async {
    final controller = CardRevealController();
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          controller: controller,
          generating: false,
          artworkVisible: true,
          forceNewReveal: true,
        ),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('card_reveal_reduce_motion_fade')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('card_reveal_3d_flip')), findsNothing);
    expect(find.byKey(const Key('card_reveal_particles')), findsNothing);
    await _pumpFor(tester, const Duration(milliseconds: 900));
    expect(
      controller.state,
      anyOf(CardRevealState.revealed, CardRevealState.completed),
    );
    await tester.pump(const Duration(milliseconds: 60));
    expect(controller.state, CardRevealState.completed);

    controller.dispose();
  });

  testWidgets('mission and level rewards run after reveal without overlap', (
    tester,
  ) async {
    final controller = CardRevealController();
    const cue = CardRevealRewardCue(
      id: 'mission-1',
      missionCompleted: true,
      xp: 50,
      newLevel: 8,
    );
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          controller: controller,
          generating: false,
          artworkVisible: true,
          forceNewReveal: true,
          rewardCue: cue,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Missione completata'), findsNothing);
    expect(find.text('LEVEL UP'), findsNothing);

    await _pumpFor(tester, const Duration(milliseconds: 2700));
    expect(controller.state, CardRevealState.revealed);
    await _pumpFor(tester, const Duration(milliseconds: 200));
    expect(find.text('Missione completata'), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);
    expect(find.text('LEVEL UP'), findsNothing);

    await _pumpFor(tester, const Duration(milliseconds: 1000));
    expect(find.text('Missione completata'), findsNothing);
    expect(find.text('LEVEL UP'), findsOneWidget);
    expect(find.text('Livello 8'), findsOneWidget);

    await _pumpFor(tester, const Duration(milliseconds: 1500));
    expect(find.text('Missione completata'), findsNothing);
    expect(find.text('LEVEL UP'), findsNothing);
    expect(controller.state, CardRevealState.completed);

    controller.dispose();
  });

  testWidgets('event XP precedes mission and level-up celebrations', (
    tester,
  ) async {
    final controller = CardRevealController(kind: CardRevealKind.event);
    const cue = CardRevealRewardCue(
      id: 'event-card-1|mission-1',
      earnedXp: 100,
      missionCompleted: true,
      xp: 50,
      newLevel: 2,
    );
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          controller: controller,
          generating: false,
          artworkVisible: true,
          forceNewReveal: true,
          rewardCue: cue,
        ),
      ),
    );
    await tester.pump();

    await _pumpFor(tester, const Duration(milliseconds: 2900));
    expect(find.byKey(const Key('card_reveal_earned_xp')), findsOneWidget);
    expect(find.text('+100 XP'), findsOneWidget);
    expect(find.text('Missione completata'), findsNothing);
    expect(find.text('LEVEL UP'), findsNothing);

    await _pumpFor(tester, const Duration(milliseconds: 850));
    expect(find.byKey(const Key('card_reveal_earned_xp')), findsNothing);
    expect(find.text('Missione completata'), findsOneWidget);
    expect(find.text('LEVEL UP'), findsNothing);

    await _pumpFor(tester, const Duration(milliseconds: 1050));
    expect(find.text('Missione completata'), findsNothing);
    expect(find.text('LEVEL UP'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('small scaled viewport keeps reward feedback in bounds', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = CardRevealController();

    await tester.pumpWidget(
      _app(
        _RevealHarness(
          controller: controller,
          generating: false,
          artworkVisible: true,
          forceNewReveal: true,
          rewardCue: const CardRevealRewardCue(
            id: 'small-screen-xp',
            earnedXp: 100,
          ),
        ),
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 2900));

    expect(tester.takeException(), isNull);
    expect(find.text('+100 XP'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('error state does not start a reveal', (tester) async {
    final controller = CardRevealController();
    await tester.pumpWidget(
      _app(
        _RevealHarness(
          controller: controller,
          generating: false,
          hasError: true,
        ),
      ),
    );
    await tester.pump();

    expect(controller.state, CardRevealState.error);
    expect(find.byKey(const Key('card_reveal_3d_flip')), findsNothing);
    expect(find.text('Errore'), findsOneWidget);

    controller.dispose();
  });

  test('rarity and event effects map deterministically', () {
    expect(
      cardRevealEffectFor(rarity: CatRarity.common),
      CardRevealEffect.common,
    );
    expect(
      cardRevealEffectFor(rarity: CatRarity.epic),
      CardRevealEffect.epic,
    );
    expect(
      cardRevealEffectFor(rarity: CatRarity.legendary),
      CardRevealEffect.legendary,
    );
    expect(
      cardRevealEffectFor(rarity: CatRarity.common, event: true),
      CardRevealEffect.event,
    );
    expect(
      cardRevealEffectFor(
        rarity: CatRarity.common,
        event: true,
        premiumEvent: true,
      ),
      CardRevealEffect.premiumEvent,
    );
  });
}

Widget _app(
  Widget child, {
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        disableAnimations: disableAnimations,
        textScaler: textScaler,
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: 240, height: 336, child: child),
        ),
      ),
    ),
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 20);
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    final remaining = duration - elapsed;
    final next = remaining < step ? remaining : step;
    await tester.pump(next);
    elapsed += next;
  }
}

class _RevealHarness extends StatefulWidget {
  const _RevealHarness({
    required this.controller,
    required this.generating,
    this.artworkVisible = false,
    this.forceNewReveal = false,
    this.hasError = false,
    this.rewardCue,
    this.prepareArtwork,
    super.key,
  });

  final CardRevealController controller;
  final bool generating;
  final bool artworkVisible;
  final bool forceNewReveal;
  final bool hasError;
  final CardRevealRewardCue? rewardCue;
  final CardArtworkPreloader? prepareArtwork;

  @override
  State<_RevealHarness> createState() => _RevealHarnessState();
}

class _RevealHarnessState extends State<_RevealHarness> {
  final CatDexCelebrationCoordinator _celebrationCoordinator =
      CatDexCelebrationCoordinator(
        haptics: const NoOpCatDexCelebrationHaptics(),
      );
  late bool _generating = widget.generating;
  late bool _artworkVisible = widget.artworkVisible;

  void showArtwork() {
    setState(() {
      _generating = false;
      _artworkVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CardRevealSurface(
      controller: widget.controller,
      celebrationCoordinator: _celebrationCoordinator,
      effect: CardRevealEffect.legendary,
      isGenerating: _generating,
      hasError: widget.hasError,
      forceNewReveal: widget.forceNewReveal,
      rewardCue: widget.rewardCue,
      prepareArtwork: widget.prepareArtwork,
      revealKey: _artworkVisible ? 'artwork-v1' : null,
      fallback: ColoredBox(
        color: const Color(0xFF111827),
        child: Center(child: Text(widget.hasError ? 'Errore' : 'Loading')),
      ),
      artwork: _artworkVisible
          ? const ColoredBox(
              key: Key('test_card_artwork'),
              color: Color(0xFF7C3AED),
            )
          : null,
    );
  }
}
