import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';

Map<String, Object?> catCardRecordToJson(CatCardRecord card) {
  return <String, Object?>{
    'cardId': card.cardId,
    'discoveryId': card.discoveryId,
    'ownerId': card.ownerId,
    'cardType': card.cardType.name,
    'rarity': card.rarity.name,
    'finalCardUrl': card.finalCardUrl,
    'illustratedCatUrl': card.illustratedCatUrl,
    'templateKey': card.templateKey,
    'generationStatus': card.generationStatus.name,
    'generationRequestId': card.generationRequestId,
    'idempotencyKey': card.idempotencyKey,
    'createdAt': card.createdAt.toUtc().toIso8601String(),
    'updatedAt': card.updatedAt.toUtc().toIso8601String(),
    'schemaVersion': card.schemaVersion,
    'eventKey': card.eventKey,
    'eventEdition': card.eventEdition,
    'eventArtworkVariantId': card.eventArtworkVariantId,
    'eventArtworkTier': card.eventArtworkTier,
    'eventTemplateKey': card.eventTemplateKey,
    'generatedDuringEventAt': card.generatedDuringEventAt
        ?.toUtc()
        .toIso8601String(),
    'isPremiumArtwork': card.isPremiumArtwork,
    'displayName': card.displayName,
    'displaySpecies': card.displaySpecies,
    'displayCoatColor': card.displayCoatColor,
    'displayCoatPattern': card.displayCoatPattern,
    'displayEyeColor': card.displayEyeColor,
    'displayPersonality': card.displayPersonality,
    'originalPhotoStoragePath': card.originalPhotoStoragePath,
  };
}

CatCardRecord catCardRecordFromJson(Map<String, Object?> json) {
  return CatCardRecord(
    cardId: json['cardId']! as String,
    discoveryId: json['discoveryId']! as String,
    ownerId: json['ownerId']! as String,
    cardType: CatCardType.values.byName(json['cardType']! as String),
    rarity: CatRarity.values.byName(json['rarity']! as String),
    finalCardUrl: json['finalCardUrl']! as String,
    illustratedCatUrl: json['illustratedCatUrl'] as String?,
    templateKey: json['templateKey']! as String,
    generationStatus: CatCardGenerationStatus.values.byName(
      json['generationStatus']! as String,
    ),
    generationRequestId: json['generationRequestId']! as String,
    idempotencyKey: json['idempotencyKey']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
    schemaVersion: json['schemaVersion'] as int? ?? 1,
    eventKey: json['eventKey'] as String?,
    eventEdition: json['eventEdition'] as String?,
    eventArtworkVariantId: json['eventArtworkVariantId'] as String?,
    eventArtworkTier: json['eventArtworkTier'] as String?,
    eventTemplateKey: json['eventTemplateKey'] as String?,
    generatedDuringEventAt: DateTime.tryParse(
      json['generatedDuringEventAt'] as String? ?? '',
    ),
    isPremiumArtwork: json['isPremiumArtwork'] as bool? ?? false,
    displayName: json['displayName'] as String?,
    displaySpecies: json['displaySpecies'] as String?,
    displayCoatColor: json['displayCoatColor'] as String?,
    displayCoatPattern: json['displayCoatPattern'] as String?,
    displayEyeColor: json['displayEyeColor'] as String?,
    displayPersonality: json['displayPersonality'] as String?,
    originalPhotoStoragePath: json['originalPhotoStoragePath'] as String?,
  );
}
