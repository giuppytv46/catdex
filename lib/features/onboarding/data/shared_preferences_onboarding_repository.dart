import 'package:catdex/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  const SharedPreferencesOnboardingRepository();

  static const _completedKey = 'catdex.onboarding.completed';

  @override
  Future<bool> isOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_completedKey) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted({required bool completed}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey, completed);
  }
}
