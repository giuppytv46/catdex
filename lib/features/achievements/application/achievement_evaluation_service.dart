import 'dart:math' as math;

import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_facts.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/domain/achievement_repository.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:flutter/foundation.dart';

@immutable
class AchievementEvaluationResult {
  const AchievementEvaluationResult({
    required this.ledger,
    required this.unlocks,
    required this.wasHistoricalReconciliation,
  });

  final AchievementLedger ledger;
  final List<AchievementUnlockResult> unlocks;
  final bool wasHistoricalReconciliation;
}

class AchievementEvaluationService {
  AchievementEvaluationService({
    required AchievementRepository achievementRepository,
    required PlayerProgressRepository localProgressRepository,
    required PlayerProgressRepository canonicalProgressRepository,
    required LevelCalculator levelCalculator,
    required PlayerProgress Function() currentSessionProgress,
    required ValueChanged<PlayerProgress> updateSessionProgress,
    DateTime Function()? clock,
  }) : _achievementRepository = achievementRepository,
       _localProgressRepository = localProgressRepository,
       _canonicalProgressRepository = canonicalProgressRepository,
       _levelCalculator = levelCalculator,
       _currentSessionProgress = currentSessionProgress,
       _updateSessionProgress = updateSessionProgress,
       _clock = clock ?? DateTime.now;

  final AchievementRepository _achievementRepository;
  final PlayerProgressRepository _localProgressRepository;
  final PlayerProgressRepository _canonicalProgressRepository;
  final LevelCalculator _levelCalculator;
  final PlayerProgress Function() _currentSessionProgress;
  final ValueChanged<PlayerProgress> _updateSessionProgress;
  final DateTime Function() _clock;

  Future<AchievementEvaluationResult> evaluate({
    required String playerId,
    required AchievementFacts facts,
    required String source,
  }) async {
    debugPrint('CATDEX_ACHIEVEMENT_EVALUATION_STARTED source=$source');
    var ledger = await _achievementRepository.load(playerId);
    final historical =
        ledger.reconciliationVersion <
        AchievementLedger.currentReconciliationVersion;
    if (historical) {
      debugPrint('CATDEX_ACHIEVEMENT_RECONCILIATION_STARTED');
    }

    final now = _clock().toUtc();
    final updatedAchievements = <String, PlayerAchievement>{
      ...ledger.achievements,
    };
    for (final definition in AchievementCatalogV1.definitions) {
      final previous =
          updatedAchievements[definition.achievementId] ??
          PlayerAchievement.initial(definition);
      final current = facts
          .valueFor(definition.metric)
          .clamp(
            0,
            definition.targetValue,
          );
      final status = previous.isUnlocked
          ? PlayerAchievementStatus.unlocked
          : current > 0
          ? PlayerAchievementStatus.inProgress
          : PlayerAchievementStatus.locked;
      updatedAchievements[definition.achievementId] = previous.copyWith(
        currentValue: current,
        targetValue: definition.targetValue,
        status: status,
        lastEvaluatedAt: now,
      );
      if (current != previous.currentValue) {
        debugPrint(
          'CATDEX_ACHIEVEMENT_PROGRESS_UPDATED '
          'id=${definition.achievementId} '
          'progress=$current/${definition.targetValue}',
        );
      }
    }
    ledger = ledger.copyWith(achievements: updatedAchievements);
    await _achievementRepository.save(ledger);

    final unlocks = <AchievementUnlockResult>[];
    for (final definition in AchievementCatalogV1.definitions) {
      final achievement = ledger.achievements[definition.achievementId]!;
      if (!achievement.isUnlocked &&
          achievement.currentValue >= achievement.targetValue) {
        final unlock = await _unlock(
          playerId: playerId,
          definition: definition,
        );
        ledger = await _achievementRepository.load(playerId);
        if (!unlock.wasAlreadyUnlocked) unlocks.add(unlock);
      }
    }

    if (historical) {
      ledger = ledger.copyWith(
        reconciliationVersion: AchievementLedger.currentReconciliationVersion,
      );
      await _achievementRepository.save(ledger);
      debugPrint(
        'CATDEX_ACHIEVEMENT_RECONCILIATION_COMPLETED '
        'unlocked=${unlocks.length}',
      );
    }
    return AchievementEvaluationResult(
      ledger: ledger,
      unlocks: List.unmodifiable(unlocks),
      wasHistoricalReconciliation: historical,
    );
  }

