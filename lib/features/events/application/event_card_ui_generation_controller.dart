import 'dart:async';

import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/application/card_generation_pipeline.dart';
import 'package:catdex/features/cards/application/card_generation_state_controller.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/events/application/event_ui_state.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EventUiGenerationPhase {
  idle,
  reserving,
  generating,
  recovering,
  persisting,
  completed,
  failed,
  blocked,
}

enum EventUiFailureReason {
  eventInactive,
  freeEventLimitReached,
  premiumRequired,
  premiumVerificationUnavailable,
  eventGenerationPending,
  eventArtworkValidationFailed,
  eventPersistenceFailed,
  rendererUnavailable,
  missingPhoto,
  photoUploadFailed,
  storagePermissionDenied,
  signedUrlFailed,
  variantSelectionRequired,
  selectedVariantInvalid,
  selectedVariantDisabled,
  selectedVariantAlreadyOwned,
  network,
  unknown,
}

@immutable
class EventUiGenerationState {
  const EventUiGenerationState({
    required this.phase,
    this.cardId,
    this.failureReason,
    this.longWait = false,
  });

  static const idle = EventUiGenerationState(
    phase: EventUiGenerationPhase.idle,
  );

  final EventUiGenerationPhase phase;
  final String? cardId;
  final EventUiFailureReason? failureReason;
  final bool longWait;

  bool get isInProgress => switch (phase) {
    EventUiGenerationPhase.reserving ||
    EventUiGenerationPhase.generating ||
    EventUiGenerationPhase.recovering ||
    EventUiGenerationPhase.persisting => true,
    _ => false,
  };
}

final eventCardUiGenerationProvider =
    NotifierProvider<
      EventCardUiGenerationController,
      Map<String, EventUiGenerationState>
    >(EventCardUiGenerationController.new);

