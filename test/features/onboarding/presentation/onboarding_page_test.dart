import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:catdex/features/onboarding/presentation/onboarding_page.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Onboarding page builds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(
            _FakeOnboardingRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: CatDexLocalizations.localizationsDelegates,
          supportedLocales: CatDexLocalizations.supportedLocales,
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingPage), findsOneWidget);
  });
}

class _FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<bool> isOnboardingCompleted() async {
    return false;
  }

  @override
  Future<void> setOnboardingCompleted({required bool completed}) async {}
}
