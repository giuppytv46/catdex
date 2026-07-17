import 'package:catdex/features/cards/presentation/reveal/card_reveal_controller.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cardRevealRewardCueProvider =
    NotifierProvider<
      CardRevealRewardCueController,
      Map<String, CardRevealRewardCue>
    >(CardRevealRewardCueController.new);

class CardRevealRewardCueController
    extends Notifier<Map<String, CardRevealRewardCue>> {
  @override
  Map<String, CardRevealRewardCue> build() => const {};

  void queue(String discoveryId, CardRevealRewardCue cue) {
    final existing = state[discoveryId];
    final next = existing == null ? cue : existing.merge(cue);
    if (existing == next) return;
    state = {...state, discoveryId: next};
  }

  void consume(String discoveryId, String cueId) {
    if (state[discoveryId]?.id != cueId) return;
    final next = Map<String, CardRevealRewardCue>.of(state)
      ..remove(discoveryId);
    state = next;
  }

  void attachLevelUp(int newLevel) {
    if (state.isEmpty) return;
    final entry = state.entries.last;
    final cue = entry.value;
    state = {
      ...state,
      entry.key: CardRevealRewardCue(
        id: cue.id,
        missionCompleted: cue.missionCompleted,
        xp: cue.xp,
        earnedXp: cue.earnedXp,
        newLevel: newLevel,
      ),
    };
  }
}

void attachCardRevealMissionBridge(WidgetRef ref) {
  ref
    ..listenManual<AsyncValue<DailyMissionLedger>>(
      dailyMissionControllerProvider,
      (previous, next) {
        final before = previous?.value;
        final after = next.value;
        if (before == null || after == null) return;

        final completedBefore = {
          for (final mission in before.missions)
            if (mission.status == DailyMissionStatus.completed ||
                mission.status == DailyMissionStatus.claimed)
              mission.missionId,
        };
        final newlyCompleted = after.missions
            .where(
              (mission) =>
                  !completedBefore.contains(mission.missionId) &&
                  (mission.status == DailyMissionStatus.completed ||
                      mission.status == DailyMissionStatus.claimed),
            )
            .toList(growable: false);
        if (newlyCompleted.isEmpty) return;

        final newOperations = after.processedOperationIds.difference(
          before.processedOperationIds,
        );
        final discoveryId = newOperations
            .map(_discoveryIdFromCardOperation)
            .whereType<String>()
            .firstOrNull;
        if (discoveryId == null) return;

        final xp = newlyCompleted
            .where((mission) => mission.rewardType == DailyMissionRewardType.xp)
            .fold<int>(0, (total, mission) => total + mission.rewardAmount);
        final cueId = newlyCompleted
            .map(
              (mission) =>
                  '${mission.missionId}:'
                  '${mission.completedAt?.toIso8601String() ?? '-'}',
            )
            .join('|');
        _afterBuild(ref, () {
          ref
              .read(cardRevealRewardCueProvider.notifier)
              .queue(
                discoveryId,
                CardRevealRewardCue(
                  id: cueId,
                  missionCompleted: true,
                  xp: xp,
                ),
              );
        });
      },
    )
    ..listenManual(
      localPlayerProgressSessionProvider,
      (previous, next) {
        if (previous == null || next.level <= previous.level) return;
        _afterBuild(ref, () {
          ref
              .read(cardRevealRewardCueProvider.notifier)
              .attachLevelUp(next.level);
        });
      },
    );
}

void _afterBuild(WidgetRef ref, VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!ref.context.mounted) return;
    callback();
  });
}

String? _discoveryIdFromCardOperation(String operationId) {
  if (operationId.startsWith('normal:')) {
    final value = operationId.substring('normal:'.length).trim();
    return value.isEmpty ? null : value;
  }
  if (operationId.startsWith('event:')) {
    final parts = operationId.split(':');
    if (parts.length >= 2 && parts[1].trim().isNotEmpty) return parts[1];
  }
  return null;
}
