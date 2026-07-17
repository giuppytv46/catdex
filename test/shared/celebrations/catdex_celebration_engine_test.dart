import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_feedback.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_overlay.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_painters.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rarity intensity grows from common to legendary', () {
    final common = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.common,
    );
    final rare = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.rare,
    );
    final legendary = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.legendary,
    );

    expect(rare.particleCount, greaterThan(common.particleCount));
    expect(rare.fireworkCount, lessThanOrEqualTo(2));
    expect(legendary.particleCount, greaterThan(rare.particleCount));
    expect(legendary.particleCount, 32);
    expect(legendary.fireworkCount, 2);
    expect(legendary.shockwaveCount, 2);
    expect(legendary.extraHapticPulse, isTrue);
  });

  test('Halloween Free and Premium use their intended palettes', () {
    final free = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.halloween,
    );
    final premium = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.halloweenPremium,
    );

    expect(free.colors, contains(const Color(0xFFF97316)));
    expect(premium.colors, contains(const Color(0xFFF97316)));
    expect(premium.colors, contains(const Color(0xFFA855F7)));
    expect(free.particleCount, 36);
    expect(premium.particleCount, 36);
    expect(free.fireworkCount, 2);
    expect(premium.fireworkCount, 2);
    expect(free.shockwaveCount, 1);
    expect(premium.shockwaveCount, 2);
    expect(premium.extraHapticPulse, isTrue);
  });

  test('procedural fireworks and particles use deterministic seeds', () {
    final theme = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.epic,
    );
    final first = CatDexCelebrationScene.generate(theme: theme, seed: 20260717);
    final second = CatDexCelebrationScene.generate(
      theme: theme,
      seed: 20260717,
    );

    expect(first.totalParticleCount, theme.particleCount);
    expect(first.particles, isNotEmpty);
    expect(first.fireworks.length, theme.fireworkCount);
    expect(first.particles.first.angle, second.particles.first.angle);
    expect(first.particles.first.distance, second.particles.first.distance);
    expect(first.fireworks.last.delay, second.fireworks.last.delay);
    expect(
      first.fireworks.last.sparkAngles,
      orderedEquals(second.fireworks.last.sparkAngles),
    );
  });

  test('Reduce Motion removes shake and reduces fireworks', () {
    final intense = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.legendary,
    );
    final reduced = CatDexCelebrationTheme.forPalette(
      CatDexCelebrationPalette.legendary,
      reduceMotion: true,
    );

    expect(reduced.shakeAmplitude, 0);
    expect(reduced.fireworkCount, 0);
    expect(reduced.particleCount, lessThanOrEqualTo(8));
    expect(reduced.particleCount, lessThan(intense.particleCount));
    expect(reduced.longTrails, isFalse);
    expect(reduced.duration, lessThan(intense.duration));
  });

  test('type budgets cap particles and corner bursts defensively', () {
    const oversized = CatDexCelebrationTheme(
      palette: CatDexCelebrationPalette.halloweenPremium,
      colors: [Colors.orange, Colors.purple],
      particleCount: 200,
      fireworkCount: 12,
      shockwaveCount: 8,
      shakeAmplitude: 4,
      duration: Duration(seconds: 2),
    );

    final discovery = oversized.boundedForType(
      CatDexCelebrationType.discoveryComplete,
    );
    final add = oversized.boundedForType(
      CatDexCelebrationType.addedToCatDex,
    );
    final normal = oversized.boundedForType(
      CatDexCelebrationType.normalCardGenerated,
    );
    final event = oversized.boundedForType(
      CatDexCelebrationType.eventCardGenerated,
    );

    expect(discovery.particleCount, 24);
    expect(add.particleCount, 28);
    expect(normal.particleCount, 32);
    expect(event.particleCount, 36);
    expect(event.fireworkCount, 2);
    expect(event.shockwaveCount, 2);
    expect(
      CatDexCelebrationScene.generate(
        theme: event,
        seed: 7,
      ).totalParticleCount,
      36,
    );
  });

  testWidgets('overlay paints impact, fireworks and expected haptics', (
    tester,
  ) async {
    final haptics = _RecordingHaptics();
    var completed = false;
    await tester.pumpWidget(
      _overlayApp(
        CatDexCelebrationOverlay(
          request: _request(CatDexCelebrationPalette.common),
          haptics: haptics,
          onCompleted: () => completed = true,
        ),
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 1250));

    expect(find.byKey(const Key('catdex_celebration_painter')), findsOne);
    expect(
      haptics.events,
      containsAllInOrder([
        CatDexCelebrationHapticEvent.preparation,
        CatDexCelebrationHapticEvent.impact,
        CatDexCelebrationHapticEvent.reveal,
      ]),
    );
    expect(completed, isFalse);

    await _pumpFor(tester, const Duration(milliseconds: 1100));
    expect(completed, isTrue);
  });

  testWidgets('Reduce Motion keeps feedback but uses reduced profile', (
    tester,
  ) async {
    final haptics = _RecordingHaptics();
    await tester.pumpWidget(
      _overlayApp(
        CatDexCelebrationOverlay(
          request: _request(
            CatDexCelebrationPalette.legendary,
            reduceMotion: true,
          ),
          haptics: haptics,
          onCompleted: () {},
        ),
        disableAnimations: true,
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 360));

    final transform = tester.widget<Transform>(
      find.byKey(const Key('catdex_celebration_foreground')),
    );
    expect(transform.transform.getTranslation().x, 0);
    expect(transform.transform.getTranslation().y, 0);
    expect(find.text('CARTA GENERATA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coordinator queues full-screen celebrations without overlap', (
    tester,
  ) async {
    final coordinator = CatDexCelebrationCoordinator(
      haptics: const NoOpCatDexCelebrationHaptics(),
    );
    late BuildContext routeContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            routeContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final first = coordinator.celebrate(
      routeContext,
      _request(CatDexCelebrationPalette.common, title: 'Prima'),
    );
    final second = coordinator.celebrate(
      routeContext,
      _request(CatDexCelebrationPalette.uncommon, title: 'Seconda'),
    );
    expect(coordinator.isBusy, isTrue);
    await tester.pump();
    await _pumpFor(tester, const Duration(milliseconds: 700));
    expect(find.text('PRIMA'), findsOneWidget);
    expect(find.text('SECONDA'), findsNothing);

    await _pumpFor(tester, const Duration(milliseconds: 1700));
    await first;
    await _pumpFor(tester, const Duration(milliseconds: 700));
    expect(find.text('SECONDA'), findsOneWidget);
    expect(find.text('PRIMA'), findsNothing);

    await _pumpFor(tester, const Duration(milliseconds: 1700));
    await second;
    expect(coordinator.isBusy, isFalse);
  });

  testWidgets('overlay disposal leaves no ticker or exception', (tester) async {
    await tester.pumpWidget(
      _overlayApp(
        CatDexCelebrationOverlay(
          request: _request(CatDexCelebrationPalette.epic),
          haptics: const NoOpCatDexCelebrationHaptics(),
          onCompleted: () {},
        ),
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 280));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.expand()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('catdex_celebration_overlay')), findsNothing);
  });

  testWidgets('celebration stays in bounds on small scaled screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _overlayApp(
        CatDexCelebrationOverlay(
          request: _request(
            CatDexCelebrationPalette.halloweenPremium,
            title: 'Evento Premium Halloween',
          ),
          haptics: const NoOpCatDexCelebrationHaptics(),
          onCompleted: () {},
        ),
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 1300));

    expect(tester.takeException(), isNull);
    expect(find.text('EVENTO PREMIUM HALLOWEEN'), findsOneWidget);
  });
}

CatDexCelebrationRequest _request(
  CatDexCelebrationPalette palette, {
  String title = 'Carta generata',
  bool reduceMotion = false,
}) {
  return CatDexCelebrationRequest(
    type: CatDexCelebrationType.normalCardGenerated,
    theme: CatDexCelebrationTheme.forPalette(
      palette,
      reduceMotion: reduceMotion,
    ),
    title: title,
    semanticLabel: title,
    seed: 42,
    reduceMotion: reduceMotion,
  );
}

Widget _overlayApp(
  Widget overlay, {
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
        body: Stack(children: [const SizedBox.expand(), overlay]),
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

class _RecordingHaptics implements CatDexCelebrationHaptics {
  final List<CatDexCelebrationHapticEvent> events = [];

  @override
  void cancel() {}

  @override
  Future<void> trigger(CatDexCelebrationHapticEvent event) async {
    events.add(event);
  }
}
