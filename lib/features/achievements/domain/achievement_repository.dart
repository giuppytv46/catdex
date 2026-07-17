import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';

abstract class AchievementRepository {
  const AchievementRepository();

  Future<AchievementLedger> load(String playerId);

  Future<void> save(AchievementLedger ledger);

  Future<List<AchievementDefinition>> loadDefinitions() async {
    return AchievementCatalogV1.definitions;
  }

  Future<List<PlayerAchievement>> loadPlayerAchievements(
    String playerId,
  ) async {
    return (await load(playerId)).achievements.values.toList(growable: false);
  }

  Future<void> saveProgress(
    String playerId,
    PlayerAchievement achievement,
  ) async {
    final ledger = await load(playerId);
    await save(
      ledger.copyWith(
        achievements: {
          ...ledger.achievements,
          achievement.achievementId: achievement,
        },
      ),
    );
  }

  Future<void> unlockAchievement(
    String playerId,
    PlayerAchievement achievement,
  ) {
    return saveProgress(playerId, achievement);
  }

  Future<void> recordRewardTransaction(
    String playerId,
    AchievementRewardTransaction transaction,
  ) async {
    final ledger = await load(playerId);
    await save(
      ledger.copyWith(
        rewardTransactions: {
          ...ledger.rewardTransactions,
          transaction.transactionId: transaction,
        },
      ),
    );
  }

  Future<void> reconcileExistingProgress(
    String playerId,
    int reconciliationVersion,
  ) async {
    final ledger = await load(playerId);
    await save(ledger.copyWith(reconciliationVersion: reconciliationVersion));
  }

  Future<PlayerAchievement?> inspectUnlockState(
    String playerId,
    String achievementId,
  ) async {
    return (await load(playerId)).achievements[achievementId];
  }

  Future<({int unlocked, int total})> calculateCategoryCompletion(
    String playerId,
    AchievementCategory category,
  ) async {
    final ledger = await load(playerId);
    final definitions = AchievementCatalogV1.definitions
        .where((definition) => definition.category == category)
        .toList(growable: false);
    final unlocked = definitions
        .where(
          (definition) =>
              ledger.achievements[definition.achievementId]?.isUnlocked == true,
        )
        .length;
    return (unlocked: unlocked, total: definitions.length);
  }
}
