import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_generation_performance.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cardGenerationPipelineProvider = Provider<CardGenerationPipeline>((ref) {
  return CardGenerationPipeline(
    remoteCardGenerationService: ref.watch(remoteCardGenerationServiceProvider),
    ref: ref,
  );
});

enum CardGenerationStage {
  illustration,
  recovery,
  render,
}

class CardGenerationResult {
  const CardGenerationResult({
    required this.generatedCardPathOrUrl,
    required this.discovery,
    this.failureReason,
  });

  final String? generatedCardPathOrUrl;
  final CatDiscovery discovery;
  final RemoteCardGenerationFailureReason? failureReason;

  bool get success =>
      generatedCardPathOrUrl != null &&
      generatedCardPathOrUrl!.trim().isNotEmpty;
}

class CardGenerationPipeline {
  const CardGenerationPipeline({
    required RemoteCardGenerationService remoteCardGenerationService,
    required Ref ref,
  }) : _remoteCardGenerationService = remoteCardGenerationService,
       _ref = ref;

  final RemoteCardGenerationService _remoteCardGenerationService;
  final Ref _ref;

  Future<CardGenerationResult> regenerateCardWithAiIllustration({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    String? debugRarityOverride,
    ValueChanged<CardGenerationStage>? onStageChanged,
  }) async {
    final totalTiming = CardGenerationPerformanceSpan.start(
      'CATDEX_PERF_FLUTTER_PIPELINE_TOTAL',
      discoveryId: discovery.id,
    );
    try {
      return await _regenerateCardWithAiIllustration(
        discovery: discovery,
        displayData: displayData,
        collectionNumber: collectionNumber,
        debugRarityOverride: debugRarityOverride,
        onStageChanged: onStageChanged,
      );
    } finally {
      totalTiming.finish();
    }
  }

  Future<CardGenerationResult> _regenerateCardWithAiIllustration({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    String? debugRarityOverride,
    ValueChanged<CardGenerationStage>? onStageChanged,
  }) async {
    debugPrint('CATDEX_CARD_REGENERATE_STARTED ${discovery.id}');
    debugPrint(
      'CATDEX_CARD_REGENERATE_DISCOVERY_NAME ${displayData.displayName}',
    );

    onStageChanged?.call(CardGenerationStage.illustration);
    final generated = await _remoteCardGenerationService.generateCard(
      discovery: discovery,
      displayData: displayData,
      collectionNumber: collectionNumber,
      debugRarityOverride: debugRarityOverride,
      onPending: (_) {
        onStageChanged?.call(CardGenerationStage.recovery);
      },
    );

    if (generated == null) {
      debugPrint('CATDEX_CARD_GENERATION_FAILED_KEEP_EXISTING_IMAGE');
      return CardGenerationResult(
        generatedCardPathOrUrl: null,
        discovery: discovery,
        failureReason: _remoteCardGenerationService.lastFailureReason,
      );
    }

    if (!isFinalGeneratedCardImageSource(generated.finalCardUrl)) {
      debugPrint('CATDEX_CARD_IMAGE_REJECTED_ORIGINAL_PHOTO_PATH');
      debugPrint('CATDEX_CARD_GENERATION_FAILED_KEEP_EXISTING_IMAGE');
      return CardGenerationResult(
        generatedCardPathOrUrl: null,
        discovery: discovery,
        failureReason: RemoteCardGenerationFailureReason.remoteApiFailure,
      );
    }

    onStageChanged?.call(CardGenerationStage.render);
    final updatedDiscovery = _discoveryWithRemoteGeneratedCard(
      discovery: discovery,
      generated: generated,
    );
    final persistedDiscovery = await _saveAndRefreshDiscovery(
      updatedDiscovery,
    );
    if (persistedDiscovery == null) {
      debugPrint('CATDEX_CARD_GENERATION_FAILED_KEEP_EXISTING_IMAGE');
      return CardGenerationResult(
        generatedCardPathOrUrl: null,
        discovery: discovery,
        failureReason: RemoteCardGenerationFailureReason.remoteApiFailure,
      );
    }
    final persistedUrl = canonicalGeneratedCardUrl(persistedDiscovery)!;
    debugPrint('CATDEX_CARD_IMAGE_SAVED_FINAL_URL $persistedUrl');

    return CardGenerationResult(
      generatedCardPathOrUrl: persistedUrl,
      discovery: persistedDiscovery,
    );
  }

