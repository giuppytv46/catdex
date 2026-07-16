import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';

enum CatCardType { normal, event }

enum CatCardGenerationStatus { pending, completed, failed }

class CatCardRecord {
  const CatCardRecord({
    required this.cardId,
    required this.discoveryId,
    required this.ownerId,
    required this.cardType,
    required this.rarity,
    required this.finalCardUrl,
    required this.templateKey,
    required this.generationStatus,
    required this.generationRequestId,
    required this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 1,
    this.illustratedCatUrl,
    this.eventKey,
    this.eventEdition,
    this.eventArtworkVariantId,
    this.eventArtworkTier,
    this.eventTemplateKey,
    this.generatedDuringEventAt,
    this.isPremiumArtwork = false,
    this.displayName,
    this.displaySpecies,
    this.displayCoatColor,
    this.displayCoatPattern,
    this.displayEyeColor,
    this.displayPersonality,
    this.originalPhotoStoragePath,
  });

  final String cardId;
  final String discoveryId;
  final String ownerId;
  final CatCardType cardType;
  final CatRarity rarity;
  final String finalCardUrl;
  final String? illustratedCatUrl;
  final String templateKey;
  final CatCardGenerationStatus generationStatus;
  final String generationRequestId;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;
  final String? eventKey;
  final String? eventEdition;
  final String? eventArtworkVariantId;
  final String? eventArtworkTier;
  final String? eventTemplateKey;
  final DateTime? generatedDuringEventAt;
  final bool isPremiumArtwork;
  final String? displayName;
  final String? displaySpecies;
  final String? displayCoatColor;
  final String? displayCoatPattern;
  final String? displayEyeColor;
  final String? displayPersonality;
  final String? originalPhotoStoragePath;

  bool get isCompleted =>
      generationStatus == CatCardGenerationStatus.completed &&
      isValidFinalCardUrl(finalCardUrl);

  String get logicalIdentity => cardType == CatCardType.normal
      ? normalCardId(discoveryId)
      : eventCardId(
          discoveryId: discoveryId,
          eventKey: eventKey!,
          eventEdition: eventEdition!,
          eventArtworkVariantId: eventArtworkVariantId!,
        );

  CatCardRecord copyWith({
    String? finalCardUrl,
    String? illustratedCatUrl,
    String? templateKey,
    CatCardGenerationStatus? generationStatus,
    DateTime? updatedAt,
  }) {
    return CatCardRecord(
      cardId: cardId,
      discoveryId: discoveryId,
      ownerId: ownerId,
      cardType: cardType,
      rarity: rarity,
      finalCardUrl: finalCardUrl ?? this.finalCardUrl,
      illustratedCatUrl: illustratedCatUrl ?? this.illustratedCatUrl,
      templateKey: templateKey ?? this.templateKey,
      generationStatus: generationStatus ?? this.generationStatus,
      generationRequestId: generationRequestId,
      idempotencyKey: idempotencyKey,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion,
      eventKey: eventKey,
      eventEdition: eventEdition,
      eventArtworkVariantId: eventArtworkVariantId,
      eventArtworkTier: eventArtworkTier,
      eventTemplateKey: eventTemplateKey,
      generatedDuringEventAt: generatedDuringEventAt,
      isPremiumArtwork: isPremiumArtwork,
      displayName: displayName,
      displaySpecies: displaySpecies,
      displayCoatColor: displayCoatColor,
      displayCoatPattern: displayCoatPattern,
      displayEyeColor: displayEyeColor,
      displayPersonality: displayPersonality,
      originalPhotoStoragePath: originalPhotoStoragePath,
    );
  }
}

String normalCardId(String discoveryId) => 'normal:$discoveryId';

String eventCardId({
  required String discoveryId,
  required String eventKey,
  required String eventEdition,
  required String eventArtworkVariantId,
}) {
  return 'event:$discoveryId:$eventKey:$eventEdition:'
      '$eventArtworkVariantId';
}

bool isValidFinalCardUrl(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      uri.path.toLowerCase().endsWith('final-card.png');
}

int normalCardCountForRarity(
  Iterable<CatCardRecord> cards,
  CatRarity rarity,
) {
  return cards
      .where(
        (card) =>
            card.cardType == CatCardType.normal &&
            card.rarity == rarity &&
            card.isCompleted,
      )
      .length;
}
