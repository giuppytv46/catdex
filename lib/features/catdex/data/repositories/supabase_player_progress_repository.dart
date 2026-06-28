import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePlayerProgressRepository implements PlayerProgressRepository {
  const SupabasePlayerProgressRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PlayerProgress> getProgress(String playerId) async {
    final profileRow = await _client
        .from('profiles')
        .select()
        .eq('id', playerId)
        .maybeSingle();

    if (profileRow == null) {
      return PlayerProgress.empty(playerId);
    }

    final achievementRows = await _client
        .from('user_achievements')
        .select('achievement_id')
        .eq('user_id', playerId);
    final badgeRows = await _client
        .from('user_badges')
        .select('badge_id')
        .eq('user_id', playerId);

    return mapProgress(
      profileRow,
      achievementRows: achievementRows,
      badgeRows: badgeRows,
    );
  }

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    await _client.from('profiles').upsert(toProfileRow(progress));

    if (progress.achievementIds.isNotEmpty) {
      await _client
          .from('user_achievements')
          .upsert(
            progress.achievementIds
                .map((id) {
                  return {
                    'user_id': progress.playerId,
                    'achievement_id': id,
                  };
                })
                .toList(growable: false),
          );
    }

    if (progress.badgeIds.isNotEmpty) {
      await _client
          .from('user_badges')
          .upsert(
            progress.badgeIds
                .map((id) {
                  return {
                    'user_id': progress.playerId,
                    'badge_id': id,
                  };
                })
                .toList(growable: false),
          );
    }
  }

  static PlayerProgress mapProgress(
    Map<String, dynamic> profileRow, {
    List<dynamic> achievementRows = const [],
    List<dynamic> badgeRows = const [],
  }) {
    return PlayerProgress(
      playerId: profileRow['id'] as String,
      totalXp: profileRow['xp'] as int? ?? 0,
      level: profileRow['level'] as int? ?? 1,
      coins: profileRow['coins'] as int? ?? 0,
      discoveryCount: profileRow['discovery_count'] as int? ?? 0,
      duplicateDiscoveryCount:
          profileRow['duplicate_discovery_count'] as int? ?? 0,
      achievementIds: achievementRows
          .cast<Map<String, dynamic>>()
          .map((row) => row['achievement_id'] as String)
          .toList(growable: false),
      badgeIds: badgeRows
          .cast<Map<String, dynamic>>()
          .map((row) => row['badge_id'] as String)
          .toList(growable: false),
    );
  }

  static Map<String, Object?> toProfileRow(PlayerProgress progress) {
    return {
      'id': progress.playerId,
      'xp': progress.totalXp,
      'level': progress.level,
      'coins': progress.coins,
      'discovery_count': progress.discoveryCount,
      'duplicate_discovery_count': progress.duplicateDiscoveryCount,
    };
  }
}
