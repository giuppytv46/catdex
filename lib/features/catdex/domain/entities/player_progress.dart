class PlayerProgress {
  const PlayerProgress({
    required this.playerId,
    required this.totalXp,
    required this.level,
    required this.coins,
    required this.discoveryCount,
    required this.duplicateDiscoveryCount,
    required this.achievementIds,
    required this.badgeIds,
  }) : assert(totalXp >= 0, 'totalXp cannot be negative'),
       assert(level >= 1 && level <= 100, 'level must be between 1 and 100'),
       assert(coins >= 0, 'coins cannot be negative'),
       assert(discoveryCount >= 0, 'discoveryCount cannot be negative'),
       assert(
         duplicateDiscoveryCount >= 0,
         'duplicateDiscoveryCount cannot be negative',
       );

  factory PlayerProgress.empty(String playerId) {
    return PlayerProgress(
      playerId: playerId,
      totalXp: 0,
      level: 1,
      coins: 0,
      discoveryCount: 0,
      duplicateDiscoveryCount: 0,
      achievementIds: const [],
      badgeIds: const [],
    );
  }

  final String playerId;
  final int totalXp;
  final int level;
  final int coins;
  final int discoveryCount;
  final int duplicateDiscoveryCount;
  final List<String> achievementIds;
  final List<String> badgeIds;

  PlayerProgress copyWith({
    int? totalXp,
    int? level,
    int? coins,
    int? discoveryCount,
    int? duplicateDiscoveryCount,
    List<String>? achievementIds,
    List<String>? badgeIds,
  }) {
    return PlayerProgress(
      playerId: playerId,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      discoveryCount: discoveryCount ?? this.discoveryCount,
      duplicateDiscoveryCount:
          duplicateDiscoveryCount ?? this.duplicateDiscoveryCount,
      achievementIds: achievementIds ?? this.achievementIds,
      badgeIds: badgeIds ?? this.badgeIds,
    );
  }
}
