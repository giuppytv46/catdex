import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

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
  }) : suggestedName = suggestedName ?? nickname ?? 'Mochi',
       customName = customName ?? nickname ?? suggestedName ?? 'Mochi',
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

  String? get nickname => customName;
  String? get photoPath => displayPhotoPath ?? originalPhotoPath;
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
}
