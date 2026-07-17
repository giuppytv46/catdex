import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:catdex/features/missions/presentation/daily_mission_widgets.dart';
import 'package:catdex/features/missions/presentation/daily_missions_page.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mission_test_fakes.dart';

void main() {
  testWidgets('Home mission section shows three missions', (tester) async {
    await _pump(
      tester,
      child: DailyMissionsHomeSection(onSeeAll: () {}),
    );

    expect(
      find.byKey(const ValueKey('home-daily-missions-section')),
      findsOneWidget,
    );
    expect(find.byType(CompactDailyMissionRow), findsNWidgets(3));
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('mission page displays progress for every mission', (
    tester,
  ) async {
    await _pump(tester, child: const DailyMissionsPage());

    expect(
      find.byKey(const ValueKey('daily-missions-page-list')),
      findsOneWidget,
    );
    expect(find.textContaining('0/1'), findsNWidgets(3));
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });

  testWidgets('completed mission displays claim CTA', (tester) async {
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'completed',
          type: DailyMissionType.discoverCats,
          status: DailyMissionStatus.completed,
          current: 1,
        ),
        testMission(id: 'card', type: DailyMissionType.generateNormalCard),
        testMission(id: 'map', type: DailyMissionType.openMap),
      ],
    );
    await _pump(tester, child: const DailyMissionsPage(), ledger: ledger);

    expect(
      find.byKey(const ValueKey('daily-mission-claim-completed')),
      findsOneWidget,
    );
    expect(find.text('Riscatta'), findsOneWidget);
  });

  testWidgets('claimed mission displays claimed state without claim button', (
    tester,
  ) async {
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'claimed',
          type: DailyMissionType.discoverCats,
          status: DailyMissionStatus.claimed,
          current: 1,
        ),
        testMission(id: 'card', type: DailyMissionType.generateNormalCard),
        testMission(id: 'map', type: DailyMissionType.openMap),
      ],
    );
    await _pump(tester, child: const DailyMissionsPage(), ledger: ledger);

    expect(find.text('Riscattata'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('daily-mission-claim-claimed')),
      findsNothing,
    );
  });

  testWidgets('mission page has no overflow on a small viewport', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const DailyMissionsPage(),
      size: const Size(320, 568),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Home mission section supports text scale 1.3', (tester) async {
    await _pump(
      tester,
      child: SingleChildScrollView(
        child: DailyMissionsHomeSection(onSeeAll: () {}),
      ),
      size: const Size(320, 568),
      textScale: 1.3,
    );

    expect(find.text('Missioni di oggi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  DailyMissionLedger? ledger,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final seeded = ledger ?? testLedger();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dailyMissionControllerProvider.overrideWith(
          () => _SeededDailyMissionController(seeded),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('it'),
        localizationsDelegates: CatDexLocalizations.localizationsDelegates,
        supportedLocales: CatDexLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

class _SeededDailyMissionController extends DailyMissionController {
  _SeededDailyMissionController(this.ledger);

  final DailyMissionLedger ledger;

  @override
  Future<DailyMissionLedger> build() async => ledger;
}
