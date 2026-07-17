import 'dart:convert';

import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/domain/achievement_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAchievementRepository extends AchievementRepository {
  const SharedPreferencesAchievementRepository();

  static const _keyPrefix = 'catdex_achievements_v1_';

  @override
  Future<AchievementLedger> load(String playerId) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('$_keyPrefix$playerId');
    if (encoded == null || encoded.trim().isEmpty) {
      return AchievementLedger.empty(playerId);
    }
    try {
      final ledger = AchievementLedger.fromJson(
        Map<String, Object?>.from(jsonDecode(encoded) as Map),
      );
      return ledger.playerId == playerId
          ? ledger
          : AchievementLedger.empty(playerId);
    } on Object catch (error) {
      debugPrint(
        'CATDEX_ACHIEVEMENTS_LOAD_FAILED reason=${error.runtimeType}',
      );
      return AchievementLedger.empty(playerId);
    }
  }

  @override
  Future<void> save(AchievementLedger ledger) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${ledger.playerId}';
    final encoded = jsonEncode(ledger.toJson());
    if (!await preferences.setString(key, encoded)) {
      throw StateError('achievement_ledger_write_failed');
    }
    final readBack = await load(ledger.playerId);
    if (jsonEncode(readBack.toJson()) != encoded) {
      throw StateError('achievement_ledger_readback_failed');
    }
  }
}
