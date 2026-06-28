abstract interface class OnboardingRepository {
  Future<bool> isOnboardingCompleted();

  Future<void> setOnboardingCompleted({required bool completed});
}
