import 'dart:math';

import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/services/cat_discovery_factory.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/pending_discovery_sync.dart';
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

    CatDiscovery? discovery;
    DiscoveryReward? reward;

    try {
      final activeSession = ref.read(activeCatDexSessionProvider);
      final discoveryRepository = ref.read(discoveryRepositoryProvider);
      final rewardCalculator = ref.read(discoveryRewardCalculatorProvider);
      final factory = ref.read(catDiscoveryFactoryProvider);
      final discoveries = await discoveryRepository.getDiscoveriesForPlayer(
        activeSession.playerId,
      );
      final duplicate = discoveries.any(
        (discovery) =>
            discovery.speciesId == result.primaryBreed.species.id &&
            discovery.variantId == result.variant.id,
      );
      reward = rewardCalculator.rewardForDiscovery(
        species: result.primaryBreed.species,
        variant: result.variant,
        rarity: result.rarity,
        duplicate: duplicate,
      );
      discovery = factory.create(
        result: result,
        discoveryId: _newDiscoveryId(),
        playerId: activeSession.playerId,
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
      final pendingSync = await _queuePendingSync(
        discovery: discovery,
        reward: reward,
      );
      state = AsyncData(
        LocalDiscoverySaveState(
          status: LocalDiscoverySaveStatus.failure,
          discovery: discovery,
          reward: reward,
          message:
              'CatDex could not save this discovery right now. Please retry.',
          pendingSync: pendingSync,
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
    final activeSession = ref.read(activeCatDexSessionProvider);
    final progressRepository = ref.read(playerProgressRepositoryProvider);
    final levelCalculator = ref.read(levelCalculatorProvider);
    final progress = await progressRepository.getProgress(
      activeSession.playerId,
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

  Future<PendingDiscoverySync?> _queuePendingSync({
    required CatDiscovery? discovery,
    required DiscoveryReward? reward,
  }) async {
    final activeSession = ref.read(activeCatDexSessionProvider);
    if (!activeSession.cloudSyncEnabled ||
        discovery == null ||
        reward == null) {
      return null;
    }

    final pendingSync = PendingDiscoverySync(
      id: 'pending-${discovery.id}',
      discovery: discovery,
      reward: reward,
      reason: PendingDiscoverySyncReason.cloudSaveFailed,
      createdAt: DateTime.now().toUtc(),
      lastErrorMessage: 'Cloud save failed.',
    );

    await ref
        .read(pendingSyncQueueRepositoryProvider)
        .enqueueDiscovery(pendingSync);
    ref.read(localDiscoverySessionProvider.notifier).addDiscovery(discovery);

    return pendingSync;
  }

  String _newDiscoveryId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
