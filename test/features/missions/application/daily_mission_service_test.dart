import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/missions/application/daily_mission_service.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_progress_event.dart';
import 'package:catdex/features/missions/domain/services/daily_mission_assignment_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mission_test_fakes.dart';

void main() {
  late MemoryDailyMissionRepository repository;
  late FakeDailyMissionRewardGateway rewards;
  late DateTime now;
  late DailyMissionService service;

  setUp(() {
    repository = MemoryDailyMissionRepository();
    rewards = FakeDailyMissionRewardGateway();
    now = DateTime(2026, 7, 17, 9);
    service = DailyMissionService(
      repository: repository,
      rewardGateway: rewards,
      assignmentService: const DailyMissionAssignmentService(),
      datePolicy: const DailyMissionDatePolicy(),
      clock: () => now,
    );
  });

  const availability = DailyMissionAvailability.standard();

  test('same-day reload preserves mission progress', () async {
    repository.value = testLedger(
      missions: [
        testMission(
          id: 'discover',
          type: DailyMissionType.discoverCats,
          target: 2,
          current: 1,
        ),
        testMission(id: 'card', type: DailyMissionType.generateNormalCard),
        testMission(id: 'map', type: DailyMissionType.openMap),
      ],
    );

    final loaded = await service.loadDaily(
      playerId: 'player-one',
      availability: availability,
    );

    expect(loaded.missions.first.currentValue, 1);
  });

  test('new local calendar day resets the mission set once', () async {
    repository.value = testLedger();
    now = DateTime(2026, 7, 18, 1);

    final loaded = await service.loadDaily(
      playerId: 'player-one',
      availability: availability,
    );

    expect(loaded.assignedDate, '2026-07-18');
    expect(loaded.missions, hasLength(3));
    final savesAfterReset = repository.saveCount;
    await service.loadDaily(
      playerId: 'player-one',
      availability: availability,
    );
    expect(repository.saveCount, savesAfterReset);
  });

  test('moving the clock backward does not recreate missions', () async {
    repository.value = testLedger(date: '2026-07-18');
    now = DateTime(2026, 7, 17, 10);

    final loaded = await service.loadDaily(
      playerId: 'player-one',
      availability: availability,
    );

    expect(loaded.assignedDate, '2026-07-18');
    expect(repository.saveCount, 0);
  });

  test('completed unclaimed mission expires on the next day', () async {
    repository.value = testLedger(
      missions: [
        testMission(
          id: 'completed',
          type: DailyMissionType.discoverCats,
          status: DailyMissionStatus.completed,
          current: 1,
        ),
        testMission(id: 'card', type: DailyMissionType.generateNormalCard),
        testMission(id: 'map', type: DailyMissionType.openMap),
      ],
    );
    now = DateTime(2026, 7, 18);

    final loaded = await service.loadDaily(
      playerId: 'player-one',
      availability: availability,
    );

    expect(loaded.expiredMissions, hasLength(3));
    expect(
      loaded.expiredMissions
          .singleWhere((mission) => mission.missionId == 'completed')
          .status,
      DailyMissionStatus.expired,
    );
  });

  test('discovery persistence event increments discovery mission', () async {
    final updated = await service.recordEvent(
      testLedger(),
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.discoverySaved,
        operationId: 'discovery-1',
      ),
    );

    expect(updated.missions.first.currentValue, 1);
    expect(updated.missions.first.status, DailyMissionStatus.completed);
  });

  test(
    'failed discovery does not increment without persisted success event',
    () {
      final ledger = testLedger();

      expect(ledger.missions.first.currentValue, 0);
      expect(repository.saveCount, 0);
    },
  );

  test('same discovery id cannot increment twice', () async {
    const event = DailyMissionProgressEvent(
      type: DailyMissionProgressEventType.discoverySaved,
      operationId: 'discovery-1',
    );
    final first = await service.recordEvent(testLedger(), event);
    final second = await service.recordEvent(first, event);

    expect(second.missions.first.currentValue, 1);
  });

  test('normal card event increments only normal card mission', () async {
    final updated = await service.recordEvent(
      testLedger(),
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.normalCardGenerated,
        operationId: 'normal-card-1',
      ),
    );

    expect(updated.missions[0].currentValue, 0);
    expect(updated.missions[1].currentValue, 1);
  });

  test('opening an existing card does not increment without success event', () {
    final ledger = testLedger();
    expect(ledger.missions[1].currentValue, 0);
    expect(repository.saveCount, 0);
  });

  test('Map open completes the map mission', () async {
    final updated = await service.recordEvent(
      testLedger(),
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.mapOpened,
        operationId: 'map-open:2026-07-17',
      ),
    );

    expect(updated.missions[2].status, DailyMissionStatus.completed);
  });

  test(
    'location mission requires the location-specific success event',
    () async {
      final ledger = testLedger(
        missions: [
          testMission(
            id: 'location',
            type: DailyMissionType.discoverWithLocation,
          ),
        ],
      );
      final normal = await service.recordEvent(
        ledger,
        const DailyMissionProgressEvent(
          type: DailyMissionProgressEventType.discoverySaved,
          operationId: 'discovery-1',
        ),
      );
      final located = await service.recordEvent(
        normal,
        const DailyMissionProgressEvent(
          type: DailyMissionProgressEventType.discoverySavedWithLocation,
          operationId: 'discovery-1',
        ),
      );

      expect(normal.missions.single.currentValue, 0);
      expect(located.missions.single.currentValue, 1);
    },
  );

  test('rarity mission matches only its configured rarity', () async {
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'common',
          type: DailyMissionType.discoverRarity,
          targetRarity: CatRarity.common,
        ),
      ],
    );
    final uncommon = await service.recordEvent(
      ledger,
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.rarityDiscovered,
        operationId: 'discovery-1',
        rarity: CatRarity.uncommon,
      ),
    );
    final common = await service.recordEvent(
      uncommon,
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.rarityDiscovered,
        operationId: 'discovery-2',
        rarity: CatRarity.common,
      ),
    );

    expect(uncommon.missions.single.currentValue, 0);
    expect(common.missions.single.currentValue, 1);
  });

  test('event card mission advances only from event-card event', () async {
    final ledger = testLedger(
      missions: [
        testMission(id: 'event', type: DailyMissionType.generateEventCard),
      ],
    );
    final normal = await service.recordEvent(
      ledger,
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.normalCardGenerated,
        operationId: 'card-1',
      ),
    );
    final event = await service.recordEvent(
      normal,
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.eventCardGenerated,
        operationId: 'event-card-1',
      ),
    );

    expect(normal.missions.single.currentValue, 0);
    expect(event.missions.single.currentValue, 1);
  });

  test('completed mission does not grant reward automatically', () async {
    await service.recordEvent(
      testLedger(),
      const DailyMissionProgressEvent(
        type: DailyMissionProgressEventType.discoverySaved,
        operationId: 'discovery-1',
      ),
    );

    expect(rewards.values[DailyMissionRewardType.xp], 0);
    expect(rewards.ensureCalls, isEmpty);
  });

  test('successful claim grants XP once and marks claimed', () async {
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'xp',
          type: DailyMissionType.discoverCats,
          status: DailyMissionStatus.completed,
          current: 1,
        ),
      ],
    );
    final result = await service.claim(ledger, 'xp');

    expect(result.type, DailyMissionClaimResultType.claimed);
    expect(result.ledger.missions.single.isClaimed, isTrue);
    expect(rewards.values[DailyMissionRewardType.xp], 50);
  });

  test('repeated claim cannot grant reward twice', () async {
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'xp',
          type: DailyMissionType.discoverCats,
          status: DailyMissionStatus.completed,
          current: 1,
        ),
      ],
    );
    final first = await service.claim(ledger, 'xp');
    final second = await service.claim(first.ledger, 'xp');

    expect(second.type, DailyMissionClaimResultType.alreadyClaimed);
    expect(rewards.ensureCalls[DailyMissionRewardType.xp], 1);
  });

  test('failed reward write keeps mission completed and claimable', () async {
    rewards.failEnsure = true;
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'xp',
          type: DailyMissionType.discoverCats,
          status: DailyMissionStatus.completed,
          current: 1,
        ),
      ],
    );
    final result = await service.claim(ledger, 'xp');

    expect(result.type, DailyMissionClaimResultType.failed);
    expect(result.ledger.missions.single.isClaimable, isTrue);
  });

  test(
    'restart reconciliation finalizes reward granted before claim write',
    () async {
      final mission = testMission(
        id: 'xp',
        type: DailyMissionType.discoverCats,
        status: DailyMissionStatus.completed,
        current: 1,
      );
      final transaction = DailyMissionClaimTransaction(
        transactionId: 'claim:2026-07-17:xp',
        missionId: 'xp',
        rewardType: DailyMissionRewardType.xp,
        rewardAmount: 50,
        baselineValue: 0,
        expectedValue: 50,
        status: DailyMissionClaimTransactionStatus.started,
        createdAt: now.toUtc(),
        updatedAt: now.toUtc(),
      );
      repository.value = testLedger(
        missions: [mission],
        transactions: {transaction.transactionId: transaction},
      );
      rewards.values[DailyMissionRewardType.xp] = 50;

      final loaded = await service.loadDaily(
        playerId: 'player-one',
        availability: availability,
      );

      expect(loaded.missions.single.isClaimed, isTrue);
      expect(rewards.ensureCalls, isEmpty);
    },
  );

  test('analysis credit reward updates analysis credit balance', () async {
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'analysis-credit',
          type: DailyMissionType.discoverWithLocation,
          status: DailyMissionStatus.completed,
          current: 1,
          rewardType: DailyMissionRewardType.analysisCredit,
          rewardAmount: 1,
        ),
      ],
    );
    await service.claim(ledger, 'analysis-credit');

    expect(rewards.values[DailyMissionRewardType.analysisCredit], 1);
  });

  test('card credit reward updates card credit balance', () async {
    final ledger = testLedger(
      missions: [
        testMission(
          id: 'card-credit',
          type: DailyMissionType.generateNormalCard,
          status: DailyMissionStatus.completed,
          current: 1,
          rewardType: DailyMissionRewardType.cardCredit,
          rewardAmount: 1,
        ),
      ],
    );
    await service.claim(ledger, 'card-credit');

    expect(rewards.values[DailyMissionRewardType.cardCredit], 1);
  });
}
