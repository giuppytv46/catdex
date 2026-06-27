import 'package:catdex/features/catdex/domain/entities/player_progress.dart';

class HomeDashboard {
  const HomeDashboard({
    required this.playerName,
    required this.playerProgress,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.pawPoints,
    required this.dailyMissions,
    required this.recentDiscoveries,
    required this.currentEvent,
  });

  final String playerName;
  final PlayerProgress playerProgress;
  final int currentLevelXp;
  final int nextLevelXp;
  final int pawPoints;
  final List<DailyMission> dailyMissions;
  final List<RecentDiscovery> recentDiscoveries;
  final CurrentEvent currentEvent;

  double get xpProgress {
    final levelRange = nextLevelXp - currentLevelXp;
    if (levelRange <= 0) {
      return 1;
    }

    final earnedInLevel = playerProgress.totalXp - currentLevelXp;
    return (earnedInLevel / levelRange).clamp(0, 1);
  }
}

class DailyMission {
  const DailyMission({
    required this.titleKey,
    required this.progress,
    required this.goal,
    required this.xpReward,
    required this.completed,
  });

  final DailyMissionTitleKey titleKey;
  final int progress;
  final int goal;
  final int xpReward;
  final bool completed;
}

enum DailyMissionTitleKey {
  discoverOneCat,
  importOnePhoto,
  visitYourCatDex,
}

class RecentDiscovery {
  const RecentDiscovery({
    required this.catName,
    required this.speciesName,
    required this.rarityName,
    required this.variantName,
    required this.location,
    required this.xpReward,
  });

  final String catName;
  final String speciesName;
  final String rarityName;
  final String variantName;
  final String location;
  final int xpReward;
}

class CurrentEvent {
  const CurrentEvent({
    required this.title,
    required this.dateRange,
    required this.badgeName,
  });

  final String title;
  final String dateRange;
  final String badgeName;
}
