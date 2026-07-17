import 'dart:async';

import 'package:catdex/features/ads/application/admob_service.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'catdex_monetization_is_premium': false,
      'catdex_monetization_daily_analysis_count': 3,
      'catdex_monetization_daily_card_generation_count': 3,
      'catdex_monetization_extra_analysis_credits': 0,
      'catdex_monetization_extra_card_generation_credits': 0,
      'catdex_monetization_last_limit_reset_date': _todayKey(),
    });
  });

  test(
    'rewarded fallback credit persists and emits one logical refresh',
    () async {
      var refreshCount = 0;
      final service = MonetizationService(() => refreshCount += 1);

      await service.addAnalysisCredits(1);
      await service.addAnalysisCredits(0);

      final status = await service.getStatus();
      expect(status.extraAnalysisCredits, 1);
      expect(refreshCount, 1);
    },
  );

  testWidgets(
    'monetization, rewarded and ad refreshes are deferred during build',
    (tester) async {
      final key = GlobalKey<_BuildPhaseRefreshHarnessState>();
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: _BuildPhaseRefreshHarness(key: key)),
        ),
      );

      key.currentState!.triggerRefreshesDuringTickerModeBuild();
      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        key.currentContext!,
        listen: false,
      );
      expect(container.read(monetizationRefreshProvider), 1);
      expect(container.read(rewardedAdStateRefreshProvider), 1);
      expect(container.read(adVisibilityRefreshProvider), 1);
      expect(errors, isEmpty);
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('TickerMode and route transition stay safe during refresh', (
    tester,
  ) async {
    final observer = _RouteObserver();
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const _RouteRefreshHome(),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Credit and close'));
    await tester.pumpAndSettle();

    expect(observer.popCount, 1);
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ad visibility refresh after celebration completion is build-safe',
    (tester) async {
      final key = GlobalKey<_CelebrationAdRefreshHarnessState>();
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: _CelebrationAdRefreshHarness(key: key)),
        ),
      );

      final coordinator = CatDexCelebrationCoordinator.instance;
      final lease = coordinator.acquire(
        CatDexCelebrationType.normalCardGenerated,
      );
      await tester.pump();
      lease.release();
      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        key.currentContext!,
        listen: false,
      );
      expect(container.read(adVisibilityRefreshProvider), 1);
      expect(errors, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deferred provider callback is safe after container disposal', (
    tester,
  ) async {
    final container = ProviderContainer();
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      _DisposeContainerBeforeDeferredRefresh(container: container),
    );
    await tester.pumpWidget(const SizedBox.shrink());

    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

class _BuildPhaseRefreshHarness extends ConsumerStatefulWidget {
  const _BuildPhaseRefreshHarness({super.key});

  @override
  ConsumerState<_BuildPhaseRefreshHarness> createState() =>
      _BuildPhaseRefreshHarnessState();
}

class _BuildPhaseRefreshHarnessState
    extends ConsumerState<_BuildPhaseRefreshHarness> {
  bool _tickerEnabled = true;
  bool _triggerRefreshes = false;

  void triggerRefreshesDuringTickerModeBuild() {
    setState(() {
      _tickerEnabled = !_tickerEnabled;
      _triggerRefreshes = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_triggerRefreshes) {
      _triggerRefreshes = false;
      for (var index = 0; index < 3; index += 1) {
        ref.read(monetizationRefreshProvider.notifier).refresh();
        ref.read(rewardedAdStateRefreshProvider.notifier).refresh();
        ref.read(adVisibilityRefreshProvider.notifier).refresh();
      }
    }
    return TickerMode(
      enabled: _tickerEnabled,
      child: const Scaffold(body: Text('Ticker child')),
    );
  }
}

class _RouteRefreshHome extends ConsumerWidget {
  const _RouteRefreshHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: TextButton(
        onPressed: () {
          unawaited(
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const _CreditRoute(),
              ),
            ),
          );
        },
        child: const Text('Open'),
      ),
    );
  }
}

class _CelebrationAdRefreshHarness extends ConsumerStatefulWidget {
  const _CelebrationAdRefreshHarness({super.key});

  @override
  ConsumerState<_CelebrationAdRefreshHarness> createState() =>
      _CelebrationAdRefreshHarnessState();
}

class _CelebrationAdRefreshHarnessState
    extends ConsumerState<_CelebrationAdRefreshHarness> {
  late final int _initialVersion;
  bool _refreshedAfterCelebration = false;

  @override
  void initState() {
    super.initState();
    _initialVersion =
        CatDexCelebrationCoordinator.instance.activityListenable.value;
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = CatDexCelebrationCoordinator.instance;
    return ValueListenableBuilder<int>(
      valueListenable: coordinator.activityListenable,
      builder: (context, version, _) {
        if (!_refreshedAfterCelebration &&
            version != _initialVersion &&
            !coordinator.isBusy) {
          _refreshedAfterCelebration = true;
          ref.read(adVisibilityRefreshProvider.notifier).refresh();
        }
        return const Scaffold(body: Text('Ad visibility harness'));
      },
    );
  }
}

class _CreditRoute extends ConsumerWidget {
  const _CreditRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: TextButton(
        onPressed: () async {
          await ref.read(monetizationServiceProvider).addAnalysisCredits(1);
          if (context.mounted) Navigator.of(context).pop();
        },
        child: const Text('Credit and close'),
      ),
    );
  }
}

class _RouteObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount += 1;
    super.didPop(route, previousRoute);
  }
}

class _DisposeContainerBeforeDeferredRefresh extends StatelessWidget {
  const _DisposeContainerBeforeDeferredRefresh({required this.container});

  final ProviderContainer container;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => container.dispose());
    return UncontrolledProviderScope(
      container: container,
      child: const _RefreshOnceDuringBuild(),
    );
  }
}

class _RefreshOnceDuringBuild extends ConsumerWidget {
  const _RefreshOnceDuringBuild();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(monetizationRefreshProvider.notifier).refresh();
    return const SizedBox.shrink();
  }
}

String _todayKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
