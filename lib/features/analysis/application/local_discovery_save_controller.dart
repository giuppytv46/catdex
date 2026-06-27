import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/services/cat_discovery_factory.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catDiscoveryFactoryProvider = Provider<CatDiscoveryFactory>((_) {
  return const CatDiscoveryFactory();
});

final localDiscoverySaveControllerProvider =
    AsyncNotifierProvider<
      LocalDiscoverySaveController,
      LocalDiscoverySaveState
    >(LocalDiscoverySaveController.new);

class LocalDiscoverySaveController
    extends AsyncNotifier<LocalDiscoverySaveState> {
  @override
  Future<LocalDiscoverySaveState> build() async {
    return const LocalDiscoverySaveState.idle();
  }

  Future<void> save(CatAnalysisResult result) async {
    state = const AsyncData(
      LocalDiscoverySaveState(status: LocalDiscoverySaveStatus.saving),
    );

    try {
      final discoveryRepository = ref.read(discoveryRepositoryProvider);
      final rewardCalculator = ref.read(discoveryRewardCalculatorProvider);
      final factory = ref.read(catDiscoveryFactoryProvider);
      final discoveries = await discoveryRepository.getDiscoveriesForPlayer(
        LocalPlayerSession.playerId,
      );
      final duplicate = discoveries.any(
        (discovery) =>
            discovery.speciesId == result.primaryBreed.species.id &&
            discovery.variantId == result.variant.id,
      );
      final reward = rewardCalculator.rewardForDiscovery(
        species: result.primaryBreed.species,
        variant: result.variant,
        rarity: result.rarity,
        duplicate: duplicate,
      );
      final discovery = factory.create(
        result: result,
        discoveryId: 'local-${DateTime.now().microsecondsSinceEpoch}',
        playerId: LocalPlayerSession.playerId,
        discoveredAt: DateTime.now().toUtc(),
        friendshipPoints: reward.friendshipPoints,
      );

      await discoveryRepository.saveDiscovery(discovery);
      await _applyProgressReward(reward);
      ref.read(localDiscoverySessionProvider.notifier).addDiscovery(discovery);
      state = AsyncData(
        LocalDiscoverySaveState(
          status: LocalDiscoverySaveStatus.saved,
          discovery: discovery,
          reward: reward,
        ),
      );
    } on Object {
      state = const AsyncData(
        LocalDiscoverySaveState(
          status: LocalDiscoverySaveStatus.failure,
          message: 'CatDex could not save this discovery locally.',
        ),
      );
    }
  }

  DiscoveryReward previewReward(CatAnalysisResult result) {
    return ref
        .read(discoveryRewardCalculatorProvider)
        .rewardForDiscovery(
          species: result.primaryBreed.species,
          variant: result.variant,
          rarity: result.rarity,
          duplicate: false,
        );
  }

  Future<void> _applyProgressReward(DiscoveryReward reward) async {
    final progressRepository = ref.read(playerProgressRepositoryProvider);
    final levelCalculator = ref.read(levelCalculatorProvider);
    final progress = await progressRepository.getProgress(
      LocalPlayerSession.playerId,
    );
    final totalXp = progress.totalXp + reward.xp;

    await progressRepository.saveProgress(
      progress.copyWith(
        totalXp: totalXp,
        level: levelCalculator.levelForXp(totalXp),
        coins: progress.coins + reward.coins,
        discoveryCount: progress.discoveryCount + 1,
        duplicateDiscoveryCount:
            progress.duplicateDiscoveryCount + (reward.duplicate ? 1 : 0),
      ),
    );
  }
}
