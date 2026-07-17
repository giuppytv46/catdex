import 'dart:async';

import 'package:catdex/features/achievements/application/achievement_evaluation_service.dart';
import 'package:catdex/features/achievements/data/shared_preferences_achievement_repository.dart';
import 'package:catdex/features/achievements/domain/achievement_facts.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/domain/achievement_repository.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (_) => const SharedPreferencesAchievementRepository(),
);

final achievementEvaluationServiceProvider =
    Provider<AchievementEvaluationService>((ref) {
      final session = ref.watch(activeCatDexSessionProvider);
      return AchievementEvaluationService(
        achievementRepository: ref.watch(achievementRepositoryProvider),
        localProgressRepository: SharedPreferencesPlayerProgressRepository(
          fallbackProgress: session.playerId == LocalPlayerSession.playerId
              ? LocalPlayerSession.initialProgress
              : null,
        ),
        canonicalProgressRepository: ref.watch(
          playerProgressRepositoryProvider,
        ),
        levelCalculator: ref.watch(levelCalculatorProvider),
        currentSessionProgress: () => ref.read(
          localPlayerProgressSessionProvider,
        ),
        updateSessionProgress: (progress) {
          ref.read(localPlayerProgressSessionProvider.notifier).progress =
              progress;
        },
      );
    });

@immutable
class AchievementControllerState {
  const AchievementControllerState({
    required this.ledger,
    required this.lastUnlocks,
    required this.lastEvaluationWasHistorical,
    required this.evaluationRevision,
    required this.isEvaluating,
  });

  factory AchievementControllerState.initial(AchievementLedger ledger) {
    return AchievementControllerState(
      ledger: ledger,
      lastUnlocks: const [],
      lastEvaluationWasHistorical: false,
      evaluationRevision: 0,
      isEvaluating: false,
    );
  }

  final AchievementLedger ledger;
  final List<AchievementUnlockResult> lastUnlocks;
  final bool lastEvaluationWasHistorical;
  final int evaluationRevision;
  final bool isEvaluating;

  AchievementControllerState copyWith({
    AchievementLedger? ledger,
    List<AchievementUnlockResult>? lastUnlocks,
    bool? lastEvaluationWasHistorical,
    int? evaluationRevision,
    bool? isEvaluating,
  }) {
    return AchievementControllerState(
      ledger: ledger ?? this.ledger,
      lastUnlocks: lastUnlocks ?? this.lastUnlocks,
      lastEvaluationWasHistorical:
          lastEvaluationWasHistorical ?? this.lastEvaluationWasHistorical,
      evaluationRevision: evaluationRevision ?? this.evaluationRevision,
      isEvaluating: isEvaluating ?? this.isEvaluating,
    );
  }
}

final achievementControllerProvider =
    AsyncNotifierProvider<AchievementController, AchievementControllerState>(
      AchievementController.new,
    );

class AchievementController extends AsyncNotifier<AchievementControllerState> {
  Future<void> _tail = Future<void>.value();

  @override
  Future<AchievementControllerState> build() async {
    final playerId = ref.watch(activeCatDexSessionProvider).playerId;
    debugPrint('CATDEX_ACHIEVEMENTS_LOAD_STARTED');
    final ledger = await ref
        .watch(achievementRepositoryProvider)
        .load(playerId);
    debugPrint(
      'CATDEX_ACHIEVEMENTS_LOAD_COMPLETED count=${ledger.achievements.length}',
    );
    return AchievementControllerState.initial(ledger);
  }

  Future<AchievementEvaluationResult> evaluate({required String source}) {
    final completer = Completer<AchievementEvaluationResult>();
    final operation = _tail.then((_) async {
      try {
        final result = await _performEvaluation(source);
        completer.complete(result);
      } on Object catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        rethrow;
      }
    });
    _tail = operation.catchError((Object error, StackTrace stackTrace) {
      debugPrint(
        'CATDEX_ACHIEVEMENT_EVALUATION_FAILED reason=${error.runtimeType}',
      );
    });
    return completer.future;
  }

  Future<AchievementEvaluationResult> _performEvaluation(String source) async {
    final current = state.value ?? await future;
    if (ref.mounted) {
      state = AsyncData(current.copyWith(isEvaluating: true));
    }
    final session = ref.read(activeCatDexSessionProvider);
    final playerId = session.playerId;
    final discoveries = await ref
        .read(discoveryRepositoryProvider)
        .getDiscoveriesForPlayer(playerId);
    final cards = await ref.read(catCardRepositoryProvider).getAllCards();
    final missionLedger = await ref
        .read(dailyMissionRepositoryProvider)
        .load(playerId);
    final localProgressRepository = SharedPreferencesPlayerProgressRepository(
      fallbackProgress: playerId == LocalPlayerSession.playerId
          ? LocalPlayerSession.initialProgress
          : null,
    );
    final progress = await _loadProgressWithOfflineFallback(
      playerId: playerId,
      localRepository: localProgressRepository,
    );
    final facts = AchievementFacts.fromPersistedData(
      discoveries: discoveries,
      cards: cards.where((card) => card.ownerId == playerId),
      missionLedger: missionLedger,
      playerLevel: progress.level,
    );
    final result = await ref
        .read(achievementEvaluationServiceProvider)
        .evaluate(playerId: playerId, facts: facts, source: source);
    if (ref.mounted) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          ledger: result.ledger,
          lastUnlocks: result.unlocks,
          lastEvaluationWasHistorical: result.wasHistoricalReconciliation,
          evaluationRevision: latest.evaluationRevision + 1,
          isEvaluating: false,
        ),
      );
    }
    return result;
  }

  Future<PlayerProgress> _loadProgressWithOfflineFallback({
    required String playerId,
    required SharedPreferencesPlayerProgressRepository localRepository,
  }) async {
    try {
      return await ref
          .read(playerProgressRepositoryProvider)
          .getProgress(playerId);
    } on Object catch (error) {
      debugPrint(
        'CATDEX_ACHIEVEMENT_PROGRESS_OFFLINE_FALLBACK '
        'reason=${error.runtimeType}',
      );
      return localRepository.getProgress(playerId);
    }
  }

  Future<void> refresh() async {
    final current = state.value ?? await future;
    final playerId = ref.read(activeCatDexSessionProvider).playerId;
    final ledger = await ref.read(achievementRepositoryProvider).load(playerId);
    if (ref.mounted) state = AsyncData(current.copyWith(ledger: ledger));
  }

  Future<void> resetDebugState() async {
    final current = state.value ?? await future;
    final playerId = ref.read(activeCatDexSessionProvider).playerId;
    final ledger = AchievementLedger.empty(playerId);
    await ref.read(achievementRepositoryProvider).save(ledger);
    if (ref.mounted) {
      state = AsyncData(
        current.copyWith(
          ledger: ledger,
          lastUnlocks: const [],
          lastEvaluationWasHistorical: false,
          evaluationRevision: current.evaluationRevision + 1,
          isEvaluating: false,
        ),
      );
    }
  }
}
