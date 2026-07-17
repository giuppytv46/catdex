import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/domain/achievement_repository.dart';

class InMemoryAchievementRepository extends AchievementRepository {
  final Map<String, AchievementLedger> _ledgers = {};

  @override
  Future<AchievementLedger> load(String playerId) async {
    return _ledgers[playerId] ?? AchievementLedger.empty(playerId);
  }

  @override
  Future<void> save(AchievementLedger ledger) async {
    _ledgers[ledger.playerId] = AchievementLedger.fromJson(ledger.toJson());
  }
}
