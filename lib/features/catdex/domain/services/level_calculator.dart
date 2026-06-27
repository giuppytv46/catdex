class LevelCalculator {
  const LevelCalculator();

  static const minimumLevel = 1;
  static const maximumLevel = 100;

  int levelForXp(int totalXp) {
    if (totalXp <= 0) {
      return minimumLevel;
    }

    for (var level = maximumLevel; level >= minimumLevel; level -= 1) {
      if (totalXp >= xpRequiredForLevel(level)) {
        return level;
      }
    }

    return minimumLevel;
  }

  int xpRequiredForLevel(int level) {
    final clampedLevel = level.clamp(minimumLevel, maximumLevel);
    final completedLevels = clampedLevel - 1;

    return completedLevels * completedLevels * 100;
  }
}
