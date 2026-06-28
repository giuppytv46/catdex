import 'package:catdex/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((_) {
  throw UnimplementedError('OnboardingRepository must be provided.');
});

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(
      OnboardingController.new,
    );

class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(onboardingRepositoryProvider).isOnboardingCompleted();
  }

  Future<void> completeOnboarding() async {
    state = const AsyncLoading<bool>();
    await ref
        .read(onboardingRepositoryProvider)
        .setOnboardingCompleted(completed: true);
    state = const AsyncData<bool>(true);
  }

  Future<void> resetOnboarding() async {
    state = const AsyncLoading<bool>();
    await ref
        .read(onboardingRepositoryProvider)
        .setOnboardingCompleted(completed: false);
    state = const AsyncData<bool>(false);
  }
}
