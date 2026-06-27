import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward_calculator.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:catdex/features/home/domain/entities/home_dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeControllerProvider = NotifierProvider<HomeController, HomeDashboard>(
  HomeController.new,
);

class HomeController extends Notifier<HomeDashboard> {
  static const _playerTotalXp = 1860;
  static const _pawPoints = 420;

  final _levelCalculator = const LevelCalculator();
  final _rewardCalculator = const DiscoveryRewardCalculator();

  @override
  HomeDashboard build() {
    final localDiscoveries = ref.watch(localDiscoverySessionProvider);
    final level = _levelCalculator.levelForXp(_playerTotalXp);
    final progress = PlayerProgress(
      playerId: 'local-explorer',
      totalXp: _playerTotalXp,
      level: level,
      coins: _pawPoints,
      discoveryCount: 3,
      duplicateDiscoveryCount: 0,
      achievementIds: const [],
      badgeIds: const [],
    );

    return HomeDashboard(
      playerName: 'Explorer',
      playerProgress: progress,
      currentLevelXp: _levelCalculator.xpRequiredForLevel(level),
      nextLevelXp: _levelCalculator.xpRequiredForLevel(level + 1),
      pawPoints: _pawPoints,
      dailyMissions: const [
        DailyMission(
          titleKey: DailyMissionTitleKey.discoverOneCat,
          progress: 1,
          goal: 1,
          xpReward: 100,
          completed: true,
        ),
        DailyMission(
          titleKey: DailyMissionTitleKey.importOnePhoto,
          progress: 0,
          goal: 1,
          xpReward: 75,
          completed: false,
        ),
        DailyMission(
          titleKey: DailyMissionTitleKey.visitYourCatDex,
          progress: 0,
          goal: 1,
          xpReward: 50,
          completed: false,
        ),
      ],
      recentDiscoveries: localDiscoveries.isEmpty
          ? _mockRecentDiscoveries()
          : localDiscoveries.take(3).map(_recentLocalDiscovery).toList(),
      currentEvent: const CurrentEvent(
        title: 'Summer Paw Festival',
        dateRange: 'Event dates placeholder',
        badgeName: 'Sun Paw Badge',
      ),
    );
  }

  List<RecentDiscovery> _mockRecentDiscoveries() {
    return [
      _recentDiscovery(
        catName: 'Mochi',
        speciesId: 'maine_coon',
        variantId: 'shiny',
        rarity: CatRarity.rare,
        location: 'Location placeholder',
      ),
      _recentDiscovery(
        catName: 'Luna',
        speciesId: 'domestic_black_cat',
        variantId: 'midnight',
        rarity: CatRarity.common,
        location: 'Location placeholder',
      ),
      _recentDiscovery(
        catName: 'Pixel',
        speciesId: 'siamese',
        variantId: 'normal',
        rarity: CatRarity.uncommon,
        location: 'Location placeholder',
      ),
    ];
  }

  RecentDiscovery _recentLocalDiscovery(CatDiscovery discovery) {
    return _recentDiscovery(
      catName: discovery.nickname ?? 'Mochi',
      speciesId: discovery.speciesId,
      variantId: discovery.variantId,
      rarity: discovery.rarity,
      location: _locationLabel(discovery),
    );
  }

  RecentDiscovery _recentDiscovery({
    required String catName,
    required String speciesId,
    required String variantId,
    required CatRarity rarity,
    required String location,
  }) {
    final species = _speciesById(speciesId);
    final variant = _variantById(variantId);

    return RecentDiscovery(
      catName: catName,
      speciesName: species.displayName,
      rarityName: _rarityName(rarity),
      variantName: variant.name,
      location: location,
      xpReward: _rewardCalculator.xpForDiscovery(
        species: species,
        variant: variant,
        rarity: rarity,
        duplicate: false,
      ),
    );
  }

  CatSpecies _speciesById(String id) {
    return CatDexSeedData.species.firstWhere((species) => species.id == id);
  }

  CatVariant _variantById(String id) {
    return CatDexSeedData.variants.firstWhere((variant) => variant.id == id);
  }

  String _rarityName(CatRarity rarity) {
    return switch (rarity) {
      CatRarity.common => 'Common',
      CatRarity.uncommon => 'Uncommon',
      CatRarity.rare => 'Rare',
      CatRarity.epic => 'Epic',
      CatRarity.legendary => 'Legendary',
      CatRarity.mythic => 'Mythic',
    };
  }

  String _locationLabel(CatDiscovery discovery) {
    final city = discovery.city;
    final country = discovery.country;
    if (city != null && country != null) {
      return '$city, $country';
    }

    return 'Location placeholder';
  }
}
