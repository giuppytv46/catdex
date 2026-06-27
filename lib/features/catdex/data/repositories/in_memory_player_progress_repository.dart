import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';

class InMemoryPlayerProgressRepository implements PlayerProgressRepository {
  InMemoryPlayerProgressRepository({
    List<PlayerProgress> progress = const [],
  }) : _progressByPlayerId = {
         for (final item in progress) item.playerId: item,
       };

  final Map<String, PlayerProgress> _progressByPlayerId;

  @override
  Future<PlayerProgress> getProgress(String playerId) async {
    return _progressByPlayerId[playerId] ?? PlayerProgress.empty(playerId);
  }

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    _progressByPlayerId[progress.playerId] = progress;
  }
}
