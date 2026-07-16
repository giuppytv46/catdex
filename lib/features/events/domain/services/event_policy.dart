import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';

enum EventAccessTier { free, premium }

class EventResolver {
  const EventResolver();

  CatDexEvent? activeEvent(
    Iterable<CatDexEvent> events, {
    required DateTime now,
  }) {
    final active = events.where((event) => event.isActiveAt(now)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return active.isEmpty ? null : active.first;
  }
}

class EventPremiumEntitlementResolver {
  const EventPremiumEntitlementResolver();

  bool hasActivePremium(PremiumStatus status, {required DateTime now}) {
    if (status.tier != PremiumTier.premium) return false;
    final expiresAt = status.expiresAt;
    return expiresAt == null || expiresAt.isAfter(now);
  }

  EventAccessTier tierFor(PremiumStatus status, {required DateTime now}) {
    return hasActivePremium(status, now: now)
        ? EventAccessTier.premium
        : EventAccessTier.free;
  }
}

class EventVariantPolicy {
  const EventVariantPolicy({
    this.entitlementResolver = const EventPremiumEntitlementResolver(),
  });

  final EventPremiumEntitlementResolver entitlementResolver;

  String variantFor(
    CatDexEvent event,
    PremiumStatus status, {
    required DateTime now,
  }) {
    return entitlementResolver.hasActivePremium(status, now: now)
        ? event.premiumVariantId
        : event.standardVariantId;
  }
}

class EventOwnedCardVisibilityPolicy {
  const EventOwnedCardVisibilityPolicy();

  bool isVisible({required bool isOwned}) => isOwned;
}
