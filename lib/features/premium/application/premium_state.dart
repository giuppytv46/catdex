import 'package:catdex/features/premium/domain/entities/monetization_placement.dart';
import 'package:catdex/features/premium/domain/entities/premium_plan.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:catdex/features/premium/domain/entities/scan_limit.dart';

class PremiumState {
  const PremiumState({
    required this.status,
    required this.scanLimit,
    required this.plans,
    required this.placements,
  });

  final PremiumStatus status;
  final ScanLimit scanLimit;
  final List<PremiumPlan> plans;
  final List<MonetizationPlacement> placements;
}
