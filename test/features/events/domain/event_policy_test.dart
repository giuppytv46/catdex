import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/services/event_policy.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = EventResolver();
  const variants = EventVariantPolicy();
  const visibility = EventOwnedCardVisibilityPolicy();
  final now = DateTime.utc(2026, 7, 16, 12);

  test('active event resolution selects the currently active event', () {
    final active = resolver.activeEvent(
      [
        _event(
          id: 'expired',
          startsAt: now.subtract(const Duration(days: 3)),
          endsAt: now.subtract(const Duration(days: 1)),
        ),
        _event(id: 'active'),
      ],
      now: now,
    );

    expect(active?.id, 'active');
  });

  test('free users never receive the Premium event variant', () {
    expect(
      variants.variantFor(_event(), const PremiumStatus.free(), now: now),
      'summer-standard',
    );
  });

  test('event metadata survives serialization', () {
    final event = _event(
      metadata: const {
        'season': 'summer',
        'labels': ['alpha', 'private'],
      },
    );

    final restored = CatDexEvent.fromJson(event.toJson());

    expect(restored.id, event.id);
    expect(restored.metadata, event.metadata);
    expect(restored.freeGenerationLimit, 3);
    expect(restored.premiumGenerationLimit, 5);
    expect(restored.allPremiumVariantIds, [
      'summer-premium',
      'summer-pumpkin-king',
      'summer-night-spirit',
    ]);
    expect(restored.transformsCatAppearance('summer-pumpkin-king'), isTrue);
  });

  test('expired events keep already owned cards visible', () {
    final expired = _event(
      startsAt: now.subtract(const Duration(days: 2)),
      endsAt: now.subtract(const Duration(days: 1)),
    );

    expect(expired.isActiveAt(now), isFalse);
    expect(visibility.isVisible(isOwned: true), isTrue);
  });
}

CatDexEvent _event({
  String id = 'summer-2026',
  DateTime? startsAt,
  DateTime? endsAt,
  Map<String, Object?> metadata = const {},
}) {
  return CatDexEvent(
    id: id,
    startsAt: startsAt ?? DateTime.utc(2026, 7),
    endsAt: endsAt ?? DateTime.utc(2026, 8),
    standardVariantId: 'summer-standard',
    premiumVariantId: 'summer-premium',
    premiumVariantIds: const [
      'summer-premium',
      'summer-pumpkin-king',
      'summer-night-spirit',
    ],
    variantSortOrders: const {
      'summer-premium': 3,
      'summer-pumpkin-king': 4,
      'summer-night-spirit': 5,
    },
    variantTransformsCatAppearance: const {
      'summer-premium': true,
      'summer-pumpkin-king': true,
      'summer-night-spirit': true,
    },
    premiumGenerationLimit: 5,
    metadata: metadata,
  );
}
