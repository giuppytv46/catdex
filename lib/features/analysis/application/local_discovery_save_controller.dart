import 'dart:io';
import 'dart:math';

import 'package:catdex/features/analysis/application/discovery_photo_storage_service.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/services/cat_discovery_factory.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/pending_discovery_sync.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> save(
    CatAnalysisResult result, {
    String? photoPath,
    String customName = 'Mochi',
    String suggestedName = 'Mochi',
    String? nickname,
  }) async {
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
      final photoStorage = ref.read(discoveryPhotoStorageServiceProvider);
      final chosenName = nickname ?? customName;
      final discoveryId = _newDiscoveryId();
      debugPrint('CATDEX_SAVE_SOURCE_IMAGE_PATH ${photoPath ?? '-'}');
      final stablePhotoPath = await photoStorage.storePhoto(
        discoveryId: discoveryId,
        sourcePath: photoPath,
      );
      debugPrint('CATDEX_SAVE_STABLE_IMAGE_PATH ${stablePhotoPath ?? '-'}');
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
        discoveryId: discoveryId,
        playerId: activeSession.playerId,
        discoveredAt: DateTime.now().toUtc(),
        friendshipPoints: reward.friendshipPoints,
        xpEarned: reward.xp,
        coinsEarned: reward.coins,
        customName: chosenName.trim().isEmpty ? suggestedName : chosenName,
        suggestedName: suggestedName,
        originalPhotoPath: stablePhotoPath,
        displayPhotoPath: stablePhotoPath,
      );
      final uploadedOriginalPath = await _uploadStableOriginalPhoto(
        discoveryId: discoveryId,
        stablePhotoPath: stablePhotoPath,
        playerId: activeSession.playerId,
      );
      debugPrint(
        'CATDEX_SAVE_UPLOADED_ORIGINAL_STORAGE_PATH '
        '${uploadedOriginalPath ?? '-'}',
      );
      if (uploadedOriginalPath != null) {
        discovery = _discoveryWithOriginalPhotoPath(
          discovery: discovery,
          originalPhotoPath: uploadedOriginalPath,
        );
        debugPrint(
          'CATDEX_ORIGINAL_PHOTO_STORAGE_PATH_SAVED $uploadedOriginalPath',
        );
      }

      await discoveryRepository.saveDiscovery(discovery);
      debugPrint(
        'CATDEX_DISCOVERY_SAVED_ORIGINAL_PHOTO_PATH '
        '${discovery.originalPhotoPath ?? '-'}',
      );
      debugPrint(
        'CATDEX_DISCOVERY_SAVED_PHOTO_PATH ${discovery.photoPath ?? '-'}',
      );
      debugPrint(
        'CATDEX_DISCOVERY_SAVED_DISPLAY_PHOTO_PATH '
        '${discovery.displayPhotoPath ?? '-'}',
      );
      final progress = await _applyProgressReward(reward);
      ref.read(localDiscoverySessionProvider.notifier).addDiscovery(discovery);
      ref.read(localPlayerProgressSessionProvider.notifier).progress = progress;
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

  void reset() {
    state = const AsyncData(LocalDiscoverySaveState.idle());
  }

  Future<PlayerProgress> _applyProgressReward(DiscoveryReward reward) async {
    final activeSession = ref.read(activeCatDexSessionProvider);
    final progressRepository = ref.read(playerProgressRepositoryProvider);
    final levelCalculator = ref.read(levelCalculatorProvider);
    final progress = await progressRepository.getProgress(
      activeSession.playerId,
    );
    final totalXp = progress.totalXp + reward.xp;

    final updatedProgress = progress.copyWith(
      totalXp: totalXp,
      level: levelCalculator.levelForXp(totalXp),
      coins: progress.coins + reward.coins,
      discoveryCount: progress.discoveryCount + 1,
      duplicateDiscoveryCount:
          progress.duplicateDiscoveryCount + (reward.duplicate ? 1 : 0),
    );

    await progressRepository.saveProgress(updatedProgress);

    return updatedProgress;
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

  Future<String?> _uploadStableOriginalPhoto({
    required String discoveryId,
    required String? stablePhotoPath,
    required String playerId,
  }) async {
    if (!ref.read(supabaseConfiguredProvider)) {
      return null;
    }
    if (stablePhotoPath == null || stablePhotoPath.trim().isEmpty) {
      return null;
    }
    final file = File(stablePhotoPath.trim());
    if (!file.existsSync()) {
      return null;
    }

    final safePlayerId = playerId.trim().isEmpty ? 'dev' : playerId.trim();
    final storagePath = 'catdex/originals/$safePlayerId/$discoveryId.jpg';
    debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_STARTED ${file.path}');
    debugPrint(
      'CATDEX_ORIGINAL_PHOTO_UPLOAD_BUCKET '
      '${SupabaseCatPhotoStorageRepository.catPhotosBucketName}',
    );
    debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_STORAGE_PATH $storagePath');

    try {
      final bytes = Uint8List.fromList(await file.readAsBytes());
      final client = ref.read(supabaseClientProvider);
      await client.storage
          .from(SupabaseCatPhotoStorageRepository.catPhotosBucketName)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final signedUrl = await client.storage
          .from(SupabaseCatPhotoStorageRepository.catPhotosBucketName)
          .createSignedUrl(storagePath, 60 * 60 * 24);
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_SUCCESS true');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_SIGNED_URL $signedUrl');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_ERROR -');
      return storagePath;
    } on Object catch (error) {
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_SUCCESS false');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_SIGNED_URL -');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_ERROR $error');
      return null;
    }
  }

  CatDiscovery _discoveryWithOriginalPhotoPath({
    required CatDiscovery discovery,
    required String originalPhotoPath,
  }) {
    final previousCard = discovery.card;
    final card = previousCard == null
        ? null
        : CatDiscoveryCard(
            cardId: previousCard.cardId,
            discoveryId: previousCard.discoveryId,
            cardFrameStyle: previousCard.cardFrameStyle,
            cardBackgroundStyle: previousCard.cardBackgroundStyle,
            cardRarityStyle: previousCard.cardRarityStyle,
            isEventCard: previousCard.isEventCard,
            originalPhotoPath: originalPhotoPath,
            generatedAt: previousCard.generatedAt,
            eventThemeId: previousCard.eventThemeId,
            cardImageUrl: previousCard.cardImageUrl,
            cardImagePath: previousCard.cardImagePath,
            aiIllustrationUrl: previousCard.aiIllustrationUrl,
            aiIllustrationPath: previousCard.aiIllustrationPath,
            illustratedCatImageUrl: previousCard.illustratedCatImageUrl,
            illustratedCatImagePath: previousCard.illustratedCatImagePath,
            cutoutImagePath: previousCard.cutoutImagePath,
            illustratedCatPath: previousCard.illustratedCatPath,
            cardTemplateId: previousCard.cardTemplateId,
            cardVersion: previousCard.cardVersion,
          );

    return CatDiscovery(
      id: discovery.id,
      playerId: discovery.playerId,
      speciesId: discovery.speciesId,
      variantId: discovery.variantId,
      rarity: discovery.rarity,
      personality: discovery.personality,
      traits: discovery.traits,
      discoveredAt: discovery.discoveredAt,
      friendshipPoints: discovery.friendshipPoints,
      customName: discovery.customName,
      suggestedName: discovery.suggestedName,
      city: discovery.city,
      country: discovery.country,
      photoPath: discovery.photoPath,
      originalPhotoPath: originalPhotoPath,
      displayPhotoPath: discovery.displayPhotoPath,
      story: discovery.story,
      funFact: discovery.funFact,
      coatColor: discovery.coatColor,
      coatPattern: discovery.coatPattern,
      eyeColor: discovery.eyeColor,
      hairLength: discovery.hairLength,
      estimatedAge: discovery.estimatedAge,
      xpEarned: discovery.xpEarned,
      coinsEarned: discovery.coinsEarned,
      confidenceScore: discovery.confidenceScore,
      card: card,
      favorite: discovery.favorite,
    );
  }
}
