import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_progress_event.dart';
import 'package:catdex/features/missions/domain/repositories/daily_mission_repository.dart';
import 'package:catdex/features/missions/domain/services/daily_mission_assignment_service.dart';
import 'package:flutter/foundation.dart';

abstract interface class DailyMissionRewardGateway {
  Future<int> currentValue(DailyMissionRewardType rewardType);

  Future<void> ensureAtLeast(
    DailyMissionRewardType rewardType,
    int expectedValue,
  );
}

enum DailyMissionClaimResultType {
  claimed,
  alreadyClaimed,
  notCompleted,
  notFound,
  failed,
}

class DailyMissionClaimResult {
  const DailyMissionClaimResult({
    required this.type,
    required this.ledger,
  });

  final DailyMissionClaimResultType type;
  final DailyMissionLedger ledger;

  bool get success =>
      type == DailyMissionClaimResultType.claimed ||
      type == DailyMissionClaimResultType.alreadyClaimed;
}

class DailyMissionService {
  const DailyMissionService({
    required DailyMissionRepository repository,
    required DailyMissionRewardGateway rewardGateway,
    required DailyMissionAssignmentService assignmentService,
    required DailyMissionDatePolicy datePolicy,
    required DateTime Function() clock,
  }) : _repository = repository,
       _rewardGateway = rewardGateway,
       _assignmentService = assignmentService,
       _datePolicy = datePolicy,
       _clock = clock;

  final DailyMissionRepository _repository;
  final DailyMissionRewardGateway _rewardGateway;
  final DailyMissionAssignmentService _assignmentService;
  final DailyMissionDatePolicy _datePolicy;
  final DateTime Function() _clock;

  Future<DailyMissionLedger> loadDaily({
    required String playerId,
    required DailyMissionAvailability availability,
  }) async {
    debugPrint('CATDEX_MISSIONS_DAILY_LOAD_STARTED');
    final today = _datePolicy.localDateKey(_clock());
    final stored = await _repository.load(playerId);
    if (stored == null) {
      return _assign(
        playerId: playerId,
        dateKey: today,
        availability: availability,
      );
    }

    if (today.compareTo(stored.lastResetDate) > 0) {
      final expired = stored.missions
          .where((mission) => !mission.isClaimed)
          .map(
            (mission) => mission.copyWith(
              status: DailyMissionStatus.expired,
            ),
          );
      final next = await _assign(
        playerId: playerId,
        dateKey: today,
        availability: availability,
        expiredMissions: [
          ...stored.expiredMissions,
          ...expired,
        ].take(30).toList(growable: false),
        claimTransactions: stored.claimTransactions,
      );
      debugPrint('CATDEX_MISSIONS_DAILY_RESET');
      return next;
    }

    // A backward clock or timezone change keeps the newest persisted set.
    return _reconcileInterruptedClaims(stored);
  }

  Future<DailyMissionLedger> recordEvent(
    DailyMissionLedger ledger,
    DailyMissionProgressEvent event,
  ) async {
    final operationKey = event.idempotencyKey;
    debugPrint('CATDEX_MISSION_PROGRESS_EVENT type=${event.type.name}');
    if (event.operationId.trim().isEmpty ||
        ledger.processedOperationIds.contains(operationKey)) {
      debugPrint('CATDEX_MISSION_PROGRESS_DUPLICATE_SKIPPED');
      return ledger;
    }

    final now = _clock().toUtc();
    var changed = false;
    final missions = <DailyMission>[];
    for (final mission in ledger.missions) {
      if (!mission.isActive || !_matches(mission, event)) {
        missions.add(mission);
        continue;
      }
      final progress = (mission.currentValue + 1).clamp(
        0,
        mission.targetValue,
      );
      final completed = progress >= mission.targetValue;
      final updated = mission.copyWith(
        currentValue: progress,
        status: completed
            ? DailyMissionStatus.completed
            : DailyMissionStatus.active,
        completedAt: completed ? now : null,
      );
      missions.add(updated);
      changed = true;
      debugPrint(
        'CATDEX_MISSION_PROGRESS_UPDATED id=${mission.missionId} '
        'progress=$progress/${mission.targetValue}',
      );
      if (completed) {
        debugPrint('CATDEX_MISSION_COMPLETED id=${mission.missionId}');
      }
    }

    final updated = ledger.copyWith(
      missions: missions,
      processedOperationIds: {
        ...ledger.processedOperationIds,
        operationKey,
      },
    );
    await _repository.save(updated);
    return changed ? updated : updated;
  }

