import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';

abstract interface class DailyMissionRepository {
  Future<DailyMissionLedger?> load(String playerId);

  Future<void> save(DailyMissionLedger ledger);
}