  Future<CatDiscovery?> _saveAndRefreshDiscovery(
    CatDiscovery discovery,
  ) async {
    final persistenceTiming = CardGenerationPerformanceSpan.start(
      'CATDEX_PERF_FLUTTER_PERSISTENCE',
      discoveryId: discovery.id,
    );
    final expectedUrl = canonicalGeneratedCardUrl(discovery);
    debugPrint('CATDEX_CARD_RESULT_SAVE_STARTED');
    debugPrint('CATDEX_CARD_RESULT_SAVE_DISCOVERY_ID ${discovery.id}');
    debugPrint('CATDEX_CARD_RESULT_SAVE_FINAL_URL ${expectedUrl ?? '-'}');

    final repository = _ref.read(discoveryRepositoryProvider);
    try {
      await repository.saveDiscovery(discovery);
      debugPrint('CATDEX_CARD_RESULT_SAVE_PERSISTED true');
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_RESULT_SAVE_PERSISTED false error=$error');
    }

    try {
      final readBack = await repository.getDiscoveryById(discovery.id);
      final readBackUrl = canonicalGeneratedCardUrl(readBack);
      debugPrint('CATDEX_CARD_RESULT_READBACK_URL ${readBackUrl ?? '-'}');
      if (readBack == null ||
          readBackUrl == null ||
          readBackUrl != expectedUrl) {
        debugPrint('CATDEX_CARD_RESULT_READBACK_FAILED');
        return null;
      }

      persistenceTiming.finish();
      final uiRefreshTiming = CardGenerationPerformanceSpan.start(
        'CATDEX_PERF_FLUTTER_UI_REFRESH',
        discoveryId: discovery.id,
      );
      try {
        _ref
            .read(localDiscoverySessionProvider.notifier)
            .replaceDiscovery(readBack);
      } finally {
        uiRefreshTiming.finish();
      }
      debugPrint('CATDEX_CARD_RESULT_READBACK_SUCCESS');
      return readBack;
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_RESULT_READBACK_FAILED error=$error');
      return null;
    } finally {
      persistenceTiming.finish();
    }
  }

  CatDiscovery _discoveryWithRemoteGeneratedCard({
    required CatDiscovery discovery,
    required RemoteGeneratedCard generated,
  }) {
    final previousCard = discovery.card;
    final card = CatDiscoveryCard(
      cardId: previousCard?.cardId ?? 'card_${discovery.id}',
      discoveryId: discovery.id,
      cardFrameStyle: previousCard?.cardFrameStyle ?? 'green/simple',
      cardBackgroundStyle: previousCard?.cardBackgroundStyle ?? 'default',
      cardRarityStyle: previousCard?.cardRarityStyle ?? discovery.rarity.name,
      isEventCard: previousCard?.isEventCard ?? false,
      originalPhotoPath: previousCard?.originalPhotoPath ?? discovery.photoPath,
      generatedAt: DateTime.now(),
      eventThemeId: previousCard?.eventThemeId,
      cardImageUrl: generated.finalCardUrl,
      aiIllustrationUrl:
          generated.illustratedCatUrl ?? previousCard?.aiIllustrationUrl,
      aiIllustrationPath: previousCard?.aiIllustrationPath,
      illustratedCatImageUrl:
          generated.illustratedCatUrl ?? previousCard?.illustratedCatImageUrl,
      illustratedCatImagePath: previousCard?.illustratedCatImagePath,
      cutoutImagePath: previousCard?.cutoutImagePath,
      illustratedCatPath:
          generated.illustratedCatUrl ?? previousCard?.illustratedCatPath,
      cardTemplateId:
          generated.selectedTemplateKey ??
          previousCard?.cardTemplateId ??
          'external_og',
      cardVersion: (previousCard?.cardVersion ?? 0) + 1,
    );

    return discovery.copyWithCard(card);
  }
}
