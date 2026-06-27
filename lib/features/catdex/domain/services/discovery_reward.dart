class DiscoveryReward {
  const DiscoveryReward({
    required this.xp,
    required this.coins,
    required this.friendshipPoints,
    required this.duplicate,
  }) : assert(xp >= 0, 'xp cannot be negative'),
       assert(coins >= 0, 'coins cannot be negative'),
       assert(
         friendshipPoints >= 0,
         'friendshipPoints cannot be negative',
       );

  final int xp;
  final int coins;
  final int friendshipPoints;
  final bool duplicate;
}
