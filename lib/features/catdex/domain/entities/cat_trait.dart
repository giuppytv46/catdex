class CatTrait {
  const CatTrait({
    required this.name,
    required this.value,
    this.rarityWeight = 1,
  }) : assert(rarityWeight >= 1, 'rarityWeight must be at least 1');

  final String name;
  final String value;
  final double rarityWeight;
}
