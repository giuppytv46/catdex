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
import 'package:catdex/features/location/application/discovery_location_capture_service.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
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
    String? cloudStoragePath,
    String customName = '',
    String suggestedName = '',
    String? nickname,
    bool usesEditedDetails = false,
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
      debugPrint('CATDEX_DISCOVERY_SAVE_STARTED id=$discoveryId');
      debugPrint('CATDEX_SAVE_SOURCE_IMAGE_PATH ${photoPath ?? '-'}');
      debugPrint('CATDEX_SAVE_SOURCE_STORAGE_PATH ${cloudStoragePath ?? '-'}');
      final stablePhotoPath = await photoStorage.storePhoto(
        discoveryId: discoveryId,
        sourcePath: photoPath,
      );
      final stablePhotoRuntimePath = await photoStorage.resolveRuntimePath(
        stablePhotoPath,
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
      final locationOutcome = await _captureLocationWithoutBlockingSave();
      discovery = factory.create(
        result: result,
        discoveryId: discoveryId,
        playerId: activeSession.playerId,
        discoveredAt: DateTime.now().toUtc(),
        friendshipPoints: reward.friendshipPoints,
        xpEarned: reward.xp,
        coinsEarned: reward.coins,
        customName: chosenName,
        suggestedName: suggestedName,
        originalPhotoPath: stablePhotoPath,
        displayPhotoPath: stablePhotoPath,
        captureLocation: locationOutcome.location,
        locationConsentVersion: locationOutcome.locationConsentVersion,
      );
      debugPrint(
        'CATDEX_LOCATION_SAVE_DISCOVERY_ID id=$discoveryId '
        'hasLocation=${discovery.captureLocation != null}',
      );
      debugPrint(
        'CATDEX_CARD_METADATA_USES_EDITED_DETAILS $usesEditedDetails',
      );
      debugPrint('CATDEX_SAVED_COAT_COLOR ${discovery.coatColor ?? '-'}');
      debugPrint(
        'CATDEX_DISCOVERY_SAVE_PERSONALITY ${discovery.personality.name}',
      );
      debugPrint(
        'CATDEX_CARD_METADATA_PERSONALITY ${discovery.personality.name}',
      );
      final uploadedOriginalPath =
          _validStoragePath(cloudStoragePath) ??
          await _uploadStableOriginalPhoto(
            discoveryId: discoveryId,
            stablePhotoPath: stablePhotoRuntimePath,
            playerId: activeSession.playerId,
          );
      debugPrint(
        'CATDEX_SAVE_UPLOADED_ORIGINAL_STORAGE_PATH '
        '${uploadedOriginalPath ?? '-'}',
      );
      if (uploadedOriginalPath != null) {
        discovery = _discoveryWithOriginalPhotoStoragePath(
          discovery: discovery,
          originalPhotoStoragePath: uploadedOriginalPath,
        );
        debugPrint(
          'CATDEX_ORIGINAL_PHOTO_STORAGE_PATH_SAVED $uploadedOriginalPath',
        );
      }

      await discoveryRepository.saveDiscovery(discovery);
      debugPrint('CATDEX_DISCOVERY_SAVE_PERSISTED id=$discoveryId');
      final persistedDiscovery = await discoveryRepository.getDiscoveryById(
        discoveryId,
      );
      if (persistedDiscovery == null) {
        debugPrint('CATDEX_DISCOVERY_SAVE_READBACK_FAILED id=$discoveryId');
        throw StateError('Discovery read-after-write failed: $discoveryId');
      }
      discovery = persistedDiscovery;
      debugPrint('CATDEX_DISCOVERY_SAVE_READBACK_SUCCESS id=$discoveryId');
      debugPrint(
        'CATDEX_LOCATION_SAVE_PERSISTED '
        'hasLocation=${discovery.captureLocation != null}',
      );
      debugPrint(
        'CATDEX_LOCATION_SAVE_READBACK_SUCCESS '
        'hasLocation=${discovery.captureLocation != null}',
      );
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
      debugPrint(
        'CATDEX_DISCOVERY_IMAGE_FIELDS_SAVED '
        'displayPhotoPath=${discovery.displayPhotoPath ?? '-'} '
        'originalPhotoPath=${discovery.originalPhotoPath ?? '-'} '
        'originalPhotoStoragePath=${discovery.originalPhotoStoragePath ?? '-'} '
        'photoPath=${discovery.photoPath ?? '-'}',
      );
      final hasUsableLocalPhoto =
          stablePhotoRuntimePath != null &&
          File(stablePhotoRuntimePath).existsSync();
      debugPrint(
        'CATDEX_DISCOVERY_SAVED_HAS_USABLE_LOCAL_PHOTO '
        '$hasUsableLocalPhoto',
      );
      final progress = await _applyProgressReward(reward);
      final discoverySession = ref.read(
        localDiscoverySessionProvider.notifier,
      );
      await (discoverySession..addDiscovery(discovery)).refreshFromRepository();
      ref.read(localPlayerProgressSessionProvider.notifier).progress = progress;
      await _trackMissionProgressAfterSave(discovery);
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

  Future<void> _trackMissionProgressAfterSave(
    CatDiscovery discovery,
  ) async {
    try {
      await ref
          .read(dailyMissionControllerProvider.notifier)
          .trackDiscoverySaved(discovery);
    } on Object catch (error) {
      debugPrint(
        'CATDEX_MISSION_PROGRESS_TRACKING_SKIPPED '
        'reason=${error.runtimeType}',
      );
    }
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

  Future<DiscoveryLocationCaptureOutcome>
  _captureLocationWithoutBlockingSave() async {
    try {
      return await ref
          .read(discoveryLocationCaptureServiceProvider)
          .captureForDiscovery();
    } on Object catch (error) {
      debugPrint(
        'CATDEX_LOCATION_REQUEST_FAILED reason=unexpected_${error.runtimeType}',
      );
      return const DiscoveryLocationCaptureOutcome();
    }
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
    debugPrint('CATDEX_PHOTO_UPLOAD_STARTED ${file.path}');
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
      debugPrint('CATDEX_PHOTO_UPLOAD_SUCCESS true');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_SIGNED_URL $signedUrl');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_ERROR -');
      return storagePath;
    } on Object catch (error) {
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_SUCCESS false');
      debugPrint('CATDEX_PHOTO_UPLOAD_SUCCESS false');
      debugPrint('CATDEX_PHOTO_UPLOAD_FAILED $error');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_SIGNED_URL -');
      debugPrint('CATDEX_ORIGINAL_PHOTO_UPLOAD_ERROR $error');
      return null;
    }
  }

  String? _validStoragePath(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '-') {
      return null;
    }

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('/')) {
      return null;
    }

    return trimmed;
  }

  CatDiscovery _discoveryWithOriginalPhotoStoragePath({
    required CatDiscovery discovery,
    required String originalPhotoStoragePath,
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
            originalPhotoPath: previousCard.originalPhotoPath,
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
      originalPhotoPath: discovery.originalPhotoPath,
      displayPhotoPath: discovery.displayPhotoPath,
      originalPhotoStoragePath: originalPhotoStoragePath,
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
      captureLocation: discovery.captureLocation,
      locationConsentVersion: discovery.locationConsentVersion,
      locationCapturedAt: discovery.locationCapturedAt,
    );
  }
}
