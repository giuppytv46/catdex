import 'package:catdex/features/catdex/domain/entities/player_progress.dart';

abstract interface class PlayerProgressRepository {
  Future<PlayerProgress> getProgress(String playerId);

  Future<void> saveProgress(PlayerProgress progress);
}
