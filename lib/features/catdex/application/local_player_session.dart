import 'package:catdex/features/catdex/domain/entities/player_progress.dart';

class LocalPlayerSession {
  const LocalPlayerSession._();

  static const playerId = 'local-explorer';
  static const initialTotalXp = 1860;
  static const initialLevel = 6;
  static const initialCoins = 420;
  static const initialDiscoveryCount = 3;

  static const initialProgress = PlayerProgress(
    playerId: playerId,
    totalXp: initialTotalXp,
    level: initialLevel,
    coins: initialCoins,
    discoveryCount: initialDiscoveryCount,
    duplicateDiscoveryCount: 0,
    achievementIds: [],
    badgeIds: [],
  );
}
