import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';

class CatDiscovery {
  const CatDiscovery({
    required this.id,
    required this.playerId,
    required this.speciesId,
    required this.variantId,
    required this.rarity,
    required this.personality,
    required this.traits,
    required this.discoveredAt,
    required this.friendshipPoints,
    String? customName,
    String? nickname,
    String? suggestedName,
    this.city,
    this.country,
    String? photoPath,
    String? originalPhotoPath,
    String? displayPhotoPath,
    this.originalPhotoStoragePath,
    this.story,
    this.funFact,
    this.coatColor,
    this.coatPattern,
    this.eyeColor,
    this.hairLength,
    this.estimatedAge,
    this.xpEarned,
    this.coinsEarned,
    this.confidenceScore,
    this.card,
    this.favorite = false,
    this.captureLocation,
    this.locationConsentVersion,
    this.locationCapturedAt,
  }) : suggestedName = suggestedName ?? nickname ?? '',
       customName = customName ?? nickname,
       originalPhotoPath = originalPhotoPath ?? photoPath,
       displayPhotoPath = displayPhotoPath ?? originalPhotoPath ?? photoPath,
       assert(friendshipPoints >= 0, 'friendshipPoints cannot be negative');

  final String id;
  final String playerId;
  final String speciesId;
  final String variantId;
  final CatRarity rarity;
  final CatPersonality personality;
  final List<CatTrait> traits;
  final DateTime discoveredAt;
  final int friendshipPoints;
  final String suggestedName;
  final String? customName;
  final String? city;
  final String? country;
  final String? originalPhotoPath;
  final String? displayPhotoPath;
  final String? originalPhotoStoragePath;
  final String? story;
  final String? funFact;
  final String? coatColor;
  final String? coatPattern;
  final String? eyeColor;
  final String? hairLength;
  final String? estimatedAge;
  final int? xpEarned;
  final int? coinsEarned;
  final double? confidenceScore;
  final CatDiscoveryCard? card;
  final bool favorite;
  final CatDiscoveryLocation? captureLocation;
  final String? locationConsentVersion;
  final DateTime? locationCapturedAt;

  String? get nickname => customName;
  String? get photoPath => displayPhotoPath ?? originalPhotoPath;

  CatDiscovery copyWith({
    String? customName,
    String? suggestedName,
    CatDiscoveryCard? card,
    CatDiscoveryLocation? captureLocation,
    String? locationConsentVersion,
    DateTime? locationCapturedAt,
    bool clearCaptureLocation = false,
  }) {
    return CatDiscovery(
      id: id,
      playerId: playerId,
      speciesId: speciesId,
      variantId: variantId,
      rarity: rarity,
      personality: personality,
      traits: traits,
      discoveredAt: discoveredAt,
      friendshipPoints: friendshipPoints,
      customName: customName ?? this.customName,
      suggestedName: suggestedName ?? this.suggestedName,
      city: city,
      country: country,
      originalPhotoPath: originalPhotoPath,
      displayPhotoPath: displayPhotoPath,
      originalPhotoStoragePath: originalPhotoStoragePath,
      story: story,
      funFact: funFact,
      coatColor: coatColor,
      coatPattern: coatPattern,
      eyeColor: eyeColor,
      hairLength: hairLength,
      estimatedAge: estimatedAge,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      confidenceScore: confidenceScore,
      card: card ?? this.card,
      favorite: favorite,
      captureLocation: clearCaptureLocation
          ? null
          : captureLocation ?? this.captureLocation,
      locationConsentVersion: clearCaptureLocation
          ? null
          : locationConsentVersion ?? this.locationConsentVersion,
      locationCapturedAt: clearCaptureLocation
          ? null
          : locationCapturedAt ??
                captureLocation?.capturedAt ??
                this.locationCapturedAt,
    );
  }

  CatDiscovery copyWithPhotoPaths({
    String? originalPhotoPath,
    String? displayPhotoPath,
    String? originalPhotoStoragePath,
  }) {
    return CatDiscovery(
      id: id,
      playerId: playerId,
      speciesId: speciesId,
      variantId: variantId,
      rarity: rarity,
      personality: personality,
      traits: traits,
      discoveredAt: discoveredAt,
      friendshipPoints: friendshipPoints,
      customName: customName,
      suggestedName: suggestedName,
      city: city,
      country: country,
      originalPhotoPath: originalPhotoPath ?? this.originalPhotoPath,
      displayPhotoPath: displayPhotoPath ?? this.displayPhotoPath,
      originalPhotoStoragePath:
          originalPhotoStoragePath ?? this.originalPhotoStoragePath,
      story: story,
      funFact: funFact,
      coatColor: coatColor,
      coatPattern: coatPattern,
      eyeColor: eyeColor,
      hairLength: hairLength,
      estimatedAge: estimatedAge,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      confidenceScore: confidenceScore,
      card: card,
      favorite: favorite,
      captureLocation: captureLocation,
      locationConsentVersion: locationConsentVersion,
      locationCapturedAt: locationCapturedAt,
    );
  }

  CatDiscovery copyWithCard(CatDiscoveryCard updatedCard) {
    return copyWith(card: updatedCard);
  }

  CatDiscovery copyWithLocation({
    CatDiscoveryLocation? captureLocation,
    String? locationConsentVersion,
    DateTime? locationCapturedAt,
    bool clearCaptureLocation = false,
  }) {
    return copyWith(
      captureLocation: captureLocation,
      locationConsentVersion: locationConsentVersion,
      locationCapturedAt: locationCapturedAt,
      clearCaptureLocation: clearCaptureLocation,
    );
  }
}

class CatDiscoveryCard {
  const CatDiscoveryCard({
    required this.cardId,
    required this.discoveryId,
    required this.cardFrameStyle,
    required this.cardBackgroundStyle,
    required this.cardRarityStyle,
    required this.isEventCard,
    required this.originalPhotoPath,
    required this.generatedAt,
    this.eventThemeId,
    this.cardImageUrl,
    this.cardImagePath,
    this.aiIllustrationUrl,
    this.aiIllustrationPath,
    this.illustratedCatImageUrl,
    this.illustratedCatImagePath,
    this.cutoutImagePath,
    this.illustratedCatPath,
    this.cardTemplateId = 'common_clean',
    this.cardVersion = 1,
    this.generationStatus,
    this.eventKey,
    this.eventEdition,
    this.eventArtworkVariantId,
    this.eventArtworkTier,
    this.eventTemplateKey,
    this.generatedDuringEventAt,
  }) : cardGeneratedAt = generatedAt;

  final String cardId;
  final String discoveryId;
  final String cardFrameStyle;
  final String cardBackgroundStyle;
  final String cardRarityStyle;
  final String? eventThemeId;
  final bool isEventCard;
  final String? cardImageUrl;
  final String? cardImagePath;
  final String? aiIllustrationUrl;
  final String? aiIllustrationPath;
  final String? illustratedCatImageUrl;
  final String? illustratedCatImagePath;
  final String? cutoutImagePath;
  final String? illustratedCatPath;
  final String cardTemplateId;
  final String? originalPhotoPath;
  final DateTime generatedAt;
  final DateTime? cardGeneratedAt;
  final int cardVersion;
  final String? generationStatus;
  final String? eventKey;
  final String? eventEdition;
  final String? eventArtworkVariantId;
  final String? eventArtworkTier;
  final String? eventTemplateKey;
  final DateTime? generatedDuringEventAt;
}
