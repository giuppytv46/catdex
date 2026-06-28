import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:catdex/features/premium/domain/entities/scan_limit.dart';

class ScanLimitCalculator {
  const ScanLimitCalculator({
    this.freeDailyLimit = 5,
    this.premiumDailyLimit,
  }) : assert(freeDailyLimit > 0, 'freeDailyLimit must be positive');

  final int freeDailyLimit;
  final int? premiumDailyLimit;

  ScanLimit limitFor({
    required PremiumStatus status,
    required int scansUsedToday,
  }) {
    if (status.isPremium && premiumDailyLimit == null) {
      return ScanLimit.unlimited(scansUsedToday: scansUsedToday);
    }

    return ScanLimit(
      dailyLimit: status.isPremium ? premiumDailyLimit : freeDailyLimit,
      scansUsedToday: scansUsedToday,
    );
  }
}
