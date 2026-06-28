import 'package:catdex/features/premium/domain/entities/premium_plan.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:catdex/features/premium/domain/repositories/premium_repository.dart';

class FakePremiumRepository implements PremiumRepository {
  const FakePremiumRepository({
    PremiumStatus status = const PremiumStatus.free(),
  }) : _status = status;

  final PremiumStatus _status;

  @override
  Future<List<PremiumPlan>> getAvailablePlans() async {
    return const [
      PremiumPlan(
        id: 'catdex_premium_monthly',
        name: 'CatDex Premium Monthly',
        billingPeriod: PremiumBillingPeriod.monthly,
        priceLabel: 'Coming soon',
        benefits: [
          'More daily scans',
          'Premium profile badge',
          'Bonus cosmetic rewards',
          'Ad-free placeholders',
        ],
        featured: false,
      ),
      PremiumPlan(
        id: 'catdex_premium_yearly',
        name: 'CatDex Premium Yearly',
        billingPeriod: PremiumBillingPeriod.yearly,
        priceLabel: 'Coming soon',
        benefits: [
          'Best value placeholder',
          'Higher scan limit',
          'Seasonal cosmetic bonuses',
          'Premium profile badge',
        ],
        featured: true,
      ),
    ];
  }

  @override
  Future<PremiumStatus> getStatus() async {
    return _status;
  }

  @override
  Future<void> restorePurchases() async {}
}
