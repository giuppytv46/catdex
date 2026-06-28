import 'package:catdex/features/premium/domain/entities/premium_plan.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';

abstract interface class PremiumRepository {
  Future<PremiumStatus> getStatus();

  Future<List<PremiumPlan>> getAvailablePlans();

  Future<void> restorePurchases();
}
