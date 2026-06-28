import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:catdex/main.dart';
import 'package:catdex/routing/app_router.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app launches and Home page renders', (tester) async {
    SharedPreferences.setMockInitialValues({
      'catdex.onboarding.completed': true,
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
}
