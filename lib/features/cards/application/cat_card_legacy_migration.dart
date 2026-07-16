import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catCardLegacyMigrationProvider = FutureProvider<int>((ref) async {
  final discoveries = ref.watch(localDiscoverySessionProvider);
  final repository = ref.read(catCardRepositoryProvider);
  final created = await migrateLegacyCatCardRecords(
    discoveries: discoveries,
    repository: repository,
  );
  if (created > 0) {
    await ref.read(catCardCollectionProvider.notifier).refresh();
  }
  return created;
});

@visibleForTesting
Future<int> migrateLegacyCatCardRecords({
  required Iterable<CatDiscovery> discoveries,
  required CatCardRepository repository,
}) async {
  var created = 0;
  debugPrint('CATDEX_CARD_LEGACY_MIGRATION_STARTED');
  for (final discovery in discoveries) {
    final record = legacyCardRecordFromDiscovery(discovery);
    if (record == null) continue;
    if (await repository.cardExists(record.logicalIdentity)) {
      debugPrint(
        'CATDEX_CARD_LEGACY_MIGRATION_SKIPPED_EXISTING ${record.cardId}',
      );
      continue;
    }
    await repository.saveCard(record);
    created += 1;
    debugPrint('CATDEX_CARD_LEGACY_MIGRATION_CREATED ${record.cardId}');
  }
  debugPrint('CATDEX_CARD_LEGACY_MIGRATION_COMPLETED created=$created');
  return created;
}

@visibleForTesting
CatCardRecord? legacyCardRecordFromDiscovery(CatDiscovery discovery) {
  final card = discovery.card;
  if (card == null || !isValidFinalCardUrl(card.cardImageUrl)) return null;
  final display = const CatDisplayFormatter().fromDiscovery(discovery);
  final isEvent =
      card.isEventCard &&
      card.eventKey?.isNotEmpty == true &&
      card.eventEdition?.isNotEmpty == true &&
      card.eventArtworkVariantId?.isNotEmpty == true;
  final cardId = isEvent
      ? eventCardId(
          discoveryId: discovery.id,
          eventKey: card.eventKey!,
          eventEdition: card.eventEdition!,
          eventArtworkVariantId: card.eventArtworkVariantId!,
        )
      : normalCardId(discovery.id);
  return CatCardRecord(
    cardId: cardId,
    discoveryId: discovery.id,
    ownerId: discovery.playerId,
    cardType: isEvent ? CatCardType.event : CatCardType.normal,
    rarity: discovery.rarity,
    finalCardUrl: card.cardImageUrl!,
    illustratedCatUrl: card.illustratedCatImageUrl ?? card.aiIllustrationUrl,
    templateKey: card.eventTemplateKey ?? card.cardTemplateId,
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'legacy:${card.cardId}',
    idempotencyKey: 'legacy:$cardId',
    createdAt: card.generatedAt,
    updatedAt: card.generatedAt,
    eventKey: isEvent ? card.eventKey : null,
    eventEdition: isEvent ? card.eventEdition : null,
    eventArtworkVariantId: isEvent ? card.eventArtworkVariantId : null,
    eventArtworkTier: isEvent ? card.eventArtworkTier : null,
    eventTemplateKey: isEvent ? card.eventTemplateKey : null,
    generatedDuringEventAt: isEvent
        ? card.generatedDuringEventAt ?? card.generatedAt
        : null,
    isPremiumArtwork: isEvent && card.eventArtworkTier == 'premium',
    displayName: display.displayName,
    displaySpecies: display.displaySpecies,
    displayCoatColor: display.displayCoatColor,
    displayCoatPattern: display.displayCoatPattern,
    displayEyeColor: display.displayEyeColor,
    displayPersonality: display.displayPersonality,
    originalPhotoStoragePath: discovery.originalPhotoStoragePath,
  );
}

CatDiscovery discoveryWithCardRecordForDisplay(
  CatDiscovery discovery,
  CatCardRecord card,
) {
  final previous = discovery.card;
  return discovery.copyWithCard(
    CatDiscoveryCard(
      cardId: card.cardId,
      discoveryId: discovery.id,
      cardFrameStyle: previous?.cardFrameStyle ?? 'green/simple',
      cardBackgroundStyle: previous?.cardBackgroundStyle ?? 'default',
      cardRarityStyle: card.rarity.name,
      isEventCard: card.cardType == CatCardType.event,
      originalPhotoPath: previous?.originalPhotoPath ?? discovery.photoPath,
      generatedAt: card.createdAt,
      eventThemeId: card.eventKey,
      cardImageUrl: card.finalCardUrl,
      aiIllustrationUrl: card.illustratedCatUrl,
      illustratedCatImageUrl: card.illustratedCatUrl,
      illustratedCatPath: card.illustratedCatUrl,
      cardTemplateId: card.templateKey,
      cardVersion: previous?.cardVersion ?? 1,
      generationStatus: card.generationStatus.name,
      eventKey: card.eventKey,
      eventEdition: card.eventEdition,
      eventArtworkVariantId: card.eventArtworkVariantId,
      eventArtworkTier: card.eventArtworkTier,
      eventTemplateKey: card.eventTemplateKey,
      generatedDuringEventAt: card.generatedDuringEventAt,
    ),
  );
}
