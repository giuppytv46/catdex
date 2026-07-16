import 'package:catdex/features/map/application/catdex_map_controller.dart';
import 'package:catdex/features/map/presentation/catdex_map_page.dart';
import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:catdex/features/profile/presentation/profile_page.dart';
import 'package:catdex/main.dart';
import 'package:catdex/routing/app_router.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('bottom navigation contains Home CatDex Capture Cards and Map', (
    tester,
  ) async {
    final container = await _pumpAppAtHome(tester);

    for (final path in [
      AppRoute.home.path,
      AppRoute.catDex.path,
      AppRoute.capture.path,
      AppRoute.cards.path,
      AppRoute.map.path,
    ]) {
      expect(find.byKey(ValueKey(path)), findsOneWidget);
    }
    expect(find.byKey(ValueKey(AppRoute.profile.path)), findsNothing);
    expect(find.text('Mappa'), findsOneWidget);

    container.dispose();
  });

  testWidgets('Profile remains accessible from the Home app bar', (
    tester,
  ) async {
    final container = await _pumpAppAtHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-profile-button')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Profilo'), findsWidgets);

    container.dispose();
  });

  testWidgets('Map tab opens the map branch', (tester) async {
    final container = await _pumpAppAtHome(tester);

    await tester.tap(find.byKey(ValueKey(AppRoute.map.path)));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      container
          .read(appRouterProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path,
      AppRoute.map.path,
    );
    expect(find.byType(CatDexMapPage), findsOneWidget);

    container.dispose();
  });

  testWidgets('switching tabs preserves the existing map page state', (
    tester,
  ) async {
    final container = await _pumpAppAtHome(tester);

    await tester.tap(find.byKey(ValueKey(AppRoute.map.path)));
    await tester.pump(const Duration(milliseconds: 350));
    final firstMapState = tester.state(find.byType(CatDexMapPage));
    container
        .read(selectedMapDiscoveryIdProvider.notifier)
        .select('preserved-id');

    await tester.tap(find.byKey(ValueKey(AppRoute.home.path)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(ValueKey(AppRoute.map.path)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.state(find.byType(CatDexMapPage)), same(firstMapState));
    expect(container.read(selectedMapDiscoveryIdProvider), 'preserved-id');

    container.dispose();
  });
}

Future<ProviderContainer> _pumpAppAtHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'catdex.onboarding.completed': true,
    'catdex_selected_locale': 'it',
  });
  final container = ProviderContainer(
    overrides: [
      onboardingRepositoryProvider.overrideWithValue(
        const SharedPreferencesOnboardingRepository(),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CatDexApp()),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go(AppRoute.home.path);
  await tester.pumpAndSettle();
  return container;
}
