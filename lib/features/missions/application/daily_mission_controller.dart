import 'dart:async';

import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/location/application/discovery_location_capture_service.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/missions/application/daily_mission_reward_gateway.dart';
import 'package:catdex/features/missions/application/daily_mission_service.dart';
import 'package:catdex/features/missions/data/shared_preferences_daily_mission_repository.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_progress_event.dart';
import 'package:catdex/features/missions/domain/repositories/daily_mission_repository.dart';
import 'package:catdex/features/missions/domain/services/daily_mission_assignment_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyMissionClockProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

final dailyMissionRepositoryProvider = Provider<DailyMissionRepository>(
  (_) => const SharedPreferencesDailyMissionRepository(),
);

final dailyMissionRewardGatewayProvider = Provider<DailyMissionRewardGateway>(
  CatDexDailyMissionRewardGateway.new,
);

final dailyMissionAvailabilityProvider =
    FutureProvider<DailyMissionAvailability>(
      (ref) async {
        final now = ref.read(dailyMissionClockProvider)();
        final eventActive =
            ref
                .read(eventRuntimeConfigurationProvider)
                .activeEvent(now.toUtc()) !=
            null;
        var locationAvailable = false;
        try {
          final repository = ref.read(discoveryLocationRepositoryProvider);
          final serviceEnabled = await repository.checkServiceEnabled();
          final permission = await repository.checkPermission();
          locationAvailable =
              serviceEnabled &&
              permission != LocationPermissionStatus.permanentlyDenied &&
              permission != LocationPermissionStatus.restricted &&
              permission != LocationPermissionStatus.unsupported;
        } on Object {
          locationAvailable = false;
        }
        return DailyMissionAvailability(
          eventActive: eventActive,
          locationAvailable: locationAvailable,
        );
      },
    );

final dailyMissionServiceProvider = Provider<DailyMissionService>((ref) {
  return DailyMissionService(
    repository: ref.watch(dailyMissionRepositoryProvider),
    rewardGateway: ref.watch(dailyMissionRewardGatewayProvider),
    assignmentService: const DailyMissionAssignmentService(),
    datePolicy: const DailyMissionDatePolicy(),
    clock: ref.watch(dailyMissionClockProvider),
  );
});

final dailyMissionControllerProvider =
    AsyncNotifierProvider<DailyMissionController, DailyMissionLedger>(
      DailyMissionController.new,
    );

class DailyMissionController extends AsyncNotifier<DailyMissionLedger> {
  Future<void> _tail = Future<void>.value();

  @override
  Future<DailyMissionLedger> build() async {
    final lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (ref.mounted) ref.invalidateSelf();
      },
    );
    ref.onDispose(lifecycleListener.dispose);
    final session = ref.watch(activeCatDexSessionProvider);
    final availability = await ref.watch(
      dailyMissionAvailabilityProvider.future,
    );
    return ref
        .watch(dailyMissionServiceProvider)
        .loadDaily(playerId: session.playerId, availability: availability);
  }

  Future<void> trackDiscoverySaved(CatDiscovery discovery) async {
    await trackEvent(
      DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.discoverySaved,
        operationId: discovery.id,
      ),
    );
    if (discovery.captureLocation?.hasValidCoordinates == true) {
      await trackEvent(
        DailyMissionProgressEvent(
          type: DailyMissionProgressEventType.discoverySavedWithLocation,
          operationId: discovery.id,
        ),
      );
    }
    await trackEvent(
      DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.rarityDiscovered,
        operationId: discovery.id,
        rarity: discovery.rarity,
      ),
    );
  }

  Future<void> trackNormalCardGenerated(String cardId) {
    return trackEvent(
      DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.normalCardGenerated,
        operationId: cardId,
      ),
    );
  }

  Future<void> trackEventCardGenerated(String cardId) {
    return trackEvent(
      DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.eventCardGenerated,
        operationId: cardId,
      ),
    );
  }

  Future<void> trackMapOpened() async {
    final dateKey = const DailyMissionDatePolicy().localDateKey(
      ref.read(dailyMissionClockProvider)(),
    );
    return trackEvent(
      DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.mapOpened,
        operationId: 'map-open:$dateKey',
      ),
    );
  }

  Future<void> trackEvent(DailyMissionProgressEvent event) {
    return _enqueue(() async {
      final ledger = await _loadCurrentDailyLedger();
      final updated = await ref
          .read(dailyMissionServiceProvider)
          .recordEvent(ledger, event);
      if (ref.mounted) state = AsyncData(updated);
    });
  }

  Future<DailyMissionClaimResultType> claim(String missionId) async {
    var resultType = DailyMissionClaimResultType.failed;
    await _enqueue(() async {
      final ledger = await _loadCurrentDailyLedger();
      final result = await ref
          .read(dailyMissionServiceProvider)
          .claim(ledger, missionId);
      resultType = result.type;
      if (ref.mounted) state = AsyncData(result.ledger);
    });
    return resultType;
  }

  Future<void> resetTodayProgressForDebug() {
    return _enqueue(() async {
      final ledger = state.value ?? await future;
      final updated = await ref
          .read(dailyMissionServiceProvider)
          .resetProgressForDebug(ledger);
      if (ref.mounted) state = AsyncData(updated);
    });
  }

  Future<void> regenerateTodayForDebug() {
    return _enqueue(() async {
      final ledger = state.value ?? await future;
      final availability = await ref.read(
        dailyMissionAvailabilityProvider.future,
      );
      final updated = await ref
          .read(dailyMissionServiceProvider)
          .regenerateForDebug(
            ledger: ledger,
            availability: availability,
          );
      if (ref.mounted) state = AsyncData(updated);
    });
  }

  Future<void> simulateNextMissionEventForDebug() async {
    final ledger = state.value ?? await future;
    final mission = ledger.missions.firstWhere(
      (candidate) => candidate.isActive,
      orElse: () => ledger.missions.first,
    );
    final type = switch (mission.missionType) {
      DailyMissionType.discoverCats =>
        DailyMissionProgressEventType.discoverySaved,
      DailyMissionType.generateNormalCard =>
        DailyMissionProgressEventType.normalCardGenerated,
      DailyMissionType.openMap => DailyMissionProgressEventType.mapOpened,
      DailyMissionType.discoverWithLocation =>
        DailyMissionProgressEventType.discoverySavedWithLocation,
      DailyMissionType.discoverRarity =>
        DailyMissionProgressEventType.rarityDiscovered,
      DailyMissionType.generateEventCard =>
        DailyMissionProgressEventType.eventCardGenerated,
    };
    await trackEvent(
      DailyMissionProgressEvent(
        type: type,
        operationId: 'debug-${DateTime.now().microsecondsSinceEpoch}',
        rarity: mission.targetRarity,
      ),
    );
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.catchError((Object error, StackTrace stackTrace) {
      debugPrint(
        'CATDEX_MISSION_OPERATION_FAILED reason=${error.runtimeType}',
      );
    });
    return next;
  }

  Future<DailyMissionLedger> _loadCurrentDailyLedger() async {
    final current = state.value ?? await future;
    final availability = await ref.read(
      dailyMissionAvailabilityProvider.future,
    );
    return ref
        .read(dailyMissionServiceProvider)
        .loadDaily(playerId: current.playerId, availability: availability);
  }
}
