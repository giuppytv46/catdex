import 'package:catdex/features/events/application/event_generation_coordinator.dart';
import 'package:catdex/features/events/data/shared_preferences_event_usage_repository.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/services/event_policy.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 7, 16);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('successful reservation and commit increments usage once', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final coordinator = EventGenerationCoordinator(usageRepository: usage);

    final reservation = await _reserveSuccess(
      coordinator,
      event: _event(),
      requestId: 'request-1',
      now: now,
    );
    expect(await coordinator.commit(reservation), isTrue);
    expect(await coordinator.commit(reservation), isFalse);
    expect(
      await usage.getCommittedUsage(
        playerId: 'player-1',
        eventId: 'summer-2026',
      ),
      1,
    );
  });

  test('free event generation limit is three', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final coordinator = EventGenerationCoordinator(usageRepository: usage);

    final variants = <String>{};
    for (var index = 0; index < 3; index += 1) {
      final reservation = await _reserveSuccess(
        coordinator,
        event: _event(),
        requestId: 'free-$index',
        now: now,
      );
      variants.add(reservation.variantId);
      await coordinator.commit(reservation);
    }

    expect(variants, {
      'summer-standard-1',
      'summer-standard-2',
      'summer-standard-3',
    });

    final fourth = await coordinator.reserve(
      event: _event(),
      premiumStatus: const PremiumStatus.free(),
      playerId: 'player-1',
      requestId: 'free-4',
      now: now,
    );
    expect(
      fourth,
      isA<EventReservationRejected>().having(
        (value) => value.reason,
        'reason',
        EventReservationFailure.limitReached,
      ),
    );
  });

  test('Premium uses the event configured limit and variant', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final coordinator = EventGenerationCoordinator(usageRepository: usage);
    final event = _event(premiumLimit: 4);

    for (var index = 0; index < 4; index += 1) {
      final reservation = await _reserveSuccess(
        coordinator,
        event: event,
        requestId: 'premium-$index',
        now: now,
        premiumStatus: const PremiumStatus.premium(),
        selectedVariantId: index.isEven
            ? 'summer-premium'
            : 'summer-standard-2',
      );
      expect(reservation.accessTier, EventAccessTier.premium);
      if (index == 0) {
        expect(reservation.variantId, 'summer-premium');
      } else if (index == 1) {
        expect(reservation.variantId, 'summer-standard-2');
      }
      await coordinator.commit(reservation);
    }

    final fifth = await coordinator.reserve(
      event: event,
      premiumStatus: const PremiumStatus.premium(),
      playerId: 'player-1',
      requestId: 'premium-5',
      now: now,
      selectedVariantId: 'summer-premium',
    );
    expect(fifth, isA<EventReservationRejected>());
  });

  test('Premium reservation requires an explicit selection', () async {
    final coordinator = EventGenerationCoordinator(
      usageRepository: const SharedPreferencesEventUsageRepository(),
    );

    final result = await coordinator.reserve(
      event: _event(),
      premiumStatus: const PremiumStatus.premium(),
      playerId: 'player-1',
      requestId: 'premium-missing-selection',
      now: now,
    );

    expect(
      result,
      isA<EventReservationRejected>().having(
        (value) => value.reason,
        'reason',
        EventReservationFailure.variantSelectionRequired,
      ),
    );
  });

  test('Premium may select any enabled Free or Premium variant', () async {
    final coordinator = EventGenerationCoordinator(
      usageRepository: const SharedPreferencesEventUsageRepository(),
    );

    for (final variant in const [
      'summer-standard-1',
      'summer-standard-2',
      'summer-standard-3',
      'summer-premium',
      'summer-pumpkin-king',
      'summer-night-spirit',
    ]) {
      final reservation = await _reserveSuccess(
        coordinator,
        event: _event(),
        requestId: 'premium-select-$variant',
        now: now,
        premiumStatus: const PremiumStatus.premium(),
        selectedVariantId: variant,
      );
      expect(reservation.variantId, variant);
      await coordinator.commit(reservation);
    }
  });

  test('invalid and disabled Premium selections are rejected', () async {
    final coordinator = EventGenerationCoordinator(
      usageRepository: const SharedPreferencesEventUsageRepository(),
    );
    final invalid = await coordinator.reserve(
      event: _event(),
      premiumStatus: const PremiumStatus.premium(),
      playerId: 'player-1',
      requestId: 'invalid-selection',
      now: now,
      selectedVariantId: 'summer-unknown',
    );
    final disabled = await coordinator.reserve(
      event: _event(disabledVariantIds: const ['summer-standard-2']),
      premiumStatus: const PremiumStatus.premium(),
      playerId: 'player-1',
      requestId: 'disabled-selection',
      now: now,
      selectedVariantId: 'summer-standard-2',
    );

    expect(
      (invalid as EventReservationRejected).reason,
      EventReservationFailure.selectedVariantInvalid,
    );
    expect(
      (disabled as EventReservationRejected).reason,
      EventReservationFailure.selectedVariantDisabled,
    );
  });

  test(
    'Free ignores a manual Free selection and rejects all Premium',
    () async {
      final coordinator = EventGenerationCoordinator(
        usageRepository: const SharedPreferencesEventUsageRepository(),
      );
      final automatic = await coordinator.reserve(
        event: _event(),
        premiumStatus: const PremiumStatus.free(),
        playerId: 'player-1',
        requestId: 'free-manual-standard',
        now: now,
        selectedVariantId: 'summer-standard-3',
      );
      expect(
        (automatic as EventReservationSuccess).reservation.variantId,
        'summer-standard-1',
      );
      for (final variant in const [
        'summer-premium',
        'summer-pumpkin-king',
        'summer-night-spirit',
      ]) {
        final premium = await coordinator.reserve(
          event: _event(),
          premiumStatus: const PremiumStatus.free(),
          playerId: 'player-1',
          requestId: 'free-manual-$variant',
          now: now,
          selectedVariantId: variant,
        );
        expect(
          (premium as EventReservationRejected).reason,
          EventReservationFailure.premiumRequired,
          reason: variant,
        );
      }
    },
  );

  test('generation failure releases reservation', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final coordinator = EventGenerationCoordinator(usageRepository: usage);
    final reservation = await _reserveSuccess(
      coordinator,
      event: _event(),
      requestId: 'retryable-request',
      now: now,
    );

    expect(coordinator.release(reservation), isTrue);
    final retry = await coordinator.reserve(
      event: _event(),
      premiumStatus: const PremiumStatus.free(),
      playerId: 'player-1',
      requestId: 'retryable-request',
      now: now,
    );
    expect(retry, isA<EventReservationSuccess>());
    expect(
      (retry as EventReservationSuccess).reservation.variantId,
      reservation.variantId,
    );
  });

  test('duplicate in-flight request reuses the same reservation', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final coordinator = EventGenerationCoordinator(usageRepository: usage);
    final first = await _reserveSuccess(
      coordinator,
      event: _event(),
      requestId: 'same-request',
      now: now,
    );
    final repeated = await coordinator.reserve(
      event: _event(),
      premiumStatus: const PremiumStatus.free(),
      playerId: 'player-1',
      requestId: 'same-request',
      now: now,
    );

    expect(repeated, isA<EventReservationSuccess>());
    expect(
      (repeated as EventReservationSuccess).reservation,
      same(first),
    );
    expect(await coordinator.commit(first), isTrue);
    expect(await coordinator.commit(first), isFalse);
  });

  test('Free user never receives Premium variant', () async {
    const usage = SharedPreferencesEventUsageRepository();
    final coordinator = EventGenerationCoordinator(usageRepository: usage);
    for (var index = 0; index < 3; index += 1) {
      final reservation = await _reserveSuccess(
        coordinator,
        event: _event(),
        requestId: 'free-safe-$index',
        now: now,
      );
      expect(reservation.variantId, isNot('summer-premium'));
      await coordinator.commit(reservation);
    }
  });

  test('usage survives repository recreation', () async {
    const first = SharedPreferencesEventUsageRepository();
    await first.setCommittedUsage(
      playerId: 'player-1',
      eventId: 'summer-2026',
      value: 2,
    );

    const recreated = SharedPreferencesEventUsageRepository();
    expect(
      await recreated.getCommittedUsage(
        playerId: 'player-1',
        eventId: 'summer-2026',
      ),
      2,
    );
  });

  test('separate events retain separate counters', () async {
    const usage = SharedPreferencesEventUsageRepository();
    await usage.setCommittedUsage(
      playerId: 'player-1',
      eventId: 'summer-2026',
      value: 3,
    );
    await usage.setCommittedUsage(
      playerId: 'player-1',
      eventId: 'winter-2026',
      value: 1,
    );

    expect(
      await usage.getCommittedUsage(
        playerId: 'player-1',
        eventId: 'summer-2026',
      ),
      3,
    );
    expect(
      await usage.getCommittedUsage(
        playerId: 'player-1',
        eventId: 'winter-2026',
      ),
      1,
    );
  });
}

