import 'package:catdex/features/events/domain/services/event_policy.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = EventPremiumEntitlementResolver();
  const visibility = EventOwnedCardVisibilityPolicy();
  final now = DateTime.utc(2026, 7, 16);

  test('event eligibility uses the canonical PremiumStatus entitlement', () {
    expect(
      resolver.hasActivePremium(
        PremiumStatus.premium(
          expiresAt: now.add(const Duration(days: 1)),
        ),
        now: now,
      ),
      isTrue,
    );
  });

  test('free tier is identified correctly', () {
    expect(
      resolver.tierFor(const PremiumStatus.free(), now: now),
      EventAccessTier.free,
    );
  });

  test('expired Premium blocks new Premium event generation', () {
    final expired = PremiumStatus.premium(
      expiresAt: now.subtract(const Duration(seconds: 1)),
    );

    expect(resolver.tierFor(expired, now: now), EventAccessTier.free);
  });

  test('owned Premium event cards remain visible after expiry', () {
    expect(visibility.isVisible(isOwned: true), isTrue);
  });
}
