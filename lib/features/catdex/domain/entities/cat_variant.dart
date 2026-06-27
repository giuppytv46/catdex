class CatVariant {
  const CatVariant({
    required this.id,
    required this.name,
    required this.rewardMultiplier,
    required this.xpBonus,
    required this.requiresEvent,
  }) : assert(rewardMultiplier >= 1, 'rewardMultiplier must be at least 1'),
       assert(xpBonus >= 0, 'xpBonus cannot be negative');

  final String id;
  final String name;
  final double rewardMultiplier;
  final int xpBonus;
  final bool requiresEvent;
}
