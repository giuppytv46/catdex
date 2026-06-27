enum CatRarity {
  common(multiplier: 1, baseXp: 100),
  uncommon(multiplier: 1.25, baseXp: 140),
  rare(multiplier: 1.75, baseXp: 210),
  epic(multiplier: 2.5, baseXp: 320),
  legendary(multiplier: 4, baseXp: 520),
  mythic(multiplier: 6, baseXp: 800);

  const CatRarity({
    required this.multiplier,
    required this.baseXp,
  });

  final double multiplier;
  final int baseXp;
}
