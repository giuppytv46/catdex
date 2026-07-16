import 'dart:convert';

import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPlayerProgressRepository
    implements PlayerProgressRepository {
  const SharedPreferencesPlayerProgressRepository({
    this.fallbackProgress,
  });

  static const _storageKeyPrefix = 'catdex_player_progress_';

  final PlayerProgress? fallbackProgress;

  @override
  Future<PlayerProgress> getProgress(String playerId) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('$_storageKeyPrefix$playerId');
    if (encoded == null || encoded.trim().isEmpty) {
      return _fallback(playerId);
    }

    try {
      final json = Map<String, Object?>.from(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      return _fromJson(json, expectedPlayerId: playerId);
    } on Object catch (error) {
      debugPrint(
        'CATDEX_RESTORE_PROGRESS_FAILED '
        'playerId=$playerId error=${error.runtimeType}',
      );
      return _fallback(playerId);
    }
  }

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_storageKeyPrefix${progress.playerId}';
    final previous = preferences.getString(key);
    final encoded = jsonEncode(_toJson(progress));
    final written = await preferences.setString(key, encoded);
    if (!written) {
      throw StateError('Player progress write failed: ${progress.playerId}');
    }

    final readBack = await getProgress(progress.playerId);
    if (jsonEncode(_toJson(readBack)) == jsonEncode(_toJson(progress))) {
      return;
    }

    if (previous == null) {
      await preferences.remove(key);
    } else {
      await preferences.setString(key, previous);
    }
    throw StateError(
      'Player progress read-after-write failed: ${progress.playerId}',
    );
  }

  PlayerProgress _fallback(String playerId) {
    final configured = fallbackProgress;
    if (configured != null && configured.playerId == playerId) {
      return configured;
    }
    return PlayerProgress.empty(playerId);
  }

  static Map<String, Object?> _toJson(PlayerProgress progress) {
    return {
      'playerId': progress.playerId,
      'totalXp': progress.totalXp,
      'level': progress.level,
      'coins': progress.coins,
      'discoveryCount': progress.discoveryCount,
      'duplicateDiscoveryCount': progress.duplicateDiscoveryCount,
      'achievementIds': progress.achievementIds,
      'badgeIds': progress.badgeIds,
    };
  }

  static PlayerProgress _fromJson(
    Map<String, Object?> json, {
    required String expectedPlayerId,
  }) {
    final playerId = json['playerId'] as String? ?? expectedPlayerId;
    if (playerId != expectedPlayerId) {
      throw const FormatException('Player progress id mismatch');
    }

    return PlayerProgress(
      playerId: playerId,
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      coins: json['coins'] as int? ?? 0,
      discoveryCount: json['discoveryCount'] as int? ?? 0,
      duplicateDiscoveryCount: json['duplicateDiscoveryCount'] as int? ?? 0,
      achievementIds: _stringList(json['achievementIds']),
      badgeIds: _stringList(json['badgeIds']),
    );
  }

  static List<String> _stringList(Object? value) {
    final values = value as List<dynamic>? ?? const [];
    return values.whereType<String>().toList(growable: false);
  }
}
