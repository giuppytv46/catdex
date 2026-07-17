import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlayerAchievement JSON preserves unlock and reward metadata', () {
    final definition = AchievementCatalogV1.definitions.first;
    final now = DateTime.utc(2026, 7, 17);
    final source = PlayerAchievement.initial(definition).copyWith(
      currentValue: 1,
      status: PlayerAchievementStatus.unlocked,
      unlockedAt: now,
      rewardTransactionId: 'achievement_reward:first_discovery',
      rewardGrantedAt: now,
      lastEvaluatedAt: now,
    );

    final restored = PlayerAchievement.fromJson(source.toJson());

    expect(restored.isUnlocked, isTrue);
    expect(restored.rewardTransactionId, source.rewardTransactionId);
    expect(restored.rewardGrantedAt, now);
  });

  test('reward transaction JSON preserves started and completed states', () {
    final now = DateTime.utc(2026, 7, 17);
    final started = AchievementRewardTransaction(
      transactionId: 'achievement_reward:first_discovery',
      achievementId: 'first_discovery',
      playerId: 'player',
      rewardXp: 50,
      previousXp: 0,
      updatedXp: 50,
      previousLevel: 1,
      updatedLevel: 1,
      status: AchievementRewardTransactionStatus.started,
      createdAt: now,
      updatedAt: now,
    );

    final restored = AchievementRewardTransaction.fromJson(started.toJson());
    final completed = restored.copyWith(
      status: AchievementRewardTransactionStatus.completed,
    );

    expect(restored.status, AchievementRewardTransactionStatus.started);
    expect(completed.status, AchievementRewardTransactionStatus.completed);
  });

  test('ledger JSON preserves reconciliation version and transactions', () {
    final ledger = AchievementLedger.empty('player').copyWith(
      reconciliationVersion: AchievementLedger.currentReconciliationVersion,
    );

    final restored = AchievementLedger.fromJson(ledger.toJson());

    expect(restored.playerId, 'player');
    expect(
      restored.reconciliationVersion,
      AchievementLedger.currentReconciliationVersion,
    );
  });

  test('typed unlock result reports level-up only when level increases', () {
    const noLevel = AchievementUnlockResult(
      achievementId: 'first_discovery',
      rewardXp: 50,
      previousXp: 0,
      updatedXp: 50,
      previousLevel: 1,
      updatedLevel: 1,
      rewardTransactionId: 'achievement_reward:first_discovery',
      wasAlreadyUnlocked: false,
    );
    const levelUp = AchievementUnlockResult(
      achievementId: 'first_discovery',
      rewardXp: 50,
      previousXp: 50,
      updatedXp: 100,
      previousLevel: 1,
      updatedLevel: 2,
      rewardTransactionId: 'achievement_reward:first_discovery',
      wasAlreadyUnlocked: false,
    );

    expect(noLevel.causedLevelUp, isFalse);
    expect(levelUp.causedLevelUp, isTrue);
  });
}
