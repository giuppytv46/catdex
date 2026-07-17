import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/events/domain/services/event_policy.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:flutter/foundation.dart';

enum EventReservationFailure {
  eventInactive,
  limitReached,
  reservationConflict,
  variantSelectionRequired,
  selectedVariantInvalid,
  premiumRequired,
  selectedVariantDisabled,
}

class EventGenerationReservation {
  const EventGenerationReservation({
    required this.requestId,
    required this.playerId,
    required this.eventId,
    required this.accessTier,
    required this.variantId,
    required this.templateKey,
    required this.instructionKey,
  });

  final String requestId;
  final String playerId;
  final String eventId;
  final EventAccessTier accessTier;
  final String variantId;
  final String templateKey;
  final String instructionKey;
}

sealed class EventReservationResult {
  const EventReservationResult();
}

class EventReservationSuccess extends EventReservationResult {
  const EventReservationSuccess(this.reservation);

  final EventGenerationReservation reservation;
}

class EventReservationRejected extends EventReservationResult {
  const EventReservationRejected(this.reason);

  final EventReservationFailure reason;
}

class EventGenerationCoordinator {
  EventGenerationCoordinator({
    required EventUsageRepository usageRepository,
    this.entitlementResolver = const EventPremiumEntitlementResolver(),
  }) : _usageRepository = usageRepository;

  final EventUsageRepository _usageRepository;
  final EventPremiumEntitlementResolver entitlementResolver;
  final Map<String, EventGenerationReservation> _reservations = {};

  Future<EventReservationResult> reserve({
    required CatDexEvent event,
    required PremiumStatus premiumStatus,
    required String playerId,
    required String requestId,
    required DateTime now,
    String? selectedVariantId,
  }) async {
    if (!event.isActiveAt(now)) {
      return const EventReservationRejected(
        EventReservationFailure.eventInactive,
      );
    }
    final reservationKey = _reservationKey(playerId, event.id, requestId);
    if (_reservations.containsKey(reservationKey)) {
      return EventReservationSuccess(_reservations[reservationKey]!);
    }

    final tier = entitlementResolver.tierFor(premiumStatus, now: now);
    final normalizedSelection = selectedVariantId?.trim();
    if (tier == EventAccessTier.premium) {
      debugPrint('CATDEX_EVENT_VARIANT_SELECTION_MODE manual');
      if (normalizedSelection == null || normalizedSelection.isEmpty) {
        debugPrint('CATDEX_EVENT_VARIANT_SELECTION_REQUIRED');
        return const EventReservationRejected(
          EventReservationFailure.variantSelectionRequired,
        );
      }
      if (!event.containsVariant(normalizedSelection)) {
        return const EventReservationRejected(
          EventReservationFailure.selectedVariantInvalid,
        );
      }
      if (!event.isVariantEnabled(normalizedSelection)) {
        return const EventReservationRejected(
          EventReservationFailure.selectedVariantDisabled,
        );
      }
    } else {
      debugPrint('CATDEX_EVENT_VARIANT_SELECTION_MODE automatic');
      if (normalizedSelection != null &&
          event.isPremiumVariant(normalizedSelection)) {
        debugPrint('CATDEX_EVENT_VARIANT_SELECTION_PREMIUM_REJECTED');
        return const EventReservationRejected(
          EventReservationFailure.premiumRequired,
        );
      }
    }
    final limit = tier == EventAccessTier.premium
        ? event.premiumGenerationLimit
        : event.freeGenerationLimit;
    final usage = await _usageRepository.getSnapshot(
      playerId: playerId,
      eventId: event.id,
    );
    final pending = _reservations.values
        .where(
          (item) => item.playerId == playerId && item.eventId == event.id,
        )
        .length;
    if (usage.committedRequestIds.contains(requestId)) {
      return const EventReservationRejected(
        EventReservationFailure.reservationConflict,
      );
    }
    if (usage.committedUsage + pending >= limit) {
      return const EventReservationRejected(
        EventReservationFailure.limitReached,
      );
    }

    final reservedVariants = _reservations.values
        .where((item) => item.playerId == playerId && item.eventId == event.id)
        .map((item) => item.variantId)
        .toSet();
    final variantId = _selectVariant(
      event: event,
      tier: tier,
      usage: usage,
      reservedVariants: reservedVariants,
      selectedVariantId: tier == EventAccessTier.premium
          ? normalizedSelection
          : null,
    );
    final reservation = EventGenerationReservation(
      requestId: requestId,
      playerId: playerId,
      eventId: event.id,
      accessTier: tier,
      variantId: variantId,
      templateKey: event.templateKeyFor(variantId),
      instructionKey: event.instructionKeyFor(variantId),
    );
    _reservations[reservationKey] = reservation;
    return EventReservationSuccess(reservation);
  }

  Future<bool> commit(EventGenerationReservation reservation) async {
    final key = _reservationKey(
      reservation.playerId,
      reservation.eventId,
      reservation.requestId,
    );
    if (_reservations.remove(key) == null) return false;
    final usage = await _usageRepository.getSnapshot(
      playerId: reservation.playerId,
      eventId: reservation.eventId,
    );
    if (usage.committedRequestIds.contains(reservation.requestId)) return true;
    await _usageRepository.saveSnapshot(
      playerId: reservation.playerId,
      eventId: reservation.eventId,
      snapshot: usage.copyWith(
        committedUsage: usage.committedUsage + 1,
        ownedVariantIds: {...usage.ownedVariantIds, reservation.variantId},
        committedRequestIds: {
          ...usage.committedRequestIds,
          reservation.requestId,
        },
      ),
    );
    return true;
  }

  String _selectVariant({
    required CatDexEvent event,
    required EventAccessTier tier,
    required EventUsageSnapshot usage,
    required Set<String> reservedVariants,
    String? selectedVariantId,
  }) {
    final unavailable = {...usage.ownedVariantIds, ...reservedVariants};
    if (tier == EventAccessTier.free) {
      return event.enabledStandardVariantIds.firstWhere(
        (variant) => !unavailable.contains(variant),
        orElse: () => event.enabledStandardVariantIds.first,
      );
    }

    if (selectedVariantId != null) {
      debugPrint(
        'CATDEX_EVENT_SELECTED_VARIANT_VALIDATED variant=$selectedVariantId',
      );
      return selectedVariantId;
    }

    if (event.premiumGuaranteedOnce &&
        event.enabledPremiumVariantIds.any(
          (variant) => !unavailable.contains(variant),
        )) {
      return event.enabledPremiumVariantIds.firstWhere(
        (variant) => !unavailable.contains(variant),
      );
    }

    final eligible = <String>[
      ...event.enabledStandardVariantIds,
      ...event.enabledPremiumVariantIds,
    ];
    final weighted = <String>[];
    for (final variant in eligible) {
      final weight = event.variantWeights[variant] ?? 1;
      for (var index = 0; index < weight; index += 1) {
        weighted.add(variant);
      }
    }
    return weighted[usage.committedUsage % weighted.length];
  }

  bool release(EventGenerationReservation reservation) {
    return _reservations.remove(
          _reservationKey(
            reservation.playerId,
            reservation.eventId,
            reservation.requestId,
          ),
        ) !=
        null;
  }

  String _reservationKey(String playerId, String eventId, String requestId) {
    return '$playerId::$eventId::$requestId';
  }
}
