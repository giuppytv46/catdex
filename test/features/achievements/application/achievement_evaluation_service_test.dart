import 'package:catdex/features/achievements/application/achievement_evaluation_service.dart';
import 'package:catdex/features/achievements/data/in_memory_achievement_repository.dart';
import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_facts.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first persisted discovery unlocks first_discovery', () async {
    final harness = _Harness();
    final result = await harness.evaluate(_facts(discoveries: 1));

    expect(result.unlocks.map((item) => item.achievementId), [
      'first_discovery',
    ]);
    expect(harness.progress.totalXp, 50);
    expect(
      result.ledger.achievements['first_discovery']?.status,
      PlayerAchievementStatus.unlocked,
    );
  });

  test('five discoveries unlock cumulative discovery achievements', () async {
    final harness = _Harness();
    final result = await harness.evaluate(_facts(discoveries: 5));

    expect(result.unlocks.map((item) => item.achievementId), [
      'first_discovery',
      'discovery_5',
    ]);
    expect(harness.progress.totalXp, 150);
  });

  test(
    'event and Halloween collection facts unlock their achievements',
    () async {
      final harness = _Harness();
      final result = await harness.evaluate(
        _facts(eventCards: 3, halloweenFree: 3),
      );

      expect(
        result.unlocks.map((item) => item.achievementId),
        containsAll([
          'first_event_card',
          'halloween_free_collection',
        ]),
      );
    },
  );

  test('progress is visible before unlock and clamps to target', () async {
    final harness = _Harness();
    final result = await harness.evaluate(_facts(discoveries: 7));

    final ten = result.ledger.achievements['discovery_10']!;
    expect(ten.status, PlayerAchievementStatus.inProgress);
    expect(ten.currentValue, 7);
    expect(ten.progress, 0.7);
    expect(
      result.ledger.achievements['first_discovery']?.currentValue,
      1,
    );
  });

  test('repeated reconciliation grants no duplicate XP', () async {
    final harness = _Harness();
    final first = await harness.evaluate(_facts(discoveries: 1));
    final second = await harness.evaluate(_facts(discoveries: 1));

    expect(first.wasHistoricalReconciliation, isTrue);
    expect(second.wasHistoricalReconciliation, isFalse);
    expect(second.unlocks, isEmpty);
    expect(harness.progress.totalXp, 50);
    expect(
      harness.progress.achievementIds.where((id) => id == 'first_discovery'),
      hasLength(1),
    );
  });

  test(
    'service recreation and repository refresh grant no duplicate XP',
    () async {
      final harness = _Harness();
      await harness.evaluate(_facts(discoveries: 1));
      final recreated = harness.recreateService();

      final result = await recreated.evaluate(
        playerId: harness.playerId,
        facts: _facts(discoveries: 1),
        source: 'restart',
      );

      expect(result.unlocks, isEmpty);
      expect(harness.progress.totalXp, 50);
    },
  );

  test('local and canonical progress merge does not duplicate XP', () async {
    final harness = _Harness();
    await harness.evaluate(_facts(discoveries: 1));
    final localSaveCount = harness.local.saveCount;
    harness.canonical.progress = harness.progress.copyWith(totalXp: 90);

    await harness.evaluate(_facts(discoveries: 1));

    expect(harness.progress.totalXp, 50);
    expect(harness.canonical.progress.totalXp, 90);
    expect(harness.local.saveCount, localSaveCount);
  });

  test('reward persistence failure remains recoverable', () async {
    final harness = _Harness()..local.failNextSave = true;

    await expectLater(
      harness.evaluate(_facts(discoveries: 1)),
      throwsA(isA<StateError>()),
    );
    final started = await harness.achievementRepository.load(harness.playerId);
    expect(
      started.rewardTransactions['achievement_reward:first_discovery']?.status,
      AchievementRewardTransactionStatus.started,
    );

    final recovered = await harness.evaluate(_facts(discoveries: 1));
    expect(recovered.unlocks.single.achievementId, 'first_discovery');
    expect(harness.progress.totalXp, 50);
  });

  test(
    'app close after XP write repairs unlock without duplicate reward',
    () async {
      final harness = _Harness(initialXp: 50);
      final definition = AchievementCatalogV1.definitions.first;
      final now = DateTime.utc(2026, 7, 17);
      await harness.achievementRepository.save(
        AchievementLedger(
          playerId: harness.playerId,
          achievements: {
            definition.achievementId: PlayerAchievement.initial(definition)
                .copyWith(
                  currentValue: 1,
                  status: PlayerAchievementStatus.inProgress,
                  lastEvaluatedAt: now,
                ),
          },
          rewardTransactions: {
            'achievement_reward:first_discovery': AchievementRewardTransaction(
              transactionId: 'achievement_reward:first_discovery',
              achievementId: 'first_discovery',
              playerId: harness.playerId,
              rewardXp: 50,
              previousXp: 0,
              updatedXp: 50,
              previousLevel: 1,
              updatedLevel: 1,
              status: AchievementRewardTransactionStatus.started,
              createdAt: now,
              updatedAt: now,
            ),
          },
          reconciliationVersion: 0,
        ),
      );

      final result = await harness.evaluate(_facts(discoveries: 1));

      expect(harness.progress.totalXp, 50);
      expect(
        result.unlocks.single.rewardTransactionId,
        'achievement_reward:first_discovery',
      );
      expect(result.ledger.achievements['first_discovery']?.isUnlocked, isTrue);
    },
  );

  test('achievement XP can trigger a level up', () async {
    final harness = _Harness(initialXp: 50);
    final result = await harness.evaluate(_facts(discoveries: 1));

    expect(result.unlocks.single.previousLevel, 1);
    expect(result.unlocks.single.updatedLevel, 2);
    expect(result.unlocks.single.causedLevelUp, isTrue);
  });

  test('stable reward transaction key is derived only from achievement ID', () {
    expect(
      achievementRewardTransactionId(' first_discovery '),
      'achievement_reward:first_discovery',
    );
  });
}

