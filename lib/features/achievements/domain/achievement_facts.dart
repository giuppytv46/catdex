import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';

class AchievementFacts {
  const AchievementFacts({
    required this.discoveryCount,
    required this.normalCardCount,
    required this.discoveryCountsByRarity,
    required this.geolocatedDiscoveryCount,
    required this.claimedDailyMissionCount,
    required this.eventCardCount,
    required this.halloweenFreeVariantCount,
    required this.halloweenPremiumVariantCount,
    required this.playerLevel,
  });

  factory AchievementFacts.fromPersistedData({
    required Iterable<CatDiscovery> discoveries,
    required Iterable<CatCardRecord> cards,
    required DailyMissionLedger? missionLedger,
    required int playerLevel,
  }) {
    final uniqueDiscoveries = <String, CatDiscovery>{
      for (final discovery in discoveries) discovery.id: discovery,
    }.values;
    final completedCards = <String, CatCardRecord>{
      for (final card in cards.where((card) => card.isCompleted))
        card.logicalIdentity: card,
    }.values;
    final completedEventCards = completedCards.where(
      (card) => card.cardType == CatCardType.event,
    );
    final halloweenVariants = completedEventCards
        .where(
          (card) => card.eventKey == AchievementCatalogV1.halloweenEventKey,
        )
        .map((card) => card.eventArtworkVariantId)
        .whereType<String>()
        .toSet();
    final completedMissionTransactions =
        missionLedger?.claimTransactions.values
            .where(
              (transaction) =>
                  transaction.status ==
                  DailyMissionClaimTransactionStatus.completed,
            )
            .map((transaction) => transaction.transactionId)
            .toSet()
            .length ??
        0;

    return AchievementFacts(
      discoveryCount: uniqueDiscoveries.length,
      normalCardCount: completedCards
          .where((card) => card.cardType == CatCardType.normal)
          .length,
      discoveryCountsByRarity: {
        for (final rarity in CatRarity.values)
          rarity: uniqueDiscoveries
              .where((discovery) => discovery.rarity == rarity)
              .length,
      },
      geolocatedDiscoveryCount: uniqueDiscoveries
          .where(
            (discovery) =>
                discovery.captureLocation?.hasValidCoordinates == true,
          )
          .length,
      claimedDailyMissionCount: completedMissionTransactions,
      eventCardCount: completedEventCards.length,
      halloweenFreeVariantCount: halloweenVariants
          .intersection(AchievementCatalogV1.halloweenFreeVariants)
          .length,
      halloweenPremiumVariantCount: halloweenVariants
          .intersection(AchievementCatalogV1.halloweenPremiumVariants)
          .length,
      playerLevel: playerLevel,
    );
  }

  final int discoveryCount;
  final int normalCardCount;
  final Map<CatRarity, int> discoveryCountsByRarity;
  final int geolocatedDiscoveryCount;
  final int claimedDailyMissionCount;
  final int eventCardCount;
  final int halloweenFreeVariantCount;
  final int halloweenPremiumVariantCount;
  final int playerLevel;

  int valueFor(AchievementMetric metric) => switch (metric) {
    AchievementMetric.persistedDiscoveries => discoveryCount,
    AchievementMetric.persistedNormalCards => normalCardCount,
    AchievementMetric.uncommonDiscoveries =>
      discoveryCountsByRarity[CatRarity.uncommon] ?? 0,
    AchievementMetric.rareDiscoveries =>
      discoveryCountsByRarity[CatRarity.rare] ?? 0,
    AchievementMetric.epicDiscoveries =>
      discoveryCountsByRarity[CatRarity.epic] ?? 0,
    AchievementMetric.legendaryDiscoveries =>
      discoveryCountsByRarity[CatRarity.legendary] ?? 0,
    AchievementMetric.geolocatedDiscoveries => geolocatedDiscoveryCount,
    AchievementMetric.claimedDailyMissions => claimedDailyMissionCount,
    AchievementMetric.persistedEventCards => eventCardCount,
    AchievementMetric.halloweenFreeVariants => halloweenFreeVariantCount,
    AchievementMetric.halloweenPremiumVariants => halloweenPremiumVariantCount,
    AchievementMetric.playerLevel => playerLevel,
  };
}
