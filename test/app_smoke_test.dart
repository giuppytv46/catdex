import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:catdex/main.dart';
import 'package:catdex/routing/app_router.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app launches and Home page renders', (tester) async {
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
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CatDexApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoute.home.path);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Explorer'), findsOneWidget);
  });

  testWidgets('bottom navigation shows Home CatDex Cattura Carte Mappa', (
    tester,
  ) async {
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
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CatDexApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoute.catDex.path);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('CatDex'), findsWidgets);
    expect(find.text('Cattura'), findsOneWidget);
    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Mappa'), findsOneWidget);
    expect(find.text('Profilo'), findsNothing);
  });

  testWidgets('first launch requires language selection', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(
          const SharedPreferencesOnboardingRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CatDexApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('中文简体'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('中文简体'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Português (Portugal)'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Português (Portugal)'), findsOneWidget);
  });
}
