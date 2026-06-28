import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/test.dart';

void main() {
  group('OnboardingController', () {
    test('loads incomplete onboarding by default', () async {
      final repository = _FakeOnboardingRepository(completed: false);
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final completed = await container.read(
        onboardingControllerProvider.future,
      );

      expect(completed, isFalse);
    });

    test('persists completion state through the repository', () async {
      final repository = _FakeOnboardingRepository(completed: false);
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding();

      expect(repository.completed, isTrue);
      expect(container.read(onboardingControllerProvider).value, isTrue);
    });
  });
}

class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository({required this.completed});

  bool completed;

  @override
  Future<bool> isOnboardingCompleted() async {
    return completed;
  }

  @override
  Future<void> setOnboardingCompleted({required bool completed}) async {
    this.completed = completed;
  }
}
