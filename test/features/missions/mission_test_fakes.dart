import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/missions/application/daily_mission_service.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:catdex/features/missions/domain/repositories/daily_mission_repository.dart';

class MemoryDailyMissionRepository implements DailyMissionRepository {
  DailyMissionLedger? value;
  int saveCount = 0;
  int? failOnSaveNumber;

  @override
  Future<DailyMissionLedger?> load(String playerId) async {
    return value?.playerId == playerId ? value : null;
  }

  @override
  Future<void> save(DailyMissionLedger ledger) async {
    saveCount += 1;
    if (saveCount == failOnSaveNumber) {
      throw StateError('test_repository_failure');
    }
    value = ledger;
  }
}

class FakeDailyMissionRewardGateway implements DailyMissionRewardGateway {
  final values = <DailyMissionRewardType, int>{
    DailyMissionRewardType.xp: 0,
    DailyMissionRewardType.analysisCredit: 0,
    DailyMissionRewardType.cardCredit: 0,
  };
  final ensureCalls = <DailyMissionRewardType, int>{};
  bool failEnsure = false;

  @override
  Future<int> currentValue(DailyMissionRewardType rewardType) async {
    return values[rewardType] ?? 0;
  }

  @override
  Future<void> ensureAtLeast(
    DailyMissionRewardType rewardType,
    int expectedValue,
  ) async {
    ensureCalls[rewardType] = (ensureCalls[rewardType] ?? 0) + 1;
    if (failEnsure) throw StateError('test_reward_failure');
    if ((values[rewardType] ?? 0) < expectedValue) {
      values[rewardType] = expectedValue;
    }
  }
}

DailyMission testMission({
  required String id,
  required DailyMissionType type,
  DailyMissionStatus status = DailyMissionStatus.active,
  DailyMissionRewardType rewardType = DailyMissionRewardType.xp,
  int rewardAmount = 50,
  int target = 1,
  int current = 0,
  CatRarity? targetRarity,
  int sortOrder = 0,
}) {
  return DailyMission(
    missionId: id,
    missionType: type,
    localizedTitleKey: DailyMissionTextKey.discoverOneCatTitle,
    localizedDescriptionKey: DailyMissionTextKey.discoverOneCatDescription,
    targetValue: target,
    currentValue: current,
    rewardType: rewardType,
    rewardAmount: rewardAmount,
    status: status,
    assignedDate: '2026-07-17',
    targetRarity: targetRarity,
    completedAt: status == DailyMissionStatus.completed
        ? DateTime.utc(2026, 7, 17, 10)
        : null,
    claimedAt: status == DailyMissionStatus.claimed
        ? DateTime.utc(2026, 7, 17, 11)
        : null,
    schemaVersion: DailyMission.currentSchemaVersion,
    sortOrder: sortOrder,
  );
}

DailyMissionLedger testLedger({
  List<DailyMission>? missions,
  Set<String> processed = const {},
  Map<String, DailyMissionClaimTransaction> transactions = const {},
  String date = '2026-07-17',
}) {
  return DailyMissionLedger(
    playerId: 'player-one',
    assignedDate: date,
    lastResetDate: date,
    missions:
        missions ??
        [
          testMission(id: 'discover', type: DailyMissionType.discoverCats),
          testMission(
            id: 'card',
            type: DailyMissionType.generateNormalCard,
            sortOrder: 1,
          ),
          testMission(
            id: 'map',
            type: DailyMissionType.openMap,
            sortOrder: 2,
          ),
        ],
    expiredMissions: const [],
    processedOperationIds: processed,
    claimTransactions: transactions,
    schemaVersion: DailyMissionLedger.currentSchemaVersion,
  );
}
