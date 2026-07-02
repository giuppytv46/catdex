class CatDisplayData {
  const CatDisplayData({
    required this.displayName,
    required this.displaySpecies,
    required this.displayCoatColor,
    required this.displayCoatPattern,
    required this.displayEyeColor,
    required this.displayHairLength,
    required this.displayAge,
    required this.displayPersonality,
    required this.displayRarity,
    required this.displayVariant,
    required this.displayStory,
    required this.displayFunFact,
  });

  final String displayName;
  final String displaySpecies;
  final String displayCoatColor;
  final String displayCoatPattern;
  final String displayEyeColor;
  final String displayHairLength;
  final String displayAge;
  final String displayPersonality;
  final String displayRarity;
  final String displayVariant;
  final String displayStory;
  final String displayFunFact;

  Map<String, Object?> toDebugJson() {
    return {
      'displayName': displayName,
      'displaySpecies': displaySpecies,
      'displayCoatColor': displayCoatColor,
      'displayCoatPattern': displayCoatPattern,
      'displayEyeColor': displayEyeColor,
      'displayHairLength': displayHairLength,
      'displayAge': displayAge,
      'displayPersonality': displayPersonality,
      'displayRarity': displayRarity,
      'displayVariant': displayVariant,
      'displayStory': displayStory,
      'displayFunFact': displayFunFact,
    };
  }
}
