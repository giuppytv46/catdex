import 'package:catdex/features/premium/application/premium_state.dart';
import 'package:catdex/features/premium/data/fake_ad_repository.dart';
import 'package:catdex/features/premium/data/fake_premium_repository.dart';
import 'package:catdex/features/premium/domain/repositories/ad_repository.dart';
import 'package:catdex/features/premium/domain/repositories/premium_repository.dart';
import 'package:catdex/features/premium/domain/services/scan_limit_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final premiumRepositoryProvider = Provider<PremiumRepository>((_) {
  return const FakePremiumRepository();
});

final adRepositoryProvider = Provider<AdRepository>((_) {
  return const FakeAdRepository();
});

final scanLimitCalculatorProvider = Provider<ScanLimitCalculator>((_) {
  return const ScanLimitCalculator();
});

final scansUsedTodayProvider = Provider<int>((_) {
  return 0;
});

final premiumControllerProvider =
    AsyncNotifierProvider<PremiumController, PremiumState>(
      PremiumController.new,
    );

class PremiumController extends AsyncNotifier<PremiumState> {
  @override
  Future<PremiumState> build() async {
    final premiumRepository = ref.watch(premiumRepositoryProvider);
    final adRepository = ref.watch(adRepositoryProvider);
    final status = await premiumRepository.getStatus();
    final scanLimit = ref
        .watch(scanLimitCalculatorProvider)
        .limitFor(
          status: status,
          scansUsedToday: ref.watch(scansUsedTodayProvider),
        );

    return PremiumState(
      status: status,
      scanLimit: scanLimit,
      plans: await premiumRepository.getAvailablePlans(),
      placements: await adRepository.getPlacements(),
    );
  }

  Future<void> restorePurchases() async {
    await ref.read(premiumRepositoryProvider).restorePurchases();
  }
}
