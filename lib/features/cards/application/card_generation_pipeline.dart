import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_generation_performance.dart';
import 'package:catdex/features/cards/application/cat_card_legacy_migration.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/events/application/event_generation_coordinator.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/events/domain/services/event_policy.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/features/premium/domain/entities/premium_status.dart';
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
    this.eventFailure,
  });

  final String? generatedCardPathOrUrl;
  final CatDiscovery discovery;
  final RemoteCardGenerationFailureReason? failureReason;
  final EventCardGenerationFailure? eventFailure;

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
    final normalRecord = await _buildCardRecord(
      discovery: discovery,
      displayData: displayData,
      generated: generated,
      cardType: CatCardType.normal,
      generationRequestId: normalCardId(discovery.id),
      idempotencyKey: normalCardId(discovery.id),
    );
    final persistedRecord = await _saveAndRefreshCardRecord(normalRecord);
    if (persistedRecord == null) {
      debugPrint('CATDEX_CARD_GENERATION_FAILED_KEEP_EXISTING_IMAGE');
      return CardGenerationResult(
        generatedCardPathOrUrl: null,
        discovery: discovery,
        failureReason: RemoteCardGenerationFailureReason.remoteApiFailure,
      );
    }
    final updatedDiscovery = _discoveryWithRemoteGeneratedCard(
      discovery: discovery,
      generated: generated,
    );
    final persistedDiscovery = await _saveAndRefreshDiscovery(
      updatedDiscovery,
    );
    final persistedUrl = persistedRecord.finalCardUrl;
    debugPrint('CATDEX_CARD_IMAGE_SAVED_FINAL_URL $persistedUrl');

    return CardGenerationResult(
      generatedCardPathOrUrl: persistedUrl,
      discovery:
          persistedDiscovery ??
          discoveryWithCardRecordForDisplay(discovery, persistedRecord),
    );
  }

  Future<CardGenerationResult> _generateEventCard({
    required CatDexEvent event,
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    required String? debugRarityOverride,
    required ValueChanged<CardGenerationStage>? onStageChanged,
  }) async {
    final runtime = _ref.read(eventRuntimeConfigurationProvider);
    final hasCanonicalPremium = await _ref
        .read(monetizationServiceProvider)
        .isPremiumUser();
    final premiumStatus =
        runtime.premiumTestEntitlementEnabled || hasCanonicalPremium
        ? const PremiumStatus.premium()
        : const PremiumStatus.free();
    final coordinator = _ref.read(eventGenerationCoordinatorProvider);
    await _ref.read(catCardLegacyMigrationProvider.future);
    await _repairEventUsageFromCardRecords(
      event: event,
      playerId: discovery.playerId,
    );
    final requestId =
        '${discovery.id}_${DateTime.now().microsecondsSinceEpoch}';
    final reservationResult = await coordinator.reserve(
      event: event,
      premiumStatus: premiumStatus,
      playerId: discovery.playerId,
      requestId: requestId,
      now: runtime.debugModeEnabled ? event.startsAt : DateTime.now().toUtc(),
    );
    if (reservationResult is EventReservationRejected) {
      final failure = _eventFailureForReservation(reservationResult.reason);
      debugPrint('CATDEX_EVENT_CARD_BLOCKED reason=${failure.name}');
      return CardGenerationResult(
        generatedCardPathOrUrl: null,
        discovery: discovery,
        eventFailure: failure,
      );
    }

    final reservation =
        (reservationResult as EventReservationSuccess).reservation;
    debugPrint('CATDEX_EVENT_CARD_RESERVATION_CREATED');
    final eventRequest = EventCardGenerationRequest(
      eventKey: event.id,
      eventEdition: event.edition,
      variantId: reservation.variantId,
      tier: reservation.accessTier == EventAccessTier.premium
          ? EventArtworkTier.premium
          : EventArtworkTier.free,
      templateKey: reservation.templateKey,
      instructionKey: reservation.instructionKey,
      generationRequestId: reservation.requestId,
    );
    final cardRepository = _ref.read(catCardRepositoryProvider);
    final existingRecord = await cardRepository.getCardById(
      eventCardId(
        discoveryId: discovery.id,
        eventKey: eventRequest.eventKey,
        eventEdition: eventRequest.eventEdition,
        eventArtworkVariantId: eventRequest.variantId,
      ),
    );
    if (existingRecord?.isCompleted == true) {
      coordinator.release(reservation);
      debugPrint('CATDEX_EVENT_CARD_EXISTING_ARTWORK_USED');
      return CardGenerationResult(
        generatedCardPathOrUrl: existingRecord!.finalCardUrl,
        discovery: discovery,
      );
    }

    var reservationOpen = true;
    try {
      onStageChanged?.call(CardGenerationStage.illustration);
      final generated = await _remoteCardGenerationService.generateCard(
        discovery: discovery,
        displayData: displayData,
        collectionNumber: collectionNumber,
        debugRarityOverride: debugRarityOverride,
        eventRequest: eventRequest,
        onPending: (_) {
          debugPrint('CATDEX_EVENT_CARD_RENDERER_RECOVERY');
          onStageChanged?.call(CardGenerationStage.recovery);
        },
      );
      if (generated == null ||
          !isFinalGeneratedCardImageSource(generated.finalCardUrl)) {
        coordinator.release(reservation);
        reservationOpen = false;
        debugPrint('CATDEX_EVENT_CARD_USAGE_RELEASED');
        return CardGenerationResult(
          generatedCardPathOrUrl: null,
          discovery: discovery,
          failureReason: _remoteCardGenerationService.lastFailureReason,
          eventFailure:
              _remoteCardGenerationService.lastEventFailure ??
              EventCardGenerationFailure.rendererFailure,
        );
      }

      onStageChanged?.call(CardGenerationStage.render);
      debugPrint('CATDEX_EVENT_CARD_PERSISTENCE_STARTED');
      final eventRecord = await _buildCardRecord(
        discovery: discovery,
        displayData: displayData,
        generated: generated,
        cardType: CatCardType.event,
        generationRequestId: eventRequest.generationRequestId,
        idempotencyKey: eventRequest.idempotencyKey(discovery.id),
      );
      final persisted = await _saveAndRefreshCardRecord(eventRecord);
      if (!_persistedEventRecordMatches(
        record: persisted,
        request: eventRequest,
      )) {
        coordinator.release(reservation);
        reservationOpen = false;
        debugPrint('CATDEX_EVENT_CARD_USAGE_RELEASED');
        return CardGenerationResult(
          generatedCardPathOrUrl: null,
          discovery: discovery,
          eventFailure: EventCardGenerationFailure.eventPersistenceFailed,
        );
      }

      debugPrint('CATDEX_EVENT_CARD_PERSISTENCE_VERIFIED');
      debugPrint('CATDEX_EVENT_CARD_NORMAL_CARD_PRESERVED');
      debugPrint('CATDEX_EVENT_CARD_ADDED_TO_COLLECTION');
      if (!await coordinator.commit(reservation)) {
        return CardGenerationResult(
          generatedCardPathOrUrl: null,
          discovery: discovery,
          eventFailure: EventCardGenerationFailure.eventPersistenceFailed,
        );
      }
      reservationOpen = false;
      debugPrint('CATDEX_EVENT_CARD_USAGE_COMMITTED');
      return CardGenerationResult(
        generatedCardPathOrUrl: generated.finalCardUrl,
        discovery: discovery,
      );
    } on Object {
      if (reservationOpen) {
        coordinator.release(reservation);
        debugPrint('CATDEX_EVENT_CARD_USAGE_RELEASED');
      }
      rethrow;
    }
  }

  Future<CardGenerationResult> generateEventCard({
    required CatDexEvent event,
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    ValueChanged<CardGenerationStage>? onStageChanged,
  }) async {
    final totalTiming = CardGenerationPerformanceSpan.start(
      'CATDEX_PERF_FLUTTER_PIPELINE_TOTAL',
      discoveryId: discovery.id,
    );
    try {
      return await _generateEventCard(
        event: event,
        discovery: discovery,
        displayData: displayData,
        collectionNumber: collectionNumber,
        debugRarityOverride: null,
        onStageChanged: onStageChanged,
      );
    } finally {
      totalTiming.finish();
    }
  }

  EventCardGenerationFailure _eventFailureForReservation(
    EventReservationFailure failure,
  ) {
    return switch (failure) {
      EventReservationFailure.eventInactive =>
        EventCardGenerationFailure.eventInactive,
      EventReservationFailure.limitReached =>
        EventCardGenerationFailure.freeEventLimitReached,
      EventReservationFailure.reservationConflict =>
        EventCardGenerationFailure.eventReservationConflict,
    };
  }

  bool _persistedEventRecordMatches({
    required CatCardRecord? record,
    required EventCardGenerationRequest request,
  }) {
    return record != null &&
        record.isCompleted &&
        record.cardType == CatCardType.event &&
        record.eventKey == request.eventKey &&
        record.eventEdition == request.eventEdition &&
        record.eventArtworkVariantId == request.variantId &&
        record.eventArtworkTier == request.tier.wireValue &&
        record.eventTemplateKey == request.templateKey;
  }

  Future<void> _repairEventUsageFromCardRecords({
    required CatDexEvent event,
    required String playerId,
  }) async {
    final cardRepository = _ref.read(catCardRepositoryProvider);
    final cloudOwnerId = _ref.read(cloudUserIdProvider);
    final eventCards =
        (await cardRepository.getEventCards(
              event.id,
              event.edition,
            ))
            .where(
              (card) =>
                  card.isCompleted &&
                  (card.ownerId == playerId || card.ownerId == cloudOwnerId),
            )
            .toList();
    final usageRepository = _ref.read(eventUsageRepositoryProvider);
    final usage = await usageRepository.getSnapshot(
      playerId: playerId,
      eventId: event.id,
    );
    final ownedVariants = eventCards
        .map((card) => card.eventArtworkVariantId)
        .whereType<String>()
        .toSet();
    final requestIds = eventCards
        .map((card) => card.generationRequestId)
        .toSet();
    if (usage.committedUsage != eventCards.length ||
        !setEquals(usage.ownedVariantIds, ownedVariants) ||
        !usage.committedRequestIds.containsAll(requestIds)) {
      await usageRepository.saveSnapshot(
        playerId: playerId,
        eventId: event.id,
        snapshot: EventUsageSnapshot(
          committedUsage: eventCards.length,
          ownedVariantIds: ownedVariants,
          committedRequestIds: requestIds,
        ),
      );
      debugPrint('CATDEX_EVENT_USAGE_REPAIRED_FROM_CARD_RECORDS');
    }
  }

  Future<CatCardRecord> _buildCardRecord({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required RemoteGeneratedCard generated,
    required CatCardType cardType,
    required String generationRequestId,
    required String idempotencyKey,
  }) async {
    final now = DateTime.now().toUtc();
    final cardId = cardType == CatCardType.normal
        ? normalCardId(discovery.id)
        : eventCardId(
            discoveryId: discovery.id,
            eventKey: generated.eventKey!,
            eventEdition: generated.eventEdition!,
            eventArtworkVariantId: generated.eventArtworkVariantId!,
          );
    final existing = await _ref
        .read(catCardRepositoryProvider)
        .getCardById(cardId);
    return CatCardRecord(
      cardId: cardId,
      discoveryId: discovery.id,
      ownerId: discovery.playerId,
      cardType: cardType,
      rarity: discovery.rarity,
      finalCardUrl: generated.finalCardUrl,
      illustratedCatUrl: generated.illustratedCatUrl,
      templateKey:
          generated.eventTemplateKey ??
          generated.selectedTemplateKey ??
          'external_og',
      generationStatus: CatCardGenerationStatus.completed,
      generationRequestId: generationRequestId,
      idempotencyKey: idempotencyKey,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      eventKey: generated.eventKey,
      eventEdition: generated.eventEdition,
      eventArtworkVariantId: generated.eventArtworkVariantId,
      eventArtworkTier: generated.eventArtworkTier,
      eventTemplateKey: generated.eventTemplateKey,
      generatedDuringEventAt: generated.isEventCard ? now : null,
      isPremiumArtwork: generated.eventArtworkTier == 'premium',
      displayName: displayData.displayName,
      displaySpecies: displayData.displaySpecies,
      displayCoatColor: displayData.displayCoatColor,
      displayCoatPattern: displayData.displayCoatPattern,
      displayEyeColor: displayData.displayEyeColor,
      displayPersonality: displayData.displayPersonality,
      originalPhotoStoragePath: discovery.originalPhotoStoragePath,
    );
  }

  Future<CatCardRecord?> _saveAndRefreshCardRecord(
    CatCardRecord card,
  ) async {
    final repository = _ref.read(catCardRepositoryProvider);
    try {
      await repository.saveCard(card);
      final readBack = await repository.getCardById(card.cardId);
      if (readBack == null ||
          readBack.cardId != card.cardId ||
          readBack.discoveryId != card.discoveryId ||
          readBack.cardType != card.cardType ||
          readBack.finalCardUrl != card.finalCardUrl ||
          !readBack.isCompleted) {
        debugPrint('CATDEX_CARD_RECORD_READBACK_FAILED');
        return null;
      }
      _ref.read(catCardCollectionProvider.notifier).upsert(readBack);
      debugPrint('CATDEX_CARD_RECORD_READBACK_SUCCESS');
      return readBack;
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_RECORD_READBACK_FAILED error=$error');
      return null;
    }
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
      isEventCard: generated.isEventCard,
      originalPhotoPath: previousCard?.originalPhotoPath ?? discovery.photoPath,
      generatedAt: DateTime.now(),
      eventThemeId: generated.eventKey ?? previousCard?.eventThemeId,
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
      generationStatus: generated.generationStatus ?? 'completed',
      eventKey: generated.eventKey,
      eventEdition: generated.eventEdition,
      eventArtworkVariantId: generated.eventArtworkVariantId,
      eventArtworkTier: generated.eventArtworkTier,
      eventTemplateKey: generated.eventTemplateKey,
      generatedDuringEventAt: generated.isEventCard ? DateTime.now() : null,
    );

    return discovery.copyWithCard(card);
  }
}