class _Harness {
  _Harness({int initialXp = 0})
    : local = _ProgressRepository(_progress(initialXp)),
      canonical = _ProgressRepository(_progress(initialXp)),
      progress = _progress(initialXp) {
    service = recreateService();
  }

  final String playerId = 'player';
  final InMemoryAchievementRepository achievementRepository =
      InMemoryAchievementRepository();
  final _ProgressRepository local;
  final _ProgressRepository canonical;
  PlayerProgress progress;
  late AchievementEvaluationService service;

  AchievementEvaluationService recreateService() {
    return AchievementEvaluationService(
      achievementRepository: achievementRepository,
      localProgressRepository: local,
      canonicalProgressRepository: canonical,
      levelCalculator: const LevelCalculator(),
      currentSessionProgress: () => progress,
      updateSessionProgress: (value) => progress = value,
      clock: () => DateTime.utc(2026, 7, 17, 12),
    );
  }

  Future<AchievementEvaluationResult> evaluate(AchievementFacts facts) {
    return service.evaluate(
      playerId: playerId,
      facts: facts,
      source: 'test',
    );
  }
}

class _ProgressRepository implements PlayerProgressRepository {
  _ProgressRepository(this.progress);

  PlayerProgress progress;
  bool failNextSave = false;
  int saveCount = 0;

  @override
  Future<PlayerProgress> getProgress(String playerId) async => progress;

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    saveCount += 1;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('simulated_write_failure');
    }
    this.progress = progress;
  }
}

PlayerProgress _progress(int xp) {
  return PlayerProgress(
    playerId: 'player',
    totalXp: xp,
    level: const LevelCalculator().levelForXp(xp),
    coins: 0,
    discoveryCount: 0,
    duplicateDiscoveryCount: 0,
    achievementIds: const [],
    badgeIds: const [],
  );
}

AchievementFacts _facts({
  int discoveries = 0,
  int normalCards = 0,
  int geolocated = 0,
  int claimedMissions = 0,
  int eventCards = 0,
  int halloweenFree = 0,
  int halloweenPremium = 0,
  int level = 1,
  Map<CatRarity, int> rarities = const {},
}) {
  return AchievementFacts(
    discoveryCount: discoveries,
    normalCardCount: normalCards,
    discoveryCountsByRarity: rarities,
    geolocatedDiscoveryCount: geolocated,
    claimedDailyMissionCount: claimedMissions,
    eventCardCount: eventCards,
    halloweenFreeVariantCount: halloweenFree,
    halloweenPremiumVariantCount: halloweenPremium,
    playerLevel: level,
  );
}
