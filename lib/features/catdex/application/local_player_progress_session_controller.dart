import 'dart:async';

import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localPlayerProgressSessionProvider =
    NotifierProvider<LocalPlayerProgressSessionController, PlayerProgress>(
      LocalPlayerProgressSessionController.new,
    );

class LocalPlayerProgressSessionController extends Notifier<PlayerProgress> {
  int _restoreRevision = 0;

  @override
  PlayerProgress build() {
    final activeSession = ref.watch(activeCatDexSessionProvider);
    final initial = activeSession.playerId == LocalPlayerSession.playerId
        ? LocalPlayerSession.initialProgress
        : PlayerProgress.empty(activeSession.playerId);
    final repository = ref.watch(playerProgressRepositoryProvider);
    final revision = ++_restoreRevision;
    unawaited(
      Future<void>.microtask(
        () => _restoreProgress(
          playerId: activeSession.playerId,
          initial: initial,
          repository: repository,
          revision: revision,
        ),
      ),
    );
    return initial;
  }

  PlayerProgress get progress => state;

  set progress(PlayerProgress progress) {
    state = progress;
  }

  Future<void> _restoreProgress({
    required String playerId,
    required PlayerProgress initial,
    required PlayerProgressRepository repository,
    required int revision,
  }) async {
    try {
      final restored = await repository.getProgress(playerId);
      if (!ref.mounted || revision != _restoreRevision) {
        return;
      }
      state = restored;
      debugPrint(
        'CATDEX_RESTORE_PROGRESS_COMPLETED '
        'playerId=$playerId xp=${restored.totalXp} level=${restored.level}',
      );
    } on Object catch (error) {
      if (!ref.mounted || revision != _restoreRevision) {
        return;
      }
      state = initial;
      debugPrint(
        'CATDEX_RESTORE_PROGRESS_FAILED '
        'playerId=$playerId error=${error.runtimeType}',
      );
    }
  }
}
