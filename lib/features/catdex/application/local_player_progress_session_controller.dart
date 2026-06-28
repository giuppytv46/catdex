import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localPlayerProgressSessionProvider =
    NotifierProvider<LocalPlayerProgressSessionController, PlayerProgress>(
      LocalPlayerProgressSessionController.new,
    );

class LocalPlayerProgressSessionController extends Notifier<PlayerProgress> {
  @override
  PlayerProgress build() {
    return LocalPlayerSession.initialProgress;
  }

  PlayerProgress get progress => state;

  set progress(PlayerProgress progress) {
    state = progress;
  }
}
