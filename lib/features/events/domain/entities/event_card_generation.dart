enum EventArtworkTier {
  free,
  premium;

  String get wireValue => name;
}

class EventCardGenerationRequest {
  const EventCardGenerationRequest({
    required this.eventKey,
    required this.eventEdition,
    required this.variantId,
    required this.tier,
    required this.templateKey,
    required this.instructionKey,
    required this.generationRequestId,
  });

  final String eventKey;
  final String eventEdition;
  final String variantId;
  final EventArtworkTier tier;
  final String templateKey;
  final String instructionKey;
  final String generationRequestId;

  String idempotencyKey(String discoveryId) {
    return 'event:$discoveryId:$eventKey:$eventEdition:$variantId:'
        '$generationRequestId';
  }

  Map<String, Object?> toPayload() {
    return <String, Object?>{
      'eventKey': eventKey,
      'eventEdition': eventEdition,
      'eventArtworkVariantId': variantId,
      'eventArtworkTier': tier.wireValue,
      'eventTemplateKey': templateKey,
      'eventInstructionKey': instructionKey,
      'eventGenerationRequestId': generationRequestId,
      'isEventCard': true,
    };
  }
}

enum EventCardGenerationFailure {
  eventInactive,
  eventVariantInvalid,
  eventVariantDisabled,
  variantSelectionRequired,
  selectedVariantInvalid,
  selectedVariantDisabled,
  selectedVariantAlreadyOwned,
  freeEventLimitReached,
  premiumRequired,
  premiumVerificationUnavailable,
  eventReservationConflict,
  eventGenerationPending,
  eventArtworkValidationFailed,
  eventPersistenceFailed,
  rendererFailure,
}
