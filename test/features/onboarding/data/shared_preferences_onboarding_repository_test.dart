import 'package:catdex/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesOnboardingRepository', () {
    test('persists onboarding completion locally', () async {
      SharedPreferences.setMockInitialValues({});
      const repository = SharedPreferencesOnboardingRepository();

      expect(await repository.isOnboardingCompleted(), isFalse);

      await repository.setOnboardingCompleted(completed: true);

      expect(await repository.isOnboardingCompleted(), isTrue);
    });
  });
}
