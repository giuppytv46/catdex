import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:test/test.dart';

void main() {
  group('PremiumStatus', () {
    test('free status is not premium', () {
      const status = PremiumStatus.free();

      expect(status.tier, PremiumTier.free);
      expect(status.isPremium, isFalse);
      expect(status.expiresAt, isNull);
    });

    test('premium status enables premium logic', () {
      final expiresAt = DateTime.utc(2026, 12, 31);
      final status = PremiumStatus.premium(expiresAt: expiresAt);

      expect(status.tier, PremiumTier.premium);
      expect(status.isPremium, isTrue);
      expect(status.expiresAt, expiresAt);
    });
  });
}
