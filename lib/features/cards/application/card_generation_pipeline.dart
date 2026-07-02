import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
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
    );

    if (generated == null) {
      return CardGenerationResult(
        generatedCardPathOrUrl: null,
        discovery: discovery,
        failureReason: _remoteCardGenerationService.lastFailureReason,
      );
    }

    onStageChanged?.call(CardGenerationStage.render);
    final updatedDiscovery = _discoveryWithRemoteGeneratedCard(
      discovery: discovery,
      generated: generated,
    );
    await _saveAndRefreshDiscovery(updatedDiscovery);

    return CardGenerationResult(
      generatedCardPathOrUrl: generated.finalCardUrl,
      discovery: updatedDiscovery,
    );
  }

  Future<void> _saveAndRefreshDiscovery(CatDiscovery discovery) async {
    await _ref.read(discoveryRepositoryProvider).saveDiscovery(discovery);
    _ref
        .read(localDiscoverySessionProvider.notifier)
        .replaceDiscovery(discovery);
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
      cardImagePath: previousCard?.cardImagePath,
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

    return _copyDiscoveryWithCard(discovery: discovery, card: card);
  }

  CatDiscovery _copyDiscoveryWithCard({
    required CatDiscovery discovery,
    required CatDiscoveryCard card,
  }) {
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