  Future<DailyMissionClaimResult> claim(
    DailyMissionLedger ledger,
    String missionId,
  ) async {
    final missionIndex = ledger.missions.indexWhere(
      (mission) => mission.missionId == missionId,
    );
    if (missionIndex < 0) {
      return DailyMissionClaimResult(
        type: DailyMissionClaimResultType.notFound,
        ledger: ledger,
      );
    }
    final mission = ledger.missions[missionIndex];
    if (mission.isClaimed) {
      return DailyMissionClaimResult(
        type: DailyMissionClaimResultType.alreadyClaimed,
        ledger: ledger,
      );
    }
    if (!mission.isCompleted) {
      return DailyMissionClaimResult(
        type: DailyMissionClaimResultType.notCompleted,
        ledger: ledger,
      );
    }

    debugPrint('CATDEX_MISSION_CLAIM_STARTED id=$missionId');
    final transactionId = 'claim:${ledger.assignedDate}:$missionId';
    var working = ledger;
    var transaction = working.claimTransactions[transactionId];
    try {
      if (transaction == null) {
        final baseline = await _rewardGateway.currentValue(
          mission.rewardType,
        );
        final now = _clock().toUtc();
        transaction = DailyMissionClaimTransaction(
          transactionId: transactionId,
          missionId: missionId,
          rewardType: mission.rewardType,
          rewardAmount: mission.rewardAmount,
          baselineValue: baseline,
          expectedValue: baseline + mission.rewardAmount,
          status: DailyMissionClaimTransactionStatus.started,
          createdAt: now,
          updatedAt: now,
        );
        working = working.copyWith(
          claimTransactions: {
            ...working.claimTransactions,
            transactionId: transaction,
          },
        );
        await _repository.save(working);
      }

      final current = await _rewardGateway.currentValue(mission.rewardType);
      if (current < transaction.expectedValue) {
        await _rewardGateway.ensureAtLeast(
          mission.rewardType,
          transaction.expectedValue,
        );
      }
      final readBack = await _rewardGateway.currentValue(mission.rewardType);
      if (readBack < transaction.expectedValue) {
        throw StateError('reward_readback_failed');
      }

      final claimedAt = _clock().toUtc();
      final missions = [...working.missions];
      missions[missionIndex] = mission.copyWith(
        status: DailyMissionStatus.claimed,
        claimedAt: claimedAt,
      );
      final completedTransaction = transaction.copyWith(
        status: DailyMissionClaimTransactionStatus.completed,
        updatedAt: claimedAt,
      );
      final completedLedger = working.copyWith(
        missions: missions,
        claimTransactions: {
          ...working.claimTransactions,
          transactionId: completedTransaction,
        },
      );
      await _repository.save(completedLedger);
      debugPrint(
        'CATDEX_MISSION_REWARD_GRANTED '
        'type=${mission.rewardType.name} amount=${mission.rewardAmount}',
      );
      debugPrint('CATDEX_MISSION_CLAIM_COMPLETED id=$missionId');
      return DailyMissionClaimResult(
        type: DailyMissionClaimResultType.claimed,
        ledger: completedLedger,
      );
    } on Object catch (error) {
      debugPrint(
        'CATDEX_MISSION_CLAIM_FAILED reason=${error.runtimeType}',
      );
      return DailyMissionClaimResult(
        type: DailyMissionClaimResultType.failed,
        ledger: working,
      );
    }
  }

