import 'dart:convert';

import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:catdex/features/missions/domain/repositories/daily_mission_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDailyMissionRepository
    implements DailyMissionRepository {
  const SharedPreferencesDailyMissionRepository();

  static const _keyPrefix = 'catdex_daily_missions_v1_';

  @override
  Future<DailyMissionLedger?> load(String playerId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_keyPrefix$playerId');
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final json = Map<String, Object?>.from(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final ledger = DailyMissionLedger.fromJson(json);
      return ledger.playerId == playerId ? ledger : null;
    } on Object catch (error) {
      debugPrint(
        'CATDEX_MISSIONS_DAILY_LOAD_FAILED reason=${error.runtimeType}',
      );
      return null;
    }
  }

  @override
  Future<void> save(DailyMissionLedger ledger) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${ledger.playerId}';
    final encoded = jsonEncode(ledger.toJson());
    if (!await preferences.setString(key, encoded)) {
      throw StateError('daily_mission_write_failed');
    }
    final readBack = await load(ledger.playerId);
    if (readBack == null || jsonEncode(readBack.toJson()) != encoded) {
      throw StateError('daily_mission_readback_failed');
    }
  }
}
