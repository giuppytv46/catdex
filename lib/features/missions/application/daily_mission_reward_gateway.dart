import 'dart:math' as math;

import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/missions/application/daily_mission_service.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatDexDailyMissionRewardGateway implements DailyMissionRewardGateway {
  const CatDexDailyMissionRewardGateway(this._ref);

  final Ref _ref;

  @override
  Future<int> currentValue(DailyMissionRewardType rewardType) async {
    return switch (rewardType) {
      DailyMissionRewardType.xp => (await _bestProgress()).totalXp,
      DailyMissionRewardType.analysisCredit =>
        (await _ref.read(monetizationServiceProvider).getStatus())
            .extraAnalysisCredits,
      DailyMissionRewardType.cardCredit =>
        (await _ref.read(monetizationServiceProvider).getStatus())
            .extraCardGenerationCredits,
    };
  }

  @override
  Future<void> ensureAtLeast(
    DailyMissionRewardType rewardType,
    int expectedValue,
  ) async {
    switch (rewardType) {
      case DailyMissionRewardType.xp:
        await _ensureXp(expectedValue);
      case DailyMissionRewardType.analysisCredit:
        final service = _ref.read(monetizationServiceProvider);
        final current = (await service.getStatus()).extraAnalysisCredits;
        if (current < expectedValue) {
          await service.addAnalysisCredits(expectedValue - current);
        }
      case DailyMissionRewardType.cardCredit:
        final service = _ref.read(monetizationServiceProvider);
        final current = (await service.getStatus()).extraCardGenerationCredits;
        if (current < expectedValue) {
          await service.addCardGenerationCredits(expectedValue - current);
        }
    }
  }

  Future<void> _ensureXp(int expectedValue) async {
    final progress = await _bestProgress();
    if (progress.totalXp >= expectedValue) return;
    final updated = progress.copyWith(
      totalXp: expectedValue,
      level: _ref.read(levelCalculatorProvider).levelForXp(expectedValue),
    );
    const localRepository = SharedPreferencesPlayerProgressRepository();
    await localRepository.saveProgress(updated);

    try {
      await _ref.read(playerProgressRepositoryProvider).saveProgress(updated);
    } on Object catch (error) {
      debugPrint(
        'CATDEX_MISSION_REWARD_REMOTE_SYNC_DEFERRED '
        'reason=${error.runtimeType}',
      );
    }
    _ref.read(localPlayerProgressSessionProvider.notifier).progress = updated;
    final localReadBack = await localRepository.getProgress(updated.playerId);
    if (localReadBack.totalXp < expectedValue) {
      throw StateError('mission_xp_local_readback_failed');
    }
  }

  Future<PlayerProgress> _bestProgress() async {
    final session = _ref.read(activeCatDexSessionProvider);
    final sessionProgress = _ref.read(localPlayerProgressSessionProvider);
    const localRepository = SharedPreferencesPlayerProgressRepository();
    final local = await localRepository.getProgress(session.playerId);
    PlayerProgress? canonical;
    try {
      canonical = await _ref
          .read(playerProgressRepositoryProvider)
          .getProgress(session.playerId);
    } on Object {
      canonical = null;
    }
    final totalXp = math.max(
      sessionProgress.totalXp,
      math.max(local.totalXp, canonical?.totalXp ?? 0),
    );
    final base = canonical?.totalXp == totalXp
        ? canonical!
        : local.totalXp == totalXp
        ? local
        : sessionProgress;
    return base.copyWith(
      totalXp: totalXp,
      level: _ref.read(levelCalculatorProvider).levelForXp(totalXp),
    );
  }
}