Future<EventGenerationReservation> _reserveSuccess(
  EventGenerationCoordinator coordinator, {
  required CatDexEvent event,
  required String requestId,
  required DateTime now,
  PremiumStatus premiumStatus = const PremiumStatus.free(),
  String? selectedVariantId,
}) async {
  final result = await coordinator.reserve(
    event: event,
    premiumStatus: premiumStatus,
    playerId: 'player-1',
    requestId: requestId,
    now: now,
    selectedVariantId: selectedVariantId,
  );
  expect(result, isA<EventReservationSuccess>());
  return (result as EventReservationSuccess).reservation;
}

CatDexEvent _event({
  int premiumLimit = 6,
  List<String> disabledVariantIds = const [],
}) {
  return CatDexEvent(
    id: 'summer-2026',
    startsAt: DateTime.utc(2026, 7),
    endsAt: DateTime.utc(2026, 8),
    standardVariantId: 'summer-standard',
    standardVariantIds: const [
      'summer-standard-1',
      'summer-standard-2',
      'summer-standard-3',
    ],
    premiumVariantId: 'summer-premium',
    premiumVariantIds: const [
      'summer-premium',
      'summer-pumpkin-king',
      'summer-night-spirit',
    ],
    premiumGenerationLimit: premiumLimit,
    disabledVariantIds: disabledVariantIds,
  );
}