class EventCardUiGenerationController
    extends Notifier<Map<String, EventUiGenerationState>> {
  final Map<String, Future<EventUiGenerationState>> _inFlight = {};

  @override
  Map<String, EventUiGenerationState> build() => const {};

  String keyFor(String eventKey, String discoveryId) =>
      '$eventKey::$discoveryId';

  EventUiGenerationState forSelection(
    String eventKey,
    String discoveryId,
  ) {
    return state[keyFor(eventKey, discoveryId)] ?? EventUiGenerationState.idle;
  }

  Future<EventUiGenerationState> generate({
    required CatDexEvent event,
    required CatDiscovery discovery,
    required int collectionNumber,
    String? selectedVariantId,
  }) {
    final key = keyFor(event.id, discovery.id);
    final current = _inFlight[key];
    if (current != null) {
      debugPrint('CATDEX_EVENT_UI_ERROR reason=event_generation_pending');
      return current;
    }
    final operation = _performGeneration(
      key: key,
      event: event,
      discovery: discovery,
      collectionNumber: collectionNumber,
      selectedVariantId: selectedVariantId,
    );
    _inFlight[key] = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_inFlight[key], operation)) {
          final removedOperation = _inFlight.remove(key);
          assert(
            identical(removedOperation, operation),
            'Only the matching event generation may clear its in-flight key.',
          );
        }
      }),
    );
    return operation;
  }

  Future<EventUiGenerationState> _performGeneration({
    required String key,
    required CatDexEvent event,
    required CatDiscovery discovery,
    required int collectionNumber,
    required String? selectedVariantId,
  }) async {
    final runtime = ref.read(eventRuntimeConfigurationProvider);
    if (runtime.activeEvent(DateTime.now().toUtc())?.id != event.id) {
      return _terminal(
        key,
        EventUiGenerationPhase.blocked,
        EventUiFailureReason.eventInactive,
      );
    }
    final remote = ref.read(remoteCardGenerationServiceProvider);
    if (!remote.isConfigured) {
      return _terminal(
        key,
        EventUiGenerationPhase.blocked,
        EventUiFailureReason.rendererUnavailable,
      );
    }

    final globalGeneration = ref.read(cardGenerationStateProvider.notifier);
    if (!globalGeneration.begin(
      discovery.id,
      label: 'Prepariamo la magia...',
    )) {
      return _terminal(
        key,
        EventUiGenerationPhase.blocked,
        EventUiFailureReason.eventGenerationPending,
      );
    }

    _set(
      key,
      const EventUiGenerationState(phase: EventUiGenerationPhase.reserving),
    );
    _scheduleLongWait(key);
    try {
      final display = const CatDisplayFormatter().fromDiscovery(discovery);
      final result = await ref
          .read(cardGenerationPipelineProvider)
          .generateEventCard(
            event: event,
            discovery: discovery,
            displayData: display,
            collectionNumber: collectionNumber,
            selectedVariantId: selectedVariantId,
            onStageChanged: (stage) {
              final phase = switch (stage) {
                CardGenerationStage.illustration =>
                  EventUiGenerationPhase.generating,
                CardGenerationStage.recovery =>
                  EventUiGenerationPhase.recovering,
                CardGenerationStage.render => EventUiGenerationPhase.persisting,
              };
              _set(
                key,
                EventUiGenerationState(
                  phase: phase,
                  longWait: state[key]?.longWait ?? false,
                ),
              );
              globalGeneration.updateLabel(
                discovery.id,
                switch (phase) {
                  EventUiGenerationPhase.generating =>
                    "Il tuo gatto sta entrando nell'evento...",
                  EventUiGenerationPhase.recovering =>
                    'La magia continua, attendi ancora un momento...',
                  EventUiGenerationPhase.persisting => 'Quasi pronta...',
                  _ => 'Creiamo la carta...',
                },
              );
            },
          );
      if (!result.success) {
        globalGeneration.fail(discovery.id);
        return _terminal(
          key,
          EventUiGenerationPhase.failed,
          _mapFailure(result.eventFailure, result.failureReason),
        );
      }

      await ref.read(catCardCollectionProvider.notifier).refresh();
      final cards = await ref
          .read(catCardRepositoryProvider)
          .getEventCards(event.id, event.edition);
      final matches =
          cards
              .where(
                (card) =>
                    card.discoveryId == discovery.id &&
                    card.isCompleted &&
                    card.finalCardUrl == result.generatedCardPathOrUrl,
              )
              .toList(growable: false)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (matches.isEmpty) {
        globalGeneration.fail(discovery.id);
        return _terminal(
          key,
          EventUiGenerationPhase.failed,
          EventUiFailureReason.eventPersistenceFailed,
        );
      }
      final cardId = matches.first.cardId;
      final completed = EventUiGenerationState(
        phase: EventUiGenerationPhase.completed,
        cardId: cardId,
      );
      _set(key, completed);
      globalGeneration.complete(discovery.id);
      ref.read(eventUiRefreshProvider.notifier).refresh();
      debugPrint('CATDEX_EVENT_UI_RESULT_CARD_ID $cardId');
      return completed;
    } on Object {
      globalGeneration.fail(discovery.id);
      debugPrint('CATDEX_EVENT_UI_ERROR reason=network');
      return _terminal(
        key,
        EventUiGenerationPhase.failed,
        EventUiFailureReason.network,
      );
    }
  }

  void reset(String eventKey, String discoveryId) {
    final key = keyFor(eventKey, discoveryId);
    state = {...state}..remove(key);
  }

  void _scheduleLongWait(String key) {
    unawaited(
      Future<void>.delayed(const Duration(seconds: 20), () {
        final current = state[key];
        if (current == null || !current.isInProgress) return;
        _set(
          key,
          EventUiGenerationState(
            phase: current.phase,
            cardId: current.cardId,
            failureReason: current.failureReason,
            longWait: true,
          ),
        );
      }),
    );
  }

  EventUiGenerationState _terminal(
    String key,
    EventUiGenerationPhase phase,
    EventUiFailureReason reason,
  ) {
    final terminal = EventUiGenerationState(
      phase: phase,
      failureReason: reason,
    );
    _set(key, terminal);
    debugPrint('CATDEX_EVENT_UI_ERROR reason=${_safeReason(reason)}');
    return terminal;
  }

  void _set(String key, EventUiGenerationState value) {
    state = {...state, key: value};
    debugPrint('CATDEX_EVENT_UI_GENERATION_STATE ${value.phase.name}');
  }

  EventUiFailureReason _mapFailure(
    EventCardGenerationFailure? eventFailure,
    RemoteCardGenerationFailureReason? remoteFailure,
  ) {
    if (eventFailure != null) {
      return switch (eventFailure) {
        EventCardGenerationFailure.eventInactive =>
          EventUiFailureReason.eventInactive,
        EventCardGenerationFailure.freeEventLimitReached =>
          EventUiFailureReason.freeEventLimitReached,
        EventCardGenerationFailure.premiumRequired =>
          EventUiFailureReason.premiumRequired,
        EventCardGenerationFailure.premiumVerificationUnavailable =>
          EventUiFailureReason.premiumVerificationUnavailable,
        EventCardGenerationFailure.eventGenerationPending ||
        EventCardGenerationFailure.eventReservationConflict =>
          EventUiFailureReason.eventGenerationPending,
        EventCardGenerationFailure.eventArtworkValidationFailed =>
          EventUiFailureReason.eventArtworkValidationFailed,
        EventCardGenerationFailure.eventPersistenceFailed =>
          EventUiFailureReason.eventPersistenceFailed,
        EventCardGenerationFailure.variantSelectionRequired =>
          EventUiFailureReason.variantSelectionRequired,
        EventCardGenerationFailure.selectedVariantInvalid =>
          EventUiFailureReason.selectedVariantInvalid,
        EventCardGenerationFailure.selectedVariantDisabled =>
          EventUiFailureReason.selectedVariantDisabled,
        EventCardGenerationFailure.selectedVariantAlreadyOwned =>
          EventUiFailureReason.selectedVariantAlreadyOwned,
        EventCardGenerationFailure.eventVariantInvalid ||
        EventCardGenerationFailure.eventVariantDisabled ||
        EventCardGenerationFailure.rendererFailure =>
          EventUiFailureReason.unknown,
      };
    }
    return switch (remoteFailure) {
      RemoteCardGenerationFailureReason.missingEndpoint =>
        EventUiFailureReason.rendererUnavailable,
      RemoteCardGenerationFailureReason.invalidPhotoUrl ||
      RemoteCardGenerationFailureReason.missingPhoto =>
        EventUiFailureReason.missingPhoto,
      RemoteCardGenerationFailureReason.photoUploadFailed =>
        EventUiFailureReason.photoUploadFailed,
      RemoteCardGenerationFailureReason.storagePermissionDenied =>
        EventUiFailureReason.storagePermissionDenied,
      RemoteCardGenerationFailureReason.signedUrlFailed =>
        EventUiFailureReason.signedUrlFailed,
      RemoteCardGenerationFailureReason.network => EventUiFailureReason.network,
      RemoteCardGenerationFailureReason.remoteApiFailure ||
      null => EventUiFailureReason.unknown,
    };
  }

  String _safeReason(EventUiFailureReason reason) => switch (reason) {
    EventUiFailureReason.eventInactive => 'event_inactive',
    EventUiFailureReason.freeEventLimitReached => 'free_limit_reached',
    EventUiFailureReason.premiumRequired => 'premium_required',
    EventUiFailureReason.premiumVerificationUnavailable =>
      'premium_verification_unavailable',
    EventUiFailureReason.eventGenerationPending => 'event_generation_pending',
    EventUiFailureReason.eventArtworkValidationFailed =>
      'artwork_validation_failed',
    EventUiFailureReason.eventPersistenceFailed => 'persistence_failed',
    EventUiFailureReason.rendererUnavailable => 'renderer_unavailable',
    EventUiFailureReason.missingPhoto => 'missing_photo',
    EventUiFailureReason.photoUploadFailed => 'photo_upload_failed',
    EventUiFailureReason.storagePermissionDenied => 'storage_permission_denied',
    EventUiFailureReason.signedUrlFailed => 'signed_url_failed',
    EventUiFailureReason.variantSelectionRequired =>
      'variant_selection_required',
    EventUiFailureReason.selectedVariantInvalid => 'selected_variant_invalid',
    EventUiFailureReason.selectedVariantDisabled => 'selected_variant_disabled',
    EventUiFailureReason.selectedVariantAlreadyOwned =>
      'selected_variant_already_owned',
    EventUiFailureReason.network => 'network',
    EventUiFailureReason.unknown => 'unknown',
  };
}
