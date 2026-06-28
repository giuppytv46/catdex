import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:catdex/features/premium/domain/services/scan_limit_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('ScanLimitCalculator', () {
    test('limits free players to the configured daily scan count', () {
      const calculator = ScanLimitCalculator();

      final limit = calculator.limitFor(
        status: const PremiumStatus.free(),
        scansUsedToday: 2,
      );

      expect(limit.unlimited, isFalse);
      expect(limit.dailyLimit, 5);
      expect(limit.scansRemaining, 3);
      expect(limit.canScan, isTrue);
    });

    test('blocks free scans when the daily limit is reached', () {
      const calculator = ScanLimitCalculator();

      final limit = calculator.limitFor(
        status: const PremiumStatus.free(),
        scansUsedToday: 5,
      );

      expect(limit.scansRemaining, 0);
      expect(limit.canScan, isFalse);
    });

    test('uses unlimited scan placeholder for premium players by default', () {
      const calculator = ScanLimitCalculator();

      final limit = calculator.limitFor(
        status: const PremiumStatus.premium(),
        scansUsedToday: 99,
      );

      expect(limit.unlimited, isTrue);
      expect(limit.scansRemaining, isNull);
      expect(limit.canScan, isTrue);
    });

    test('supports a higher premium daily limit placeholder', () {
      const calculator = ScanLimitCalculator(premiumDailyLimit: 50);

      final limit = calculator.limitFor(
        status: const PremiumStatus.premium(),
        scansUsedToday: 12,
      );

      expect(limit.unlimited, isFalse);
      expect(limit.dailyLimit, 50);
      expect(limit.scansRemaining, 38);
      expect(limit.canScan, isTrue);
    });
  });
}