  Future<AchievementUnlockResult> _unlock({
    required String playerId,
    required AchievementDefinition definition,
  }) async {
    debugPrint(
      'CATDEX_ACHIEVEMENT_UNLOCK_STARTED id=${definition.achievementId}',
    );
    var ledger = await _achievementRepository.load(playerId);
    final currentAchievement =
        ledger.achievements[definition.achievementId] ??
        PlayerAchievement.initial(definition);
    final transactionId = achievementRewardTransactionId(
      definition.achievementId,
    );
    final existingTransaction = ledger.rewardTransactions[transactionId];
    if (existingTransaction != null &&
        existingTransaction.status ==
            AchievementRewardTransactionStatus.completed) {
      if (!currentAchievement.isUnlocked) {
        final repaired = currentAchievement.copyWith(
          status: PlayerAchievementStatus.unlocked,
          unlockedAt:
              currentAchievement.unlockedAt ?? existingTransaction.updatedAt,
          rewardTransactionId: transactionId,
          rewardGrantedAt: existingTransaction.updatedAt,
        );
        ledger = ledger.copyWith(
          achievements: {
            ...ledger.achievements,
            definition.achievementId: repaired,
          },
        );
        await _achievementRepository.save(ledger);
      }
      debugPrint(
        'CATDEX_ACHIEVEMENT_REWARD_DUPLICATE_SKIPPED '
        'id=${definition.achievementId}',
      );
      return _resultFromTransaction(
        existingTransaction,
        wasAlreadyUnlocked: true,
      );
    }

    final progress = await _bestProgress(playerId);
    final now = _clock().toUtc();
    final transaction =
        existingTransaction ??
        AchievementRewardTransaction(
          transactionId: transactionId,
          achievementId: definition.achievementId,
          playerId: playerId,
          rewardXp: definition.rewardXp,
          previousXp: progress.totalXp,
          updatedXp: progress.totalXp + definition.rewardXp,
          previousLevel: progress.level,
          updatedLevel: _levelCalculator.levelForXp(
            progress.totalXp + definition.rewardXp,
          ),
          status: AchievementRewardTransactionStatus.started,
          createdAt: now,
          updatedAt: now,
        );
    ledger = ledger.copyWith(
      rewardTransactions: {
        ...ledger.rewardTransactions,
        transactionId: transaction,
      },
    );
    await _achievementRepository.save(ledger);

    final latest = await _bestProgress(playerId);
    final targetXp = math.max(latest.totalXp, transaction.updatedXp);
    final achievementIds = <String>{
      ...latest.achievementIds,
      definition.achievementId,
    }.toList(growable: false);
    final badgeIds = <String>{
      ...latest.badgeIds,
      definition.achievementId,
    }.toList(growable: false);
    final updatedProgress = latest.copyWith(
      totalXp: targetXp,
      level: _levelCalculator.levelForXp(targetXp),
      achievementIds: achievementIds,
      badgeIds: badgeIds,
    );
    await _localProgressRepository.saveProgress(updatedProgress);
    final localReadBack = await _localProgressRepository.getProgress(playerId);
    if (localReadBack.totalXp < transaction.updatedXp) {
      throw StateError('achievement_reward_local_readback_failed');
    }
    try {
      await _canonicalProgressRepository.saveProgress(localReadBack);
    } on Object catch (error) {
      debugPrint(
        'CATDEX_ACHIEVEMENT_REWARD_REMOTE_SYNC_DEFERRED '
        'reason=${error.runtimeType}',
      );
    }
    _updateSessionProgress(localReadBack);

    ledger = await _achievementRepository.load(playerId);
    final completedAt = _clock().toUtc();
    final completedTransaction = transaction.copyWith(
      updatedXp: localReadBack.totalXp,
      updatedLevel: localReadBack.level,
      status: AchievementRewardTransactionStatus.completed,
      updatedAt: completedAt,
    );
    final completedAchievement =
        (ledger.achievements[definition.achievementId] ?? currentAchievement)
            .copyWith(
              status: PlayerAchievementStatus.unlocked,
              unlockedAt: completedAt,
              rewardTransactionId: transactionId,
              rewardGrantedAt: completedAt,
            );
    ledger = ledger.copyWith(
      achievements: {
        ...ledger.achievements,
        definition.achievementId: completedAchievement,
      },
      rewardTransactions: {
        ...ledger.rewardTransactions,
        transactionId: completedTransaction,
      },
    );
    await _achievementRepository.save(ledger);
    debugPrint(
      'CATDEX_ACHIEVEMENT_REWARD_GRANTED '
      'id=${definition.achievementId} xp=${definition.rewardXp}',
    );
    debugPrint(
      'CATDEX_ACHIEVEMENT_UNLOCK_COMPLETED id=${definition.achievementId}',
    );
    return _resultFromTransaction(
      completedTransaction,
      wasAlreadyUnlocked: false,
    );
  }

  AchievementUnlockResult _resultFromTransaction(
    AchievementRewardTransaction transaction, {
    required bool wasAlreadyUnlocked,
  }) {
    return AchievementUnlockResult(
      achievementId: transaction.achievementId,
      rewardXp: transaction.rewardXp,
      previousXp: transaction.previousXp,
      updatedXp: transaction.updatedXp,
      previousLevel: transaction.previousLevel,
      updatedLevel: transaction.updatedLevel,
      rewardTransactionId: transaction.transactionId,
      wasAlreadyUnlocked: wasAlreadyUnlocked,
    );
  }

  Future<PlayerProgress> _bestProgress(String playerId) async {
    final session = _currentSessionProgress();
    final local = await _localProgressRepository.getProgress(playerId);
    PlayerProgress? canonical;
    try {
      canonical = await _canonicalProgressRepository.getProgress(playerId);
    } on Object {
      canonical = null;
    }
    final totalXp = math.max(
      session.playerId == playerId ? session.totalXp : 0,
      math.max(local.totalXp, canonical?.totalXp ?? 0),
    );
    final base = canonical?.totalXp == totalXp
        ? canonical!
        : local.totalXp == totalXp
        ? local
        : session.playerId == playerId
        ? session
        : local;
    return base.copyWith(
      totalXp: totalXp,
      level: _levelCalculator.levelForXp(totalXp),
    );
  }
}
