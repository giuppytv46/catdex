class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.xpReward,
    required this.hidden,
  }) : assert(xpReward >= 0, 'xpReward cannot be negative');

  final String id;
  final String name;
  final String description;
  final int xpReward;
  final bool hidden;
}
