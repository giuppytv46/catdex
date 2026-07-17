import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/achievements/application/achievement_controller.dart';
import 'package:catdex/features/achievements/data/in_memory_achievement_repository.dart';
import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/presentation/achievement_badge.dart';
import 'package:catdex/features/achievements/presentation/achievement_profile_section.dart';
import 'package:catdex/features/achievements/presentation/achievements_page.dart';
import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('achievement page shows category filters', (tester) async {
    await _pump(tester, const AchievementsPage());

    expect(find.text('Traguardi'), findsOneWidget);
    expect(find.text('Tutti'), findsOneWidget);
    expect(find.text('Scoperte'), findsWidgets);
    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Rarità'), findsOneWidget);
    expect(find.text('Esplorazione'), findsOneWidget);
    expect(find.text('Missioni'), findsOneWidget);
    expect(find.text('Eventi'), findsOneWidget);
    expect(find.text('Progressione'), findsOneWidget);
  });

  testWidgets('locked achievement shows real progress', (tester) async {
    final ledger = _ledger(
      progress: const {'discovery_10': 7},
    );
    await _pump(tester, const AchievementsPage(), ledger: ledger);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('achievement-discovery_10')),
      220,
      scrollable: _pageScrollable(),
    );
    expect(find.text('7 / 10'), findsOneWidget);
    expect(find.text('Occhio felino'), findsOneWidget);
  });

  testWidgets('unlocked achievement shows date and XP reward', (tester) async {
    final ledger = _ledger(unlocked: const ['first_discovery']);
    await _pump(tester, const AchievementsPage(), ledger: ledger);

    expect(find.text('Prima scoperta'), findsOneWidget);
    expect(find.text('+50 XP'), findsOneWidget);
    expect(find.text('17/07/2026'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('Premium achievement is visible without forced paywall', (
    tester,
  ) async {
    await _pump(tester, const AchievementsPage());
    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey('achievement-halloween_premium_collection'),
      ),
      220,
      scrollable: _pageScrollable(),
    );

    expect(find.text('Maestro di Halloween'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.textContaining('Sblocca CatDex Premium'), findsNothing);
  });

  testWidgets('small viewport and text scale 1.3 do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      const AchievementsPage(),
      textScaler: const TextScaler.linear(1.3),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile shows the three latest unlocked badges', (tester) async {
    final ledger = _ledger(
      unlocked: const [
        'first_discovery',
        'discovery_5',
        'first_normal_card',
        'first_uncommon',
      ],
    );
    await _pump(tester, const AchievementProfileSection(), ledger: ledger);

    expect(find.byType(AchievementBadge), findsNWidgets(3));
    expect(find.text('4 / 27'), findsOneWidget);
    expect(find.text('Vedi tutti i traguardi'), findsOneWidget);
  });

  testWidgets('Profile empty state shows the closest achievement', (
    tester,
  ) async {
    final ledger = _ledger(progress: const {'discovery_5': 4});
    await _pump(tester, const AchievementProfileSection(), ledger: ledger);

    expect(find.byType(AchievementBadge), findsOneWidget);
    expect(find.text('Piccolo esploratore'), findsOneWidget);
  });
}

Finder _pageScrollable() {
  return find
      .descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      )
      .first;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  AchievementLedger? ledger,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final repository = InMemoryAchievementRepository();
  await repository.save(ledger ?? _ledger());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        achievementRepositoryProvider.overrideWithValue(repository),
        activeCatDexSessionProvider.overrideWithValue(
          const ActiveCatDexSession.guest(playerId: 'local-explorer'),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('it'),
        supportedLocales: CatDexLocalizations.supportedLocales,
        localizationsDelegates: CatDexLocalizations.localizationsDelegates,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: widget!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AchievementLedger _ledger({
  List<String> unlocked = const [],
  Map<String, int> progress = const {},
}) {
  final unlockedSet = unlocked.toSet();
  final now = DateTime.utc(2026, 7, 17);
  return AchievementLedger(
    playerId: 'local-explorer',
    achievements: {
      for (final definition in AchievementCatalogV1.definitions)
        definition.achievementId: PlayerAchievement.initial(definition)
            .copyWith(
              currentValue: unlockedSet.contains(definition.achievementId)
                  ? definition.targetValue
                  : progress[definition.achievementId] ?? 0,
              status: unlockedSet.contains(definition.achievementId)
                  ? PlayerAchievementStatus.unlocked
                  : (progress[definition.achievementId] ?? 0) > 0
                  ? PlayerAchievementStatus.inProgress
                  : PlayerAchievementStatus.locked,
              unlockedAt: unlockedSet.contains(definition.achievementId)
                  ? now.add(Duration(seconds: definition.sortOrder))
                  : null,
              lastEvaluatedAt: now,
            ),
    },
    rewardTransactions: const {},
    reconciliationVersion: AchievementLedger.currentReconciliationVersion,
  );
}