  Future<DailyMissionLedger> resetProgressForDebug(
    DailyMissionLedger ledger,
  ) async {
    final reset = ledger.copyWith(
      missions: [
        for (final mission in ledger.missions)
          if (mission.isClaimed)
            mission
          else
            mission.copyWith(
              currentValue: 0,
              status: DailyMissionStatus.active,
              clearCompletedAt: true,
            ),
      ],
      processedOperationIds: const {},
    );
    await _repository.save(reset);
    return reset;
  }

  Future<DailyMissionLedger> regenerateForDebug({
    required DailyMissionLedger ledger,
    required DailyMissionAvailability availability,
  }) {
    return _assign(
      playerId: ledger.playerId,
      dateKey: ledger.assignedDate,
      availability: availability,
      expiredMissions: ledger.expiredMissions,
      claimTransactions: ledger.claimTransactions,
      generationSalt: 'debug-${_clock().microsecondsSinceEpoch}',
    );
  }

  Future<DailyMissionLedger> _assign({
    required String playerId,
    required String dateKey,
    required DailyMissionAvailability availability,
    List<DailyMission> expiredMissions = const [],
    Map<String, DailyMissionClaimTransaction> claimTransactions = const {},
    String generationSalt = '',
  }) async {
    final ledger = DailyMissionLedger(
      playerId: playerId,
      assignedDate: dateKey,
      lastResetDate: dateKey,
      missions: _assignmentService.assign(
        playerId: playerId,
        dateKey: dateKey,
        availability: availability,
        generationSalt: generationSalt,
      ),
      expiredMissions: List.unmodifiable(expiredMissions),
      processedOperationIds: const {},
      claimTransactions: Map.unmodifiable(claimTransactions),
      schemaVersion: DailyMissionLedger.currentSchemaVersion,
    );
    await _repository.save(ledger);
    debugPrint('CATDEX_MISSIONS_DAILY_ASSIGNED date=$dateKey');
    return ledger;
  }

  Future<DailyMissionLedger> _reconcileInterruptedClaims(
    DailyMissionLedger ledger,
  ) async {
    var updated = ledger;
    var changed = false;
    for (final transaction in ledger.claimTransactions.values) {
      if (transaction.status != DailyMissionClaimTransactionStatus.started) {
        continue;
      }
      try {
        final current = await _rewardGateway.currentValue(
          transaction.rewardType,
        );
        if (current < transaction.expectedValue) continue;
        final index = updated.missions.indexWhere(
          (mission) => mission.missionId == transaction.missionId,
        );
        if (index < 0 || updated.missions[index].isClaimed) continue;
        final now = _clock().toUtc();
        final missions = [...updated.missions];
        missions[index] = missions[index].copyWith(
          status: DailyMissionStatus.claimed,
          claimedAt: now,
        );
        updated = updated.copyWith(
          missions: missions,
          claimTransactions: {
            ...updated.claimTransactions,
            transaction.transactionId: transaction.copyWith(
              status: DailyMissionClaimTransactionStatus.completed,
              updatedAt: now,
            ),
          },
        );
        changed = true;
      } on Object {
        // Offline reward readback keeps the completed mission safely retryable.
      }
    }
    if (changed) await _repository.save(updated);
    return updated;
  }

  bool _matches(
    DailyMission mission,
    DailyMissionProgressEvent event,
  ) {
    return switch ((mission.missionType, event.type)) {
      (
        DailyMissionType.discoverCats,
        DailyMissionProgressEventType.discoverySaved,
      ) =>
        true,
      (
        DailyMissionType.generateNormalCard,
        DailyMissionProgressEventType.normalCardGenerated,
      ) =>
        true,
      (
        DailyMissionType.openMap,
        DailyMissionProgressEventType.mapOpened,
      ) =>
        true,
      (
        DailyMissionType.discoverWithLocation,
        DailyMissionProgressEventType.discoverySavedWithLocation,
      ) =>
        true,
      (
        DailyMissionType.discoverRarity,
        DailyMissionProgressEventType.rarityDiscovered,
      ) =>
        mission.targetRarity == event.rarity,
      (
        DailyMissionType.generateEventCard,
        DailyMissionProgressEventType.eventCardGenerated,
      ) =>
        true,
      _ => false,
    };
  }
}
